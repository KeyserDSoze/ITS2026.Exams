$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$tools = Join-Path $repoRoot 'tools'
$source = Join-Path $repoRoot 'src/dev/sample/solution'
$tempRoot = Join-Path 'C:\' ("ITS-EXAM-E2E-" + [guid]::NewGuid().ToString('N'))
$examRoot = Join-Path $tempRoot 'random\nested\student-project'
$batchOut = Join-Path $tempRoot 'batch-results'

New-Item -ItemType Directory -Force -Path $examRoot | Out-Null
try {
    Copy-Item -Path (Join-Path $source '*') -Destination $examRoot -Recurse -Force
    Set-Content -Path (Join-Path $examRoot '.exam-id') -Value 'DEV-SAMPLE|USB-E2E-TOKEN' -Encoding UTF8
    Set-Content -Path (Join-Path $examRoot 'domanda1.txt') -Value ('Risposta di test sufficientemente lunga. ' * 10) -Encoding UTF8
    Set-Content -Path (Join-Path $examRoot 'domanda2.txt') -Value ('Seconda risposta di test sufficientemente lunga. ' * 10) -Encoding UTF8
    if (-not (Test-Path (Join-Path $examRoot 'README.md'))) { Set-Content (Join-Path $examRoot 'README.md') '# Test' }

    & (Join-Path $tools 'PREPARE-EXAM.ps1') -ExamRoot $examRoot
    $marker = Get-Item -Force (Join-Path $examRoot '.exam-id')
    if (-not ($marker.Attributes -band [System.IO.FileAttributes]::Hidden)) { throw '.exam-id was not hidden.' }
    if (-not ($marker.Attributes -band [System.IO.FileAttributes]::ReadOnly)) { throw '.exam-id was not made read-only.' }

    $env:EXAM_CI = '1'
    & cmd.exe /c "`"$tools\CORREZIONE.cmd`" -SearchRoot `"$tempRoot`" -ExamId DEV-SAMPLE"
    if ($LASTEXITCODE -ne 0) { throw "CORREZIONE.cmd failed with exit code $LASTEXITCODE" }

    $resultDir = Join-Path $tools 'RISULTATI'
    $report = Get-ChildItem -Path $resultDir -Filter 'RISULTATO-DEV-SAMPLE-*.json' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $report) { throw 'USB launcher did not create a JSON result report.' }
    $html = Get-ChildItem -Path $resultDir -Filter 'RISULTATO-DEV-SAMPLE-*.html' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $html) { throw 'USB launcher did not create an HTML result report.' }

    $result = Get-Content -Raw $report.FullName | ConvertFrom-Json
    if ($result.technicalScore -ne 20 -or $result.questionsScore -ne 10 -or $result.total -ne 30) {
        throw "Unexpected end-to-end score: $($result | ConvertTo-Json -Compress)"
    }
    if ((Get-Content -Raw $html.FullName) -notmatch 'Totale: 30/30') { throw 'HTML report does not contain the expected total.' }

    & (Join-Path $tools 'grade-batch.ps1') -SearchRoot $tempRoot -OutputDirectory $batchOut
    $csv = Get-ChildItem -Path $batchOut -Filter 'RIEPILOGO-*.csv' | Select-Object -First 1
    if (-not $csv) { throw 'Batch grading did not create a CSV summary.' }
    $rows = @(Import-Csv $csv.FullName)
    if ($rows.Count -ne 1 -or [int]$rows[0].Total -ne 30) { throw 'Unexpected batch CSV result.' }

    Write-Host "USB operations end-to-end OK. JSON=$($report.FullName), HTML=$($html.FullName), CSV=$($csv.FullName)"
}
finally {
    Remove-Item -Recurse -Force $tempRoot -ErrorAction SilentlyContinue
    Remove-Item Env:EXAM_CI -ErrorAction SilentlyContinue
}
