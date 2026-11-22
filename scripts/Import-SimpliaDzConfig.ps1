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
