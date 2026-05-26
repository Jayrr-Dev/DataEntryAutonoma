#Requires -Version 5.1
<#
.SYNOPSIS
    Graphical install wizard for Data Entry Autonoma.

.DESCRIPTION
    Installs the standalone DataEntryAutonoma.exe to a chosen folder,
    creates data folders, and optional Desktop / Start Menu shortcuts.
    No AutoHotkey install is required on the target PC.
    Run from the project root:  .\runInstallWizard.ps1
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

$ErrorActionPreference = "Stop"

if ([Net.ServicePointManager]::SecurityProtocol -band [Net.SecurityProtocolType]::Tls12) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
} else {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

# =============================================================================
# Constants
# =============================================================================

$APP_DISPLAY_NAME = "Data Entry Autonoma"
$APP_FOLDER_NAME = "DataEntryAutonoma"
$EXE_FILE_NAME = "DataEntryAutonoma.exe"
$SCRIPT_FILE_NAME = "dataEntryAutonoma.ahk"
$ICON_FILE_NAME = "dataEntryAutonoma.ico"
$LICENSE_FILE_NAME = "LICENSE"
$README_FILE_NAME = "README.md"
$CHANGELOG_FILE_NAME = "CHANGELOG.md"
$VERSION_FILE_NAME = "VERSION"
$INSTALL_WIZARD_PS1 = "runInstallWizard.ps1"
$INSTALL_WIZARD_BAT = "runInstallWizard.bat"
$UNINSTALL_WIZARD_PS1 = "runUninstallWizard.ps1"
$UNINSTALL_WIZARD_BAT = "runUninstallWizard.bat"

$DEFAULT_INSTALL_DIR = Join-Path (Join-Path $env:LOCALAPPDATA "Programs") $APP_FOLDER_NAME
$DIST_RELATIVE_PATH = "dist"
$ASSETS_RELATIVE_PATH = "assets"

$GITHUB_REPO_OWNER = "Jayrr-Dev"
$GITHUB_REPO_NAME = "DataEntryAutonoma"
$GITHUB_RELEASES_LATEST_URL = "https://api.github.com/repos/$GITHUB_REPO_OWNER/$GITHUB_REPO_NAME/releases/latest"
$RELEASE_ZIP_NAME_PATTERN = "DataEntryAutonoma-v*-win64.zip"
$DOWNLOAD_USER_AGENT = "$APP_DISPLAY_NAME Install Wizard"

$WIZARD_WIDTH = 520
$WIZARD_HEIGHT = 440
$CONTENT_WIDTH = 460

$COLOR_BG = [System.Drawing.Color]::FromArgb(248, 249, 250)
$COLOR_TEXT = [System.Drawing.Color]::FromArgb(26, 26, 26)
$COLOR_MUTED = [System.Drawing.Color]::FromArgb(107, 114, 128)

$PROJECT_ROOT = $PSScriptRoot
$DIST_EXE_PATH = Join-Path $PROJECT_ROOT (Join-Path $DIST_RELATIVE_PATH $EXE_FILE_NAME)
$SOURCE_SCRIPT_PATH = Join-Path $PROJECT_ROOT $SCRIPT_FILE_NAME
$COMPILE_SCRIPT_PATH = Join-Path $PROJECT_ROOT "compile.ps1"

# =============================================================================
# Install helpers
# =============================================================================

# Returns the selected standalone exe path when the file exists.
function Get-StandaloneExeSourcePath {
    if ($script:StandaloneExeSourcePath -and (Test-Path $script:StandaloneExeSourcePath)) {
        return $script:StandaloneExeSourcePath
    }

    return ""
}

# Returns true when a standalone exe is ready to install.
function Test-StandaloneExeAvailable {
    return [bool](Get-StandaloneExeSourcePath)
}

# Uses a local exe from the wizard folder or dist, when available.
function Initialize-InstallSource {
    $localExePath = Join-Path $PROJECT_ROOT $EXE_FILE_NAME

    if (Test-Path $localExePath) {
        $script:StandaloneExeSourcePath = $localExePath
        $script:ReleaseSourceRoot = $PROJECT_ROOT
        return
    }

    if (Test-Path $DIST_EXE_PATH) {
        $script:StandaloneExeSourcePath = $DIST_EXE_PATH
        $script:ReleaseSourceRoot = $PROJECT_ROOT
        return
    }

    $script:StandaloneExeSourcePath = ""
    $script:ReleaseSourceRoot = $PROJECT_ROOT
}

# Ensures install files are available, downloading only when needed.
function Ensure-InstallSourceReady {
    param([string]$StatusMessage = "")

    if (Test-StandaloneExeAvailable) {
        return $true
    }

    try {
        if ($StatusMessage -ne "") {
            Set-WizardStatusMessage $StatusMessage
        }

        Invoke-DownloadLatestRelease | Out-Null
        return $true
    } catch {
        $pickedPath = Show-InstallSourceBrowseDialog
        if ($pickedPath -ne "") {
            $script:StandaloneExeSourcePath = $pickedPath
            $script:ReleaseSourceRoot = Split-Path $pickedPath -Parent
            $script:DownloadedReleaseVersion = ""
            return $true
        }

        Show-WizardError "Could not find or download $EXE_FILE_NAME.`r`n$($_.Exception.Message)"
        return $false
    }
}

# Prompts the user to pick DataEntryAutonoma.exe manually.
function Show-InstallSourceBrowseDialog {
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = "Select $EXE_FILE_NAME"
    $dialog.Filter = "Application (*.exe)|$EXE_FILE_NAME|All executables (*.exe)|*.exe"
    $dialog.FileName = $EXE_FILE_NAME

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.FileName
    }

    return ""
}

# Updates the welcome step status label when present.
function Set-WizardStatusMessage {
    param([string]$Message)

    if (Test-ControlUsable $script:Welcome_StatusLabel) {
        $script:Welcome_StatusLabel.Text = $Message
        [System.Windows.Forms.Application]::DoEvents()
    }
}

# Returns the app version from VERSION in the active release or project root.
function Get-LocalProjectVersion {
    $versionPath = Get-ReleaseSourcePath $VERSION_FILE_NAME
    if (Test-Path $versionPath) {
        return (Get-Content -LiteralPath $versionPath -Raw).Trim()
    }

    $projectVersionPath = Join-Path $PROJECT_ROOT $VERSION_FILE_NAME
    if (Test-Path $projectVersionPath) {
        return (Get-Content -LiteralPath $projectVersionPath -Raw).Trim()
    }

    return ""
}

# Returns a short label for the install source shown on the welcome screen.
function Get-InstallSourceSummary {
    if (-not (Test-StandaloneExeAvailable)) {
        return "The app will be downloaded when you click Next."
    }

    if ($script:DownloadedReleaseVersion) {
        return "Ready to install version $($script:DownloadedReleaseVersion)."
    }

    $localVersion = Get-LocalProjectVersion
    if ($localVersion) {
        return "Ready to install version $localVersion from this folder."
    }

    return "Ready to install from this folder."
}

# Returns the root folder used for LICENSE, README, icons, and wizard scripts during install.
function Get-ReleaseSourceRoot {
    if ($script:ReleaseSourceRoot) {
        return $script:ReleaseSourceRoot
    }

    return $PROJECT_ROOT
}

# Resolves a file path under the active release source root.
function Get-ReleaseSourcePath {
    param([string]$RelativePath)

    return Join-Path (Get-ReleaseSourceRoot) $RelativePath
}

# Returns metadata for the latest GitHub release win64 zip asset.
function Get-LatestReleaseZipAsset {
    $headers = @{
        "User-Agent" = $DOWNLOAD_USER_AGENT
        "Accept"     = "application/vnd.github+json"
    }

    $release = Invoke-RestMethod -Uri $GITHUB_RELEASES_LATEST_URL -Headers $headers -UseBasicParsing
    $asset = $release.assets | Where-Object { $_.name -like $RELEASE_ZIP_NAME_PATTERN } | Select-Object -First 1

    if (-not $asset) {
        throw "No win64 release zip found for $($release.tag_name)."
    }

    return @{
        TagName     = $release.tag_name
        Version     = ($release.tag_name -replace '^v', '')
        DownloadUrl = $asset.browser_download_url
        FileName    = $asset.name
    }
}

# Downloads and extracts the latest GitHub release; sets exe and release source paths.
function Invoke-DownloadLatestRelease {
    $asset = Get-LatestReleaseZipAsset
    $tempRoot = Join-Path $env:TEMP ("DataEntryAutonoma-Setup-" + [guid]::NewGuid().ToString("N"))
    Ensure-Directory $tempRoot

    $zipPath = Join-Path $tempRoot $asset.FileName
    $extractPath = Join-Path $tempRoot "extracted"
    Ensure-Directory $extractPath

    $headers = @{ "User-Agent" = $DOWNLOAD_USER_AGENT }
    Invoke-WebRequest -Uri $asset.DownloadUrl -OutFile $zipPath -Headers $headers -UseBasicParsing

    if (Test-Path $extractPath) {
        Remove-Item -LiteralPath $extractPath -Recurse -Force
    }
    Ensure-Directory $extractPath
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $extractPath)

    $exePath = Join-Path $extractPath $EXE_FILE_NAME
    if (-not (Test-Path $exePath)) {
        throw "$EXE_FILE_NAME not found in $($asset.FileName)."
    }

    $script:ReleaseSourceRoot = $extractPath
    $script:StandaloneExeSourcePath = $exePath
    $script:DownloadedReleaseVersion = $asset.Version

    return $asset
}

# Returns true when this machine can build the exe from source (maintainers only).
function Test-CanBuildStandaloneExe {
    $ahk2Exe = "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
    return (Test-Path $COMPILE_SCRIPT_PATH) -and (Test-Path $ahk2Exe) -and (Test-Path $SOURCE_SCRIPT_PATH)
}

# Ensures a directory exists.
function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

# Copies one file when the source exists.
function Copy-InstallFile {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-Path $Source)) {
        return $false
    }

    Copy-Item -Path $Source -Destination $Destination -Force
    return $true
}

# Returns true when the install folder already contains a previous installation.
function Test-ExistingInstallation {
    param([string]$InstallDir)

    return Test-Path (Join-Path $InstallDir $EXE_FILE_NAME)
}

# Sets $script:IsUpgrade from the current install directory.
function Update-UpgradeDetection {
    param([string]$InstallDir)

    $script:IsUpgrade = Test-ExistingInstallation -InstallDir $InstallDir
}

# Updates the install-location step upgrade notice label.
function Update-Step2UpgradeNotice {
    param(
        [string]$PathText,
        [System.Windows.Forms.Label]$NoticeLabel
    )

    Update-UpgradeDetection -InstallDir $PathText.Trim()
    if ($script:IsUpgrade) {
        $NoticeLabel.Text = "Upgrading existing installation (your recordings, presets, and CSV files will be kept)."
    } else {
        $NoticeLabel.Text = ""
    }
}

# Creates Desktop and Start Menu shortcuts for the installed app.
function New-InstallShortcuts {
    param(
        [string]$InstallDir,
        [string]$TargetPath,
        [string]$IconPath = "",
        [bool]$DesktopShortcut,
        [bool]$StartMenuShortcut
    )

    $shell = New-Object -ComObject WScript.Shell
    $shortcutName = "$APP_DISPLAY_NAME.lnk"

    $targets = @()
    if ($DesktopShortcut) {
        $targets += Join-Path ([Environment]::GetFolderPath("Desktop")) $shortcutName
    }
    if ($StartMenuShortcut) {
        $programsDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
        Ensure-Directory $programsDir
        $targets += Join-Path $programsDir $shortcutName
    }

    foreach ($shortcutPath in $targets) {
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $TargetPath
        $shortcut.WorkingDirectory = $InstallDir
        if ($IconPath -and (Test-Path $IconPath)) {
            $shortcut.IconLocation = $IconPath
        }
        $shortcut.Description = $APP_DISPLAY_NAME
        $shortcut.Save()
    }
}

# Copies the standalone exe and supporting files; preserves user data folders on upgrade.
function Install-ApplicationFiles {
    param([string]$InstallDir)

    $exeSource = Get-StandaloneExeSourcePath
    if (-not $exeSource) {
        throw "No $EXE_FILE_NAME selected. Browse for the exe or download a release from GitHub."
    }

    Update-UpgradeDetection -InstallDir $InstallDir

    Ensure-Directory $InstallDir
    Ensure-Directory (Join-Path $InstallDir "recordings")
    Ensure-Directory (Join-Path $InstallDir "saved-inputs")
    Ensure-Directory (Join-Path $InstallDir "csv-batches")

    $releaseRoot = Get-ReleaseSourceRoot

    Copy-InstallFile (Join-Path $releaseRoot $LICENSE_FILE_NAME) (Join-Path $InstallDir $LICENSE_FILE_NAME)
    Copy-InstallFile (Join-Path $releaseRoot $README_FILE_NAME) (Join-Path $InstallDir $README_FILE_NAME)
    Copy-InstallFile (Join-Path $releaseRoot $CHANGELOG_FILE_NAME) (Join-Path $InstallDir $CHANGELOG_FILE_NAME)
    Copy-InstallFile (Join-Path $releaseRoot $VERSION_FILE_NAME) (Join-Path $InstallDir $VERSION_FILE_NAME)
    Copy-InstallFile (Join-Path $releaseRoot $INSTALL_WIZARD_PS1) (Join-Path $InstallDir $INSTALL_WIZARD_PS1)
    Copy-InstallFile (Join-Path $releaseRoot $INSTALL_WIZARD_BAT) (Join-Path $InstallDir $INSTALL_WIZARD_BAT)
    Copy-InstallFile (Join-Path $releaseRoot $UNINSTALL_WIZARD_PS1) (Join-Path $InstallDir $UNINSTALL_WIZARD_PS1)
    Copy-InstallFile (Join-Path $releaseRoot $UNINSTALL_WIZARD_BAT) (Join-Path $InstallDir $UNINSTALL_WIZARD_BAT)

    $destinationExe = Join-Path $InstallDir $EXE_FILE_NAME
    Copy-Item -Path $exeSource -Destination $destinationExe -Force

    $sourceIconPath = Get-ReleaseSourcePath (Join-Path $ASSETS_RELATIVE_PATH $ICON_FILE_NAME)
    $iconPath = ""
    if (Test-Path $sourceIconPath) {
        $iconPath = Join-Path $InstallDir (Join-Path $ASSETS_RELATIVE_PATH $ICON_FILE_NAME)
        Ensure-Directory (Split-Path $iconPath -Parent)
        Copy-Item -Path $sourceIconPath -Destination $iconPath -Force
    }

    return @{
        LaunchPath = $destinationExe
        IconPath = $iconPath
        IsUpgrade = $script:IsUpgrade
    }
}

# Runs compile.ps1 to build dist\DataEntryAutonoma.exe (maintainers only).
function Invoke-BuildStandaloneExe {
    if (-not (Test-Path $COMPILE_SCRIPT_PATH)) {
        throw "Build script not found: $COMPILE_SCRIPT_PATH"
    }

    & $COMPILE_SCRIPT_PATH

    if (-not (Test-Path $DIST_EXE_PATH)) {
        throw "Build finished but $EXE_FILE_NAME was not created."
    }

    $script:StandaloneExeSourcePath = $DIST_EXE_PATH
}

# Starts the installed standalone application.
function Start-InstalledApplication {
    param(
        [string]$LaunchPath,
        [string]$WorkingDirectory
    )

    Start-Process -FilePath $LaunchPath -WorkingDirectory $WorkingDirectory
}

# Returns true when a WinForms control can still be updated safely.
function Test-ControlUsable {
    param([System.Windows.Forms.Control]$Control)

    return $null -ne $Control -and -not $Control.IsDisposed
}

# Enables or disables wizard navigation while a long-running step is active.
function Set-WizardNavigationEnabled {
    param([bool]$Enabled)

    if ($Enabled) {
        $btnBack.Enabled = ($script:CurrentStep -gt 0) -and ($script:CurrentStep -lt 3)
        $btnNext.Enabled = $script:CurrentStep -lt 3
        $btnCancel.Enabled = $script:CurrentStep -lt 3
    } else {
        $btnBack.Enabled = $false
        $btnNext.Enabled = $false
        $btnCancel.Enabled = $false
    }
}

# Shows an unexpected wizard error without crashing the WinForms host.
function Show-WizardError {
    param([string]$Message)

    [System.Windows.Forms.MessageBox]::Show(
        $Message,
        $APP_DISPLAY_NAME,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
}

# =============================================================================
# Wizard UI
# =============================================================================

[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = "$APP_DISPLAY_NAME Setup"
$form.ClientSize = New-Object System.Drawing.Size($WIZARD_WIDTH, $WIZARD_HEIGHT)
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.StartPosition = "CenterScreen"
$form.BackColor = $COLOR_BG
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.Add_ThreadException({
    param($sender, $eventArgs)

    Show-WizardError "Setup error:`r`n$($eventArgs.Exception.Message)"
    $eventArgs.ExceptionHandled = $true
    $script:WizardBusy = $false
    Set-WizardNavigationEnabled $true
})

$script:CurrentStep = 0
Initialize-InstallSource
$script:DownloadedReleaseVersion = ""
$script:InstallDir = $DEFAULT_INSTALL_DIR
$script:CreateDesktopShortcut = $true
$script:CreateStartMenuShortcut = $true
$script:LaunchWhenFinished = $true
$script:LastInstallResult = $null
$script:Step3_Failed = $false
$script:IsUpgrade = $false
$script:WizardBusy = $false
$script:Welcome_StatusLabel = $null

$contentPanel = New-Object System.Windows.Forms.Panel
$contentPanel.Location = New-Object System.Drawing.Point(30, 20)
$contentPanel.Size = New-Object System.Drawing.Size($CONTENT_WIDTH, 280)
$contentPanel.BackColor = $COLOR_BG
$form.Controls.Add($contentPanel)

$btnBack = New-Object System.Windows.Forms.Button
$btnBack.Text = "< Back"
$btnBack.Size = New-Object System.Drawing.Size(90, 32)
$btnBack.Location = New-Object System.Drawing.Point(230, 330)
$form.Controls.Add($btnBack)

$btnNext = New-Object System.Windows.Forms.Button
$btnNext.Text = "Next >"
$btnNext.Size = New-Object System.Drawing.Size(90, 32)
$btnNext.Location = New-Object System.Drawing.Point(330, 330)
$form.Controls.Add($btnNext)

$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "Cancel"
$btnCancel.Size = New-Object System.Drawing.Size(90, 32)
$btnCancel.Location = New-Object System.Drawing.Point(420, 330)
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
Thank you for installing $APP_DISPLAY_NAME.

This wizard copies the app to your chosen folder and can add Desktop and Start Menu shortcuts. AutoHotkey is not required on your PC.

Click Next to choose where to install.
"@ 120
            $body.Location = New-Object System.Drawing.Point(0, 44)
            $contentPanel.Controls.Add($body)

            $status = New-BodyLabel (Get-InstallSourceSummary) 48
            $status.Location = New-Object System.Drawing.Point(0, 168)
            $status.ForeColor = [System.Drawing.Color]::FromArgb(6, 95, 70)
            $contentPanel.Controls.Add($status)
            $script:Welcome_StatusLabel = $status
        }

        1 {
            $btnBack.Enabled = $true
            $btnNext.Text = "Next >"
            $btnCancel.Enabled = $true

            $title = New-TitleLabel "Install location"
            $title.Location = New-Object System.Drawing.Point(0, 0)
            $contentPanel.Controls.Add($title)

            $body = New-BodyLabel "Choose the folder where the app will be installed." 40
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

            $hintText = "Default location does not require administrator rights. The installer will create recordings, saved-inputs, and csv-batches folders inside this directory."
            $hint = New-BodyLabel $hintText 56
            $hint.Location = New-Object System.Drawing.Point(0, 130)
            $contentPanel.Controls.Add($hint)

            $upgradeNotice = New-BodyLabel "" 40
            $upgradeNotice.Location = New-Object System.Drawing.Point(0, 188)
            $upgradeNotice.ForeColor = [System.Drawing.Color]::FromArgb(6, 95, 70)
            $contentPanel.Controls.Add($upgradeNotice)

            $script:Step2_PathBox = $pathBox
            $script:Step2_UpgradeNotice = $upgradeNotice

            Update-Step2UpgradeNotice -PathText $pathBox.Text -NoticeLabel $upgradeNotice

            $pathBox.Add_TextChanged({
                if (-not (Test-ControlUsable $script:Step2_PathBox) -or -not (Test-ControlUsable $script:Step2_UpgradeNotice)) {
                    return
                }

                Update-Step2UpgradeNotice -PathText $script:Step2_PathBox.Text -NoticeLabel $script:Step2_UpgradeNotice
            })

            $btnBrowse.Add_Click({
                $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
                $dialog.Description = "Select install folder"
                $dialog.SelectedPath = $pathBox.Text
                if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                    $pathBox.Text = Join-Path $dialog.SelectedPath $APP_FOLDER_NAME
                }
            })
        }

        2 {
            $btnBack.Enabled = $true
            $btnNext.Text = "Install"
            $btnCancel.Enabled = $true

            $title = New-TitleLabel "Shortcuts and launch"
            $title.Location = New-Object System.Drawing.Point(0, 0)
            $contentPanel.Controls.Add($title)

            $chkDesktop = New-Object System.Windows.Forms.CheckBox
            $chkDesktop.Text = "Create Desktop shortcut"
            $chkDesktop.AutoSize = $true
            $chkDesktop.Location = New-Object System.Drawing.Point(0, 52)
            $chkDesktop.Checked = $script:CreateDesktopShortcut
            $contentPanel.Controls.Add($chkDesktop)

            $chkStart = New-Object System.Windows.Forms.CheckBox
            $chkStart.Text = "Create Start Menu shortcut"
            $chkStart.AutoSize = $true
            $chkStart.Location = New-Object System.Drawing.Point(0, 82)
            $chkStart.Checked = $script:CreateStartMenuShortcut
            $contentPanel.Controls.Add($chkStart)

            $chkLaunch = New-Object System.Windows.Forms.CheckBox
            $chkLaunch.Text = "Launch $APP_DISPLAY_NAME when setup finishes"
            $chkLaunch.AutoSize = $true
            $chkLaunch.Location = New-Object System.Drawing.Point(0, 112)
            $chkLaunch.Checked = $script:LaunchWhenFinished
            $contentPanel.Controls.Add($chkLaunch)

            Update-UpgradeDetection -InstallDir $script:InstallDir
            $installType = if ($script:IsUpgrade) { "Upgrade" } else { "Fresh install" }

            $displayVersion = if ($script:DownloadedReleaseVersion) {
                $script:DownloadedReleaseVersion
            } else {
                Get-LocalProjectVersion
            }
            $versionLine = if ($displayVersion) { "Version: v$displayVersion`r`n" } else { "" }
            $summary = New-BodyLabel "$installType`r`n`r`n$versionLine Install: $EXE_FILE_NAME`r`nInstall folder:`r`n$script:InstallDir" 100
            $summary.Location = New-Object System.Drawing.Point(0, 150)
            $contentPanel.Controls.Add($summary)

            $script:Step2_Desktop = $chkDesktop
            $script:Step2_Start = $chkStart
            $script:Step2_Launch = $chkLaunch
        }

        3 {
            $btnBack.Enabled = $false
            $btnNext.Text = "Finish"
            $btnCancel.Enabled = $false

            $title = New-TitleLabel "Installing"
            $title.Location = New-Object System.Drawing.Point(0, 0)
            $contentPanel.Controls.Add($title)

            $progress = New-Object System.Windows.Forms.ProgressBar
            $progress.Style = "Marquee"
            $progress.MarqueeAnimationSpeed = 30
            $progress.Size = New-Object System.Drawing.Size($CONTENT_WIDTH, 24)
            $progress.Location = New-Object System.Drawing.Point(0, 56)
            $contentPanel.Controls.Add($progress)

            $status = New-BodyLabel "Copying files..." 120
            $status.Location = New-Object System.Drawing.Point(0, 92)
            $contentPanel.Controls.Add($status)

            Update-UpgradeDetection -InstallDir $script:InstallDir
            if ($script:IsUpgrade) {
                $status.Text = "Upgrading existing installation (your recordings, presets, and CSV files will be kept)..."
            }

            try {
                [System.Windows.Forms.Application]::DoEvents()
                $script:LastInstallResult = Install-ApplicationFiles -InstallDir $script:InstallDir
                $script:IsUpgrade = $script:LastInstallResult.IsUpgrade

                New-InstallShortcuts `
                    -InstallDir $script:InstallDir `
                    -TargetPath $script:LastInstallResult.LaunchPath `
                    -IconPath $script:LastInstallResult.IconPath `
                    -DesktopShortcut $script:CreateDesktopShortcut `
                    -StartMenuShortcut $script:CreateStartMenuShortcut

                $progress.Style = "Continuous"
                $progress.Value = 100
                $status.ForeColor = [System.Drawing.Color]::FromArgb(6, 95, 70)
                $completionLabel = if ($script:IsUpgrade) { "Upgrade" } else { "Installation" }
                $status.Text = "$completionLabel completed successfully.`r`n`r`nInstalled to:`r`n$script:InstallDir"
            } catch {
                $progress.Style = "Continuous"
                $progress.Value = 0
                $status.ForeColor = [System.Drawing.Color]::FromArgb(185, 28, 28)
                $status.Text = "Installation failed:`r`n$($_.Exception.Message)"
                $script:Step3_Failed = $true
                $btnNext.Text = "Close"
            }
        }

        4 {
            $btnBack.Enabled = $false
            $btnNext.Text = "Close"
            $btnCancel.Enabled = $false

            $title = New-TitleLabel "Setup complete"
            $title.Location = New-Object System.Drawing.Point(0, 0)
            $contentPanel.Controls.Add($title)

            $bodyText = @"
$APP_DISPLAY_NAME is ready to use.

Open the app from your Desktop or Start Menu shortcut, or run it from:
$script:InstallDir
"@
            $body = New-BodyLabel $bodyText 160
            $body.Location = New-Object System.Drawing.Point(0, 44)
            $contentPanel.Controls.Add($body)
        }
    }
}

function Save-CurrentStepState {
    switch ($script:CurrentStep) {
        1 {
            $script:InstallDir = $script:Step2_PathBox.Text.Trim()
        }
        2 {
            $script:CreateDesktopShortcut = $script:Step2_Desktop.Checked
            $script:CreateStartMenuShortcut = $script:Step2_Start.Checked
            $script:LaunchWhenFinished = $script:Step2_Launch.Checked
        }
    }
}

function Test-CurrentStepValid {
    switch ($script:CurrentStep) {
        1 {
            $path = $script:Step2_PathBox.Text.Trim()
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
        }
    }

    return $true
}

$btnCancel.Add_Click({ $form.Close() })

$btnBack.Add_Click({
    if ($script:WizardBusy) {
        return
    }

    if ($script:CurrentStep -gt 0) {
        Save-CurrentStepState
        $script:CurrentStep -= 1
        Show-WizardStep
    }
})

$btnNext.Add_Click({
    if ($script:WizardBusy) {
        return
    }

    try {
    if ($script:CurrentStep -eq 4) {
        if ($script:LaunchWhenFinished -and $script:LastInstallResult -and -not $script:Step3_Failed) {
            Start-InstalledApplication `
                -LaunchPath $script:LastInstallResult.LaunchPath `
                -WorkingDirectory $script:InstallDir
        }
        $form.Close()
        return
    }

    if ($script:CurrentStep -eq 3) {
        $form.Close()
        return
    }

    if ($script:CurrentStep -eq 0) {
        if (-not (Test-StandaloneExeAvailable)) {
            $script:WizardBusy = $true
            Set-WizardNavigationEnabled $false
            try {
                if (-not (Ensure-InstallSourceReady -StatusMessage "Downloading the latest version...")) {
                    return
                }
            } finally {
                $script:WizardBusy = $false
                Set-WizardNavigationEnabled $true
            }
        }
    }

    Save-CurrentStepState

    if (-not (Test-CurrentStepValid)) {
        return
    }

    if ($script:CurrentStep -eq 2) {
        $script:Step3_Failed = $false
        $script:CurrentStep = 3
        Show-WizardStep
        if (-not $script:Step3_Failed) {
            $script:CurrentStep = 4
            Show-WizardStep
        }
        return
    }

    $script:CurrentStep += 1
    Show-WizardStep
    } catch {
        Show-WizardError "Setup error:`r`n$($_.Exception.Message)"
    }
})

Show-WizardStep
[void]$form.ShowDialog()
