param([Parameter(Mandatory=$true)][string]$ExamRoot,[switch]$Json)
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../../..')).Path
& (Join-Path $repoRoot 'tools/grade-dev-practice.ps1') -ExamRoot $ExamRoot -ExamId 'DEV-009-SAMPLE' -ApiPath '/api/tasks' -JsonProperty 'name' -Mutation 'patch' -RequireUi -Json:$Json
