param([Parameter(Mandatory=$true)][string]$ExamRoot,[switch]$Json)
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../../..')).Path
& (Join-Path $repoRoot 'tools/grade-dev-practice.ps1') -ExamRoot $ExamRoot -ExamId 'DEV-007-SAMPLE' -ApiPath '/api/movies' -JsonProperty 'title' -Mutation 'delete' -RequireUi -Json:$Json
