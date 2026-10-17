param([Parameter(Mandatory=$true)][string]$ExamRoot,[switch]$Json)
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../../..')).Path
& (Join-Path $repoRoot 'tools/grade-dev-practice.ps1') -ExamRoot $ExamRoot -ExamId 'DEV-008-SAMPLE' -ApiPath '/api/expenses' -JsonProperty 'name' -ExtraProperty 'note' -Mutation 'delete' -RequireUi -Json:$Json
