[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$TenantId,
    [switch]$SeedDemo
)

. (Join-Path $PSScriptRoot 'Import-SimpliaWearConfig.ps1')

Assert-TenantConfigured -TenantId $TenantId
$env:SIMPLIAWEAR_TENANTS_FILE = Get-TenantCatalogPath

Push-Location $PlatformRoot
try {
    $arguments = @('run', '--project', 'src\SimpliaWear.DatabaseMigrator', '--', '--tenant', $TenantId)
    if ($SeedDemo) { $arguments += '--seed-demo' }
    & dotnet @arguments
    if ($LASTEXITCODE -ne 0) { throw "Migrator exited with code $LASTEXITCODE." }
}
finally { Pop-Location }
