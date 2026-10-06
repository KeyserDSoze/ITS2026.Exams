$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$tools = Join-Path $repoRoot 'tools'
$source = Join-Path $repoRoot 'src/dev/sample/solution'
$tempRoot = Join-Path 'C:\' ("ITS-EXAM-E2E-" + [guid]::NewGuid().ToString('N'))
$examRoot = Join-Path $tempRoot 'random\nested\student-project'

New-Item -ItemType Directory -Force -Path $examRoot | Out-Null
try {
    Copy-Item -Path (Join-Path $source '*') -Destination $examRoot -Recurse -Force
    Set-Content -Path (Join-Path $examRoot '.exam-id') -Value 'DEV-SAMPLE|USB-E2E-TOKEN' -Encoding UTF8
    Set-Content -Path (Join-Path $examRoot 'domanda1.txt') -Value ('Risposta di test sufficientemente lunga. ' * 10) -Encoding UTF8
    Set-Content -Path (Join-Path $examRoot 'domanda2.txt') -Value ('Seconda risposta di test sufficientemente lunga. ' * 10) -Encoding UTF8

    $env:EXAM_CI = '1'
    & cmd.exe /c "`"$tools\CORREZIONE.cmd`" -SearchRoot `"$tempRoot`" -ExamId DEV-SAMPLE"
    if ($LASTEXITCODE -ne 0) { throw "CORREZIONE.cmd failed with exit code $LASTEXITCODE" }

    $report = Get-ChildItem -Path (Join-Path $tools 'RISULTATI') -Filter 'RISULTATO-DEV-SAMPLE-*.json' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $report) { throw 'USB launcher did not create a result report.' }
    $result = Get-Content -Raw $report.FullName | ConvertFrom-Json
    if ($result.technicalScore -ne 20 -or $result.questionsScore -ne 10 -or $result.total -ne 30) {
        throw "Unexpected end-to-end score: $($result | ConvertTo-Json -Compress)"
    }
    Write-Host "USB end-to-end OK. Report: $($report.FullName)"
}
finally {
    Remove-Item -Recurse -Force $tempRoot -ErrorAction SilentlyContinue
    Remove-Item Env:EXAM_CI -ErrorAction SilentlyContinue
}
