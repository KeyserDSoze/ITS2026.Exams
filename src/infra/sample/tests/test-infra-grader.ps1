$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sample = Split-Path -Parent $here
$grader = Join-Path $sample 'grader/grade-infra.ps1'
$candidate = Join-Path $sample 'candidate'

$passJson = (& $grader -ExamRoot $candidate -StateFile (Join-Path $here 'fixtures/pass.json') -Json | Select-Object -Last 1)
$pass = $passJson | ConvertFrom-Json
if ($pass.score -ne 20) { throw "Passing infra fixture must score 20/20. Result: $passJson" }

$failJson = (& $grader -ExamRoot $candidate -StateFile (Join-Path $here 'fixtures/fail.json') -Json | Select-Object -Last 1)
$fail = $failJson | ConvertFrom-Json
if ($fail.score -ge 20) { throw "Failing infra fixture must not score 20/20. Result: $failJson" }

Write-Host "INFRA simulated grader OK. Pass=$($pass.score)/20, fail=$($fail.score)/20"
