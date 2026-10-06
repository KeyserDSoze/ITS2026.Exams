$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$tools = Join-Path $repoRoot 'tools'

$temp = Join-Path ([System.IO.Path]::GetTempPath()) ("its-exam-test-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $temp | Out-Null
try {
    Set-Content -Path (Join-Path $temp '.exam-id') -Value 'DEV-SAMPLE|TEST-TOKEN'
    Set-Content -Path (Join-Path $temp 'domanda1.txt') -Value ('A' * 250)
    Set-Content -Path (Join-Path $temp 'domanda2.txt') -Value 'troppo corta'

    $discoveryJson = (& (Join-Path $tools 'grade-exam.ps1') -SearchRoot $temp -DiscoveryOnly -Json | Select-Object -Last 1)
    $discovery = $discoveryJson | ConvertFrom-Json
    if ($discovery.examId -ne 'DEV-SAMPLE') { throw 'Exam discovery failed.' }

    $questionsJson = (& (Join-Path $tools 'grade-questions.ps1') -ExamRoot $temp -Json | Select-Object -Last 1)
    $questions = $questionsJson | ConvertFrom-Json
    if ($questions.domanda1 -ne 5 -or $questions.domanda2 -ne 0 -or $questions.totale -ne 5) {
        throw "Question grader failed. Result: $questionsJson"
    }

    Write-Host 'Common tests OK.'
}
finally {
    Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue
}
