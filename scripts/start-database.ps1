[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot 'Import-SimpliaWearConfig.ps1')

Push-Location $PlatformRoot
try {
    docker compose up -d
    docker compose ps
}
finally { Pop-Location }
