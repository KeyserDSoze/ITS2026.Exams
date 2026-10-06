param(
    [Parameter(Mandatory=$true)][string]$ExamRoot,
    [int]$MinLength = 200,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'

function Get-AnswerScore([string]$Path) {
    if (-not (Test-Path $Path)) { return 0 }
    $text = (Get-Content -Raw -Path $Path).Trim()
    if ($text.Length -ge $MinLength) { return 5 }
    return 0
}

$q1 = Get-AnswerScore (Join-Path $ExamRoot 'domanda1.txt')
$q2 = Get-AnswerScore (Join-Path $ExamRoot 'domanda2.txt')
$result = [pscustomobject]@{
    domanda1 = $q1
    domanda2 = $q2
    totale = ($q1 + $q2)
    soglia_caratteri = $MinLength
}

if ($Json) { $result | ConvertTo-Json -Compress }
else {
    Write-Host "Domanda 1: $q1/5"
    Write-Host "Domanda 2: $q2/5"
    Write-Host "DOMANDE: $($result.totale)/10"
}
