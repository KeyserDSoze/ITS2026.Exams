$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') { throw 'This reference solution requires Windows.' }

$sampleRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$candidate = Join-Path $sampleRoot 'candidate'
$config = Get-Content -Raw (Join-Path $candidate 'exam-config.json') | ConvertFrom-Json

if (Get-Command Install-WindowsFeature -ErrorAction SilentlyContinue) {
    Install-WindowsFeature Web-Server -IncludeManagementTools | Out-Null
} else {
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All -NoRestart | Out-Null
}
Import-Module WebAdministration -ErrorAction Stop

New-Item -ItemType Directory -Force -Path $config.physicalPath | Out-Null
Copy-Item -Path (Join-Path $candidate 'website/*') -Destination $config.physicalPath -Recurse -Force

if (Get-Website -Name $config.siteName -ErrorAction SilentlyContinue) {
    Remove-Website -Name $config.siteName
}
New-Website -Name $config.siteName -PhysicalPath $config.physicalPath -Port ([int]$config.port) -Force | Out-Null
Start-Website -Name $config.siteName

Get-NetFirewallRule -DisplayName $config.firewallRule -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName $config.firewallRule -Direction Inbound -Protocol TCP -LocalPort ([int]$config.port) -Action Allow | Out-Null

if (-not (Get-LocalUser -Name $config.localUser -ErrorAction SilentlyContinue)) {
    New-LocalUser -Name $config.localUser -NoPassword -AccountNeverExpires | Out-Null
}

New-Item -ItemType Directory -Force -Path $config.dataFolder | Out-Null
& icacls.exe $config.dataFolder /grant "$($config.localUser):(OI)(CI)M" /T /C | Out-Null
if ($LASTEXITCODE -ne 0) { throw "icacls failed with exit code $LASTEXITCODE" }

$taskArguments = "-NoProfile -Command `"Invoke-WebRequest 'http://localhost:$($config.port)/' -UseBasicParsing | Out-Null`""
$taskAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $taskArguments
$taskTrigger = New-ScheduledTaskTrigger -Daily -At '23:59'
Register-ScheduledTask -TaskName $config.scheduledTask -Action $taskAction -Trigger $taskTrigger -Force | Out-Null

Write-Host 'Reference infrastructure configuration applied.'
