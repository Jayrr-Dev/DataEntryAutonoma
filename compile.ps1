#Requires -Version 5.1
<#
.SYNOPSIS
    Compiles relayInput.ahk into a standalone InputRelay.exe (no AHK install required on target PCs).

.DESCRIPTION
    Uses Ahk2Exe with the AutoHotkey v2 64-bit base interpreter. Output goes to dist\InputRelay.exe.
    Run from the project root:  .\compile.ps1
#>

$ErrorActionPreference = "Stop"

$PROJECT_ROOT = $PSScriptRoot
$INPUT_SCRIPT = Join-Path $PROJECT_ROOT "relayInput.ahk"
$OUTPUT_DIR = Join-Path $PROJECT_ROOT "dist"
$OUTPUT_EXE = Join-Path $OUTPUT_DIR "InputRelay.exe"

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
Write-Host "  -> $OUTPUT_EXE"

& $AHK2EXE /in $INPUT_SCRIPT /out $OUTPUT_EXE /base $AHK_BASE

if (-not (Test-Path $OUTPUT_EXE)) {
    Write-Error "Compilation failed - output file was not created."
}

$sizeKb = [math]::Round((Get-Item $OUTPUT_EXE).Length / 1KB, 1)
Write-Host ('Done. {0} ({1} KB)' -f $OUTPUT_EXE, $sizeKb)
