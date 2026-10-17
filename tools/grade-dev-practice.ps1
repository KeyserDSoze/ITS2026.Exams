param(
    [Parameter(Mandatory=$true)][string]$ExamRoot,
    [Parameter(Mandatory=$true)][string]$ExamId,
    [Parameter(Mandatory=$true)][string]$ApiPath,
    [Parameter(Mandatory=$true)][string]$JsonProperty,
    [string]$ExtraProperty = '',
    [ValidateSet('none','delete','patch','patch+delete','put+delete')][string]$Mutation = 'none',
    [switch]$RequireUi,
    [switch]$RequireFilter,
    [switch]$Json
)
$ErrorActionPreference = 'Stop'
$checks = [System.Collections.Generic.List[object]]::new()
$score = 0
function Add-Check([string]$Name,[int]$Points,[bool]$Passed,[string]$Detail = '') {
    if ($Passed) { $script:score += $Points }
    $checks.Add([pscustomobject]@{ name=$Name; points=$Points; passed=$Passed; detail=$Detail })
}
function Request([string]$Method,[string]$Url,[object]$Payload=$null) {
    $args = @{ Uri=$Url; Method=$Method; UseBasicParsing=$true; TimeoutSec=5 }
    if ($null -ne $Payload) {
        $args.ContentType = 'application/json'
        $args.Body = ($Payload | ConvertTo-Json -Compress)
    }
    Invoke-WebRequest @args
}
function CheckHttpError([string]$Method,[string]$Url,[object]$Payload,[int]$StatusCode) {
    try { $null=Request $Method $Url $Payload; return $false }
    catch { return ($null -ne $_.Exception.Response -and [int]$_.Exception.Response.StatusCode -eq $StatusCode) }
}
$port=Get-Random -Minimum 51000 -Maximum 59000
$base="http://127.0.0.1:$port"
$process=$null
$started=$false
try {
    if (-not (Test-Path (Join-Path $ExamRoot 'ExamApp.csproj'))) { throw 'Progetto .csproj mancante.' }
    $process=Start-Process -FilePath dotnet -ArgumentList @('run','--no-launch-profile','--','--urls',$base) -WorkingDirectory $ExamRoot -PassThru
    for($i=0;$i -lt 60;$i++){
        Start-Sleep -Milliseconds 500
        try { $null=Request 'GET' "$base$ApiPath"; $started=$true; break }
        catch { if($process.HasExited){break} }
    }
    Add-Check 'Applicazione avviabile' 2 $started
    if(-not $started){throw 'Applicazione non raggiungibile'}
    $getOk=$false
    try {
        $response=Request 'GET' "$base$ApiPath"
        $parsed=$response.Content | ConvertFrom-Json
        $getOk=($response.StatusCode -eq 200) -and $response.Content.TrimStart().StartsWith('[') -and
               ($null -ne $parsed) -and ($response.Content -match ('"' + [regex]::Escape($JsonProperty) + '"\s*:'))
    } catch {}
    Add-Check 'GET restituisce array JSON' 2 $getOk

    $name="CI-$([guid]::NewGuid().ToString('N').Substring(0,8))"
    $body=@{ $JsonProperty=$name }
    if($ExtraProperty){ $body[$ExtraProperty]='valore-aggiuntivo' }
    $posted=$null; $postOk=$false; $newId=-1
    try {
        $resp=Request 'POST' "$base$ApiPath" $body
        $posted=$resp.Content | ConvertFrom-Json
        $newId=[int]$posted.id
        $postOk=($resp.StatusCode -eq 201) -and ($newId -gt 0) -and
                ($posted.$JsonProperty -eq $name) -and
                ((-not $ExtraProperty) -or ($posted.$ExtraProperty -eq $body[$ExtraProperty]))
    } catch {}
    Add-Check 'POST 201 con oggetto JSON' 3 $postOk

    $invalid=$true
    foreach($value in @('', '   ')){
        $badBody=@{ $JsonProperty=$value }
        if($ExtraProperty){$badBody[$ExtraProperty]='valore-aggiuntivo'}
        if(-not (CheckHttpError 'POST' "$base$ApiPath" $badBody 400)) { $invalid=$false }
    }
    if($ExtraProperty){
        $badBody=@{ $JsonProperty=$name; $ExtraProperty='   ' }
        if(-not (CheckHttpError 'POST' "$base$ApiPath" $badBody 400)){ $invalid=$false }
    }
    Add-Check 'Input vuoto/spazi = HTTP 400' 2 $invalid

    $visible=$false
    if($postOk){
        try {
            $after=(Request 'GET' "$base$ApiPath").Content | ConvertFrom-Json
            $visible=@($after | Where-Object { $_.$JsonProperty -eq $name }).Count -gt 0
        } catch {}
    }
    Add-Check 'POST visibile nel GET successivo' 2 $visible

    $htmlOk=$false
    try {
        $page=Request 'GET' "$base/index.html"
        $htmlOk=($page.StatusCode -eq 200) -and $page.Content.Contains('<html')
    } catch {}
    Add-Check 'Frontend HTML raggiungibile' 2 $htmlOk

    $jsPath=Join-Path $ExamRoot 'wwwroot/app.js'
    $js=''
    if(Test-Path $jsPath){$js=Get-Content -Raw $jsPath}
    $postPattern='method\s*:\s*[''"]POST'
    $jsOk=($js -match 'fetch\s*\(') -and $js.Contains($ApiPath) -and
          ($js -match $postPattern) -and ($js -match 'JSON\.stringify') -and ($js -match 'response\.json')
    Add-Check 'Frontend JavaScript GET/POST JSON' 2 $jsOk

    $mutationOk=$false
    if($Mutation -eq 'none'){
        $mutationOk=($js -match 'textContent') -and ($js -match 'appendChild') -and
                    ($js -match 'loadEntries')
    }elseif($postOk){
        $url="$base$ApiPath/$newId"
        $mutationOk=$true
        if($Mutation -like '*patch*'){
            try {
                $change=Request 'PATCH' $url @{state=$true}
                $patched=$change.Content | ConvertFrom-Json
                $newList=(Request 'GET' "$base$ApiPath").Content | ConvertFrom-Json
                $found=@($newList | Where-Object {$_.id -eq $newId})
                $stateProp=if($found.Count){@($found[0].PSObject.Properties | Where-Object { $_.Name -notin @('id',$JsonProperty,$ExtraProperty) -and $_.Value -is [bool] }) | Select-Object -First 1}else{$null}
                $mutationOk=($change.StatusCode -eq 200) -and $found.Count -eq 1 -and
                            ($null -ne $stateProp) -and ($stateProp.Value -eq $true)
            } catch {$mutationOk=$false}
        }
        if($Mutation -like '*put*'){
            try {
                $changedText="EDIT-$name"
                $update=Request 'PUT' $url @{ $JsonProperty=$changedText }
                $changed=$update.Content | ConvertFrom-Json
                $newList=(Request 'GET' "$base$ApiPath").Content | ConvertFrom-Json
                $found=@($newList | Where-Object {$_.id -eq $newId -and $_.$JsonProperty -eq $changedText})
                $mutationOk=$mutationOk -and ($update.StatusCode -eq 200) -and
                            ($changed.$JsonProperty -eq $changedText) -and $found.Count -eq 1
            } catch {$mutationOk=$false}
        }
        if($Mutation -like '*delete*'){
            try {
                $del=Request 'DELETE' $url
                $newList=(Request 'GET' "$base$ApiPath").Content | ConvertFrom-Json
                $stillThere=@($newList | Where-Object {$_.id -eq $newId}).Count -gt 0
                $missing=CheckHttpError 'DELETE' $url $null 404
                $mutationOk=$mutationOk -and ($del.StatusCode -eq 204) -and (-not $stillThere) -and $missing
            } catch {$mutationOk=$false}
        }
    }
    Add-Check 'Funzione avanzata o rendering DOM' 3 $mutationOk

    $uiOk=(Test-Path (Join-Path $ExamRoot 'wwwroot/index.html')) -and
          (Test-Path (Join-Path $ExamRoot 'wwwroot/style.css'))
    if($uiOk -and $RequireUi){
        $html=Get-Content -Raw (Join-Path $ExamRoot 'wwwroot/index.html')
        $css=Get-Content -Raw (Join-Path $ExamRoot 'wwwroot/style.css')
        $uiOk=($html -match '<p\s+id="helper"') -and ($html -match 'class="helper"') -and
              ($css -match '(?m)^\.helper\s*\{') -and ($css -match '(?m)^\.entry-card\s*\{')
        if($RequireFilter){ $uiOk=$uiOk -and ($html -match 'id="search"') -and ($js -match '#search') }
    }
    Add-Check 'Interventi HTML e CSS' 2 $uiOk
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
