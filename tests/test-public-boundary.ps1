$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Push-Location $repoRoot
try {
    $tracked = @(& git ls-files)
    if ($LASTEXITCODE -ne 0) { throw 'git ls-files failed.' }

    $forbiddenPrefixes = @('private-graders/', 'dist-private/')
    foreach ($prefix in $forbiddenPrefixes) {
        $hit = @($tracked | Where-Object { $_ -like "$prefix*" })
        if ($hit.Count -gt 0) { throw "Private path is tracked: $($hit -join ', ')" }
    }

    $forbiddenExact = @('src/dev/exams.json', 'src/infra/exams.json', 'docs/exams.md')
    foreach ($path in $forbiddenExact) {
        if ($tracked -contains $path) { throw "Real-exam manifest/document must not be public: $path" }
    }

    $markers = @($tracked | Where-Object { $_ -like '*/.exam-id' -or $_ -eq '.exam-id' })
    foreach ($marker in $markers) {
        $value = (Get-Content -Raw $marker).Trim()
        $id = $value.Split('|')[0]
        if ($id -notmatch '-SAMPLE$') {
            throw "Non-sample exam marker is tracked publicly: $marker => $id"
        }
    }

    Write-Host 'Public repository boundary OK.'
}
finally {
    Pop-Location
}
