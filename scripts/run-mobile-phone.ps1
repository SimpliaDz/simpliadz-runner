[CmdletBinding()]
param(
    [string]$DeviceId
)

. (Join-Path $PSScriptRoot 'Import-SimpliaDzConfig.ps1')

if ([string]::IsNullOrWhiteSpace($DeviceId)) { $DeviceId = $LocalConfig.mobile.phoneDeviceId }
$apiUrl = Get-ApiUrl -Target Phone
Push-Location $MobileRoot
try {
    $arguments = @('run', "--dart-define=API_BASE_URL=$apiUrl")
    if (-not [string]::IsNullOrWhiteSpace($DeviceId)) { $arguments += @('-d', $DeviceId) }
    Write-Host "Running mobile app against $apiUrl."
    & flutter @arguments
}
finally { Pop-Location }
