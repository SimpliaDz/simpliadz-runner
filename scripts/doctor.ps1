[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot 'Import-SimpliaDzConfig.ps1')

Write-Host 'Simplia local-development configuration'
Write-Host "  Workspace: $WorkspaceRoot"
Write-Host "  API bind:  http://$($LocalConfig.api.listenHost):$($LocalConfig.api.port)"
Write-Host "  Tenant:    $($LocalConfig.api.activeTenantId)"
$catalogPath = Get-TenantCatalogPath
Assert-TenantConfigured -TenantId $LocalConfig.api.activeTenantId
Write-Host "  Catalog:   $catalogPath"
Write-Host "  Browser:   $(Get-ApiUrl -Target Browser)"
Write-Host "  Emulator:  $(Get-ApiUrl -Target Emulator)"
Write-Host "  Phone:     $(Get-ApiUrl -Target Phone)"
foreach ($command in @('dotnet', 'node', 'yarn', 'flutter')) {
    Write-Host "  $command available: $($null -ne (Get-Command $command -ErrorAction SilentlyContinue))"
}
foreach ($path in @($MobileRoot, $WebRoot, $PlatformRoot)) {
    Write-Host "  $(Split-Path -Leaf $path) found: $(Test-Path -LiteralPath $path)"
}
