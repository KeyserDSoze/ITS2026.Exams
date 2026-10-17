param(
  [Parameter(Mandatory=$true)][string]$ExamRoot,
  [Parameter(Mandatory=$true)][string]$ExamId,
  [Parameter(Mandatory=$true)][string]$ApiPath,
  [Parameter(Mandatory=$true)][string]$JsonProperty,
  [switch]$Json
)
$ErrorActionPreference = 'Stop'
$checks = [System.Collections.Generic.List[object]]::new()
$score = 0
function Add-Check([string]$Name,[int]$Points,[bool]$Passed,[string]$Detail='') {
  if($Passed){$script:score += $Points}
  $checks.Add([pscustomobject]@{name=$Name;points=$Points;passed=$Passed;detail=$Detail})
}
$port = Get-Random -Minimum 51000 -Maximum 59000
$baseUrl = "http://127.0.0.1:$port"
$process = $null
$started = $false
try {
  if(-not (Test-Path (Join-Path $ExamRoot 'ExamApp.csproj'))){throw 'ExamApp.csproj mancante'}
  $process = Start-Process -FilePath 'dotnet' -ArgumentList @('run','--no-launch-profile','--','--urls',$baseUrl) -WorkingDirectory $ExamRoot -PassThru
  for($i=0; $i -lt 90; $i++){
    Start-Sleep -Milliseconds 500
    try {$null=Invoke-WebRequest -Uri "$baseUrl$ApiPath" -UseBasicParsing -TimeoutSec 2; $started=$true; break}
    catch {if($process.HasExited){break}}
  }
  Add-Check 'Applicazione avviabile' 2 $started
  if(-not $started){throw 'Applicazione non raggiungibile'}
  try {
    $initial = @(Invoke-RestMethod -Uri "$baseUrl$ApiPath" -Method Get -TimeoutSec 5)
    $getOk = @($initial | Where-Object {$_.PSObject.Properties.Name -contains $JsonProperty}).Count -gt 0
    Add-Check 'GET con JSON' 3 $getOk
  } catch {Add-Check 'GET con JSON' 3 $false $_.Exception.Message}
  $newValue = "CI-$([guid]::NewGuid().ToString('N').Substring(0,8))"
  $postOk = $false
  try {
    $payload = @{$JsonProperty=$newValue} | ConvertTo-Json -Compress
    $response = Invoke-WebRequest -Uri "$baseUrl$ApiPath" -Method Post -ContentType 'application/json' -Body $payload -UseBasicParsing -TimeoutSec 5
    $created = $response.Content | ConvertFrom-Json
    $postOk = ($response.StatusCode -eq 201) -and ($null -ne $created.id) -and ($created.($JsonProperty) -eq $newValue)
    Add-Check 'POST 201 e JSON' 4 $postOk
  } catch {Add-Check 'POST 201 e JSON' 4 $false $_.Exception.Message}
  $invalidOk = $true
  foreach($value in @('','   ')){
    $rejected = $false
    try {
      $body=@{$JsonProperty=$value} | ConvertTo-Json -Compress
      $null=Invoke-WebRequest -Uri "$baseUrl$ApiPath" -Method Post -ContentType 'application/json' -Body $body -UseBasicParsing -TimeoutSec 5
    } catch {if($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -eq 400){$rejected=$true}}
    if(-not $rejected){$invalidOk=$false}
  }
  Add-Check 'Input vuoto/spazi = 400' 3 $invalidOk
  $persisted=$false
  if($postOk){
    try {
      $after=@(Invoke-RestMethod -Uri "$baseUrl$ApiPath" -Method Get -TimeoutSec 5)
      $persisted=@($after | Where-Object {$_.$JsonProperty -eq $newValue}).Count -gt 0
    } catch {}
  }
  Add-Check 'Nuovo elemento restituito nel GET' 3 $persisted
  $frontend=$false
  try {$page=Invoke-WebRequest -Uri "$baseUrl/index.html" -UseBasicParsing -TimeoutSec 5;$frontend=($page.StatusCode -eq 200) -and ($page.Content -match '<html')}
  catch{}
  Add-Check 'Frontend raggiungibile' 2 $frontend
  $jsPath=Join-Path $ExamRoot 'wwwroot/app.js'
  $jsOk=$false
  if(Test-Path $jsPath){
    $js=Get-Content -Raw $jsPath
    $postPattern='method\s*:\s*[''"]POST'
    $jsOk=($js -match 'fetch\s*\(') -and $js.Contains($ApiPath) -and ($js -match $postPattern) -and ($js -match 'JSON\.stringify') -and ($js -match 'response\.json')
  }
  Add-Check 'JavaScript con GET/POST JSON' 3 $jsOk
} catch {
  if($checks.Count -eq 0){Add-Check 'Applicazione avviabile' 2 $false $_.Exception.Message}
} finally {
  if($process -and -not $process.HasExited){Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue}
}
$result=[pscustomobject]@{exam=$ExamId;score=$score;maxScore=20;checks=$checks}
if($Json){$result | ConvertTo-Json -Depth 5 -Compress}
else {
  foreach($c in $checks){$status=if($c.passed){'PASS'}else{'FAIL'};Write-Host "$status [$($c.points)] $($c.name) $($c.detail)"}
  Write-Host "PUNTEGGIO TECNICO: $score/20"
}
