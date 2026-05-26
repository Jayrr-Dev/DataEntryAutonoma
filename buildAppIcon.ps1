#Requires -Version 5.1
<#
.SYNOPSIS
    Builds assets\dataEntryAutonoma.ico from assets\dataEntryAutonoma.svg.
#>

$ErrorActionPreference = "Stop"

$PROJECT_ROOT = $PSScriptRoot
$ASSETS_DIR = Join-Path $PROJECT_ROOT "assets"
$SVG_FILE = Join-Path $ASSETS_DIR "dataEntryAutonoma.svg"
$ICO_FILE = Join-Path $ASSETS_DIR "dataEntryAutonoma.ico"
$PNG_FILE = Join-Path $ASSETS_DIR "dataEntryAutonoma-256.png"

if (-not (Test-Path $SVG_FILE)) {
    Write-Error "SVG source not found: $SVG_FILE"
}

New-Item -ItemType Directory -Force -Path $ASSETS_DIR | Out-Null

Write-Host "Rendering icon PNG from SVG..."
Push-Location $ASSETS_DIR
try {
    npx --yes @resvg/resvg-js-cli --fit-width 256 --fit-height 256 dataEntryAutonoma.svg dataEntryAutonoma-256.png | Out-Null
}
finally {
    Pop-Location
}

if (-not (Test-Path $PNG_FILE)) {
    Write-Error "PNG render failed: $PNG_FILE"
}

Write-Host "Building ICO..."
Add-Type -AssemblyName System.Drawing

$bitmap = [System.Drawing.Bitmap]::FromFile($PNG_FILE)
try {
    $icon = [System.Drawing.Icon]::FromHandle($bitmap.GetHicon())
    $stream = [System.IO.File]::Create($ICO_FILE)
    try {
        $icon.Save($stream)
    }
    finally {
        $stream.Close()
    }
}
finally {
    $bitmap.Dispose()
}

$sizeKb = [math]::Round((Get-Item $ICO_FILE).Length / 1KB, 1)
Write-Host ('Done. {0} ({1} KB)' -f $ICO_FILE, $sizeKb)
