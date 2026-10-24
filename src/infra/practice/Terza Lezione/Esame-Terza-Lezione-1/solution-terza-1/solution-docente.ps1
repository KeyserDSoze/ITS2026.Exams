#requires -Version 5.1
<#
.SYNOPSIS
    Soluzione automatica docente del facsimile Infrastructure - Inventario IT.
.DESCRIPTION
    Terza lezione: due profili NTFS, pool dedicato, log IIS e backup verificato.
    Eseguire nella VM Windows Server con Windows PowerShell 5.1 x64 elevato.
    Legge exam-config.json, configura il laboratorio e avvia il grader.
    Puo essere rilanciato: aggiorna gli elementi dell'esercizio gia presenti.
    Non modifica consegna, configurazione e grader; il grader aggiorna il suo contatore.
    Per ogni nuovo utente genera una password casuale, mostrata solo in console.
    Per un utente esistente conserva la password, salvo -UserPassword oppure -ReaderPassword.
    Exit: 0 = grader 20/20; 1 = grader con FAIL; 2 = errore di configurazione;
    3010 = riavvio necessario: riavviare la VM e rilanciare lo script.
.EXAMPLE
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\solution-terza-1\solution-docente.ps1 -ExamRoot C:\Exam
#>
[CmdletBinding()]
param(
    [string]$ExamRoot,
    [Security.SecureString]$UserPassword, [Security.SecureString]$ReaderPassword
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
    Assert-SolutionCondition ($id -ceq 'INFRA-FACSIMILE-05|ITS-INVENTARIO-LOG-BACKUP-2026' -and
        $id -ceq $config.examId -and $config.schemaVersion -eq 1) 'Pacchetto non compatibile con questa soluzione.'
    # Limitare la soluzione ai nomi e ai percorsi di questo laboratorio.
    $expected = @{
        siteName = 'ITS-InventarioLab'; applicationPool = 'InventarioLabPool'; physicalPath = 'C:\LabWeb\Inventario'; port = 8121
        bindingIPAddress = '*'; bindingHostName = ''; firewallRule = 'ITS Inventario HTTP 8121'
        localUser = 'asset_editor'; localGroup = 'AssetEditors'; readerUser = 'asset_reader'; readerGroup = 'AssetReaders'; dataFolder = 'C:\AssetLab\Dati'
        expectedText = 'INVENTARIO ITS - ONLINE'; scheduledTask = 'InventarioBackup'; maxScore = 20
    }
    foreach ($name in $expected.Keys) {
        Assert-SolutionCondition ($null -ne $config.PSObject.Properties[$name] -and
            [string]$config.$name -ceq [string]$expected[$name]) "Valore inatteso in exam-config.json: $name."
    }
    $logExpected = @{centralMode='Site'; enabled=$true; format='W3C'; directory='C:\AssetLab\LogIIS'; period='Daily'; destination='File'}
    foreach ($name in $logExpected.Keys) {
        Assert-SolutionCondition ($null -ne $config.PSObject.Properties['logging'] -and
            $null -ne $config.logging.PSObject.Properties[$name] -and
            [string]$config.logging.$name -ceq [string]$logExpected[$name]) "Valore inatteso nei log IIS: $name."
    }
    $taskExpected = @{
        path = '\'; dailyAt = '18:10'; daysInterval = 1; principalSid = 'S-1-5-18'
        runLevel = 'HighestAvailable'; execute = '%SystemRoot%\System32\cmd.exe'
        arguments = '/c copy /Y "C:\LabWeb\Inventario\index.html" "C:\AssetLab\Dati\inventario-backup.html"'
        backupFile = 'C:\AssetLab\Dati\inventario-backup.html'
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
    $names = @('Web-Server', 'Web-Static-Content', 'Web-Default-Doc', 'Web-Mgmt-Console', 'Web-Scripting-Tools', 'Web-Http-Logging')
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
        $group = New-LocalGroup -Name $Config.localGroup -Description 'Gruppo del laboratorio Inventario IT' -ErrorAction Stop
    }
    $members = @(Get-LocalGroupMember -Group $group -ErrorAction Stop)
    if (@($members | Where-Object { $_.SID.Value -eq $user.SID.Value }).Count -eq 0) {
        Add-LocalGroupMember -Group $group -Member $user -ErrorAction Stop
    }
    return [pscustomobject]@{ User = $user; Group = $group }
}

function Set-ProjectAccounts {
    param($Config, [Security.SecureString]$Password, [Security.SecureString]$ReadPassword)
    $editor = Set-ExamAccounts $Config $Password
    $readerConfig = [pscustomobject]@{localUser=$Config.readerUser; localGroup=$Config.readerGroup}
    $reader = Set-ExamAccounts $readerConfig $ReadPassword
    $administrators = Get-LocalGroup -SID 'S-1-5-32-544' -ErrorAction Stop
    foreach ($group in @($editor.Group, $administrators)) {
        $members = @(Get-LocalGroupMember -Group $group -ErrorAction Stop)
        if (@($members | Where-Object { $_.SID.Value -eq $reader.User.SID.Value }).Count -gt 0) {
            Remove-LocalGroupMember -Group $group -Member $reader.User -Confirm:$false -ErrorAction Stop
        }
    }
    return [pscustomobject]@{User=$editor.User; Group=$editor.Group; ReaderUser=$reader.User; ReaderGroup=$reader.Group}
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
    # Solo DACL: mantenere proprietario e audit; rimuovere concessioni che
    # potrebbero consentire al lettore di scrivere tramite gruppi comuni.
    $acl.SetSecurityDescriptorSddlForm('D:P', [Security.AccessControl.AccessControlSections]::Access)
    foreach ($sidValue in @('S-1-5-18', 'S-1-5-32-544')) {
        $acl.AddAccessRule((New-ExamAccessRule ([Security.Principal.SecurityIdentifier]::new($sidValue)) 'FullControl'))
    }
    $acl.AddAccessRule((New-ExamAccessRule $Accounts.Group.SID 'Modify'))
    $acl.AddAccessRule((New-ExamAccessRule $Accounts.ReaderGroup.SID 'ReadAndExecute'))
    Save-ExamDirectoryAcl $Config.dataFolder $acl
}

function Set-ExamLogging {
    param($Config, $Site, $AppHost)
    New-Item -ItemType Directory -Path $Config.logging.directory -Force -ErrorAction Stop | Out-Null
    $log = $Site.GetChildElement('logFile')
    $log['enabled'] = $true
    $log['logFormat'] = $Config.logging.format
    $log['directory'] = $Config.logging.directory
    $log['period'] = $Config.logging.period
    $log['logTargetW3C'] = $Config.logging.destination
    $globalLog = $AppHost.GetSection('system.applicationHost/log')
    $globalLog['centralLogFileMode'] = $Config.logging.centralMode
}
function Set-ExamWebsite {
    param($Config, [string]$Root)
    New-Item -ItemType Directory -Path $Config.physicalPath -Force -ErrorAction Stop | Out-Null
    Copy-Item -LiteralPath (Join-Path $Root 'website\index.html') `
        -Destination (Join-Path $Config.physicalPath 'index.html') -Force -ErrorAction Stop
    $poolName = $Config.applicationPool
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
    } finally { $manager.Dispose() }
    # Dopo il commit, riaprire la configurazione e acquisire un nuovo sito
    # scrivibile. I riferimenti della sessione precedente sono in sola lettura.
    $manager = New-Object Microsoft.Web.Administration.ServerManager
    try {
        $site = $manager.Sites[$Config.siteName]
        Assert-SolutionCondition ($null -ne $site) 'Sito non trovato dopo il salvataggio della configurazione IIS.'
        # Configurazione nel file applicationHost.config, limitata al sito.
        $appHost = $manager.GetApplicationHostConfiguration()
        Set-ExamLogging $Config $site $appHost
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
    $ruleName = 'ITS-Inventario-HTTP-8121-Docente'
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
        -Description 'Backup giornaliero della homepage Inventario IT' -Force -ErrorAction Stop | Out-Null
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
    param($Config, [string]$Root, [Security.SecureString]$Password, [Security.SecureString]$ReadPassword)
    Write-Host '[1/7] Installazione IIS e avvio servizio'
    if (Install-ExamIis) {
        Write-Host 'Riavvio richiesto da Windows: riavviare la VM e rilanciare questo stesso script.' -ForegroundColor Yellow
        return 3010
    }
    Write-Host '[2/7] Due utenti, gruppi e appartenenze'
    $accounts = Set-ProjectAccounts $Config $Password $ReadPassword
    Write-Host '[3/7] Cartella dati: editor Modify, lettore Read and Execute'
    Set-ExamDataPermissions $Config $accounts
    Write-Host '[4/7] Sito, pool, binding, pagina e log IIS'
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
    $solutionExit = Invoke-TeacherSolution $configuration $resolvedRoot $UserPassword $ReaderPassword
    exit $solutionExit
} catch {
    Write-Host ('ERRORE SOLUZIONE DOCENTE: ' + $_.Exception.Message) -ForegroundColor Red
    exit 2
}
