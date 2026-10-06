param(
    [string]$SearchRoot = 'C:\',
    [string]$ExamId,
    [switch]$DiscoveryOnly,
    [switch]$Json,
    [string]$ReportDirectory = (Join-Path $PSScriptRoot 'RISULTATI'),
    [string]$PrivateGraderRoot
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($PrivateGraderRoot)) {
    $PrivateGraderRoot = if ($env:ITS_EXAM_PRIVATE_GRADERS) { $env:ITS_EXAM_PRIVATE_GRADERS } else { Join-Path $repoRoot 'private-graders' }
}

function Find-Markers([string]$Root) {
    if (-not (Test-Path $Root)) { return @() }
    return @(Get-ChildItem -Path $Root -Filter '.exam-id' -File -Recurse -Force -ErrorAction SilentlyContinue)
}

function ConvertTo-HtmlEncoded([object]$Value) {
    return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function Write-HtmlReport([object]$Result, [string]$Path) {
    $rows = foreach ($check in @($Result.technicalChecks)) {
        $status = if ($check.passed) { 'PASS' } else { 'FAIL' }
        "<tr><td>$(ConvertTo-HtmlEncoded $check.name)</td><td>$status</td><td>$($check.points)</td></tr>"
    }
    $html = @"
<!doctype html>
<html lang="it">
<head>
<meta charset="utf-8">
<title>Risultato $($Result.examId)</title>
<style>
body{font-family:Arial,sans-serif;max-width:900px;margin:40px auto;padding:0 20px}h1{margin-bottom:8px}.score{font-size:1.4rem;font-weight:700;margin:20px 0}table{border-collapse:collapse;width:100%}th,td{border:1px solid #ccc;padding:8px;text-align:left}th{background:#f3f3f3}.meta{color:#555}
</style>
</head>
<body>
<h1>Risultato esame $(ConvertTo-HtmlEncoded $Result.examId)</h1>
<p class="meta">Percorso: $(ConvertTo-HtmlEncoded $Result.examRoot)</p>
<div class="score">Tecnico: $($Result.technicalScore)/20 &nbsp; | &nbsp; Domande: $($Result.questionsScore)/10 &nbsp; | &nbsp; Totale: $($Result.total)/30</div>
<h2>Dettaglio controlli tecnici</h2>
<table><thead><tr><th>Controllo</th><th>Esito</th><th>Punti</th></tr></thead><tbody>
$($rows -join "`n")
</tbody></table>
</body>
</html>
"@
    Set-Content -Path $Path -Value $html -Encoding UTF8
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
    }
    'INFRA-SAMPLE' {
        $grader = Join-Path $repoRoot 'src/infra/sample/grader/grade-infra.ps1'
    }
    default {
        $grader = Join-Path (Join-Path $PrivateGraderRoot $id) 'grade.ps1'
        if (-not (Test-Path $grader -PathType Leaf)) {
            throw "Exam ID non supportato dal framework pubblico e grader privato non trovato: $id"
        }
    }
}

$technical = (& $grader -ExamRoot $root -Json | Select-Object -Last 1) | ConvertFrom-Json
if ([int]$technical.maxScore -ne 20) { throw "Il grader tecnico $id deve avere maxScore=20." }

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

New-Item -ItemType Directory -Force -Path $ReportDirectory | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$jsonFile = Join-Path $ReportDirectory "RISULTATO-$id-$stamp.json"
$htmlFile = Join-Path $ReportDirectory "RISULTATO-$id-$stamp.html"
$result | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 $jsonFile
Write-HtmlReport -Result $result -Path $htmlFile

if ($Json) { $result | ConvertTo-Json -Depth 6 -Compress }
else {
    Write-Host "Esame: $id"
    Write-Host "Tecnico: $($result.technicalScore)/20"
    Write-Host "Domande: $($result.questionsScore)/10"
    Write-Host "TOTALE: $($result.total)/30"
    Write-Host "Report JSON: $jsonFile"
    Write-Host "Report HTML: $htmlFile"
}
