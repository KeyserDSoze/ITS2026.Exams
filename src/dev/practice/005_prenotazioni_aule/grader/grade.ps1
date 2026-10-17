param([Parameter(Mandatory=$true)][string]$ExamRoot,[switch]$Json)
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../../..')).Path
& (Join-Path $repoRoot 'tools/grade-dev-practice.ps1') -ExamRoot $ExamRoot -ExamId 'DEV-005-SAMPLE' -ApiPath '/api/bookings' -JsonProperty 'name' -ExtraProperty 'note' -RequireUi -Json:$Json
