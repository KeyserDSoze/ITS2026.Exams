$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sample = Split-Path -Parent $here
$grader = Join-Path $sample 'grader/grade-dev.ps1'
$solution = Join-Path $sample 'solution'
$candidate = Join-Path $sample 'candidate'

Write-Host 'Testing reference solution...'
$solutionJson = (& $grader -ExamRoot $solution -Json | Select-Object -Last 1)
$solutionResult = $solutionJson | ConvertFrom-Json
if ($solutionResult.score -ne 20) {
    throw "Reference DEV solution must score 20/20, got $($solutionResult.score). Result: $solutionJson"
}

Write-Host 'Testing intentionally incomplete candidate skeleton...'
$candidateJson = (& $grader -ExamRoot $candidate -Json | Select-Object -Last 1)
$candidateResult = $candidateJson | ConvertFrom-Json
if ($candidateResult.score -ge 20) {
    throw "Incomplete DEV skeleton must not score 20/20. Result: $candidateJson"
}

Write-Host "DEV grader OK. Reference=$($solutionResult.score)/20, incomplete=$($candidateResult.score)/20"
