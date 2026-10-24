#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ExamRoot,
    [switch]$Json
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Assert-Condition {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Update-GraderExecutionCount {
    param([string]$Root)
    $counterPath = Join-Path $Root 'grader\.grader-database.txt'
    $stream = $null
    try {
        # Lock esclusivo: due console aperte insieme non devono perdere un avvio.
        for ($attempt = 0; $attempt -lt 50; $attempt++) {
            try {
                $stream = [IO.File]::Open($counterPath, [IO.FileMode]::OpenOrCreate,
                    [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
                break
            } catch [IO.IOException] {
                $errorCode = $_.Exception.HResult -band 65535
                if ($errorCode -notin @(32, 33) -or $attempt -eq 49) { throw }
                Start-Sleep -Milliseconds 100
            }
        }
        $reader = [IO.StreamReader]::new($stream, [Text.Encoding]::UTF8, $true, 1024, $true)
        try { $stored = $reader.ReadToEnd().Trim() } finally { $reader.Dispose() }
        [long]$count = 0
        if ($stored.Length -gt 0) {
            $valid = [long]::TryParse($stored, [Globalization.NumberStyles]::None,
                [Globalization.CultureInfo]::InvariantCulture, [ref]$count)
            if (-not $valid -or $count -lt 0 -or $count -eq [long]::MaxValue) {
                throw "Contatore non valido in '$counterPath'. Il valore non e stato azzerato."
            }
        }
        [long]$next = $count + 1
        $bytes = [Text.Encoding]::UTF8.GetBytes($next.ToString([Globalization.CultureInfo]::InvariantCulture) + "`r`n")
        $stream.Position = 0
        $stream.SetLength(0)
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush($true)
        return $next
    } finally {
        if ($null -ne $stream) { $stream.Dispose() }
    }
}

function Get-NormalizedPath {
    param([string]$Path)
    $expanded = [Environment]::ExpandEnvironmentVariables($Path.Trim().Trim('"'))
    return [IO.Path]::GetFullPath($expanded).TrimEnd('\')
}

function Get-ExamSite {
    param($Config)
    Import-Module WebAdministration -ErrorAction Stop
    $sites = @(Get-Website -Name $Config.siteName -ErrorAction Stop |
        Where-Object { $_.Name -ieq $Config.siteName })
    Assert-Condition ($sites.Count -eq 1) "Sito '$($Config.siteName)' non trovato."
    return $sites[0]
}

function Test-ExpectedBinding {
    param($Site, $Config)
    $expected = '{0}:{1}:{2}' -f $Config.bindingIPAddress, $Config.port, $Config.bindingHostName
    $bindings = @($Site.Bindings.Collection | Where-Object {
        $_.protocol -ieq 'http' -and $_.bindingInformation -ieq $expected
    })
    return ($bindings.Count -gt 0)
}

function Invoke-Requirement {
    param([string]$Id, [string]$Label, [int]$Points, [scriptblock]$Test)
    $passed = $false
    $detail = 'Requisito soddisfatto.'
    try {
        & $Test | Out-Null
        $passed = $true
    } catch {
        $detail = $_.Exception.Message
    }
    return [pscustomobject][ordered]@{
        id = $Id
        label = $Label
        status = $(if ($passed) { 'PASS' } else { 'FAIL' })
        passed = $passed
        earnedPoints = $(if ($passed) { $Points } else { 0 })
        maxPoints = $Points
        detail = $detail
    }
}

function Test-GroupModifyAcl {
    param($Config)
    Assert-Condition (Test-Path -LiteralPath $Config.dataFolder -PathType Container) 'Cartella dati assente.'
    $user = Get-LocalUser -Name $Config.localUser -ErrorAction Stop
    $group = Get-LocalGroup -Name $Config.localGroup -ErrorAction Stop
    $acl = Get-Acl -LiteralPath $Config.dataFolder -ErrorAction Stop
    # Richiedere le ACE direttamente come SID evita confronti su nomi localizzati.
    $rules = @($acl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]))
    $modify = [int][Security.AccessControl.FileSystemRights]::Modify
    $sync = [int][Security.AccessControl.FileSystemRights]::Synchronize
    $children = [int][Security.AccessControl.InheritanceFlags]::ContainerInherit -bor
        [int][Security.AccessControl.InheritanceFlags]::ObjectInherit
    $groupAllow = 0
    $groupRights = 0
    $denySids = @($user.SID.Value, $group.SID.Value, 'S-1-1-0', 'S-1-5-11', 'S-1-5-32-545')
    foreach ($rule in $rules) {
        $sid = $rule.IdentityReference.Value
        $rights = [int]$rule.FileSystemRights
        $appliesHere = (([int]$rule.PropagationFlags -band
            [int][Security.AccessControl.PropagationFlags]::InheritOnly) -eq 0)
        if ($sid -eq $user.SID.Value -and $rule.AccessControlType -eq 'Allow') {
            throw 'Trovata una ACE Allow direttamente sull''utente; usare il gruppo.'
        }
        if ($sid -in $denySids -and $rule.AccessControlType -eq 'Deny' -and
            ($rights -band $modify) -ne 0) {
            throw 'Una ACE Deny su utente, gruppo o gruppo comune limita Modify.'
        }
        if ($sid -eq $group.SID.Value -and $rule.AccessControlType -eq 'Allow') {
            $groupRights = $groupRights -bor $rights
            $onlyModify = (($rights -band (-bnot $sync)) -eq $modify)
            $inheritsToBoth = (([int]$rule.InheritanceFlags -band $children) -eq $children)
            if (-not $rule.IsInherited -and $onlyModify -and $inheritsToBoth -and
                $appliesHere -and [int]$rule.PropagationFlags -eq 0) {
                $groupAllow++
            }
        }
    }
    Assert-Condition ($groupAllow -gt 0) 'Manca una ACE esplicita Modify per il gruppo su cartella, sottocartelle e file.'
    Assert-Condition (($groupRights -band (-bnot ($modify -bor $sync))) -eq 0) 'Il gruppo ha diritti aggiuntivi oltre Modify (es. Full control).'
}

function Test-FirewallConfiguration {
    param($Config)
    $profiles = @(Get-NetFirewallProfile -PolicyStore ActiveStore -ErrorAction Stop)
    Assert-Condition ($profiles.Count -ge 3 -and @($profiles | Where-Object {
        [string]$_.Enabled -ne 'True'
    }).Count -eq 0) 'Windows Defender Firewall deve essere attivo su tutti i profili.'
    $rules = @(Get-NetFirewallRule -PolicyStore ActiveStore -DisplayName $Config.firewallRule -ErrorAction Stop |
        Where-Object { $_.DisplayName -ieq $Config.firewallRule })
    $valid = $false
    foreach ($rule in $rules) {
        $profileNames = @(([string]$rule.Profile).Split(',') | ForEach-Object { $_.Trim() })
        $allProfiles = ($profileNames -contains 'Any' -or
            @(@('Domain', 'Private', 'Public') | Where-Object { $_ -notin $profileNames }).Count -eq 0)
        if ([string]$rule.Enabled -ne 'True' -or [string]$rule.Direction -ne 'Inbound' -or
            [string]$rule.Action -ne 'Allow' -or -not $allProfiles) { continue }
        # Tutti i filtri devono appartenere ALLA STESSA regola.
        $port = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $rule -ErrorAction Stop
        $address = Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $rule -ErrorAction Stop
        $application = Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $rule -ErrorAction Stop
        $service = Get-NetFirewallServiceFilter -AssociatedNetFirewallRule $rule -ErrorAction Stop
        if ([string]$port.Protocol -in @('TCP', '6') -and
            @($port.LocalPort).Count -eq 1 -and [string]$port.LocalPort -eq [string]$Config.port -and
            [string]$port.RemotePort -eq 'Any' -and
            [string]$address.LocalAddress -eq 'Any' -and [string]$address.RemoteAddress -eq 'Any' -and
            [string]$application.Program -eq 'Any' -and [string]$service.Service -eq 'Any') {
            $valid = $true
        }
    }
    Assert-Condition $valid "Regola '$($Config.firewallRule)' assente o non conforme a direzione, azione, profili, TCP/porta e ambito richiesti."
}

function Get-XmlText {
    param([Xml.XmlNode]$Node, [string]$XPath, [Xml.XmlNamespaceManager]$Namespaces)
    $found = $Node.SelectSingleNode($XPath, $Namespaces)
    if ($null -eq $found) { return '' }
    return $found.InnerText
}

function Test-TaskConfiguration {
    param($Config)
    $task = Get-ScheduledTask -TaskName $Config.scheduledTask -TaskPath $Config.task.path -ErrorAction Stop
    Assert-Condition ($null -ne $task -and [string]$task.State -ne 'Disabled') 'Attivita assente o disabilitata.'
    [xml]$xml = Export-ScheduledTask -TaskName $Config.scheduledTask -TaskPath $Config.task.path -ErrorAction Stop
    $ns = New-Object Xml.XmlNamespaceManager($xml.NameTable)
    $ns.AddNamespace('t', 'http://schemas.microsoft.com/windows/2004/02/mit/task')
    $root = $xml.DocumentElement
    $enabled = Get-XmlText $root 't:Settings/t:Enabled' $ns
    Assert-Condition ($enabled -notin @('false', '0')) 'Attivita disabilitata nelle impostazioni.'
    $principals = @($root.SelectNodes('t:Principals/t:Principal', $ns))
    Assert-Condition ($principals.Count -eq 1) 'Serve un solo account di esecuzione.'
    $principal = $principals[0]
    $userId = Get-XmlText $principal 't:UserId' $ns
    $sid = $userId
    if ($userId -notmatch '^S-1-') {
        $sid = (New-Object Security.Principal.NTAccount($userId)).Translate(
            [Security.Principal.SecurityIdentifier]).Value
    }
    Assert-Condition ($sid -eq $Config.task.principalSid) 'L''attivita deve essere eseguita da SYSTEM.'
    Assert-Condition ((Get-XmlText $principal 't:RunLevel' $ns) -eq $Config.task.runLevel) 'Mancano i privilegi piu elevati.'
    $triggers = @($root.SelectNodes('t:Triggers/*', $ns))
    Assert-Condition ($triggers.Count -eq 1 -and $triggers[0].LocalName -eq 'CalendarTrigger') 'Serve un solo trigger giornaliero.'
    $trigger = $triggers[0]
    Assert-Condition ((Get-XmlText $trigger 't:Enabled' $ns) -notin @('false', '0')) 'Trigger disabilitato.'
    $interval = Get-XmlText $trigger 't:ScheduleByDay/t:DaysInterval' $ns
    Assert-Condition ($interval -eq [string]$Config.task.daysInterval) 'Il trigger deve ripetersi ogni giorno (intervallo 1).'
    $boundaryText = Get-XmlText $trigger 't:StartBoundary' $ns
    $boundary = [DateTimeOffset]::Parse($boundaryText, [Globalization.CultureInfo]::InvariantCulture)
    # Con offset esplicito confrontare l'ora effettiva locale della VM.
    $localBoundary = $boundary.LocalDateTime
    Assert-Condition ($localBoundary.ToString('HH:mm') -eq $Config.task.dailyAt -and
        $localBoundary.Second -eq 0) "Orario richiesto: $($Config.task.dailyAt), ora locale della VM."
    Assert-Condition ($localBoundary.Date -le (Get-Date).Date) 'La data iniziale del trigger deve essere oggi o precedente.'
    Assert-Condition ([string]::IsNullOrWhiteSpace((Get-XmlText $trigger 't:EndBoundary' $ns))) 'Il trigger non deve avere scadenza.'
    Assert-Condition ($null -eq $trigger.SelectSingleNode('t:Repetition', $ns)) 'Non impostare ripetizioni aggiuntive del trigger.'
    $delay = Get-XmlText $trigger 't:RandomDelay' $ns
    if ($delay) {
        Assert-Condition ([Xml.XmlConvert]::ToTimeSpan($delay).Ticks -eq 0) 'Non impostare ritardi casuali.'
    }
    $actions = @($root.SelectNodes('t:Actions/*', $ns))
    Assert-Condition ($actions.Count -eq 1 -and $actions[0].LocalName -eq 'Exec') 'Serve una sola azione Avvio programma.'
    $command = Get-XmlText $actions[0] 't:Command' $ns
    Assert-Condition ((Get-NormalizedPath $command) -ieq (Get-NormalizedPath $Config.task.execute)) 'Programma dell''azione non corretto.'
    $arguments = Get-XmlText $actions[0] 't:Arguments' $ns
    Assert-Condition ($arguments.Trim() -ceq $Config.task.arguments.Trim()) 'Argomenti dell''azione diversi da quelli richiesti nel README.'
    Assert-Condition ([string]::IsNullOrWhiteSpace((Get-XmlText $actions[0] 't:WorkingDirectory' $ns))) 'Lasciare vuoto il campo Avvia in.'
}

function Get-InfrastructureReport {
    param($Config)
    $checks = @(
        Invoke-Requirement 'iis' 'IIS installato e servizio W3SVC avviato' 1 {
            $feature = Get-WindowsFeature -Name Web-Server -ErrorAction Stop
            Assert-Condition ($feature.Installed -eq $true) 'Ruolo Web Server (IIS) non installato.'
            $service = Get-Service -Name W3SVC -ErrorAction Stop
            Assert-Condition ($service.Status -eq 'Running') 'Servizio W3SVC non in esecuzione.'
        }
        Invoke-Requirement 'site' 'Sito IIS avviato, percorso fisico e index.html corretti' 1 {
            $site = Get-ExamSite $Config
            Assert-Condition ($site.State -eq 'Started') 'Sito presente ma non avviato.'
            Assert-Condition ((Get-NormalizedPath $site.physicalPath) -ieq (Get-NormalizedPath $Config.physicalPath)) 'Percorso fisico del sito non corretto.'
            Assert-Condition (Test-Path -LiteralPath (Join-Path $Config.physicalPath 'index.html') -PathType Leaf) 'index.html assente nel percorso richiesto.'
        }
        
        Invoke-Requirement 'binding' 'Binding HTTP sulla porta richiesta' 1 {
            $site = Get-ExamSite $Config
            Assert-Condition (Test-ExpectedBinding $site $Config) 'Manca il binding HTTP su tutte le interfacce, porta richiesta e host vuoto.'
        }
        Invoke-Requirement 'http' 'HTTP 200 e contenuto atteso' 1 {
            $site = Get-ExamSite $Config
            Assert-Condition ($site.State -eq 'Started' -and (Test-ExpectedBinding $site $Config)) 'Il sito richiesto deve essere avviato con il binding corretto.'
            Assert-Condition ((Get-NormalizedPath $site.physicalPath) -ieq
                (Get-NormalizedPath $Config.physicalPath)) 'La risposta deve provenire dal sito nel percorso richiesto.'
            $response = Invoke-WebRequest -Uri "http://127.0.0.1:$($Config.port)/" -UseBasicParsing -TimeoutSec 8 -MaximumRedirection 0 -ErrorAction Stop
            Assert-Condition ($response.StatusCode -eq 200) 'Il sito non restituisce HTTP 200.'
            Assert-Condition ([string]$response.Content -clike ('*' + $Config.expectedText + '*')) 'Testo atteso non presente nella risposta HTTP.'
        }
        Invoke-Requirement 'firewall' 'Regola firewall e profili attivi' 1 {
            Test-FirewallConfiguration $Config
        }
        Invoke-Requirement 'user' 'Utente locale presente e abilitato' 1 {
            $user = Get-LocalUser -Name $Config.localUser -ErrorAction Stop
            Assert-Condition ($null -ne $user -and $user.Enabled -eq $true) 'Utente locale assente o disabilitato.'
        }
        
        Invoke-Requirement 'membership' 'Gruppo editor presente e utente membro diretto' 1 {
            $user = Get-LocalUser -Name $Config.localUser -ErrorAction Stop
            $group = Get-LocalGroup -Name $Config.localGroup -ErrorAction Stop
            $members = @(Get-LocalGroupMember -Group $group -ErrorAction Stop)
            Assert-Condition (@($members | Where-Object { $_.SID.Value -eq $user.SID.Value }).Count -gt 0) 'Utente non presente tra i membri diretti del gruppo locale.'
        }
        
        Invoke-Requirement 'groupModify' 'Cartella dati e Modify al gruppo senza Allow diretti all''utente' 1 {
            Test-GroupModifyAcl $Config
        }
        Invoke-Requirement 'task' 'Scheduled Task con account, trigger e azione corretti' 1 {
            Test-TaskConfiguration $Config
        }
        Invoke-Requirement 'pool' 'Pool dedicato avviato e associato al sito' 1 {
            Test-ExamApplicationPool $Config
        }
        Invoke-Requirement 'backup' 'Task eseguito correttamente e copia della homepage valida' 1 {
            Test-HomepageBackup $Config
        }
        Invoke-Requirement 'readerUser' 'Secondo utente abilitato e non amministratore' 1 {
            $reader = Get-LocalUser -Name $Config.readerUser -ErrorAction Stop
            Assert-Condition ($null -ne $reader -and $reader.Enabled -eq $true) 'Utente lettore assente o disabilitato.'
            $administrators = Get-LocalGroup -SID 'S-1-5-32-544' -ErrorAction Stop
            $admins = @(Get-LocalGroupMember -Group $administrators -ErrorAction Stop)
            Assert-Condition (@($admins | Where-Object { $_.SID.Value -eq $reader.SID.Value }).Count -eq 0) 'Il lettore non deve essere amministratore.'
        }
        Invoke-Requirement 'readerMembership' 'Lettore nel gruppo Readers e fuori da Editors' 1 {
            $reader = Get-LocalUser -Name $Config.readerUser -ErrorAction Stop
            $readers = Get-LocalGroup -Name $Config.readerGroup -ErrorAction Stop
            $members = @(Get-LocalGroupMember -Group $readers -ErrorAction Stop)
            Assert-Condition (@($members | Where-Object { $_.SID.Value -eq $reader.SID.Value }).Count -gt 0) 'Aggiungere direttamente il lettore a TrainingReaders.'
            $editors = Get-LocalGroup -Name $Config.localGroup -ErrorAction Stop
            $editorsMembers = @(Get-LocalGroupMember -Group $editors -ErrorAction Stop)
            Assert-Condition (@($editorsMembers | Where-Object { $_.SID.Value -eq $reader.SID.Value }).Count -eq 0) 'Il lettore non deve appartenere a TrainingEditors.'
        }
        Invoke-Requirement 'readerAcl' 'Read and Execute al gruppo Readers senza permessi diretti' 1 {
            Test-GroupReadAcl $Config
        }
        Invoke-Requirement 'logging' 'Log IIS W3C per sito nella directory richiesta, ogni giorno' 1 {
            Test-ExamLogging $Config
        }
        Invoke-Requirement 'virtualDirectory' 'Directory virtuale materiali collegata alla cartella esterna' 1 {
            Test-ExamVirtualDirectory $Config
        }
        Invoke-Requirement 'catalogHttp' 'Catalogo raggiungibile via HTTP con contenuto atteso' 1 {
            Test-ExamVirtualDirectory $Config
            $site = Get-ExamSite $Config
            Assert-Condition ($site.State -eq 'Started' -and (Test-ExpectedBinding $site $Config)) 'Avviare il sito e configurare il binding richiesto.'
            $uri = 'http://127.0.0.1:{0}/{1}/' -f $Config.port, $Config.virtualDirectory.alias
            $response = Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec 8 -MaximumRedirection 0 -ErrorAction Stop
            Assert-Condition ($response.StatusCode -eq 200) 'Il materiali non restituisce HTTP 200.'
            Assert-Condition ([string]$response.Content -clike ('*' + $Config.virtualDirectory.expectedText + '*')) 'Contenuto del materiali non corretto.'
        }
        Invoke-Requirement 'extraPage' 'Pagina contatti.html presente e raggiungibile via HTTP' 1 {
            Test-ExamExtraPage $Config
        }
        Invoke-Requirement 'directAcl' 'Cartella Personale con Modify diretto all''editor' 1 {
            Test-DirectUserAcl $Config
        }
        Invoke-Requirement 'reportTask' 'Task report configurato, eseguito e file generato correttamente' 1 {
            Test-ReportTask $Config
        }
    )
    $score = [int](($checks | Measure-Object -Property earnedPoints -Sum).Sum)
    $max = [int](($checks | Measure-Object -Property maxPoints -Sum).Sum)
    Assert-Condition ($max -eq 20 -and $max -eq $Config.maxScore) 'Errore interno nella griglia punteggi.'
    return [pscustomobject][ordered]@{
        examId = $Config.examId
        computerName = $env:COMPUTERNAME
        evaluatedAt = (Get-Date).ToString('o')
        status = $(if ($score -eq $max) { 'PASS' } else { 'FAIL' })
        score = $score
        maxScore = $max
        checks = $checks
    }
}

function Read-ExamConfig {
    param([string]$Root)
    $configPath = Join-Path $Root 'exam-config.json'
    $idPath = Join-Path $Root '.exam-id'
    Assert-Condition (Test-Path -LiteralPath $configPath -PathType Leaf) 'exam-config.json non trovato.'
    Assert-Condition (Test-Path -LiteralPath $idPath -PathType Leaf) '.exam-id non trovato.'
    $config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($name in @('schemaVersion','examId','maxScore','siteName','physicalPath','port',
        'bindingIPAddress','bindingHostName','firewallRule','localUser','localGroup',
        'dataFolder','expectedText','scheduledTask','applicationPool','readerUser','readerGroup','task','logging','virtualDirectory','extraPage','directFolder','reportTask')) {
        Assert-Condition ($null -ne $config.PSObject.Properties[$name]) "Proprieta di configurazione mancante: $name."
    }
    foreach ($name in @('path','dailyAt','daysInterval','principalSid','runLevel','execute','arguments','backupFile')) {
        Assert-Condition ($null -ne $config.task.PSObject.Properties[$name]) "Proprieta task mancante: $name."
    }
    foreach ($name in @('alias','physicalPath','indexFile','sourceFile','expectedText')) {
        Assert-Condition ($null -ne $config.virtualDirectory.PSObject.Properties[$name]) "Proprieta directory virtuale mancante: $name."
    }
    foreach ($name in @('fileName','expectedText')) {
        Assert-Condition ($null -ne $config.extraPage.PSObject.Properties[$name]) "Proprieta seconda pagina mancante: $name."
    }
    foreach ($name in @('name','path','dailyAt','daysInterval','principalSid','runLevel','execute','arguments','reportFile','expectedText')) {
        Assert-Condition ($null -ne $config.reportTask.PSObject.Properties[$name]) "Proprieta task report mancante: $name."
    }
    $id = (Get-Content -LiteralPath $idPath -Raw -Encoding UTF8).Trim()
    Assert-Condition ($id -ceq $config.examId -and $id -ceq 'INFRA-FACSIMILE-07|ITS-FORMAZIONE-RIEPILOGO-2026') 'Identificativo del pacchetto non coerente.'
    Assert-Condition ($config.schemaVersion -eq 1 -and $config.maxScore -eq 20) 'Versione configurazione o punteggio massimo non validi.'
    Assert-Condition ($config.port -is [int] -and $config.port -ge 1 -and $config.port -le 65535) 'Porta TCP non valida.'
    foreach ($path in @($config.physicalPath, $config.dataFolder, $config.directFolder, $config.reportTask.reportFile)) {
        Assert-Condition ($path -match '^[A-Za-z]:\\' -and $path -notmatch '[*?]') 'Usare percorsi assoluti locali senza wildcard.'
    }
    return $config
}

function Assert-GradingEnvironment {
    Assert-Condition ($env:OS -eq 'Windows_NT') 'Il grader richiede Windows Server.'
    Assert-Condition ($PSVersionTable.PSEdition -eq 'Desktop' -and [Environment]::Is64BitProcess) 'Usare Windows PowerShell 5.1 a 64 bit (powershell.exe), non pwsh o x86.'
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    Assert-Condition ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) 'Aprire Windows PowerShell come amministratore.'
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    Assert-Condition ($os.ProductType -eq 3) 'Usare un server autonomo/membro, non Windows client o un controller di dominio.'
}

function Test-ExamApplicationPool {
    param($Config)
    Import-Module WebAdministration -ErrorAction Stop
    $pool = Get-Item -LiteralPath ('IIS:\AppPools\' + $Config.applicationPool) -ErrorAction Stop
    Assert-Condition ($null -ne $pool) 'Pool di applicazioni richiesto assente.'
    Assert-Condition ([string]$pool.managedRuntimeVersion -eq '') 'Impostare il runtime del pool su No Managed Code.'
    Assert-Condition ([string]$pool.processModel.identityType -in @('ApplicationPoolIdentity','4')) 'Impostare l''identita del pool su ApplicationPoolIdentity.'
    Assert-Condition ((Get-WebAppPoolState -Name $Config.applicationPool -ErrorAction Stop).Value -eq 'Started') 'Il pool di applicazioni deve essere avviato.'
    $site = Get-Item -LiteralPath ('IIS:\Sites\' + $Config.siteName) -ErrorAction Stop
    Assert-Condition ([string]$site.applicationPool -ieq $Config.applicationPool) 'Associare il sito al pool di applicazioni richiesto.'
}

function Test-HomepageBackup {
    param($Config)
    $task = Get-ScheduledTask -TaskName $Config.scheduledTask -TaskPath $Config.task.path -ErrorAction Stop
    $info = Get-ScheduledTaskInfo -TaskName $Config.scheduledTask -TaskPath $Config.task.path -ErrorAction Stop
    Assert-Condition ($task.State -ne 'Running' -and $info.LastRunTime -gt [datetime]'2000-01-01' -and
        $info.LastTaskResult -eq 0) 'Eseguire il task e ottenere risultato 0x0.'
    $source = Join-Path $Config.physicalPath 'index.html'
    Assert-Condition (Test-Path -LiteralPath $source -PathType Leaf) 'Homepage sorgente assente.'
    Assert-Condition (Test-Path -LiteralPath $Config.task.backupFile -PathType Leaf) 'File homepage-backup.html assente.'
    $sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256 -ErrorAction Stop).Hash
    $backupHash = (Get-FileHash -LiteralPath $Config.task.backupFile -Algorithm SHA256 -ErrorAction Stop).Hash
    Assert-Condition ($sourceHash -ceq $backupHash) 'La copia di backup non corrisponde alla homepage pubblicata.'
}
function Test-GroupReadAcl {
    param($Config)
    Assert-Condition (Test-Path -LiteralPath $Config.dataFolder -PathType Container) 'Cartella dati assente.'
    $user = Get-LocalUser -Name $Config.readerUser -ErrorAction Stop
    $group = Get-LocalGroup -Name $Config.readerGroup -ErrorAction Stop
    $acl = Get-Acl -LiteralPath $Config.dataFolder -ErrorAction Stop
    # Richiedere le ACE direttamente come SID evita confronti su nomi localizzati.
    $rules = @($acl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]))
    $modify = [int][Security.AccessControl.FileSystemRights]::ReadAndExecute
    $sync = [int][Security.AccessControl.FileSystemRights]::Synchronize
    $children = [int][Security.AccessControl.InheritanceFlags]::ContainerInherit -bor
        [int][Security.AccessControl.InheritanceFlags]::ObjectInherit
    $groupAllow = 0
    $groupRights = 0
    $denySids = @($user.SID.Value, $group.SID.Value, 'S-1-1-0', 'S-1-5-11', 'S-1-5-32-545')
    foreach ($rule in $rules) {
        $sid = $rule.IdentityReference.Value
        $rights = [int]$rule.FileSystemRights
        $appliesHere = (([int]$rule.PropagationFlags -band
            [int][Security.AccessControl.PropagationFlags]::InheritOnly) -eq 0)
        if ($sid -eq $user.SID.Value -and $rule.AccessControlType -eq 'Allow') {
            throw 'Trovata una ACE Allow direttamente sull''utente; usare il gruppo.'
        }
        if ($sid -in $denySids -and $rule.AccessControlType -eq 'Deny' -and
            ($rights -band $modify) -ne 0) {
            throw 'Una ACE Deny su utente, gruppo o gruppo comune limita ReadAndExecute.'
        }
        if ($sid -eq $group.SID.Value -and $rule.AccessControlType -eq 'Allow') {
            $groupRights = $groupRights -bor $rights
            $onlyReadAndExecute = (($rights -band (-bnot $sync)) -eq $modify)
            $inheritsToBoth = (([int]$rule.InheritanceFlags -band $children) -eq $children)
            if (-not $rule.IsInherited -and $onlyReadAndExecute -and $inheritsToBoth -and
                $appliesHere -and [int]$rule.PropagationFlags -eq 0) {
                $groupAllow++
            }
        }
    }
    Assert-Condition ($groupAllow -gt 0) 'Manca una ACE esplicita ReadAndExecute per il gruppo su cartella, sottocartelle e file.'
    Assert-Condition (($groupRights -band (-bnot ($modify -bor $sync))) -eq 0) 'Il gruppo ha diritti aggiuntivi oltre ReadAndExecute (es. Full control).'
}

function Get-ExamIisPropertyValue {
    param([string]$Filter, [string]$Name)
    $values = @(Get-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter $Filter -Name $Name -ErrorAction Stop)
    Assert-Condition ($values.Count -eq 1) "Valore IIS assente o ambiguo: $Name."
    $value = $values[0]
    Assert-Condition ($null -ne $value) "Valore IIS nullo: $Name."
    # WebAdministration puo restituire lo scalare oppure un attributo con Value.
    # Controllare l'esistenza della proprieta prima di leggerla con StrictMode.
    $wrappedValue = $value.PSObject.Properties['Value']
    if ($null -ne $wrappedValue) { $value = $wrappedValue.Value }
    Assert-Condition ($null -ne $value) "Valore IIS nullo: $Name."
    $enumNames = @{
        centralLogFileMode = @{'0'='Site';'1'='CentralBinary';'2'='CentralW3C'}
        logFormat = @{'0'='IIS';'1'='NCSA';'2'='W3C';'3'='Custom'}
        period = @{'0'='MaxSize';'1'='Daily';'2'='Weekly';'3'='Monthly';'4'='Hourly'}
        logTargetW3C = @{'1'='File';'2'='ETW';'3'='File, ETW'}
        enabled = @{'0'=$false;'1'=$true}
    }
    $text = [string]$value
    if ($enumNames.ContainsKey($Name) -and $enumNames[$Name].ContainsKey($text)) {
        return $enumNames[$Name][$text]
    }
    return $value
}

function Test-ExamLogging {
    param($Config)
    Import-Module WebAdministration -ErrorAction Stop
    $feature = Get-WindowsFeature -Name Web-Http-Logging -ErrorAction Stop
    Assert-Condition ($feature.Installed -eq $true) 'Funzionalita Registrazione HTTP non installata.'
    Assert-Condition (Test-Path -LiteralPath $Config.logging.directory -PathType Container) 'Directory dei log IIS assente.'
    $mode = Get-ExamIisPropertyValue -Filter 'system.applicationHost/log' -Name 'centralLogFileMode'
    Assert-Condition ([string]$mode -eq $Config.logging.centralMode) 'Impostare un file di log per sito.'
    $filter = "system.applicationHost/sites/site[@name='$($Config.siteName)']/logFile"
    $enabled = Get-ExamIisPropertyValue -Filter $filter -Name 'enabled'
    $format = Get-ExamIisPropertyValue -Filter $filter -Name 'logFormat'
    $directory = Get-ExamIisPropertyValue -Filter $filter -Name 'directory'
    $period = Get-ExamIisPropertyValue -Filter $filter -Name 'period'
    $target = Get-ExamIisPropertyValue -Filter $filter -Name 'logTargetW3C'
    Assert-Condition ([string]$enabled -ieq 'True') 'Abilitare la registrazione del sito.'
    Assert-Condition ([string]$format -eq $Config.logging.format) 'Formato log richiesto: W3C.'
    Assert-Condition ((Get-NormalizedPath ([string]$directory)) -ieq (Get-NormalizedPath $Config.logging.directory)) 'Directory log non corretta.'
    Assert-Condition ([string]$period -eq $Config.logging.period) 'Creare un nuovo file di log ogni giorno.'
    Assert-Condition ([string]$target -eq $Config.logging.destination) 'Impostare la destinazione del log su File.'
}
function Get-ExamVirtualDirectory {
    param($Config)
    Add-Type -Path (Join-Path $env:SystemRoot 'System32\inetsrv\Microsoft.Web.Administration.dll') -ErrorAction Stop
    $manager = New-Object Microsoft.Web.Administration.ServerManager
    try {
        $site = $manager.Sites[$Config.siteName]
        Assert-Condition ($null -ne $site) 'Sito IIS non trovato.'
        $path = '/' + $Config.virtualDirectory.alias
        Assert-Condition ($null -eq $site.Applications[$path]) 'Il materiali deve essere una directory virtuale, non un''applicazione separata.'
        $directory = $site.Applications['/'].VirtualDirectories[$path]
        Assert-Condition ($null -ne $directory) 'Directory virtuale materiali assente.'
        return [pscustomobject]@{path=[string]$directory.Path; physicalPath=[string]$directory.PhysicalPath}
    } finally { $manager.Dispose() }
}

function Test-ExamVirtualDirectory {
    param($Config)
    $directory = Get-ExamVirtualDirectory $Config
    Assert-Condition ($directory.path -ceq ('/' + $Config.virtualDirectory.alias)) 'Alias della directory virtuale errato.'
    Assert-Condition ((Get-NormalizedPath $directory.physicalPath) -ieq (Get-NormalizedPath $Config.virtualDirectory.physicalPath)) 'Percorso fisico della directory virtuale errato.'
    Assert-Condition (Test-Path -LiteralPath $Config.virtualDirectory.physicalPath -PathType Container) 'Cartella esterna del materiali assente.'
    Assert-Condition (Test-Path -LiteralPath (Join-Path $Config.virtualDirectory.physicalPath $Config.virtualDirectory.indexFile) -PathType Leaf) 'index.html del materiali assente.'
}
function Test-ExamExtraPage {
    param($Config)
    Assert-Condition (Test-Path -LiteralPath (Join-Path $Config.physicalPath $Config.extraPage.fileName) -PathType Leaf) 'Pagina contatti.html assente nella cartella del sito.'
    $site = Get-ExamSite $Config
    Assert-Condition ($site.State -eq 'Started' -and (Test-ExpectedBinding $site $Config)) 'Avviare il sito e configurare il binding richiesto.'
    Assert-Condition ((Get-NormalizedPath $site.physicalPath) -ieq (Get-NormalizedPath $Config.physicalPath)) 'La seconda pagina deve appartenere al sito nel percorso richiesto.'
    $uri = 'http://127.0.0.1:{0}/{1}' -f $Config.port, $Config.extraPage.fileName
    $response = Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec 8 -MaximumRedirection 0 -ErrorAction Stop
    Assert-Condition ($response.StatusCode -eq 200) 'contatti.html non restituisce HTTP 200.'
    Assert-Condition ([string]$response.Content -clike ('*' + $Config.extraPage.expectedText + '*')) 'Testo richiesto assente dalla seconda pagina.'
}
function Test-DirectUserAcl {
    param($Config)
    Assert-Condition (Test-Path -LiteralPath $Config.directFolder -PathType Container) 'Cartella Personale assente.'
    $user = Get-LocalUser -Name $Config.localUser -ErrorAction Stop
    $acl = Get-Acl -LiteralPath $Config.directFolder -ErrorAction Stop
    $rules = @($acl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]))
    $modify = [int][Security.AccessControl.FileSystemRights]::Modify
    $sync = [int][Security.AccessControl.FileSystemRights]::Synchronize
    $children = [int][Security.AccessControl.InheritanceFlags]'ContainerInherit, ObjectInherit'
    $userRights = 0
    $valid = $false
    $denySids = @($user.SID.Value, 'S-1-1-0', 'S-1-5-11', 'S-1-5-32-545')
    $group = Get-LocalGroup -Name $Config.localGroup -ErrorAction Stop
    $denySids += $group.SID.Value
    foreach ($rule in $rules) {
        $sid = $rule.IdentityReference.Value
        $rights = [int]$rule.FileSystemRights
        if ($sid -in $denySids -and $rule.AccessControlType -eq 'Deny' -and ($rights -band $modify) -ne 0) {
            throw 'Una ACE Deny sull''utente o su un suo gruppo limita Modify nella cartella Personale.'
        }
        if ($sid -eq $user.SID.Value -and $rule.AccessControlType -eq 'Allow') {
            $userRights = $userRights -bor $rights
            if (-not $rule.IsInherited -and ($rights -band (-bnot $sync)) -eq $modify -and
                ([int]$rule.InheritanceFlags -band $children) -eq $children -and
                [int]$rule.PropagationFlags -eq 0) { $valid = $true }
        }
    }
    Assert-Condition $valid 'Assegnare Modify direttamente all''editor su cartella, sottocartelle e file.'
    Assert-Condition (($userRights -band (-bnot ($modify -bor $sync))) -eq 0) 'L''editor ha diritti diretti aggiuntivi oltre Modify sulla cartella Personale.'
}

function Test-ReportTask {
    param($Config)
    $taskConfig = [pscustomobject]@{ scheduledTask = $Config.reportTask.name; task = $Config.reportTask }
    Test-TaskConfiguration $taskConfig
    $task = Get-ScheduledTask -TaskName $Config.reportTask.name -TaskPath $Config.reportTask.path -ErrorAction Stop
    $info = Get-ScheduledTaskInfo -TaskName $Config.reportTask.name -TaskPath $Config.reportTask.path -ErrorAction Stop
    Assert-Condition ($task.State -ne 'Running' -and $info.LastRunTime -gt [datetime]'2000-01-01' -and
        $info.LastTaskResult -eq 0) 'Eseguire FormazioneReport e ottenere risultato 0x0.'
    Assert-Condition (Test-Path -LiteralPath $Config.reportTask.reportFile -PathType Leaf) 'File report-giornaliero.txt assente.'
    $content = Get-Content -LiteralPath $Config.reportTask.reportFile -Raw -ErrorAction Stop
    Assert-Condition (([string]$content).Trim() -ceq $Config.reportTask.expectedText) 'Il report non contiene il testo richiesto.'
}
$executionNumber = $null
try {
    if ([string]::IsNullOrWhiteSpace($ExamRoot)) {
        $ExamRoot = Split-Path -Parent $PSScriptRoot
    }
    Assert-GradingEnvironment
    $config = Read-ExamConfig $ExamRoot
    $executionNumber = Update-GraderExecutionCount $ExamRoot
    if (-not $Json) { Write-Output "ESECUZIONE GRADER N. $executionNumber" }
    $result = Get-InfrastructureReport $config
    $result | Add-Member -MemberType NoteProperty -Name executionNumber -Value $executionNumber
    if ($Json) {
        $result | ConvertTo-Json -Depth 6
    } else {
        Write-Output "FACSIMILE INFRASTRUCTURE - $($result.examId)"
        foreach ($check in $result.checks) {
            Write-Output ('{0} [{1}/{2}] {3}' -f $check.status, $check.earnedPoints, $check.maxPoints, $check.label)
            if (-not $check.passed) { Write-Output ('  Motivo: ' + $check.detail) }
        }
        Write-Output "PUNTEGGIO TECNICO: $($result.score)/$($result.maxScore)"
        Write-Output "ESITO COMPLESSIVO: $($result.status)"
    }
    if ($result.score -eq $result.maxScore) { exit 0 }
    exit 1
} catch {
    if ($Json) {
        [pscustomobject]@{ status = 'ERROR'; error = $_.Exception.Message; score = $null; maxScore = 20; executionNumber = $executionNumber } |
            ConvertTo-Json -Depth 3
    } else {
        Write-Output ('ERRORE DI AVVIO: ' + $_.Exception.Message)
        Write-Output 'Nessun punteggio assegnato. Consultare grader\AVVIA-GRADER.txt.'
    }
    exit 2
}
