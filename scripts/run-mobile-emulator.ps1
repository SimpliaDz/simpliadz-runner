[CmdletBinding()]
param(
    [string]$DeviceId
)

. (Join-Path $PSScriptRoot 'Import-SimpliaDzConfig.ps1')

if ([string]::IsNullOrWhiteSpace($DeviceId)) { $DeviceId = $LocalConfig.mobile.emulatorDeviceId }
$apiUrl = Get-ApiUrl -Target Emulator
Push-Location $MobileRoot
try {
    $arguments = @('run', "--dart-define=API_BASE_URL=$apiUrl")
    if (-not [string]::IsNullOrWhiteSpace($DeviceId)) { $arguments += @('-d', $DeviceId) }
    Write-Host "Running mobile app against $apiUrl."
    & flutter @arguments
}
finally { Pop-Location }
