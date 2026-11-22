[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$TenantId,
    [switch]$SeedDemo
)

. (Join-Path $PSScriptRoot 'Import-SimpliaDzConfig.ps1')

Assert-TenantConfigured -TenantId $TenantId
$env:SIMPLIADZ_TENANTS_FILE = Get-TenantCatalogPath

Push-Location $PlatformRoot
try {
    $arguments = @('run', '--project', 'src\SimpliaDz.DatabaseMigrator', '--', '--tenant', $TenantId)
    if ($SeedDemo) { $arguments += '--seed-demo' }
    & dotnet @arguments
    if ($LASTEXITCODE -ne 0) { throw "Migrator exited with code $LASTEXITCODE." }
}
finally { Pop-Location }
