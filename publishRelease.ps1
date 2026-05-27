#Requires -Version 5.1
<#
.SYNOPSIS
    Builds, packages, and uploads the win64 release zip to GitHub.

.DESCRIPTION
    One-step maintainer flow:
      1. .\compile.ps1
      2. .\packageRelease.ps1
      3. gh release upload (creates the release tag if missing)

    Run from the project root:  .\publishRelease.ps1
#>

$ErrorActionPreference = "Stop"

$PROJECT_ROOT = $PSScriptRoot
$VERSION_FILE = Join-Path $PROJECT_ROOT "VERSION"
$COMPILE_SCRIPT = Join-Path $PROJECT_ROOT "compile.ps1"
$PACKAGE_SCRIPT = Join-Path $PROJECT_ROOT "packageRelease.ps1"

if (-not (Test-Path $VERSION_FILE)) {
    Write-Error "VERSION file not found at $VERSION_FILE"
}

$VERSION = (Get-Content -LiteralPath $VERSION_FILE -Raw).Trim()
$TAG = "v$VERSION"
$PACKAGE_NAME = "DataEntryAutonoma-v$VERSION-win64"
$ZIP_PATH = Join-Path $PROJECT_ROOT (Join-Path "release" "$PACKAGE_NAME.zip")

Write-Host "Publishing $TAG ..."
Write-Host ""

& $COMPILE_SCRIPT
& $PACKAGE_SCRIPT

if (-not (Test-Path $ZIP_PATH)) {
    Write-Error "Release zip not found: $ZIP_PATH"
}

$ghCommand = Get-Command gh -ErrorAction SilentlyContinue
if (-not $ghCommand) {
    Write-Error "GitHub CLI (gh) is not installed. Install it, run gh auth login, then rerun this script."
}

$releaseExists = $false
try {
    gh release view $TAG --repo Jayrr-Dev/DataEntryAutonoma 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $releaseExists = $true
    }
} catch {
    $releaseExists = $false
}

if (-not $releaseExists) {
    $changelogPath = Join-Path $PROJECT_ROOT "CHANGELOG.md"
    $notes = "Data Entry Autonoma $TAG"
    if (Test-Path $changelogPath) {
        $changelogText = Get-Content -LiteralPath $changelogPath -Raw
        if ($changelogText -match "(?ms)\#\# \[$VERSION\][^\#]*") {
            $notes = $Matches[0].Trim()
        }
    }

    gh release create $TAG $ZIP_PATH `
        --repo Jayrr-Dev/DataEntryAutonoma `
        --title "Data Entry Autonoma $TAG" `
        --notes $notes
} else {
    gh release upload $TAG $ZIP_PATH `
        --repo Jayrr-Dev/DataEntryAutonoma `
        --clobber
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "GitHub release upload failed."
}

Write-Host ""
Write-Host "Published $TAG"
Write-Host "  Zip: $ZIP_PATH"
Write-Host "  URL: https://github.com/Jayrr-Dev/DataEntryAutonoma/releases/tag/$TAG"
