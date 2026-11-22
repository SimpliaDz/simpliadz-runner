[CmdletBinding()]
param(
    [ValidateSet('en', 'fr', 'ar')]
    [string]$Language
)

. (Join-Path $PSScriptRoot 'Import-SimpliaDzConfig.ps1')

$proxyTarget = Get-ApiUrl -Target Browser
$proxyPath = Join-Path $WebRoot 'proxy.local.conf.json'
$proxy = @{ '/api' = @{ target = $proxyTarget; secure = $false; changeOrigin = $true; pathRewrite = @{ '^/api' = '' } } }
$proxy | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $proxyPath -Encoding utf8

if ([string]::IsNullOrWhiteSpace($Language)) {
    Write-Host 'Choose the frontend language:'
    Write-Host '  [1] English'
    Write-Host '  [2] Français'
    Write-Host '  [3] العربية'
    $choice = Read-Host 'Choice (1-3, default 1)'
    $Language = switch ($choice) {
        '2' { 'fr' }
        '3' { 'ar' }
        default { 'en' }
    }
}

$scriptName = switch ($Language) {
    'fr' { 'start:fr' }
    'ar' { 'start:ar' }
    default { 'start' }
}

Write-Host "Starting web app in '$Language' on port $($LocalConfig.web.port); /api proxies to $proxyTarget."
Push-Location $WebRoot
try {
    & yarn $scriptName -- --port $LocalConfig.web.port --proxy-config proxy.local.conf.json
}
finally {
    Pop-Location
}
