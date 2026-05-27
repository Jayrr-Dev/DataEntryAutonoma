#Requires -Version 5.1
<#
.SYNOPSIS
    Unblocks and starts DataEntryAutonoma.exe from the release or install folder.

.DESCRIPTION
    Downloaded zips get a Windows "Mark of the Web" block that can stop the exe from
    opening when double-clicked. This script clears that block, then launches the app.
#>

$ErrorActionPreference = "Stop"

$APP_ROOT = $PSScriptRoot
$EXE_PATH = Join-Path $APP_ROOT "DataEntryAutonoma.exe"

if (-not (Test-Path -LiteralPath $EXE_PATH)) {
    Write-Error "DataEntryAutonoma.exe not found in: $APP_ROOT"
}

foreach ($path in @(
        $EXE_PATH,
        (Join-Path $APP_ROOT "assets\dataEntryAutonoma.ico")
    )) {
    if (Test-Path -LiteralPath $path) {
        Unblock-File -LiteralPath $path -ErrorAction SilentlyContinue
    }
}

try {
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $EXE_PATH
    $startInfo.WorkingDirectory = $APP_ROOT
    $startInfo.UseShellExecute = $true
    [System.Diagnostics.Process]::Start($startInfo) | Out-Null
} catch {
    Write-Host ""
    Write-Host "Could not start the app automatically."
    Write-Host "If Windows SmartScreen appeared, choose More info, then Run anyway."
    Write-Host ""
    Write-Host "Or right-click DataEntryAutonoma.exe -> Properties -> check Unblock -> OK, then open again."
    Write-Host ""
    Read-Host "Press Enter to close"
    exit 1
}
