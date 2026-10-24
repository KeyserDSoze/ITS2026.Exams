#requires -Version 5.1
<#
.SYNOPSIS
    Soluzione automatica docente del facsimile Infrastructure - Service Desk ITS.
.DESCRIPTION
    Versione 2: conserva anche i permessi generici ereditati di Windows.
    Eseguire nella VM Windows Server con Windows PowerShell 5.1 x64 elevato.
    Legge exam-config.json, configura il laboratorio e avvia il grader.
    Puo essere rilanciato: aggiorna gli elementi dell'esercizio gia presenti.
    Non modifica consegna, configurazione e grader; il grader aggiorna il suo contatore.
    Per un nuovo utente genera una password casuale, mostrata solo in console.
    Per un utente esistente conserva la password, salvo -UserPassword.
    Exit: 0 = grader 20/20; 1 = grader con FAIL; 2 = errore di configurazione;
    3010 = riavvio necessario: riavviare la VM e rilanciare lo script.
.EXAMPLE
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Exam\solution\solution-docente.ps1 -ExamRoot C:\Exam
#>
[CmdletBinding()]
param(
    [string]$ExamRoot,
    [Security.SecureString]$UserPassword
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Assert-SolutionCondition {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Assert-SolutionEnvironment {
    Assert-SolutionCondition ($env:OS -eq 'Windows_NT' -and
        $PSVersionTable.PSEdition -eq 'Desktop' -and [Environment]::Is64BitProcess) `
        'Usare Windows PowerShell 5.1 a 64 bit (powershell.exe) nella VM Windows Server.'
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    Assert-SolutionCondition ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) `
        'Aprire Windows PowerShell come amministratore.'
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    Assert-SolutionCondition ($os.ProductType -eq 3) `
        'Lo script richiede un server autonomo/membro, non un PC client o un controller di dominio.'
}

function Resolve-ExamRoot {
    param([string]$RequestedRoot, [string]$ScriptDirectory)
    if ($RequestedRoot) {
        return (Resolve-Path -LiteralPath $RequestedRoot -ErrorAction Stop).ProviderPath
    }
    foreach ($candidate in @($ScriptDirectory, (Split-Path -Parent $ScriptDirectory), 'C:\Exam')) {
        if ($candidate -and (Test-Path -LiteralPath (Join-Path $candidate 'exam-config.json') -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $candidate).ProviderPath
        }
    }
    throw 'Pacchetto Exam non trovato. Specificare -ExamRoot con il percorso della cartella estratta.'
}

function Read-SolutionConfig {
    param([string]$Root)
    $configPath = Join-Path $Root 'exam-config.json'
    $idPath = Join-Path $Root '.exam-id'
    Assert-SolutionCondition (Test-Path -LiteralPath $configPath -PathType Leaf) 'exam-config.json assente.'
    Assert-SolutionCondition (Test-Path -LiteralPath $idPath -PathType Leaf) '.exam-id assente.'
    $config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $id = (Get-Content -LiteralPath $idPath -Raw -Encoding UTF8).Trim()
    Assert-SolutionCondition ($id -ceq 'INFRA-FACSIMILE-03|ITS-SERVICEDESK-BACKUP-2026' -and
        $id -ceq $config.examId -and $config.schemaVersion -eq 1) 'Pacchetto non compatibile con questa soluzione.'
    # Limitare la soluzione ai nomi e ai percorsi di questo laboratorio.
    $expected = @{
        siteName = 'ITS-ServiceDesk'; physicalPath = 'C:\LabWeb\ServiceDesk'; port = 8107
        bindingIPAddress = '*'; bindingHostName = ''; firewallRule = 'ITS ServiceDesk HTTP 8107'
        localUser = 'desk_operator'; localGroup = 'DeskOperators'; dataFolder = 'C:\ServiceDesk\Dati'
        expectedText = 'SERVICE DESK ITS - OK'; scheduledTask = 'ServiceDeskBackup'; maxScore = 20
    }
    foreach ($name in $expected.Keys) {
        Assert-SolutionCondition ($null -ne $config.PSObject.Properties[$name] -and
            [string]$config.$name -ceq [string]$expected[$name]) "Valore inatteso in exam-config.json: $name."
    }
    $taskExpected = @{
        path = '\'; dailyAt = '17:15'; daysInterval = 1; principalSid = 'S-1-5-18'
        runLevel = 'HighestAvailable'; execute = '%SystemRoot%\System32\cmd.exe'
        arguments = '/c copy /Y "C:\LabWeb\ServiceDesk\index.html" "C:\ServiceDesk\Dati\homepage-backup.html"'
        backupFile = 'C:\ServiceDesk\Dati\homepage-backup.html'
    }
    foreach ($name in $taskExpected.Keys) {
        Assert-SolutionCondition ($null -ne $config.task.PSObject.Properties[$name] -and
            [string]$config.task.$name -ceq [string]$taskExpected[$name]) "Valore inatteso nella Scheduled Task: $name."
    }
    foreach ($file in @('website\index.html', 'grader\grade-infra.ps1')) {
        Assert-SolutionCondition (Test-Path -LiteralPath (Join-Path $Root $file) -PathType Leaf) "File assente: $file."
    }
    $html = Get-Content -LiteralPath (Join-Path $Root 'website\index.html') -Raw -Encoding UTF8
    Assert-SolutionCondition ($html.Contains($config.expectedText)) 'La pagina fornita non contiene il testo atteso.'
    return $config
}

function Install-ExamIis {
    Import-Module ServerManager -ErrorAction Stop
    $names = @('Web-Server', 'Web-Static-Content', 'Web-Default-Doc', 'Web-Mgmt-Console', 'Web-Scripting-Tools')
    $features = @(Get-WindowsFeature -Name $names -ErrorAction Stop)
    Assert-SolutionCondition ($features.Count -eq $names.Count) 'Uno o piu componenti IIS richiesti non sono disponibili.'
    if (@($features | Where-Object { -not $_.Installed }).Count -gt 0) {
        $installation = Install-WindowsFeature -Name $names -IncludeManagementTools -ErrorAction Stop
        Assert-SolutionCondition ($installation.Success -eq $true) 'Installazione IIS non completata.'
        if ([string]$installation.RestartNeeded -eq 'Yes') { return $true }
    }
    Import-Module WebAdministration -ErrorAction Stop
    Set-Service -Name W3SVC -StartupType Automatic -ErrorAction Stop
    Start-Service -Name W3SVC -ErrorAction Stop
    return $false
}

function New-ExamPassword {
    $bytes = New-Object byte[] 24
    $rng = New-Object Security.Cryptography.RNGCryptoServiceProvider
    try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
    $plain = 'P!8a-' + [Convert]::ToBase64String($bytes)
    return [pscustomobject]@{
        Secure = (ConvertTo-SecureString -String $plain -AsPlainText -Force)
        Plain = $plain
    }
}

function Set-ExamAccounts {
    param($Config, [Security.SecureString]$Password)
    Import-Module Microsoft.PowerShell.LocalAccounts -ErrorAction Stop
    $user = Get-LocalUser -Name $Config.localUser -ErrorAction SilentlyContinue
    if ($null -eq $user) {
        $generated = $null
        if ($null -eq $Password) {
            $generated = New-ExamPassword
            $Password = $generated.Secure
        }
        $user = New-LocalUser -Name $Config.localUser -Password $Password `
            -Description 'Utente del laboratorio Infrastructure ITS' -AccountNeverExpires `
            -PasswordNeverExpires -ErrorAction Stop
        if ($null -ne $generated) {
            Write-Host "Password generata per $($Config.localUser): $($generated.Plain)" -ForegroundColor Yellow
        }
    } else {
        if ($null -ne $Password) { Set-LocalUser -Name $Config.localUser -Password $Password -ErrorAction Stop }
        Set-LocalUser -Name $Config.localUser -AccountNeverExpires -PasswordNeverExpires $true -ErrorAction Stop
    }
    Enable-LocalUser -Name $Config.localUser -ErrorAction Stop
    $group = Get-LocalGroup -Name $Config.localGroup -ErrorAction SilentlyContinue
    if ($null -eq $group) {
        $group = New-LocalGroup -Name $Config.localGroup -Description 'Editor della cartella dati dello sportello IT' -ErrorAction Stop
    }
    $members = @(Get-LocalGroupMember -Group $group -ErrorAction Stop)
    if (@($members | Where-Object { $_.SID.Value -eq $user.SID.Value }).Count -eq 0) {
        Add-LocalGroupMember -Group $group -Member $user -ErrorAction Stop
    }
    return [pscustomobject]@{ User = $user; Group = $group }
}

function New-ExamAccessRule {
    param([Security.Principal.IdentityReference]$Identity, [Security.AccessControl.FileSystemRights]$Rights)
    return New-Object Security.AccessControl.FileSystemAccessRule($Identity, $Rights,
        [Security.AccessControl.InheritanceFlags]'ContainerInherit, ObjectInherit',
        [Security.AccessControl.PropagationFlags]::None,
        [Security.AccessControl.AccessControlType]::Allow)
}

function Save-ExamDirectoryAcl {
    param([string]$Path, [Security.AccessControl.DirectorySecurity]$Acl)
    # Persistenza .NET delle sole sezioni modificate; non riscrivere audit,
    # proprietario o gruppo quando si stanno correggendo solo i permessi.
    [IO.Directory]::SetAccessControl($Path, $Acl)
}

function Set-ExamDataPermissions {
    param($Config, $Accounts)
    New-Item -ItemType Directory -Path $Config.dataFolder -Force -ErrorAction Stop | Out-Null
    $acl = Get-Acl -LiteralPath $Config.dataFolder -ErrorAction Stop
    # Conservare le ACE a livello binario: possono contenere diritti generici
    # validi per Windows (es. GENERIC_ALL 0x10000000 su CREATOR OWNER) che il
    # costruttore FileSystemAccessRule non accetta. Copiare le ACE conserva
    # maschere, flag di propagazione e SID senza convertirne i diritti.
    $raw = [Security.AccessControl.RawSecurityDescriptor]::new($acl.GetSecurityDescriptorBinaryForm(), 0)
    $subjects = @($Accounts.User.SID.Value, $Accounts.Group.SID.Value)
    $common = @('S-1-1-0', 'S-1-5-11', 'S-1-5-32-545')
    $denied = @()
    $allowed = @()
    $other = @()
    $revision = [byte]2
    if ($null -ne $raw.DiscretionaryAcl) {
        $revision = $raw.DiscretionaryAcl.Revision
        foreach ($ace in $raw.DiscretionaryAcl) {
            $qualified = $ace -is [Security.AccessControl.QualifiedAce]
            if ($qualified -and ($ace.SecurityIdentifier.Value -in $subjects -or
                ($ace.SecurityIdentifier.Value -in $common -and
                    $ace.AceQualifier -eq [Security.AccessControl.AceQualifier]::AccessDenied))) {
                continue
            }
            $preserved = $ace.Copy()
            $preserved.AceFlags = [Security.AccessControl.AceFlags]([int]$preserved.AceFlags -band
                (-bnot [int][Security.AccessControl.AceFlags]::Inherited))
            # Dopo la conversione in ACE esplicite, mantenere l'ordine canonico:
            # tutte le Deny prima delle Allow, preservando l'ordine in ogni classe.
            if ($qualified -and $ace.AceQualifier -eq [Security.AccessControl.AceQualifier]::AccessDenied) {
                $denied += $preserved
            } elseif ($qualified -and $ace.AceQualifier -eq [Security.AccessControl.AceQualifier]::AccessAllowed) {
                $allowed += $preserved
            } else {
                $other += $preserved
            }
        }
    }
    $preservedAces = @($denied) + @($allowed) + @($other)
    $dacl = [Security.AccessControl.RawAcl]::new($revision, $preservedAces.Count)
    foreach ($ace in $preservedAces) { $dacl.InsertAce($dacl.Count, $ace) }
    $raw.DiscretionaryAcl = $dacl
    $flags = [int]$raw.ControlFlags -bor [int][Security.AccessControl.ControlFlags]::DiscretionaryAclProtected -bor
        [int][Security.AccessControl.ControlFlags]::DiscretionaryAclPresent
    $autoInheritance = [int][Security.AccessControl.ControlFlags]::DiscretionaryAclAutoInherited -bor
        [int][Security.AccessControl.ControlFlags]::DiscretionaryAclAutoInheritRequired
    $raw.SetFlags([Security.AccessControl.ControlFlags]($flags -band (-bnot $autoInheritance)))
    $binary = New-Object byte[] $raw.BinaryLength
    $raw.GetBinaryForm($binary, 0)
    $acl.SetSecurityDescriptorBinaryForm($binary, [Security.AccessControl.AccessControlSections]::Access)
    foreach ($sidValue in @('S-1-5-18', 'S-1-5-32-544')) {
        $sid = New-Object Security.Principal.SecurityIdentifier($sidValue)
        $acl.SetAccessRule((New-ExamAccessRule $sid 'FullControl'))
    }
    $acl.AddAccessRule((New-ExamAccessRule $Accounts.Group.SID 'Modify'))
    Save-ExamDirectoryAcl $Config.dataFolder $acl
}

function Set-ExamWebsite {
    param($Config, [string]$Root)
    New-Item -ItemType Directory -Path $Config.physicalPath -Force -ErrorAction Stop | Out-Null
    Copy-Item -LiteralPath (Join-Path $Root 'website\index.html') `
        -Destination (Join-Path $Config.physicalPath 'index.html') -Force -ErrorAction Stop
    $poolName = $Config.siteName + '-Pool'
    $binding = '{0}:{1}:{2}' -f $Config.bindingIPAddress, $Config.port, $Config.bindingHostName
    Add-Type -Path (Join-Path $env:SystemRoot 'System32\inetsrv\Microsoft.Web.Administration.dll') -ErrorAction Stop
    $manager = New-Object Microsoft.Web.Administration.ServerManager
    try {
        foreach ($otherSite in $manager.Sites) {
            if ($otherSite.Name -ieq $Config.siteName) { continue }
            foreach ($otherBinding in $otherSite.Bindings) {
                Assert-SolutionCondition (-not ($otherBinding.Protocol -ieq 'http' -and
                    $otherBinding.BindingInformation -ieq $binding)) `
                    "Binding $binding gia assegnato al sito '$($otherSite.Name)'."
            }
        }
        $pool = $manager.ApplicationPools[$poolName]
        if ($null -eq $pool) { $pool = $manager.ApplicationPools.Add($poolName) }
        $pool.ManagedRuntimeVersion = ''
        $pool.AutoStart = $true
        $pool.ProcessModel.IdentityType = [Microsoft.Web.Administration.ProcessModelIdentityType]::ApplicationPoolIdentity
        $site = $manager.Sites[$Config.siteName]
        if ($null -eq $site) {
            $site = $manager.Sites.Add($Config.siteName, 'http', $binding, $Config.physicalPath)
        } else {
            $site.Applications['/'].VirtualDirectories['/'].PhysicalPath = $Config.physicalPath
            $exists = @($site.Bindings | Where-Object {
                $_.Protocol -ieq 'http' -and $_.BindingInformation -ieq $binding
            }).Count -gt 0
            if (-not $exists) { $site.Bindings.Add($binding, 'http') | Out-Null }
        }
        $site.ServerAutoStart = $true
        $site.Applications['/'].ApplicationPoolName = $poolName
        $manager.CommitChanges()
        # Configurazione nel file applicationHost.config, limitata al sito.
        $appHost = $manager.GetApplicationHostConfiguration()
        $anonymous = $appHost.GetSection('system.webServer/security/authentication/anonymousAuthentication', $Config.siteName)
        $anonymous['enabled'] = $true
        $anonymous['userName'] = ''
        $defaults = $appHost.GetSection('system.webServer/defaultDocument', $Config.siteName)
        $defaults['enabled'] = $true
        $files = $defaults.GetCollection('files')
        $files.Clear()
        $element = $files.CreateElement('add')
        $element['value'] = 'index.html'
        $files.Add($element)
        $manager.CommitChanges()
    } finally { $manager.Dispose() }
    $poolAccount = New-Object Security.Principal.NTAccount('IIS APPPOOL', $poolName)
    $poolSid = $poolAccount.Translate([Security.Principal.SecurityIdentifier])
    $webAcl = Get-Acl -LiteralPath $Config.physicalPath -ErrorAction Stop
    $webAcl.SetAccessRule((New-ExamAccessRule $poolSid 'ReadAndExecute'))
    Save-ExamDirectoryAcl $Config.physicalPath $webAcl
    if ((Get-WebAppPoolState -Name $poolName).Value -ne 'Started') { Start-WebAppPool -Name $poolName -ErrorAction Stop }
    if ((Get-Website -Name $Config.siteName).State -ne 'Started') { Start-Website -Name $Config.siteName -ErrorAction Stop }
}

function Set-ExamFirewall {
    param($Config)
    Import-Module NetSecurity -ErrorAction Stop
    Set-NetFirewallProfile -Profile Domain, Private, Public -Enabled True -ErrorAction Stop
    $ruleName = 'ITS-ServiceDesk-HTTP-8107-Docente'
    $existing = @(Get-NetFirewallRule -PolicyStore PersistentStore -DisplayName $Config.firewallRule -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -ieq $Config.firewallRule })
    foreach ($rule in $existing) { $rule | Remove-NetFirewallRule -ErrorAction Stop }
    New-NetFirewallRule -Name $ruleName -DisplayName $Config.firewallRule -Direction Inbound `
        -Action Allow -Enabled True -Profile Any -Protocol TCP -LocalPort $Config.port `
        -RemotePort Any -LocalAddress Any -RemoteAddress Any -Program Any -Service Any -ErrorAction Stop | Out-Null
}

function Set-ExamTask {
    param($Config)
    Import-Module ScheduledTasks -ErrorAction Stop
    $time = [DateTime]::ParseExact($Config.task.dailyAt, 'HH:mm', [Globalization.CultureInfo]::InvariantCulture)
    $start = (Get-Date).Date.Add($time.TimeOfDay)
    $action = New-ScheduledTaskAction -Execute ([Environment]::ExpandEnvironmentVariables($Config.task.execute)) `
        -Argument $Config.task.arguments -ErrorAction Stop
    $trigger = New-ScheduledTaskTrigger -Daily -DaysInterval $Config.task.daysInterval -At $start -ErrorAction Stop
    $principal = New-ScheduledTaskPrincipal -UserId $Config.task.principalSid -LogonType ServiceAccount -RunLevel Highest -ErrorAction Stop
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 1) -ErrorAction Stop
    Register-ScheduledTask -TaskName $Config.scheduledTask -TaskPath $Config.task.path `
        -Action $action -Trigger $trigger -Principal $principal -Settings $settings `
        -Description 'Backup giornaliero della homepage Service Desk ITS' -Force -ErrorAction Stop | Out-Null
    Enable-ScheduledTask -TaskName $Config.scheduledTask -TaskPath $Config.task.path -ErrorAction Stop | Out-Null
    $requestedAt = (Get-Date).AddSeconds(-2)
    Start-ScheduledTask -TaskName $Config.scheduledTask -TaskPath $Config.task.path -ErrorAction Stop
    $completed = $false
    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        $task = Get-ScheduledTask -TaskName $Config.scheduledTask -TaskPath $Config.task.path -ErrorAction Stop
        $info = Get-ScheduledTaskInfo -TaskName $Config.scheduledTask -TaskPath $Config.task.path -ErrorAction Stop
        if ($task.State -ne 'Running' -and $info.LastRunTime -ge $requestedAt -and $info.LastTaskResult -eq 0) {
            $completed = $true
            break
        }
        Start-Sleep -Seconds 1
    }
    Assert-SolutionCondition $completed 'La prova di esecuzione della Scheduled Task non e terminata correttamente entro 20 secondi.'
    $backupPath = $Config.task.backupFile
    $sourcePath = Join-Path $Config.physicalPath 'index.html'
    Assert-SolutionCondition (Test-Path -LiteralPath $backupPath -PathType Leaf) 'La copia giornaliera della homepage non e stata creata.'
    $sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256 -ErrorAction Stop).Hash
    $backupHash = (Get-FileHash -LiteralPath $backupPath -Algorithm SHA256 -ErrorAction Stop).Hash
    Assert-SolutionCondition ($sourceHash -ceq $backupHash) 'La copia della homepage non corrisponde al file pubblicato.'
}

function Wait-ExamHttp {
    param($Config)
    $lastError = ''
    for ($attempt = 0; $attempt -lt 12; $attempt++) {
        try {
            $response = Invoke-WebRequest -Uri "http://127.0.0.1:$($Config.port)/" -UseBasicParsing `
                -TimeoutSec 5 -MaximumRedirection 0 -ErrorAction Stop
            Assert-SolutionCondition ($response.StatusCode -eq 200 -and
                ([string]$response.Content).Contains($Config.expectedText)) 'Risposta HTTP o contenuto non corretto.'
            return
        } catch { $lastError = $_.Exception.Message }
        Start-Sleep -Seconds 1
    }
    throw "Il sito non risponde correttamente: $lastError"
}

function Invoke-TeacherSolution {
    param($Config, [string]$Root, [Security.SecureString]$Password)
    Write-Host '[1/7] Installazione IIS e avvio servizio'
    if (Install-ExamIis) {
        Write-Host 'Riavvio richiesto da Windows: riavviare la VM e rilanciare questo stesso script.' -ForegroundColor Yellow
        return 3010
    }
    Write-Host '[2/7] Utente, gruppo e appartenenza'
    $accounts = Set-ExamAccounts $Config $Password
    Write-Host '[3/7] Cartella dati e Modify al gruppo'
    Set-ExamDataPermissions $Config $accounts
    Write-Host '[4/7] Sito, binding, pagina e accesso IIS'
    Set-ExamWebsite $Config $Root
    Write-Host '[5/7] Regola firewall'
    Set-ExamFirewall $Config
    Write-Host '[6/7] Scheduled Task e prova del backup'
    Set-ExamTask $Config
    Wait-ExamHttp $Config
    Write-Host '[7/7] Valutazione automatica con il grader'
    $grader = Join-Path $Root 'grader\grade-infra.ps1'
    $engine = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    & $engine -NoProfile -ExecutionPolicy Bypass -File $grader -ExamRoot $Root | Out-Host
    $graderExit = $LASTEXITCODE
    if ($graderExit -eq 0) {
        Write-Host "Soluzione completata. Sito: http://localhost:$($Config.port)/" -ForegroundColor Green
    } else {
        Write-Host "Il grader ha restituito il codice $graderExit. Leggere i motivi riportati sopra." -ForegroundColor Yellow
    }
    return [int]$graderExit
}

try {
    Assert-SolutionEnvironment
    $resolvedRoot = Resolve-ExamRoot $ExamRoot $PSScriptRoot
    $configuration = Read-SolutionConfig $resolvedRoot
    $solutionExit = Invoke-TeacherSolution $configuration $resolvedRoot $UserPassword
    exit $solutionExit
} catch {
    Write-Host ('ERRORE SOLUZIONE DOCENTE: ' + $_.Exception.Message) -ForegroundColor Red
    exit 2
}
