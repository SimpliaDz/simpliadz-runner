[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$TenantId,
    [switch]$SeedDemo
)

. (Join-Path $PSScriptRoot 'Import-SimpliaDzConfig.ps1')

Push-Location $PlatformRoot
try {
    $arguments = @('run', '--project', 'src\SimpliaDz.DatabaseMigrator', '--', '--tenant', $TenantId)
    if ($SeedDemo) { $arguments += '--seed-demo' }
    & dotnet @arguments
}
finally { Pop-Location }
