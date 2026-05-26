#Requires -Version 5.1
<#
.SYNOPSIS
    Packages dist\DataEntryAutonoma.exe into a release zip and folder mirror for distribution.

.DESCRIPTION
    Requires a prior successful .\compile.ps1 run. Creates release\DataEntryAutonoma-v<VERSION>-win64.zip
    and release\DataEntryAutonoma-v<VERSION>-win64\ for inspection.

    Run from the project root:  .\packageRelease.ps1
#>

$ErrorActionPreference = "Stop"

$PROJECT_ROOT = $PSScriptRoot
$VERSION_FILE = Join-Path $PROJECT_ROOT "VERSION"
if (Test-Path $VERSION_FILE) {
    $VERSION = (Get-Content -LiteralPath $VERSION_FILE -Raw).Trim()
} else {
    $VERSION = "1.0.5"
}
$DIST_EXE = Join-Path $PROJECT_ROOT "dist\DataEntryAutonoma.exe"
$RELEASE_DIR = Join-Path $PROJECT_ROOT "release"
$PACKAGE_NAME = "DataEntryAutonoma-v$VERSION-win64"
$STAGING_DIR = Join-Path $RELEASE_DIR $PACKAGE_NAME
$ZIP_PATH = Join-Path $RELEASE_DIR "$PACKAGE_NAME.zip"

$FILES_AT_ROOT = @(
    "LICENSE",
    "README.md",
    "CHANGELOG.md",
    "runInstallWizard.bat",
    "runInstallWizard.ps1"
)

$OPTIONAL_FILES_AT_ROOT = @(
    "runUninstallWizard.bat",
    "runUninstallWizard.ps1"
)

if (-not (Test-Path $DIST_EXE)) {
    Write-Error @"
Release exe not found: $DIST_EXE
Run .\compile.ps1 first, then run this script again.
"@
}

if (Test-Path $STAGING_DIR) {
    Remove-Item -LiteralPath $STAGING_DIR -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $STAGING_DIR | Out-Null

Copy-Item -LiteralPath $DIST_EXE -Destination (Join-Path $STAGING_DIR "DataEntryAutonoma.exe")

$assetsDir = Join-Path $STAGING_DIR "assets"
New-Item -ItemType Directory -Force -Path $assetsDir | Out-Null
$iconSource = Join-Path $PROJECT_ROOT "assets\dataEntryAutonoma.ico"
if (-not (Test-Path $iconSource)) {
    Write-Error "App icon not found: $iconSource"
}
Copy-Item -LiteralPath $iconSource -Destination (Join-Path $assetsDir "dataEntryAutonoma.ico")

foreach ($folderName in @("recordings", "saved-inputs", "csv-batches")) {
    $emptyDir = Join-Path $STAGING_DIR $folderName
    New-Item -ItemType Directory -Force -Path $emptyDir | Out-Null
    New-Item -ItemType File -Force -Path (Join-Path $emptyDir ".gitkeep") | Out-Null
}

foreach ($fileName in $FILES_AT_ROOT) {
    $sourcePath = Join-Path $PROJECT_ROOT $fileName
    if (-not (Test-Path $sourcePath)) {
        Write-Error "Required file not found: $sourcePath"
    }
    Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $STAGING_DIR $fileName)
}

foreach ($fileName in $OPTIONAL_FILES_AT_ROOT) {
    $sourcePath = Join-Path $PROJECT_ROOT $fileName
    if (Test-Path $sourcePath) {
        Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $STAGING_DIR $fileName)
    }
}

if (Test-Path $ZIP_PATH) {
    Remove-Item -LiteralPath $ZIP_PATH -Force
}

Compress-Archive -Path (Join-Path $STAGING_DIR "*") -DestinationPath $ZIP_PATH -CompressionLevel Optimal

$zipSizeMb = [math]::Round((Get-Item $ZIP_PATH).Length / 1MB, 2)
Write-Host ""
Write-Host "Release package created successfully."
Write-Host "  Folder: $STAGING_DIR"
Write-Host "  Zip:    $ZIP_PATH ($zipSizeMb MB)"
