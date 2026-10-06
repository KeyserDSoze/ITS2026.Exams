param(
    [string]$SearchRoot = 'C:\',
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'RISULTATI')
)

$ErrorActionPreference = 'Stop'
$grader = Join-Path $PSScriptRoot 'grade-exam.ps1'
if (-not (Test-Path $grader)) { throw 'grade-exam.ps1 not found.' }

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$markers = @(Get-ChildItem -Path $SearchRoot -Filter '.exam-id' -File -Recurse -Force -ErrorAction SilentlyContinue | Sort-Object FullName -Unique)
if ($markers.Count -eq 0) { throw "No exam markers found under $SearchRoot" }

$rows = @()
foreach ($marker in $markers) {
    $examRoot = Split-Path -Parent $marker.FullName
    $json = (& $grader -SearchRoot $examRoot -Json -ReportDirectory $OutputDirectory | Select-Object -Last 1)
    $result = $json | ConvertFrom-Json
    $rows += [pscustomobject]@{
        StudentFolder = Split-Path -Leaf $examRoot
        ExamId = $result.examId
        ExamRoot = $result.examRoot
        Technical = $result.technicalScore
        Questions = $result.questionsScore
        Total = $result.total
        Max = $result.totalMax
    }
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$csv = Join-Path $OutputDirectory "RIEPILOGO-$stamp.csv"
$rows | Sort-Object StudentFolder, ExamId | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8

Write-Host "Corrected $($rows.Count) exam package(s)."
Write-Host "CSV summary: $csv"
$rows | Format-Table -AutoSize
