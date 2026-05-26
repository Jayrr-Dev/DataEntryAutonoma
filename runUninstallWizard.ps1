#Requires -Version 5.1
<#
.SYNOPSIS
    Graphical uninstall wizard for Data Entry Autonoma.

.DESCRIPTION
    Removes installed application files, optional user data, apply-state.ini,
    and Desktop / Start Menu shortcuts from a chosen install folder.
    Run from the project root, release zip, or install folder:
    .\runUninstallWizard.ps1
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

# =============================================================================
# Constants
# =============================================================================

$APP_DISPLAY_NAME = "Data Entry Autonoma"
$APP_FOLDER_NAME = "DataEntryAutonoma"
$EXE_FILE_NAME = "DataEntryAutonoma.exe"
$SHORTCUT_FILE_NAME = "$APP_DISPLAY_NAME.lnk"
$LICENSE_FILE_NAME = "LICENSE"
$README_FILE_NAME = "README.md"
$APPLY_STATE_FILE_NAME = "apply-state.ini"
$RECORDINGS_FOLDER_NAME = "recordings"
$SAVED_INPUTS_FOLDER_NAME = "saved-inputs"
$CSV_BATCHES_FOLDER_NAME = "csv-batches"
$ASSETS_FOLDER_NAME = "assets"

$UNINSTALL_SCRIPT_NAME = "runUninstallWizard.ps1"
$UNINSTALL_BATCH_NAME = "runUninstallWizard.bat"

$DEFAULT_INSTALL_DIR = Join-Path (Join-Path $env:LOCALAPPDATA "Programs") $APP_FOLDER_NAME

$WIZARD_WIDTH = 520
$WIZARD_HEIGHT = 480
$CONTENT_WIDTH = 460

$COLOR_BG = [System.Drawing.Color]::FromArgb(248, 249, 250)
$COLOR_TEXT = [System.Drawing.Color]::FromArgb(26, 26, 26)
$COLOR_MUTED = [System.Drawing.Color]::FromArgb(107, 114, 128)
$COLOR_SUCCESS = [System.Drawing.Color]::FromArgb(6, 95, 70)
$COLOR_ERROR = [System.Drawing.Color]::FromArgb(185, 28, 28)
$COLOR_WARNING = [System.Drawing.Color]::FromArgb(180, 83, 9)

$SCRIPT_ROOT = $PSScriptRoot

# =============================================================================
# Uninstall helpers
# =============================================================================

# Returns true when the install folder contains the application exe.
function Test-InstallFolderValid {
    param([string]$InstallDir)

    if (-not $InstallDir) {
        return $false
    }

    if (-not (Test-Path $InstallDir)) {
        return $false
    }

    $exePath = Join-Path $InstallDir $EXE_FILE_NAME
    return Test-Path $exePath
}

# Returns true when this wizard is running from inside the install folder.
function Test-RunningFromInstallDir {
    param([string]$InstallDir)

    $scriptRoot = $SCRIPT_ROOT.TrimEnd('\')
    $installRoot = $InstallDir.TrimEnd('\')
    return ($scriptRoot -eq $installRoot)
}

# Removes a file or folder when it exists.
function Remove-IfExists {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return
    }

    Remove-Item -LiteralPath $Path -Recurse -Force
}

# Removes Desktop and/or Start Menu shortcuts for the app.
function Remove-InstallShortcuts {
    param(
        [bool]$RemoveDesktopShortcut,
        [bool]$RemoveStartMenuShortcut
    )

    if ($RemoveDesktopShortcut) {
        Remove-IfExists (Join-Path ([Environment]::GetFolderPath("Desktop")) $SHORTCUT_FILE_NAME)
    }

    if ($RemoveStartMenuShortcut) {
        $programsDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
        Remove-IfExists (Join-Path $programsDir $SHORTCUT_FILE_NAME)
    }
}

# Schedules deletion of uninstaller scripts and optionally the install folder after this wizard exits.
function Schedule-PostUninstallCleanup {
    param(
        [string]$InstallDir,
        [bool]$RemoveEntireFolder
    )

    $uninstallScriptPath = Join-Path $InstallDir $UNINSTALL_SCRIPT_NAME
    $uninstallBatchPath = Join-Path $InstallDir $UNINSTALL_BATCH_NAME
    $cleanupBatchPath = Join-Path $env:TEMP ("DataEntryAutonoma_cleanup_{0}.bat" -f ([guid]::NewGuid().ToString("N")))

    if ($RemoveEntireFolder) {
        $batchContent = @"
@echo off
ping 127.0.0.1 -n 3 > nul
rd /s /q "$InstallDir"
del /f /q "%~f0"
"@
    } else {
        $batchContent = @"
@echo off
ping 127.0.0.1 -n 3 > nul
del /f /q "$uninstallScriptPath" 2>nul
del /f /q "$uninstallBatchPath" 2>nul
del /f /q "%~f0"
"@
    }

    Set-Content -LiteralPath $cleanupBatchPath -Value $batchContent -Encoding ASCII
    Start-Process -FilePath $cleanupBatchPath -WindowStyle Hidden
}

# Performs the selected uninstall actions.
function Invoke-UninstallApplication {
    param(
        [string]$InstallDir,
        [bool]$RemoveAppFiles,
        [bool]$RemoveUserData,
        [bool]$RemoveApplyState,
        [bool]$RemoveDesktopShortcut,
        [bool]$RemoveStartMenuShortcut
    )

    $runningFromInstallDir = Test-RunningFromInstallDir -InstallDir $InstallDir
    $removedItems = New-Object System.Collections.Generic.List[string]

    Remove-InstallShortcuts `
        -RemoveDesktopShortcut $RemoveDesktopShortcut `
        -RemoveStartMenuShortcut $RemoveStartMenuShortcut

    if ($RemoveDesktopShortcut) {
        $removedItems.Add("Desktop shortcut") | Out-Null
    }
    if ($RemoveStartMenuShortcut) {
        $removedItems.Add("Start Menu shortcut") | Out-Null
    }

    if ($RemoveApplyState) {
        $applyStatePath = Join-Path $InstallDir $APPLY_STATE_FILE_NAME
        if (Test-Path $applyStatePath) {
            Remove-IfExists $applyStatePath
            $removedItems.Add($APPLY_STATE_FILE_NAME) | Out-Null
        }
    }

    if ($RemoveUserData) {
        $recordingsPath = Join-Path $InstallDir $RECORDINGS_FOLDER_NAME
        $savedInputsPath = Join-Path $InstallDir $SAVED_INPUTS_FOLDER_NAME
        $csvBatchesPath = Join-Path $InstallDir $CSV_BATCHES_FOLDER_NAME

        if (Test-Path $recordingsPath) {
            Remove-IfExists $recordingsPath
            $removedItems.Add("$RECORDINGS_FOLDER_NAME\ folder") | Out-Null
        }
        if (Test-Path $savedInputsPath) {
            Remove-IfExists $savedInputsPath
            $removedItems.Add("$SAVED_INPUTS_FOLDER_NAME\ folder") | Out-Null
        }
        if (Test-Path $csvBatchesPath) {
            Remove-IfExists $csvBatchesPath
            $removedItems.Add("$CSV_BATCHES_FOLDER_NAME\ folder") | Out-Null
        }
    }

    if ($RemoveAppFiles) {
        $appPaths = @(
            (Join-Path $InstallDir $EXE_FILE_NAME),
            (Join-Path $InstallDir $LICENSE_FILE_NAME),
            (Join-Path $InstallDir $README_FILE_NAME),
            (Join-Path $InstallDir $ASSETS_FOLDER_NAME)
        )

        foreach ($path in $appPaths) {
            if (Test-Path $path) {
                Remove-IfExists $path
            }
        }

        $removedItems.Add("Application files ($EXE_FILE_NAME, $ASSETS_FOLDER_NAME\, $LICENSE_FILE_NAME, $README_FILE_NAME)") | Out-Null

        if ($runningFromInstallDir) {
            $remainingItems = @(Get-ChildItem -LiteralPath $InstallDir -Force -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -ne $UNINSTALL_SCRIPT_NAME -and $_.Name -ne $UNINSTALL_BATCH_NAME
            })
            $removeEntireFolder = ($remainingItems.Count -eq 0)
            Schedule-PostUninstallCleanup -InstallDir $InstallDir -RemoveEntireFolder $removeEntireFolder

            if ($removeEntireFolder) {
                $removedItems.Add("Remaining install folder (scheduled after wizard closes)") | Out-Null
            } else {
                $removedItems.Add("Uninstaller scripts (scheduled after wizard closes)") | Out-Null
            }
        } else {
            Remove-IfExists (Join-Path $InstallDir $UNINSTALL_SCRIPT_NAME)
            Remove-IfExists (Join-Path $InstallDir $UNINSTALL_BATCH_NAME)

            $remainingItems = @(Get-ChildItem -LiteralPath $InstallDir -Force -ErrorAction SilentlyContinue)
            if ($remainingItems.Count -eq 0) {
                Remove-IfExists $InstallDir
                $removedItems.Add("Install folder") | Out-Null
            }
        }
    }

    return $removedItems
}

# Builds a summary string for the confirmation step.
function Get-UninstallSummaryText {
    param(
        [string]$InstallDir,
        [bool]$RemoveAppFiles,
        [bool]$RemoveUserData,
        [bool]$RemoveApplyState,
        [bool]$RemoveDesktopShortcut,
        [bool]$RemoveStartMenuShortcut
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("Install folder:") | Out-Null
    $lines.Add($InstallDir) | Out-Null
    $lines.Add("") | Out-Null
    $lines.Add("The following will be removed:") | Out-Null

    if ($RemoveAppFiles) {
        $lines.Add("  - Application files ($EXE_FILE_NAME, $ASSETS_FOLDER_NAME\, $LICENSE_FILE_NAME, $README_FILE_NAME)") | Out-Null
    }
    if ($RemoveUserData) {
        $lines.Add("  - User data ($RECORDINGS_FOLDER_NAME\ and $SAVED_INPUTS_FOLDER_NAME\)") | Out-Null
    }
    if ($RemoveApplyState) {
        $lines.Add("  - $APPLY_STATE_FILE_NAME") | Out-Null
    }
    if ($RemoveDesktopShortcut) {
        $lines.Add("  - Desktop shortcut") | Out-Null
    }
    if ($RemoveStartMenuShortcut) {
        $lines.Add("  - Start Menu shortcut") | Out-Null
    }

    if ($lines.Count -eq 4) {
        $lines.Add("  - Nothing selected") | Out-Null
    }

    if (Test-RunningFromInstallDir -InstallDir $InstallDir) {
        $lines.Add("") | Out-Null
        $lines.Add("Note: The uninstaller is running from the install folder.") | Out-Null
        $lines.Add("Any remaining files will be deleted after this wizard closes.") | Out-Null
    }

    return ($lines -join "`r`n")
}

# =============================================================================
# Wizard UI
# =============================================================================

[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = "$APP_DISPLAY_NAME Uninstall"
$form.ClientSize = New-Object System.Drawing.Size($WIZARD_WIDTH, $WIZARD_HEIGHT)
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.StartPosition = "CenterScreen"
$form.BackColor = $COLOR_BG
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$script:CurrentStep = 0
$script:InstallDir = $DEFAULT_INSTALL_DIR
$script:RemoveAppFiles = $true
$script:RemoveUserData = $true
$script:RemoveApplyState = $true
$script:RemoveDesktopShortcut = $true
$script:RemoveStartMenuShortcut = $true
$script:LastUninstallResult = $null
$script:Step4_Failed = $false

$contentPanel = New-Object System.Windows.Forms.Panel
$contentPanel.Location = New-Object System.Drawing.Point(30, 20)
$contentPanel.Size = New-Object System.Drawing.Size($CONTENT_WIDTH, 320)
$contentPanel.BackColor = $COLOR_BG
$form.Controls.Add($contentPanel)

$btnBack = New-Object System.Windows.Forms.Button
$btnBack.Text = "< Back"
$btnBack.Size = New-Object System.Drawing.Size(90, 32)
$btnBack.Location = New-Object System.Drawing.Point(230, 370)
$form.Controls.Add($btnBack)

$btnNext = New-Object System.Windows.Forms.Button
$btnNext.Text = "Next >"
$btnNext.Size = New-Object System.Drawing.Size(90, 32)
$btnNext.Location = New-Object System.Drawing.Point(330, 370)
$form.Controls.Add($btnNext)

$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "Cancel"
$btnCancel.Size = New-Object System.Drawing.Size(90, 32)
$btnCancel.Location = New-Object System.Drawing.Point(420, 370)
$form.Controls.Add($btnCancel)

function Clear-ContentPanel {
    $contentPanel.Controls.Clear()
}

function New-TitleLabel {
    param([string]$Text)

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.AutoSize = $false
    $label.Size = New-Object System.Drawing.Size($CONTENT_WIDTH, 32)
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $label.ForeColor = $COLOR_TEXT
    return $label
}

function New-BodyLabel {
    param(
        [string]$Text,
        [int]$Height = 120
    )

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.AutoSize = $false
    $label.Size = New-Object System.Drawing.Size($CONTENT_WIDTH, $Height)
    $label.ForeColor = $COLOR_MUTED
    return $label
}

function Show-WizardStep {
    Clear-ContentPanel

    switch ($script:CurrentStep) {
        0 {
            $btnBack.Enabled = $false
            $btnNext.Text = "Next >"
            $btnCancel.Enabled = $true

            $title = New-TitleLabel "Welcome"
            $title.Location = New-Object System.Drawing.Point(0, 0)
            $contentPanel.Controls.Add($title)

            $body = New-BodyLabel @"
This wizard removes $APP_DISPLAY_NAME from your computer.

You can choose which files, user data, and shortcuts to remove. Recordings and saved presets can be deleted permanently if you select that option.

Click Next to choose the install folder and select what to remove.
"@ 220
            $body.Location = New-Object System.Drawing.Point(0, 44)
            $contentPanel.Controls.Add($body)
        }

        1 {
            $btnBack.Enabled = $true
            $btnNext.Text = "Next >"
            $btnCancel.Enabled = $true

            $title = New-TitleLabel "Install location"
            $title.Location = New-Object System.Drawing.Point(0, 0)
            $contentPanel.Controls.Add($title)

            $body = New-BodyLabel "Choose the folder where $APP_DISPLAY_NAME is installed." 40
            $body.Location = New-Object System.Drawing.Point(0, 44)
            $contentPanel.Controls.Add($body)

            $pathBox = New-Object System.Windows.Forms.TextBox
            $pathBox.Text = $script:InstallDir
            $pathBox.Size = New-Object System.Drawing.Size(350, 28)
            $pathBox.Location = New-Object System.Drawing.Point(0, 92)
            $contentPanel.Controls.Add($pathBox)

            $btnBrowse = New-Object System.Windows.Forms.Button
            $btnBrowse.Text = "Browse..."
            $btnBrowse.Size = New-Object System.Drawing.Size(90, 28)
            $btnBrowse.Location = New-Object System.Drawing.Point(360, 90)
            $contentPanel.Controls.Add($btnBrowse)

            $hint = New-BodyLabel "Default location: $DEFAULT_INSTALL_DIR`r`nThe folder must contain $EXE_FILE_NAME." 72
            $hint.Location = New-Object System.Drawing.Point(0, 130)
            $contentPanel.Controls.Add($hint)

            $btnBrowse.Add_Click({
                $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
                $dialog.Description = "Select install folder"
                if (Test-Path $pathBox.Text) {
                    $dialog.SelectedPath = $pathBox.Text
                } else {
                    $dialog.SelectedPath = $DEFAULT_INSTALL_DIR
                }
                if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                    $pathBox.Text = $dialog.SelectedPath
                }
            })

            $script:Step1_PathBox = $pathBox
        }

        2 {
            $btnBack.Enabled = $true
            $btnNext.Text = "Next >"
            $btnCancel.Enabled = $true

            $title = New-TitleLabel "Removal options"
            $title.Location = New-Object System.Drawing.Point(0, 0)
            $contentPanel.Controls.Add($title)

            $chkAppFiles = New-Object System.Windows.Forms.CheckBox
            $chkAppFiles.Text = "Remove application files ($EXE_FILE_NAME, $ASSETS_FOLDER_NAME\, $LICENSE_FILE_NAME, $README_FILE_NAME)"
            $chkAppFiles.AutoSize = $true
            $chkAppFiles.Location = New-Object System.Drawing.Point(0, 44)
            $chkAppFiles.Checked = $script:RemoveAppFiles
            $contentPanel.Controls.Add($chkAppFiles)

            $chkUserData = New-Object System.Windows.Forms.CheckBox
            $chkUserData.Text = "Remove recordings, saved presets, and CSV bulk inputs (deletes your user data permanently)"
            $chkUserData.AutoSize = $true
            $chkUserData.Location = New-Object System.Drawing.Point(0, 74)
            $chkUserData.Checked = $script:RemoveUserData
            $contentPanel.Controls.Add($chkUserData)

            $chkApplyState = New-Object System.Windows.Forms.CheckBox
            $chkApplyState.Text = "Remove $APPLY_STATE_FILE_NAME (last selected recording, preset, and CSV)"
            $chkApplyState.AutoSize = $true
            $chkApplyState.Location = New-Object System.Drawing.Point(0, 104)
            $chkApplyState.Checked = $script:RemoveApplyState
            $contentPanel.Controls.Add($chkApplyState)

            $chkDesktop = New-Object System.Windows.Forms.CheckBox
            $chkDesktop.Text = "Remove Desktop shortcut"
            $chkDesktop.AutoSize = $true
            $chkDesktop.Location = New-Object System.Drawing.Point(0, 134)
            $chkDesktop.Checked = $script:RemoveDesktopShortcut
            $contentPanel.Controls.Add($chkDesktop)

            $chkStart = New-Object System.Windows.Forms.CheckBox
            $chkStart.Text = "Remove Start Menu shortcut"
            $chkStart.AutoSize = $true
            $chkStart.Location = New-Object System.Drawing.Point(0, 164)
            $chkStart.Checked = $script:RemoveStartMenuShortcut
            $contentPanel.Controls.Add($chkStart)

            $warn = New-BodyLabel "Warning: Removing recordings, presets, and CSV files cannot be undone. You will be asked to confirm on the next step." 56
            $warn.ForeColor = $COLOR_WARNING
            $warn.Location = New-Object System.Drawing.Point(0, 200)
            $contentPanel.Controls.Add($warn)

            $script:Step2_AppFiles = $chkAppFiles
            $script:Step2_UserData = $chkUserData
            $script:Step2_ApplyState = $chkApplyState
            $script:Step2_Desktop = $chkDesktop
            $script:Step2_Start = $chkStart
        }

        3 {
            $btnBack.Enabled = $true
            $btnNext.Text = "Uninstall"
            $btnCancel.Enabled = $true

            $title = New-TitleLabel "Confirm removal"
            $title.Location = New-Object System.Drawing.Point(0, 0)
            $contentPanel.Controls.Add($title)

            $summaryText = Get-UninstallSummaryText `
                -InstallDir $script:InstallDir `
                -RemoveAppFiles $script:RemoveAppFiles `
                -RemoveUserData $script:RemoveUserData `
                -RemoveApplyState $script:RemoveApplyState `
                -RemoveDesktopShortcut $script:RemoveDesktopShortcut `
                -RemoveStartMenuShortcut $script:RemoveStartMenuShortcut

            $summary = New-BodyLabel $summaryText 250
            $summary.Location = New-Object System.Drawing.Point(0, 44)
            $contentPanel.Controls.Add($summary)
        }

        4 {
            $btnBack.Enabled = $false
            $btnNext.Text = "Finish"
            $btnCancel.Enabled = $false

            $title = New-TitleLabel "Removing"
            $title.Location = New-Object System.Drawing.Point(0, 0)
            $contentPanel.Controls.Add($title)

            $progress = New-Object System.Windows.Forms.ProgressBar
            $progress.Style = "Marquee"
            $progress.MarqueeAnimationSpeed = 30
            $progress.Size = New-Object System.Drawing.Size($CONTENT_WIDTH, 24)
            $progress.Location = New-Object System.Drawing.Point(0, 56)
            $contentPanel.Controls.Add($progress)

            $status = New-BodyLabel "Removing selected items..." 180
            $status.Location = New-Object System.Drawing.Point(0, 92)
            $contentPanel.Controls.Add($status)

            try {
                [System.Windows.Forms.Application]::DoEvents()
                $script:LastUninstallResult = Invoke-UninstallApplication `
                    -InstallDir $script:InstallDir `
                    -RemoveAppFiles $script:RemoveAppFiles `
                    -RemoveUserData $script:RemoveUserData `
                    -RemoveApplyState $script:RemoveApplyState `
                    -RemoveDesktopShortcut $script:RemoveDesktopShortcut `
                    -RemoveStartMenuShortcut $script:RemoveStartMenuShortcut

                $progress.Style = "Continuous"
                $progress.Value = 100
                $status.ForeColor = $COLOR_SUCCESS

                $resultLines = @("Uninstall completed successfully.", "", "Removed:")
                foreach ($item in $script:LastUninstallResult) {
                    $resultLines += "  - $item"
                }
                if ($script:LastUninstallResult.Count -eq 0) {
                    $resultLines += "  - No matching files or shortcuts were found."
                }

                if (Test-RunningFromInstallDir -InstallDir $script:InstallDir -and $script:RemoveAppFiles) {
                    $resultLines += ""
                    $resultLines += "Remaining install files will be removed shortly after you close this wizard."
                }

                $status.Text = ($resultLines -join "`r`n")
            } catch {
                $progress.Style = "Continuous"
                $progress.Value = 0
                $status.ForeColor = $COLOR_ERROR
                $status.Text = "Uninstall failed:`r`n$($_.Exception.Message)"
                $script:Step4_Failed = $true
                $btnNext.Text = "Close"
            }
        }

        5 {
            $btnBack.Enabled = $false
            $btnNext.Text = "Close"
            $btnCancel.Enabled = $false

            $title = New-TitleLabel "Uninstall complete"
            $title.Location = New-Object System.Drawing.Point(0, 0)
            $contentPanel.Controls.Add($title)

            $bodyText = @"
$APP_DISPLAY_NAME has been removed based on your selections.

If you removed application files, the app is no longer installed on this PC.
"@
            if (Test-RunningFromInstallDir -InstallDir $script:InstallDir -and $script:RemoveAppFiles) {
                $bodyText += @"

The install folder and uninstaller will be deleted automatically after you close this wizard if no other files remain.
"@
            }

            $body = New-BodyLabel $bodyText 180
            $body.Location = New-Object System.Drawing.Point(0, 44)
            $contentPanel.Controls.Add($body)
        }
    }
}

function Save-CurrentStepState {
    switch ($script:CurrentStep) {
        1 {
            $script:InstallDir = $script:Step1_PathBox.Text.Trim()
        }
        2 {
            $script:RemoveAppFiles = $script:Step2_AppFiles.Checked
            $script:RemoveUserData = $script:Step2_UserData.Checked
            $script:RemoveApplyState = $script:Step2_ApplyState.Checked
            $script:RemoveDesktopShortcut = $script:Step2_Desktop.Checked
            $script:RemoveStartMenuShortcut = $script:Step2_Start.Checked
        }
    }
}

function Test-CurrentStepValid {
    switch ($script:CurrentStep) {
        1 {
            $path = $script:Step1_PathBox.Text.Trim()
            if (-not $path) {
                [System.Windows.Forms.MessageBox]::Show(
                    "Please choose an install folder.",
                    $APP_DISPLAY_NAME,
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                ) | Out-Null
                return $false
            }

            $script:InstallDir = $path

            if (-not (Test-Path $script:InstallDir)) {
                [System.Windows.Forms.MessageBox]::Show(
                    @"
The install folder was not found:

$script:InstallDir

Choose the folder where $APP_DISPLAY_NAME is installed, or cancel if the app is not installed on this PC.
"@,
                    $APP_DISPLAY_NAME,
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                ) | Out-Null
                return $false
            }

            if (-not (Test-InstallFolderValid -InstallDir $script:InstallDir)) {
                [System.Windows.Forms.MessageBox]::Show(
                    @"
$EXE_FILE_NAME was not found in:

$script:InstallDir

This folder does not look like a $APP_DISPLAY_NAME installation. Choose the correct folder or cancel.
"@,
                    $APP_DISPLAY_NAME,
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                ) | Out-Null
                return $false
            }
        }
        2 {
            if (-not ($script:Step2_AppFiles.Checked -or
                $script:Step2_UserData.Checked -or
                $script:Step2_ApplyState.Checked -or
                $script:Step2_Desktop.Checked -or
                $script:Step2_Start.Checked)) {
                [System.Windows.Forms.MessageBox]::Show(
                    "Select at least one item to remove, or click Cancel to exit.",
                    $APP_DISPLAY_NAME,
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                ) | Out-Null
                return $false
            }
        }
        3 {
            if ($script:RemoveUserData) {
                $confirm = [System.Windows.Forms.MessageBox]::Show(
                    @"
You selected removal of recordings, saved presets, and CSV bulk inputs.

This permanently deletes your user data and cannot be undone.

Continue with uninstall?
"@,
                    $APP_DISPLAY_NAME,
                    [System.Windows.Forms.MessageBoxButtons]::YesNo,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                )
                if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) {
                    return $false
                }
            }
        }
    }

    return $true
}

$btnCancel.Add_Click({ $form.Close() })

$btnBack.Add_Click({
    if ($script:CurrentStep -gt 0) {
        Save-CurrentStepState
        $script:CurrentStep -= 1
        Show-WizardStep
    }
})

$btnNext.Add_Click({
    if ($script:CurrentStep -eq 5) {
        $form.Close()
        return
    }

    if ($script:CurrentStep -eq 4) {
        $form.Close()
        return
    }

    Save-CurrentStepState

    if (-not (Test-CurrentStepValid)) {
        return
    }

    if ($script:CurrentStep -eq 3) {
        $script:Step4_Failed = $false
        $script:CurrentStep = 4
        Show-WizardStep
        if (-not $script:Step4_Failed) {
            $script:CurrentStep = 5
            Show-WizardStep
        }
        return
    }

    $script:CurrentStep += 1
    Show-WizardStep
})

Show-WizardStep
[void]$form.ShowDialog()
