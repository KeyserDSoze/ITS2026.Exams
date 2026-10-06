param(
    [Parameter(Mandatory=$true)][string]$PrivateGraderRoot,
    [string]$OutputDirectory = (Join-Path (Split-Path -Parent $PSScriptRoot) 'dist-private')
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$privateRoot = [System.IO.Path]::GetFullPath($PrivateGraderRoot)
if (-not (Test-Path $privateRoot -PathType Container)) { throw "Private grader root not found: $privateRoot" }

$graderFolders = @(Get-ChildItem -Path $privateRoot -Directory)
if ($graderFolders.Count -eq 0) { throw 'No private grader folders found.' }
foreach ($folder in $graderFolders) {
    if (-not (Test-Path (Join-Path $folder.FullName 'grade.ps1') -PathType Leaf)) {
        throw "Missing grade.ps1 in private grader folder: $($folder.Name)"
    }
}

if (Test-Path $OutputDirectory) { Remove-Item -Recurse -Force $OutputDirectory }
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$stage = Join-Path $OutputDirectory '_stage'
$usb = Join-Path $stage 'USB-CORRETTORE-PRIVATE'
New-Item -ItemType Directory -Force -Path (Join-Path $usb 'tools') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $usb 'src/dev/sample/grader') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $usb 'src/infra/sample/grader') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $usb 'private-graders') | Out-Null

Get-ChildItem -Path (Join-Path $repoRoot 'tools') -File |
    Where-Object { $_.Name -notin @('build-packages.ps1','build-private-usb.ps1') } |
    Copy-Item -Destination (Join-Path $usb 'tools') -Force
Copy-Item -Path (Join-Path $repoRoot 'src/dev/sample/grader/*') -Destination (Join-Path $usb 'src/dev/sample/grader') -Force
Copy-Item -Path (Join-Path $repoRoot 'src/infra/sample/grader/*') -Destination (Join-Path $usb 'src/infra/sample/grader') -Force
Copy-Item -Path (Join-Path $privateRoot '*') -Destination (Join-Path $usb 'private-graders') -Recurse -Force

$zip = Join-Path $OutputDirectory 'USB-CORRETTORE-PRIVATE.zip'
Compress-Archive -Path (Join-Path $usb '*') -DestinationPath $zip -CompressionLevel Optimal
Remove-Item -Recurse -Force $stage

Write-Host "Private USB package created: $zip"
Write-Host "Included private graders: $($graderFolders.Name -join ', ')"
