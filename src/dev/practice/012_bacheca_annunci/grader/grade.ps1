param([Parameter(Mandatory=$true)][string]$ExamRoot,[switch]$Json)
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../../..')).Path
& (Join-Path $repoRoot 'tools/grade-dev-practice.ps1') -ExamRoot $ExamRoot -ExamId 'DEV-012-SAMPLE' -ApiPath '/api/announcements' -JsonProperty 'title' -Mutation 'patch+delete' -RequireUi -RequireFilter -Json:$Json
