param([Parameter(Mandatory=$true)][string]$ExamRoot,[switch]$Json)
$repoRoot=(Resolve-Path (Join-Path $PSScriptRoot '../../../../..')).Path
& (Join-Path $repoRoot 'tools/grade-dev-practice.ps1') -ExamRoot $ExamRoot -ExamId 'DEV-BOOKS-SAMPLE' -ApiPath '/api/books' -JsonProperty 'title' -Json:$Json
