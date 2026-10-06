param(
    [Parameter(Mandatory=$true)][string]$ExamRoot
)

$ErrorActionPreference = 'Stop'
$root = [System.IO.Path]::GetFullPath($ExamRoot)
if (-not (Test-Path $root -PathType Container)) { throw "Exam root not found: $root" }

$required = @('.exam-id','domanda1.txt','domanda2.txt','README.md')
foreach ($name in $required) {
    $path = Join-Path $root $name
    if (-not (Test-Path $path -PathType Leaf)) { throw "Missing required file: $name" }
}

$marker = Join-Path $root '.exam-id'
$value = (Get-Content -Raw $marker).Trim()
if ([string]::IsNullOrWhiteSpace($value) -or -not $value.Contains('|')) {
    throw 'Invalid .exam-id format. Expected EXAM-ID|TOKEN.'
}

Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue
$item = Get-Item -Force $marker
$item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden -bor [System.IO.FileAttributes]::ReadOnly

Write-Host 'Exam package prepared successfully.'
Write-Host "Root: $root"
Write-Host "Marker: $value"
Write-Host 'The .exam-id marker is Hidden + ReadOnly.'
