[CmdletBinding()]
param(
    [string]$TenantId
)

. (Join-Path $PSScriptRoot 'Import-SimpliaDzConfig.ps1')

$port = $LocalConfig.api.port
$listenHost = $LocalConfig.api.listenHost
if ([string]::IsNullOrWhiteSpace($listenHost)) {
    throw 'api.listenHost must be configured in config\\local.json.'
}

$env:ASPNETCORE_ENVIRONMENT = 'Development'
$env:ASPNETCORE_URLS = "http://${listenHost}:$port"

if ([string]::IsNullOrWhiteSpace($TenantId)) {
    $TenantId = $LocalConfig.api.activeTenantId
}
if (-not [string]::IsNullOrWhiteSpace($TenantId)) {
    $env:Tenancy__ActiveTenantId = $TenantId
}

Write-Host "Starting API on $env:ASPNETCORE_URLS for tenant '$($env:Tenancy__ActiveTenantId)'."
Push-Location $PlatformRoot
try {
    dotnet run --project 'src\SimpliaDz.Api' --no-launch-profile
}
finally {
    Pop-Location
}
