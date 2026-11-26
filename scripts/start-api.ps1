[CmdletBinding()]
param(
    [string]$TenantId
)

. (Join-Path $PSScriptRoot 'Import-SimpliaWearConfig.ps1')

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
if ([string]::IsNullOrWhiteSpace($TenantId)) { throw 'Set api.activeTenantId or pass -TenantId.' }
Assert-TenantConfigured -TenantId $TenantId
$env:Tenancy__ActiveTenantId = $TenantId
$env:SIMPLIAWEAR_TENANTS_FILE = Get-TenantCatalogPath

Write-Host "Starting API on $env:ASPNETCORE_URLS for tenant '$($env:Tenancy__ActiveTenantId)'."
Push-Location $PlatformRoot
try {
    dotnet run --project 'src\SimpliaWear.Api' --no-launch-profile
    if ($LASTEXITCODE -ne 0) { throw "API exited with code $LASTEXITCODE." }
}
finally {
    Pop-Location
}
