$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
function Check([string]$Project,[string]$Grader,[bool]$ExpectFull){
  $line=(& $Grader -ExamRoot $Project -Json | Select-Object -Last 1)
  $result=$line | ConvertFrom-Json
  if($ExpectFull -and $result.score -ne 20){throw "Soluzione guidata != 20: $line"}
  if(-not $ExpectFull -and $result.score -ge 20){throw "Skeleton incompleto ha 20: $line"}
  Write-Host "$($result.exam) - $($result.score)/20"
}
Check (Join-Path $root 'books/solution') (Join-Path $root 'books/grader/grade.ps1') $true
Check (Join-Path $root 'books/candidate') (Join-Path $root 'books/grader/grade.ps1') $false
Check (Join-Path $root 'tickets/candidate') (Join-Path $root 'tickets/grader/grade.ps1') $false
