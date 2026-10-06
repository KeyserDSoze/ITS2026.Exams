$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sample = Split-Path -Parent $here
$grader = Join-Path $sample 'grader/grade-infra.ps1'
$candidate = Join-Path $sample 'candidate'
$passFixture = Join-Path $here 'fixtures/pass.json'

$passJson = (& $grader -ExamRoot $candidate -StateFile $passFixture -Json | Select-Object -Last 1)
$pass = $passJson | ConvertFrom-Json
if ($pass.score -ne 20) { throw "Passing infra fixture must score 20/20. Result: $passJson" }

$weights = [ordered]@{
    iisInstalled=2; siteNameOk=2; pathOk=2; portOk=2; siteResponds=3;
    firewallOk=2; userExists=2; folderExists=1; modifyPermission=2; taskExists=2
}
$baseState = Get-Content -Raw $passFixture | ConvertFrom-Json
$tempFiles = @()
try {
    foreach ($name in $weights.Keys) {
        $state = $baseState | ConvertTo-Json -Depth 5 | ConvertFrom-Json
        $state.$name = $false
        $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) ("infra-$name-$([guid]::NewGuid().ToString('N')).json")
        $tempFiles += $tempFile
        $state | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 $tempFile
        $json = (& $grader -ExamRoot $candidate -StateFile $tempFile -Json | Select-Object -Last 1)
        $result = $json | ConvertFrom-Json
        $expected = 20 - [int]$weights[$name]
        if ($result.score -ne $expected) {
            throw "Disabling $name should score $expected/20, got $($result.score). Result: $json"
        }
    }
}
finally {
    $tempFiles | ForEach-Object { Remove-Item $_ -Force -ErrorAction SilentlyContinue }
}

Write-Host 'INFRA simulated grader OK: 20/20 reference and all individual negative cases verified.'
