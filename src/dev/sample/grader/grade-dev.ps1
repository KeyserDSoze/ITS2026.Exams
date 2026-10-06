param(
    [Parameter(Mandatory=$true)][string]$ExamRoot,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
$checks = [System.Collections.Generic.List[object]]::new()
$score = 0

function Add-Check([string]$Name, [int]$Points, [bool]$Passed, [string]$Detail = '') {
    if ($Passed) { $script:score += $Points }
    $checks.Add([pscustomobject]@{ name=$Name; points=$Points; passed=$Passed; detail=$Detail })
}

$port = Get-Random -Minimum 51000 -Maximum 59000
$baseUrl = "http://127.0.0.1:$port"
$process = $null
$started = $false

try {
    $process = Start-Process -FilePath 'dotnet' -ArgumentList @('run','--no-launch-profile','--','--urls',$baseUrl) -WorkingDirectory $ExamRoot -PassThru

    for ($i = 0; $i -lt 40; $i++) {
        Start-Sleep -Milliseconds 500
        try {
            $null = Invoke-WebRequest -Uri "$baseUrl/api/items" -UseBasicParsing -TimeoutSec 2
            $started = $true
            break
        } catch {
            if ($process.HasExited) { break }
        }
    }

    Add-Check 'Applicazione avviabile' 2 $started
    if (-not $started) { throw 'Applicazione non raggiungibile.' }

    try {
        $get = Invoke-RestMethod -Uri "$baseUrl/api/items" -Method Get -TimeoutSec 5
        Add-Check 'GET /api/items' 3 ($null -ne $get)
    } catch { Add-Check 'GET /api/items' 3 $false $_.Exception.Message }

    $createdName = "CI-item-$([guid]::NewGuid().ToString('N').Substring(0,8))"
    $postOk = $false
    try {
        $response = Invoke-WebRequest -Uri "$baseUrl/api/items" -Method Post -ContentType 'application/json' -Body (@{name=$createdName} | ConvertTo-Json -Compress) -UseBasicParsing -TimeoutSec 5
        $postOk = ($response.StatusCode -eq 201)
        Add-Check 'POST valido restituisce 201' 4 $postOk
    } catch { Add-Check 'POST valido restituisce 201' 4 $false $_.Exception.Message }

    $badRequest = $false
    try {
        $null = Invoke-WebRequest -Uri "$baseUrl/api/items" -Method Post -ContentType 'application/json' -Body '{"name":""}' -UseBasicParsing -TimeoutSec 5
    } catch {
        if ($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -eq 400) { $badRequest = $true }
    }
    Add-Check 'Input vuoto restituisce 400' 3 $badRequest

    $persisted = $false
    if ($postOk) {
        try {
            $after = Invoke-RestMethod -Uri "$baseUrl/api/items" -Method Get -TimeoutSec 5
            $persisted = @($after | Where-Object { $_.name -eq $createdName }).Count -gt 0
        } catch {}
    }
    Add-Check 'Elemento inserito presente nel GET successivo' 3 $persisted

    $indexOk = $false
    try {
        $home = Invoke-WebRequest -Uri "$baseUrl/" -UseBasicParsing -TimeoutSec 5
        $indexOk = $home.StatusCode -eq 200 -and $home.Content -match '<html'
    } catch {}
    Add-Check 'Frontend servito' 2 $indexOk

    $jsPath = Join-Path $ExamRoot 'wwwroot/app.js'
    $jsOk = $false
    if (Test-Path $jsPath) {
        $js = Get-Content -Raw $jsPath
        $postPattern = 'method\s*:\s*[''\"]POST'
        $jsOk = ($js -match 'fetch\s*\(') -and ($js -match '/api/items') -and ($js -match $postPattern)
    }
    Add-Check 'JavaScript usa GET/POST API' 3 $jsOk
}
catch {
    if (-not $started -and $checks.Count -eq 0) { Add-Check 'Applicazione avviabile' 2 $false $_.Exception.Message }
}
finally {
    if ($process -and -not $process.HasExited) { Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue }
}

$result = [pscustomobject]@{ exam='DEV-SAMPLE'; score=$score; maxScore=20; checks=$checks }
if ($Json) { $result | ConvertTo-Json -Depth 5 -Compress }
else {
    foreach ($c in $checks) { Write-Host "$(if($c.passed){'PASS'}else{'FAIL'}) [$($c.points)] $($c.name) $($c.detail)" }
    Write-Host "PUNTEGGIO TECNICO: $score/20"
}
