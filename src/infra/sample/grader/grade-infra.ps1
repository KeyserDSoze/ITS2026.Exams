param(
    [Parameter(Mandatory=$true)][string]$ExamRoot,
    [string]$StateFile,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
$configPath = Join-Path $ExamRoot 'exam-config.json'
if (-not (Test-Path $configPath)) { throw "Missing exam-config.json in $ExamRoot" }
$config = Get-Content -Raw $configPath | ConvertFrom-Json

function Get-RealState {
    if (-not $IsWindows) { throw 'Real infrastructure grading requires Windows.' }

    $iisInstalled = $false
    if (Get-Command Get-WindowsFeature -ErrorAction SilentlyContinue) {
        $iisInstalled = ((Get-WindowsFeature Web-Server).InstallState -eq 'Installed')
    } else {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -ErrorAction SilentlyContinue
        $iisInstalled = ($feature.State -eq 'Enabled')
    }

    $siteNameOk = $false
    $pathOk = $false
    $portOk = $false
    $responds = $false
    if ($iisInstalled) {
        Import-Module WebAdministration
        $site = Get-Website -Name $config.siteName -ErrorAction SilentlyContinue
        $siteNameOk = $null -ne $site
        if ($site) {
            $actualPath = (Get-Item "IIS:\Sites\$($config.siteName)").physicalPath
            $pathOk = ([System.IO.Path]::GetFullPath($actualPath).TrimEnd('\') -ieq [System.IO.Path]::GetFullPath($config.physicalPath).TrimEnd('\'))
            $portOk = @($site.Bindings.Collection | Where-Object { $_.protocol -eq 'http' -and $_.bindingInformation -match ":$($config.port):" }).Count -gt 0
            try {
                $web = Invoke-WebRequest -Uri "http://localhost:$($config.port)/" -UseBasicParsing -TimeoutSec 5
                $responds = ($web.StatusCode -eq 200 -and $web.Content -match [regex]::Escape($config.expectedText))
            } catch {}
        }
    }

    $firewall = $false
    $rule = Get-NetFirewallRule -DisplayName $config.firewallRule -ErrorAction SilentlyContinue
    if ($rule) {
        $pf = $rule | Get-NetFirewallPortFilter -ErrorAction SilentlyContinue
        $firewall = ($rule.Enabled -eq 'True' -and $rule.Action -eq 'Allow' -and @($pf | Where-Object { $_.Protocol -eq 'TCP' -and [int]$_.LocalPort -eq [int]$config.port }).Count -gt 0)
    }

    $userExists = $null -ne (Get-LocalUser -Name $config.localUser -ErrorAction SilentlyContinue)
    $folderExists = Test-Path $config.dataFolder
    $modifyPermission = $false
    if ($folderExists) {
        $acl = Get-Acl $config.dataFolder
        foreach ($entry in $acl.Access) {
            if (($entry.IdentityReference.Value -eq $config.localUser -or $entry.IdentityReference.Value -like "*\$($config.localUser)") -and $entry.AccessControlType -eq 'Allow' -and ($entry.FileSystemRights.ToString() -match 'Modify')) {
                $modifyPermission = $true
                break
            }
        }
    }

    $taskExists = $null -ne (Get-ScheduledTask -TaskName $config.scheduledTask -ErrorAction SilentlyContinue)

    [pscustomobject]@{
        iisInstalled=$iisInstalled; siteNameOk=$siteNameOk; pathOk=$pathOk; portOk=$portOk; siteResponds=$responds;
        firewallOk=$firewall; userExists=$userExists; folderExists=$folderExists; modifyPermission=$modifyPermission; taskExists=$taskExists
    }
}

$state = if ($StateFile) { Get-Content -Raw $StateFile | ConvertFrom-Json } else { Get-RealState }

$weights = [ordered]@{
    iisInstalled=2; siteNameOk=2; pathOk=2; portOk=2; siteResponds=3;
    firewallOk=2; userExists=2; folderExists=1; modifyPermission=2; taskExists=2
}

$score = 0
$checks = foreach ($name in $weights.Keys) {
    $passed = [bool]$state.$name
    $points = [int]$weights[$name]
    if ($passed) { $score += $points }
    [pscustomobject]@{name=$name; points=$points; passed=$passed}
}

$result = [pscustomobject]@{ exam='INFRA-SAMPLE'; score=$score; maxScore=20; checks=$checks }
if ($Json) { $result | ConvertTo-Json -Depth 5 -Compress }
else {
    foreach ($c in $checks) { Write-Host "$(if($c.passed){'PASS'}else{'FAIL'}) [$($c.points)] $($c.name)" }
    Write-Host "PUNTEGGIO TECNICO: $score/20"
}
