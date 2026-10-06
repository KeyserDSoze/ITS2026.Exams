param(
    [string]$OutputDirectory = (Join-Path (Split-Path -Parent $PSScriptRoot) 'dist')
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
if (Test-Path $OutputDirectory) { Remove-Item -Recurse -Force $OutputDirectory }
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$staging = Join-Path $OutputDirectory '_staging'
New-Item -ItemType Directory -Force -Path $staging | Out-Null

function New-ZipFromFolder([string]$Source, [string]$ZipPath) {
    if (Test-Path $ZipPath) { Remove-Item -Force $ZipPath }
    Compress-Archive -Path (Join-Path $Source '*') -DestinationPath $ZipPath -CompressionLevel Optimal
}

# Candidate packages
New-ZipFromFolder (Join-Path $repoRoot 'src/dev/sample/candidate') (Join-Path $OutputDirectory 'DEV-SAMPLE-CANDIDATO.zip')
New-ZipFromFolder (Join-Path $repoRoot 'src/infra/sample/candidate') (Join-Path $OutputDirectory 'INFRA-SAMPLE-CANDIDATO.zip')

# USB corrector package: preserve the same relative layout expected by grade-exam.ps1.
$usb = Join-Path $staging 'USB-CORRETTORE'
New-Item -ItemType Directory -Force -Path (Join-Path $usb 'tools') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $usb 'src/dev/sample/grader') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $usb 'src/infra/sample/grader') | Out-Null

Get-ChildItem -Path (Join-Path $repoRoot 'tools') -File | Where-Object { $_.Name -ne 'build-packages.ps1' } | Copy-Item -Destination (Join-Path $usb 'tools') -Force
Copy-Item -Path (Join-Path $repoRoot 'src/dev/sample/grader/*') -Destination (Join-Path $usb 'src/dev/sample/grader') -Force
Copy-Item -Path (Join-Path $repoRoot 'src/infra/sample/grader/*') -Destination (Join-Path $usb 'src/infra/sample/grader') -Force
New-ZipFromFolder $usb (Join-Path $OutputDirectory 'USB-CORRETTORE.zip')

Remove-Item -Recurse -Force $staging
Write-Host "Packages created in $OutputDirectory"
Get-ChildItem $OutputDirectory -Filter *.zip | ForEach-Object { Write-Host " - $($_.Name) [$($_.Length) bytes]" }
