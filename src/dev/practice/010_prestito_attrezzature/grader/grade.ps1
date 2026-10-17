param([Parameter(Mandatory=$true)][string]$ExamRoot,[switch]$Json)
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../../..')).Path
& (Join-Path $repoRoot 'tools/grade-dev-practice.ps1') -ExamRoot $ExamRoot -ExamId 'DEV-010-SAMPLE' -ApiPath '/api/equipment' -JsonProperty 'name' -Mutation 'patch+delete' -RequireUi -Json:$Json
