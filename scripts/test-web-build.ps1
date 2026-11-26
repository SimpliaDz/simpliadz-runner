[CmdletBinding()]
param(
    [int]$Port = 4300,
    [switch]$NoBuild
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Import-SimpliaWearConfig.ps1')

$outputRoot = Join-Path $WebRoot 'dist\simplia-web\browser'
$serverScript = Join-Path $PSScriptRoot 'serve-localized-web.mjs'
$apiTarget = Get-ApiUrl -Target Browser

Push-Location $WebRoot
try {
    if (-not $NoBuild) {
        Write-Host 'Building localized production frontend (en-US, fr, ar)...'
        & yarn build
        if ($LASTEXITCODE -ne 0) { throw 'Frontend production build failed.' }
    }

    if (-not (Test-Path -LiteralPath (Join-Path $outputRoot 'en-US\index.html')) -or
        -not (Test-Path -LiteralPath (Join-Path $outputRoot 'fr\index.html')) -or
        -not (Test-Path -LiteralPath (Join-Path $outputRoot 'ar\index.html'))) {
        throw "Localized build output is incomplete: $outputRoot. Run without -NoBuild."
    }

    Write-Host "Serving the production build on http://localhost:$Port. /api proxies to $apiTarget. Press Ctrl+C to stop."
    & node $serverScript --root $outputRoot --api-target $apiTarget --port $Port
    if ($LASTEXITCODE -ne 0) { throw 'Localized frontend preview server exited with an error.' }
}
finally {
    Pop-Location
}
