$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$folders = @(Get-ChildItem $root -Directory | Where-Object { $_.Name -match '^\d{3}_' } | Sort-Object Name)
if($folders.Count -ne 12){throw "Attese 12 esercitazioni: trovate $($folders.Count)"}
foreach($folder in $folders){
    $grader=Join-Path $folder.FullName 'grader/grade.ps1'
    foreach($role in @('solution','candidate')){
        $project=Join-Path $folder.FullName $role
        $line=(& $grader -ExamRoot $project -Json | Select-Object -Last 1)
        if(-not $line){throw "Grader senza output: $($folder.Name) $role"}
        $result=$line | ConvertFrom-Json
        if($role -eq 'solution' -and $result.score -ne 20){throw "Soluzione $($folder.Name) != 20/20: $line"}
        if($role -eq 'candidate' -and $result.score -ge 20){throw "Skeleton $($folder.Name) non deve avere 20/20: $line"}
        Write-Host "$($folder.Name) $role = $($result.score)/20"
    }
}
Write-Host 'Tutte le 12 esercitazioni DEV hanno superato i test automatici.'
