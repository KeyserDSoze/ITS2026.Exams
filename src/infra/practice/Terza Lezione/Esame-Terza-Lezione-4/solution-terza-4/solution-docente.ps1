#requires -Version 5.1
<# Soluzione docente - Esame-Terza-Lezione-4, Portale Segreteria.
Eseguire solo nella VM Windows Server con Windows PowerShell 5.1 x64 come amministratore.
Configura il laboratorio e lancia il grader. Puo essere rilanciata; conserva la password
degli utenti esistenti, salvo il parametro -UserPassword. Password nuove mostrate in console.
Exit: 0=20/20, 1=FAIL, 2=errore, 3010=riavvio richiesto e successivo rilancio.
#>
[CmdletBinding()]
param([string]$ExamRoot,[Security.SecureString]$UserPassword)
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
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
        $group = New-LocalGroup -Name $Config.localGroup -Description 'Gruppo del laboratorio Portale Segreteria' -ErrorAction Stop
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

function Set-ExamWebsite {
    param($Config, [string]$Root)
    New-Item -ItemType Directory -Path $Config.physicalPath -Force -ErrorAction Stop | Out-Null
    Copy-Item -LiteralPath (Join-Path $Root 'website\index.html') `
        -Destination (Join-Path $Config.physicalPath 'index.html') -Force -ErrorAction Stop
    $poolName = 'DefaultAppPool'
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
        $pool.AutoStart = $true
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
    $ruleName = 'ITS-Segreteria-HTTP-8157-Docente'
    $existing = @(Get-NetFirewallRule -PolicyStore PersistentStore -DisplayName $Config.firewallRule -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -ieq $Config.firewallRule })
    foreach ($rule in $existing) { $rule | Remove-NetFirewallRule -ErrorAction Stop }
    New-NetFirewallRule -Name $ruleName -DisplayName $Config.firewallRule -Direction Inbound `
        -Action Allow -Enabled True -Profile Any -Protocol TCP -LocalPort $Config.port `
        -RemotePort Any -LocalAddress Any -RemoteAddress Any -Program Any -Service Any -ErrorAction Stop | Out-Null
}

function Invoke-ExamScheduledTask {
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
        -Description 'Attivita giornaliera del Portale Segreteria' -Force -ErrorAction Stop | Out-Null
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
}

function Set-ExamTask {
    param($Config)
    Invoke-ExamScheduledTask $Config
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

function Read-SolutionConfig {
    param([string]$Root)
    $configPath=Join-Path $Root 'exam-config.json';$idPath=Join-Path $Root '.exam-id'
    Assert-SolutionCondition (Test-Path -LiteralPath $configPath -PathType Leaf) 'exam-config.json assente.'
    Assert-SolutionCondition (Test-Path -LiteralPath $idPath -PathType Leaf) '.exam-id assente.'
    $config=Get-Content -LiteralPath $configPath -Raw -Encoding UTF8|ConvertFrom-Json
    $id=(Get-Content -LiteralPath $idPath -Raw -Encoding UTF8).Trim()
    Assert-SolutionCondition ($id -ceq 'INFRA-FACSIMILE-08|ITS-SEGRETERIA-BASE-2026' -and $id -ceq $config.examId -and $config.schemaVersion -eq 1) 'Pacchetto non compatibile con questa soluzione.'
    $expected=@{
        siteName='ITS-SegreteriaLab';physicalPath='C:\LabWeb\Segreteria';port=8157
        bindingIPAddress='*';bindingHostName='';firewallRule='ITS Segreteria HTTP 8157'
        localUser='segr_operator';localGroup='SegreteriaOperators';dataFolder='C:\SegreteriaLab\Dati'
        expectedText='SEGRETERIA ITS - ONLINE';scheduledTask='SegreteriaBackup';maxScore=20
    }
    foreach($name in $expected.Keys){
        Assert-SolutionCondition ($null -ne $config.PSObject.Properties[$name] -and [string]$config.$name -ceq [string]$expected[$name]) "Valore inatteso in exam-config.json: $name."
    }
    Assert-SolutionCondition ($null -ne $config.PSObject.Properties['task']) 'Configurazione task assente.'
    $taskExpected=@{
        path='\';dailyAt='18:00';daysInterval=1;principalSid='S-1-5-18';runLevel='HighestAvailable'
        execute='%SystemRoot%\System32\cmd.exe'
        arguments='/c copy /Y "C:\LabWeb\Segreteria\index.html" "C:\SegreteriaLab\Dati\homepage-backup.html"'
        backupFile='C:\SegreteriaLab\Dati\homepage-backup.html'
    }
    foreach($name in $taskExpected.Keys){
        Assert-SolutionCondition ($null -ne $config.task.PSObject.Properties[$name] -and [string]$config.task.$name -ceq [string]$taskExpected[$name]) "Valore inatteso nel task: $name."
    }
    foreach($file in @('website\index.html','grader\grade-infra.ps1')){
        Assert-SolutionCondition (Test-Path -LiteralPath (Join-Path $Root $file) -PathType Leaf) "File assente: $file."
    }
    $html=Get-Content -LiteralPath (Join-Path $Root 'website\index.html') -Raw -Encoding UTF8
    Assert-SolutionCondition ($html.Contains($config.expectedText)) 'La pagina fornita non contiene il testo atteso.'
    return $config
}

function Set-ExamDataPermissions {
    param($Config,$Accounts)
    New-Item -ItemType Directory -Path $Config.dataFolder -Force -ErrorAction Stop|Out-Null
    $acl=Get-Acl -LiteralPath $Config.dataFolder -ErrorAction Stop
    $acl.SetSecurityDescriptorSddlForm('D:P',[Security.AccessControl.AccessControlSections]::Access)
    foreach($sidValue in @('S-1-5-18','S-1-5-32-544')){
        $acl.AddAccessRule((New-ExamAccessRule ([Security.Principal.SecurityIdentifier]::new($sidValue)) 'FullControl'))
    }
    $acl.AddAccessRule((New-ExamAccessRule $Accounts.Group.SID 'Modify'))
    Save-ExamDirectoryAcl $Config.dataFolder $acl
}

function Invoke-TeacherSolution {
    param($Config,[string]$Root,[Security.SecureString]$Password)
    Write-Host '[1/6] IIS e servizio W3SVC'
    if(Install-ExamIis){Write-Host 'Riavvio richiesto: riavviare la VM e rilanciare lo stesso comando.' -ForegroundColor Yellow;return 3010}
    Write-Host '[2/6] Utente, gruppo e appartenenza'
    $accounts=Set-ExamAccounts $Config $Password
    Write-Host '[3/6] Cartella dati e permesso Modify al gruppo'
    Set-ExamDataPermissions $Config $accounts
    Write-Host '[4/6] Sito IIS e firewall'
    Set-ExamWebsite $Config $Root
    Set-ExamFirewall $Config
    Write-Host '[5/6] Task giornaliero, backup e verifica HTTP'
    Set-ExamTask $Config
    Wait-ExamHttp $Config
    Write-Host '[6/6] Grader su 20'
    $grader=Join-Path $Root 'grader\grade-infra.ps1'
    $engine=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    & $engine -NoProfile -ExecutionPolicy Bypass -File $grader -ExamRoot $Root|Out-Host
    $graderExit=$LASTEXITCODE
    if($graderExit -eq 0){Write-Host "Soluzione completata: http://localhost:$($Config.port)/" -ForegroundColor Green}
    else{Write-Host "Il grader ha restituito $graderExit. Leggere i motivi dei controlli FAIL." -ForegroundColor Yellow}
    return [int]$graderExit
}

try {
    Assert-SolutionEnvironment
    $resolvedRoot=Resolve-ExamRoot $ExamRoot $PSScriptRoot
    $configuration=Read-SolutionConfig $resolvedRoot
    $solutionExit=Invoke-TeacherSolution $configuration $resolvedRoot $UserPassword
    exit $solutionExit
} catch {
    Write-Host ('ERRORE SOLUZIONE DOCENTE: '+$_.Exception.Message) -ForegroundColor Red
    exit 2
}
