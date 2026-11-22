[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:DevRoot = Split-Path -Parent $PSScriptRoot
$script:WorkspaceRoot = Split-Path -Parent $script:DevRoot
$script:MobileRoot = Join-Path $script:WorkspaceRoot 'simpliadz-mobile'
$script:WebRoot = Join-Path $script:WorkspaceRoot 'simpliadz-web'
$script:PlatformRoot = Join-Path $script:WorkspaceRoot 'simpliadz-platform'

$localConfigPath = Join-Path $script:DevRoot 'config\local.json'
if (-not (Test-Path -LiteralPath $localConfigPath)) {
    throw "Missing $localConfigPath. Copy config\\local.example.json to config\\local.json and update it for this machine."
}

$script:LocalConfig = Get-Content -LiteralPath $localConfigPath -Raw | ConvertFrom-Json

function Get-TenantCatalogPath {
    $configuredPath = $script:LocalConfig.api.tenantCatalogPath
    if ([string]::IsNullOrWhiteSpace($configuredPath)) {
        throw 'Set api.tenantCatalogPath in config/local.json.'
    }

    $path = if ([System.IO.Path]::IsPathRooted($configuredPath)) {
        $configuredPath
    } else {
        Join-Path $script:DevRoot $configuredPath
    }
    $path = [System.IO.Path]::GetFullPath($path)
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Tenant catalog not found: $path. Copy config/tenants.example.json to config/tenants.local.json and configure it."
    }
    return $path
}

function Assert-TenantConfigured {
    param([Parameter(Mandatory)][string]$TenantId)

    $catalogPath = Get-TenantCatalogPath
    $catalog = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
    if ($null -eq $catalog.Tenancy -or $null -eq $catalog.Tenancy.Tenants) {
        throw "Tenant catalog must define Tenancy.Tenants: $catalogPath."
    }
    $entry = $catalog.Tenancy.Tenants.PSObject.Properties[$TenantId]
    if ($null -eq $entry) { throw "Tenant '$TenantId' is not defined in $catalogPath." }
    $tenant = $entry.Value
    if ([string]::IsNullOrWhiteSpace($tenant.Name)) { throw "Tenant '$TenantId' needs a name." }
    if ([string]::IsNullOrWhiteSpace($tenant.ConnectionString) -or
        $tenant.ConnectionString.Contains('CHANGE_ME')) {
        throw "Tenant '$TenantId' needs a configured connection string in $catalogPath."
    }
}

function Get-ApiUrl {
    param([Parameter(Mandatory)][ValidateSet('Browser', 'Phone', 'Emulator')] [string]$Target)

    $port = $script:LocalConfig.api.port
    $apiHost = switch ($Target) {
        'Browser' { $script:LocalConfig.api.browserHost }
        'Phone' { $script:LocalConfig.api.phoneHost }
        'Emulator' { '10.0.2.2' }
    }

    if ([string]::IsNullOrWhiteSpace($apiHost)) {
        throw "No API host is configured for the $Target target in config\\local.json."
    }

    return "http://${apiHost}:$port"
}
