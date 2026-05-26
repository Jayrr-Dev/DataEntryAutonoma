#Requires -Version 5.1
<#
.SYNOPSIS
    Compiles dataEntryAutonoma.ahk into a standalone DataEntryAutonoma.exe (no AHK install required on target PCs).

.DESCRIPTION
    Uses Ahk2Exe with the AutoHotkey v2 64-bit base interpreter. Output goes to dist\DataEntryAutonoma.exe.
    Run from the project root:  .\compile.ps1
#>

$ErrorActionPreference = "Stop"

$PROJECT_ROOT = $PSScriptRoot
$VERSION_FILE = Join-Path $PROJECT_ROOT "VERSION"
$APP_VERSION = if (Test-Path $VERSION_FILE) { (Get-Content -LiteralPath $VERSION_FILE -Raw).Trim() } else { "unknown" }
$INPUT_SCRIPT = Join-Path $PROJECT_ROOT "dataEntryAutonoma.ahk"
$OUTPUT_DIR = Join-Path $PROJECT_ROOT "dist"
$OUTPUT_EXE = Join-Path $OUTPUT_DIR "DataEntryAutonoma.exe"
$APP_ICON = Join-Path $PROJECT_ROOT "assets\dataEntryAutonoma.ico"

$AHK2EXE = "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
$AHK_BASE = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"

if (-not (Test-Path $INPUT_SCRIPT)) {
    Write-Error "Input script not found: $INPUT_SCRIPT"
}

if (-not (Test-Path $AHK2EXE)) {
    Write-Error @"
Ahk2Exe not found at: $AHK2EXE
Install AutoHotkey v2 from https://www.autohotkey.com/ (include the compiler).
"@
}

if (-not (Test-Path $AHK_BASE)) {
    Write-Error @"
AutoHotkey v2 base not found at: $AHK_BASE
Install AutoHotkey v2 from https://www.autohotkey.com/
"@
}

New-Item -ItemType Directory -Force -Path $OUTPUT_DIR | Out-Null

Write-Host "Compiling $INPUT_SCRIPT"
Write-Host "  version: $APP_VERSION (keep in sync with C.appVersion in dataEntryAutonoma.ahk)"
Write-Host "  -> $OUTPUT_EXE"

if (Test-Path $APP_ICON) {
    Write-Host "  icon: $APP_ICON"
    & $AHK2EXE /in $INPUT_SCRIPT /out $OUTPUT_EXE /base $AHK_BASE /icon $APP_ICON
}
else {
    Write-Warning "App icon not found ($APP_ICON). Run .\buildAppIcon.ps1 first."
    & $AHK2EXE /in $INPUT_SCRIPT /out $OUTPUT_EXE /base $AHK_BASE
}

if (-not (Test-Path $OUTPUT_EXE)) {
    Write-Error "Compilation failed - output file was not created."
}

$sizeKb = [math]::Round((Get-Item $OUTPUT_EXE).Length / 1KB, 1)
Write-Host ('Done. {0} ({1} KB)' -f $OUTPUT_EXE, $sizeKb)
