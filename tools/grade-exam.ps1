param(
    [string]$SearchRoot = 'C:\',
    [string]$ExamId,
    [switch]$DiscoveryOnly,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

function Find-Markers([string]$Root) {
    if (-not (Test-Path $Root)) { return @() }
    return @(Get-ChildItem -Path $Root -Filter '.exam-id' -File -Recurse -Force -ErrorAction SilentlyContinue)
}

Write-Host "Ricerca marker .exam-id in $SearchRoot ..."
$markers = @()
$normalizedRoot = [System.IO.Path]::GetFullPath($SearchRoot).TrimEnd('\')

if ($normalizedRoot -ieq 'C:') {
    $fastRoots = @('C:\Exam', 'C:\Users', 'C:\Projects', 'C:\Workspace')
    foreach ($candidateRoot in $fastRoots) {
        $markers += Find-Markers $candidateRoot
    }
    $markers = @($markers | Sort-Object FullName -Unique)
    if ($markers.Count -eq 0) {
        Write-Host 'Nessun marker nei percorsi rapidi: fallback alla scansione completa di C:\ ...'
        $markers = Find-Markers 'C:\'
    }
} else {
    $markers = Find-Markers $SearchRoot
}

if ($ExamId) {
    $markers = @($markers | Where-Object { ((Get-Content -Raw $_.FullName).Trim().Split('|')[0]) -eq $ExamId })
}
if ($markers.Count -eq 0) { throw 'Nessun esame riconosciuto trovato.' }
if ($markers.Count -gt 1) { throw "Trovati $($markers.Count) esami. Specificare -ExamId o rimuovere i duplicati per evitare ambiguita." }

$marker = $markers[0]
$root = Split-Path -Parent $marker.FullName
$markerValue = (Get-Content -Raw $marker.FullName).Trim()
$parts = $markerValue.Split('|')
$id = $parts[0]
$token = if ($parts.Count -gt 1) { $parts[1] } else { '' }

if ($DiscoveryOnly) {
    $result = [pscustomobject]@{ examId=$id; token=$token; examRoot=$root }
    if ($Json) { $result | ConvertTo-Json -Compress } else { $result | Format-List }
    exit 0
}

switch ($id) {
    'DEV-SAMPLE' {
        $grader = Join-Path $repoRoot 'src/dev/sample/grader/grade-dev.ps1'
        $technical = (& $grader -ExamRoot $root -Json | Select-Object -Last 1) | ConvertFrom-Json
    }
    'INFRA-SAMPLE' {
        $grader = Join-Path $repoRoot 'src/infra/sample/grader/grade-infra.ps1'
        $technical = (& $grader -ExamRoot $root -Json | Select-Object -Last 1) | ConvertFrom-Json
    }
    default { throw "Exam ID non supportato: $id" }
}

$questionGrader = Join-Path $PSScriptRoot 'grade-questions.ps1'
$questions = (& $questionGrader -ExamRoot $root -Json | Select-Object -Last 1) | ConvertFrom-Json

$result = [pscustomobject]@{
    examId=$id
    examRoot=$root
    technicalScore=[int]$technical.score
    technicalMax=20
    questionsScore=[int]$questions.totale
    questionsMax=10
    total=([int]$technical.score + [int]$questions.totale)
    totalMax=30
    technicalChecks=$technical.checks
}

$outDir = Join-Path $PSScriptRoot 'RISULTATI'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$outFile = Join-Path $outDir "RISULTATO-$id-$stamp.json"
$result | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 $outFile

if ($Json) { $result | ConvertTo-Json -Depth 6 -Compress }
else {
    Write-Host "Esame: $id"
    Write-Host "Tecnico: $($result.technicalScore)/20"
    Write-Host "Domande: $($result.questionsScore)/10"
    Write-Host "TOTALE: $($result.total)/30"
    Write-Host "Report: $outFile"
}
