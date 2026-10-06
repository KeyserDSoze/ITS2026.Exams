$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$tools = Join-Path $repoRoot 'tools'
$temp = Join-Path ([System.IO.Path]::GetTempPath()) ("its-private-grader-test-" + [guid]::NewGuid().ToString('N'))
$exam = Join-Path $temp 'student'
$private = Join-Path $temp 'private-graders'
$graderDir = Join-Path $private 'PRIVATE-SAMPLE'
$out = Join-Path $temp 'reports'
$dist = Join-Path $temp 'dist-private'

New-Item -ItemType Directory -Force -Path $exam, $graderDir | Out-Null
try {
    Set-Content -Path (Join-Path $exam '.exam-id') -Value 'PRIVATE-SAMPLE|TEST-TOKEN' -Encoding UTF8
    Set-Content -Path (Join-Path $exam 'domanda1.txt') -Value ('A' * 250) -Encoding UTF8
    Set-Content -Path (Join-Path $exam 'domanda2.txt') -Value ('B' * 250) -Encoding UTF8
    Set-Content -Path (Join-Path $exam 'README.md') -Value '# Private sample test' -Encoding UTF8

    $fakeGrader = @'
param([Parameter(Mandatory=$true)][string]$ExamRoot,[switch]$Json)
$result = [pscustomobject]@{
    exam='PRIVATE-SAMPLE'
    score=20
    maxScore=20
    checks=@([pscustomobject]@{name='privateSampleCheck';points=20;passed=$true})
}
if ($Json) { $result | ConvertTo-Json -Depth 5 -Compress } else { $result }
'@
    Set-Content -Path (Join-Path $graderDir 'grade.ps1') -Value $fakeGrader -Encoding UTF8

    $json = (& (Join-Path $tools 'grade-exam.ps1') -SearchRoot $exam -PrivateGraderRoot $private -ReportDirectory $out -Json | Select-Object -Last 1)
    $result = $json | ConvertFrom-Json
    if ($result.examId -ne 'PRIVATE-SAMPLE' -or $result.technicalScore -ne 20 -or $result.total -ne 30) {
        throw "Private grader extension failed: $json"
    }

    & (Join-Path $tools 'build-private-usb.ps1') -PrivateGraderRoot $private -OutputDirectory $dist
    $zip = Join-Path $dist 'USB-CORRETTORE-PRIVATE.zip'
    if (-not (Test-Path $zip)) { throw 'Private USB ZIP was not created.' }

    $expanded = Join-Path $temp 'expanded'
    Expand-Archive -Path $zip -DestinationPath $expanded
    if (-not (Test-Path (Join-Path $expanded 'private-graders/PRIVATE-SAMPLE/grade.ps1'))) { throw 'Private grader missing from private USB package.' }
    if (-not (Test-Path (Join-Path $expanded 'tools/CORREZIONE.cmd'))) { throw 'CORREZIONE.cmd missing from private USB package.' }

    Write-Host 'Private grader extension test OK.'
}
finally {
    Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue
}
