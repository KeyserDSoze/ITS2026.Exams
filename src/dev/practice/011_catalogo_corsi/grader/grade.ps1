param([Parameter(Mandatory=$true)][string]$ExamRoot,[switch]$Json)
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../../..')).Path
& (Join-Path $repoRoot 'tools/grade-dev-practice.ps1') -ExamRoot $ExamRoot -ExamId 'DEV-011-SAMPLE' -ApiPath '/api/courses' -JsonProperty 'title' -Mutation 'put+delete' -RequireUi -Json:$Json
