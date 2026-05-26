#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn
SendMode "Input"
SetMouseDelay -1
SetKeyDelay -1

; dataEntryAutonoma.ahk
; Data Entry Autonoma — record clicks, scrolls, and keys; replay with presets or CSV batches.
; Copyright (c) 2026 Jayrr Dev — https://github.com/Jayrr-Dev/DataEntryAutonoma
; SPDX-License-Identifier: MIT
; Unified Record and Run module with CSV batch support.
; Recordings: recordings\di-*.log
; Presets: saved-inputs\*.txt
; Esc saves recording (Cancel on the save dialog discards). Esc stops Run or a CSV batch.

EnableDpiAwareness()
CoordMode "Mouse", "Screen"

; =============================================================================
; Constants
; =============================================================================

C := {
    appVersion: "1.0.2", ; keep in sync with VERSION at project root
    recordingsDir: A_ScriptDir "\recordings",
    savesDir: A_ScriptDir "\saved-inputs",
    appIconFile: A_ScriptDir "\assets\dataEntryAutonoma.ico",
    stateFile: A_ScriptDir "\apply-state.ini",
    saveExt: ".txt",
    prefix: "di-",
    diPrefix: "di-",
    wheelDelta: 120,
    flushIntervalMs: 1000,
    batchRowPauseMs: 750,
    csvBatchHelpMessage: "
    (
CSV batch replays the selected recording once per row. Each row supplies variable values for that full pass.

Expected format:
  label,value1,value2,value3

Examples:
  1,Alice,100,East
  2,Bob,250,West

  Single value (maps to variable-1 only):
  hello

How it works:
  • Run replays the entire recording for row 1, then row 2, and so on
  • Column 1 is a row label (status display only)
  • Columns 2+ map to variable-1, variable-2, variable-3, ...
  • Blank lines and lines starting with # are ignored
  • Preset is optional — speeds and run options only; row values are used instead of preset variables
  • Config (next to the info button) opens CSV batch options, including Ask to run next line
  • Ask to run next line shows a progress table and a prompt before each row (Run, Skip, or Run all remaining)
  • Esc stops the whole batch
    )",
    recordingTipText: "Esc = Save · Hold Shift = delay",
    recordingTipOffsetX: 240,
    recordingTipOffsetY: 16,
    cursorTipOffsetX: 12,
    cursorTipOffsetY: 12,
    recordingTipRefreshMs: 1000,
    recordingTransientTipMs: 3000,
    minShiftDelayMs: 200,
    shiftDelayTipRefreshMs: 100,
    fileDeleteAttempts: 5,
    fileDeleteRetryMs: 250,

    stateSection: "last",
    statePresetKey: "preset",
    stateRecordingKey: "recording",
    stateCsvKey: "csv",
    stateCsvAskNextLineKey: "csvAskNextLine",

    csvBatchConfigTitle: "CSV batch settings",
    csvAskNextLineLabel: "Ask to run next line before each row",
    csvBatchProgressTitle: "CSV batch progress",
    csvBatchStatusPending: "",
    csvBatchStatusDone: "✓",
    csvBatchStatusSkipped: "Skipped",
    csvBatchPromptChoiceNone: "",
    csvBatchPromptChoiceRun: "run",
    csvBatchPromptChoiceSkip: "skip",
    csvBatchPromptChoiceRunAll: "runAll",
    csvBatchVarDisplayCount: 5,
    csvBatchPromptPollMs: 50,
    csvBatchPromptRun: "Run this row",
    csvBatchPromptSkip: "Skip",
    csvBatchPromptRunAll: "Run all remaining",

    defaultPlaybackSpeed: 1.0,
    defaultTypingSpeed: 1.0,
    defaultMoveSpeed: 1.5,
    defaultInitialDelayMs: 1000,
    defaultClickPauseMs: 150,
    defaultSegmentPauseMs: 200,
    defaultUseRecordedTiming: false,
    defaultSmoothMouse: true,
    defaultHumanTyping: true,

    minKeyDelayMs: 8,
    maxKeyDelayMs: 186,
    minEnterDelayMs: 128,
    maxEnterDelayMs: 556,

    moveMinMs: 35,
    moveMaxMs: 350,
    moveMsPerPx: 0.45,
    curveMinOffset: 55,
    curveMaxOffset: 240,
    curveOffsetRatio: 0.28,
    moveStepsMin: 28,
    moveStepsPerPx: 0.65,
    moveStepMinSleepMs: 1,

    variableTipMs: 2500,
    blockUserMouse: true,

    SM_XVIRTUALSCREEN: 76,
    SM_YVIRTUALSCREEN: 77,
    SM_CXVIRTUALSCREEN: 78,
    SM_CYVIRTUALSCREEN: 79,

    WM_SETICON: 0x0080,
    ICON_SMALL: 0,
    ICON_BIG: 1,

    WH_MOUSE_LL: 14,
    WH_KEYBOARD_LL: 13,
    LLMHF_INJECTED: 0x1,

    WM_LBUTTONDOWN: 0x201,
    WM_RBUTTONDOWN: 0x204,
    WM_MBUTTONDOWN: 0x207,
    WM_XBUTTONDOWN: 0x20B,
    WM_MOUSEWHEEL: 0x20A,
    WM_MOUSEHWHEEL: 0x20E,

    WM_KEYDOWN: 0x100,
    WM_KEYUP: 0x101,
    WM_SYSKEYDOWN: 0x104,
    WM_SYSKEYUP: 0x105,

    VK_ESCAPE: 0x1B,
    VK_F9: 0x78,
    VK_F10: 0x79,
    VK_LSHIFT: 0xA0,
    VK_RSHIFT: 0xA1,

    ignoredExes: [
        "AutoHotkey64.exe",
        "AutoHotkey32.exe",
        "AutoHotkeyUX.exe",
        "SnippingTool.exe"
    ]
}

; Manage window theme — colors, spacing, typography (UI/styling only).
UI := {
    bg: "F8F9FA",
    surface: "FFFFFF",
    textPrimary: "1A1A1A",
    textMuted: "6B7280",
    textHint: "9CA3AF",
    accent: "2563EB",
    accentText: "FFFFFF",
    detectBg: "ECFDF5",
    detectText: "065F46",
    statusBg: "EEF2FF",
    statusText: "1E3A8A",
    sessionText: "4B5563",
    listBg: "FFFFFF",
    editBg: "FFFFFF",
    secondaryBtnBg: "FFFFFF",
    secondaryBtnText: "374151",
    fontFamily: "Segoe UI",
    fontSizeTitle: 11,
    fontSizeBody: 10,
    fontSizeSmall: 9,
    contentWidth: 420,
    tabContentWidth: 404,
    tabListWidth: 388,
    marginX: 18,
    marginY: 16,
    btnGap: 6,
    btnHeightSecondary: 26,
    btnHeightTool: 28,
    btnHeightPrimary: 44,
    infoBtnSize: 14,
    infoBtnFontSize: 7,
    infoBtnBg: "EEF2FF",
    listRecordingH: 148,
    listPresetH: 64,
    tabStripHeight: 36,
    tabInnerPad: 52,
    tabRowGap: 8,
    tabLabelHeight: 16,
    tabPanelSafetyPad: 12,
    recordingColName: "Name",
    recordingColVarCount: "Variable count",
    statusHeight: 30,
    csvEditWidth: 300,
    csvBatchConfigBtnWidth: 52,
    csvBatchTableWidth: 560,
    csvBatchTableHeight: 240,
    csvBatchPromptWidth: 400,
    csvBatchPromptBtnWidth: 118
}

CSV_BATCH_PROGRESS_COLUMNS := ["Row", "Var1", "Var2", "Var3", "Var4", "Var5", "Status"]

; Main window title — must match CreateManageGui; used for #SingleInstance rediscovery.
APP_GUI_TITLE := "Data Entry Autonoma v" C.appVersion

; =============================================================================
; State
; =============================================================================

S := {
    recording: false,
    applying: false,
    batchRunning: false,
    stopBatch: false,
    csvAskNextLine: false,
    csvPromptChoice: "",

    filePath: "",
    logFile: "",
    editingLogPath: "",
    logEditorGui: "",
    startedAt: 0,
    hasOrigin: false,
    originX: 0,
    originY: 0,
    lastTargetX: 0,
    lastTargetY: 0,
    shiftDelayHeld: false,
    shiftDelayStartedAt: 0,
    waitingForKey: false,
    keyIndex: 0,

    variables: [],
    playbackSpeed: C.defaultPlaybackSpeed,
    typingSpeed: C.defaultTypingSpeed,
    moveSpeed: C.defaultMoveSpeed,
    initialDelayMs: C.defaultInitialDelayMs,
    clickPauseMs: C.defaultClickPauseMs,
    segmentPauseMs: C.defaultSegmentPauseMs,
    useRecordedTiming: C.defaultUseRecordedTiming,
    smoothMouse: C.defaultSmoothMouse,
    humanTyping: C.defaultHumanTyping,
    virtualBounds: "",

    mouseHook: 0,
    keyboardHook: 0,
    mouseCallback: 0,
    keyboardCallback: 0,
    mouseBlockHook: 0,
    mouseBlockCallback: 0,

    gui: "",
    statusCtrl: "",
    sessionCtrl: "",
    recordingList: "",
    recordingPaths: [],
    presetList: "",
    presetPaths: [],
    csvEdit: "",
    detectButton: "",
    applyButton: "",
    refreshButton: "",
    editButton: "",
    browseCsvButton: "",
    csvBatchInfoButton: "",
    csvBatchConfigButton: "",
    csvBatchRunAllRemaining: false,
    csvBatchTableGui: "",
    csvBatchTableLv: "",
    csvBatchPromptGui: "",
    renameRecordingButton: "",
    editRecordingButton: "",
    deleteRecordingButton: "",
    deletePresetButton: "",
    smoothMouseRadio: "",
    instantMouseRadio: "",
    humanTypingRadio: "",
    instantTypingRadio: "",
    mainTab: ""
}

ActivateExistingManageInstance()
ApplyManageStartupIcon()

CreateManageGui()
EnsureDir(C.savesDir)
EnsureDir(C.recordingsDir)
OnExit (*) => Cleanup()

#HotIf IsRecording()
Esc::SaveRecording()
#HotIf

#HotIf IsApplying() || IsBatchRunning()
Esc::RequestStop()
#HotIf


; =============================================================================
; GUI
; =============================================================================

/**
 * Applies the manage-window theme (background, font, margins).
 * @param {Gui} gui Target window.
 */
ApplyManageGuiTheme(gui) {
    global UI

    gui.BackColor := UI.bg
    gui.SetFont("s" UI.fontSizeBody, UI.fontFamily)
    gui.MarginX := UI.marginX
    gui.MarginY := UI.marginY
    ApplyManageAppIcon(gui)
}

/**
 * Sets the script tray icon before any GUI windows are created.
 */
ApplyManageStartupIcon() {
    global C

    if FileExist(C.appIconFile)
        TraySetIcon(C.appIconFile, , true)
}

/**
 * Sets the window/taskbar icon when the bundled ICO is present.
 * @param {Gui} gui Target window.
 */
ApplyManageAppIcon(gui) {
    global C

    if !gui || !FileExist(C.appIconFile)
        return

    smallIcon := LoadPicture(C.appIconFile, "Icon1 w16 h16", &iconType)
    if smallIcon
        SendMessage(C.WM_SETICON, C.ICON_SMALL, smallIcon, gui)

    largeIcon := LoadPicture(C.appIconFile, "Icon1 w32 h32", &iconType)
    if largeIcon
        SendMessage(C.WM_SETICON, C.ICON_BIG, largeIcon, gui)
}

/**
 * Styles a tiny circular info button beside inline labels.
 * @param {Gui.Button} btn Info button control.
 */
ApplyManageCircularInfoButton(btn) {
    global UI

    if !btn
        return

    btn.SetFont("s" UI.infoBtnFontSize " bold", UI.fontFamily)
    btn.Opt("+Background" UI.infoBtnBg " c" UI.accent)

    size := UI.infoBtnSize
    region := DllCall("CreateEllipticRgn", "Int", 0, "Int", 0, "Int", size, "Int", size, "Ptr")
    if region
        DllCall("SetWindowRgn", "Ptr", btn.Hwnd, "Ptr", region, "Int", true)
}

/**
 * Adds a muted section header label.
 * @param {Gui} gui Target window.
 * @param {String} title Section title text.
 * @returns {Gui.Text} Created text control.
 */
BuildManageSectionHeader(gui, title) {
    global UI

    gui.SetFont("s" UI.fontSizeSmall " bold", UI.fontFamily)
    header := gui.Add("Text", "xm w" UI.contentWidth " c" UI.textMuted, title)
    gui.SetFont("s" UI.fontSizeBody, UI.fontFamily)
    return header
}

/**
 * Width for three equal buttons in one row (tab list width minus gaps).
 * @returns {Integer}
 */
GetManageThreeButtonWidth() {
    global UI
    return Floor((UI.tabListWidth - UI.btnGap * 2) / 3)
}

/**
 * Width for two equal primary action buttons (full content width minus gap).
 * @returns {Integer}
 */
GetManagePrimaryButtonWidth() {
    global UI
    return Floor((UI.contentWidth - UI.btnGap) / 2)
}

/**
 * Returns Tab3 height (tab strip + tallest page content) so nothing is clipped.
 * @returns {Integer}
 */
GetManageTabPanelHeight() {
    global UI

    recordingTab := UI.listRecordingH + UI.tabRowGap + UI.btnHeightSecondary
    presetTab := UI.listPresetH + UI.tabRowGap + UI.tabLabelHeight + UI.tabRowGap + UI.btnHeightTool
        + UI.tabRowGap + UI.btnHeightTool
    playbackTab := (UI.tabLabelHeight + UI.tabRowGap + 24) * 2 + UI.tabRowGap + 36

    return UI.tabStripHeight + UI.tabInnerPad + Max(recordingTab, presetTab, playbackTab) + UI.tabPanelSafetyPad
}

/**
 * Builds the unified Record + Run window.
 */
CreateManageGui() {
    global C, S, UI

    threeBtnW := GetManageThreeButtonWidth()
    primaryBtnW := GetManagePrimaryButtonWidth()
    btnGap := UI.btnGap
    hSec := UI.btnHeightSecondary
    hTool := UI.btnHeightTool
    hPrimary := UI.btnHeightPrimary

    S.gui := Gui("+AlwaysOnTop -MaximizeBox", APP_GUI_TITLE)
    ApplyManageGuiTheme(S.gui)
    S.gui.OnEvent("Close", GuiClosed)

    S.gui.SetFont("s" UI.fontSizeTitle, UI.fontFamily)
    S.gui.Add("Text", "xm w" UI.contentWidth " c" UI.textPrimary, "Data Entry Autonoma")
    S.gui.SetFont("s" UI.fontSizeBody, UI.fontFamily)
    S.gui.Add(
        "Text",
        "xm w" UI.contentWidth " c" UI.textMuted,
        "Record once. Run with presets or CSV batches.  v" C.appVersion
    )

    S.statusCtrl := S.gui.Add(
        "Edit",
        "xm w" UI.contentWidth " h" UI.statusHeight " ReadOnly -TabStop +Background" UI.statusBg " c" UI.statusText,
        "Ready"
    )
    S.gui.SetFont("s" UI.fontSizeSmall, UI.fontFamily)
    S.sessionCtrl := S.gui.Add("Text", "xm w" UI.contentWidth " c" UI.sessionText, "Recording: —")
    S.gui.SetFont("s" UI.fontSizeBody, UI.fontFamily)

    S.mainTab := S.gui.Add(
        "Tab3",
        "xm w" UI.contentWidth " h" GetManageTabPanelHeight(),
        ["Recordings", "Input Presets", "Run Options"]
    )

    ; --- Recording tab ---
    S.mainTab.UseTab(1)
    S.recordingList := S.gui.Add(
        "ListView",
        "Section w" UI.tabListWidth " h" UI.listRecordingH " -Multi +Background" UI.listBg,
        [UI.recordingColName, UI.recordingColVarCount]
    )
    S.recordingList.OnEvent("ItemSelect", (*) => (RememberSelections(), UpdateSelectionStatus()))
    S.recordingList.ModifyCol(2, "Integer")

    S.renameRecordingButton := S.gui.Add(
        "Button",
        "xs w" threeBtnW " h" hSec " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Rename"
    )
    S.renameRecordingButton.OnEvent("Click", RenameSelectedRecording)

    S.editRecordingButton := S.gui.Add(
        "Button",
        "x+" btnGap " w" threeBtnW " h" hSec " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Edit Log"
    )
    S.editRecordingButton.OnEvent("Click", ShowRecordingLogEditor)

    S.deleteRecordingButton := S.gui.Add(
        "Button",
        "x+" btnGap " w" threeBtnW " h" hSec " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Delete"
    )
    S.deleteRecordingButton.OnEvent("Click", DeleteSelectedRecording)

    ; --- Input Presets tab ---
    S.mainTab.UseTab(2)
    S.presetList := S.gui.Add(
        "ListBox",
        "Section w" UI.tabListWidth " h" UI.listPresetH " +Background" UI.listBg
    )
    S.presetList.OnEvent("Change", (*) => (
        RememberSelections(),
        LoadSelectedPresetPlaybackOptions(),
        UpdateSelectionStatus()
    ))

    S.gui.SetFont("s" UI.fontSizeSmall, UI.fontFamily)
    S.gui.Add("Text", "xs c" UI.textMuted, "CSV batch (optional)")
    S.csvBatchInfoButton := S.gui.Add(
        "Button",
        "x+2 w" UI.infoBtnSize " h" UI.infoBtnSize " -Theme +Background" UI.infoBtnBg " c" UI.accent,
        "i"
    )
    S.csvBatchInfoButton.OnEvent("Click", ShowCsvBatchHelp)
    ApplyManageCircularInfoButton(S.csvBatchInfoButton)
    S.csvBatchConfigButton := S.gui.Add(
        "Button",
        "x+" UI.btnGap " w" UI.csvBatchConfigBtnWidth " h" UI.infoBtnSize
        " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Config"
    )
    S.csvBatchConfigButton.OnEvent("Click", ShowCsvBatchConfig)
    S.gui.SetFont("s" UI.fontSizeBody, UI.fontFamily)
    S.csvEdit := S.gui.Add("Edit", "xs w" UI.csvEditWidth " +Background" UI.editBg, "")
    S.browseCsvButton := S.gui.Add(
        "Button",
        "x+" btnGap " w" (UI.tabListWidth - UI.csvEditWidth - btnGap) " h" hTool
        " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Browse..."
    )
    S.browseCsvButton.OnEvent("Click", BrowseCsvFile)

    S.refreshButton := S.gui.Add(
        "Button",
        "xs w" threeBtnW " h" hTool " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Refresh"
    )
    S.refreshButton.OnEvent("Click", (*) => RefreshAllLists(true))

    S.editButton := S.gui.Add(
        "Button",
        "x+" btnGap " w" threeBtnW " h" hTool " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Edit Preset"
    )
    S.editButton.OnEvent("Click", ShowPresetEditor)

    S.deletePresetButton := S.gui.Add(
        "Button",
        "x+" btnGap " w" threeBtnW " h" hTool " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Delete Preset"
    )
    S.deletePresetButton.OnEvent("Click", DeleteSelectedPreset)

    ; --- Run Options tab ---
    S.mainTab.UseTab(3)
    S.gui.SetFont("s" UI.fontSizeSmall, UI.fontFamily)
    S.gui.Add("Text", "Section w" UI.tabListWidth " c" UI.textMuted, "Mouse movement")
    S.smoothMouseRadio := S.gui.Add(
        "Radio",
        "xs" (C.defaultSmoothMouse ? " Checked" : ""),
        "Smooth"
    )
    S.instantMouseRadio := S.gui.Add(
        "Radio",
        "x+16" (!C.defaultSmoothMouse ? " Checked" : ""),
        "Instant"
    )
    S.gui.Add("Text", "xs w" UI.tabListWidth " c" UI.textMuted, "Typing")
    S.humanTypingRadio := S.gui.Add(
        "Radio",
        "xs" (C.defaultHumanTyping ? " Checked" : ""),
        "Human-like"
    )
    S.instantTypingRadio := S.gui.Add(
        "Radio",
        "x+16" (!C.defaultHumanTyping ? " Checked" : ""),
        "Instant"
    )
    S.gui.SetFont("s" UI.fontSizeBody, UI.fontFamily)

    S.mainTab.UseTab()

    S.gui.Add("Text", "xm w" UI.contentWidth " h4", "")

    S.detectButton := S.gui.Add(
        "Button",
        "xm w" primaryBtnW " h" hPrimary " +Background" UI.detectBg " c" UI.detectText,
        "Record"
    )
    S.detectButton.OnEvent("Click", (*) => StartRecording())

    S.applyButton := S.gui.Add(
        "Button",
        "x+" btnGap " w" primaryBtnW " h" hPrimary " Default +Background" UI.accent " c" UI.accentText,
        "Run"
    )
    S.applyButton.OnEvent("Click", ApplyFromGui)

    S.gui.SetFont("s" UI.fontSizeSmall, UI.fontFamily)
    S.gui.Add(
        "Text",
        "xm w" UI.contentWidth " c" UI.textHint,
        "Record captures clicks, scrolls, and keys. Esc saves (Cancel on the dialog discards). Esc stops Run."
    )

    S.gui.Show()
    ApplyManageAppIcon(S.gui)
    RefreshAllLists(true)
}

GuiClosed(*) {
    global S

    if S.recording
        CancelRecording()
    else if S.applying || S.batchRunning
        RequestStop()
    else
        ExitApp()
}

/**
 * Enables or disables interactive controls while recording or applying.
 * @param {Boolean} enabled Whether controls should accept input.
 */
SetInteractiveState(enabled) {
    global S

    for ctrl in [S.detectButton, S.applyButton, S.refreshButton, S.editButton,
        S.renameRecordingButton, S.editRecordingButton, S.deleteRecordingButton,
        S.deletePresetButton, S.recordingList, S.presetList, S.csvEdit, S.browseCsvButton,
        S.csvBatchInfoButton, S.csvBatchConfigButton, S.smoothMouseRadio, S.instantMouseRadio, S.humanTypingRadio, S.instantTypingRadio,
        S.mainTab] {
        if ctrl
            ctrl.Enabled := enabled
    }
}

/**
 * Sets playback option radio buttons on the main window.
 * @param {Boolean} smoothMouse Whether smooth mouse movement is selected.
 * @param {Boolean} humanTyping Whether human-like typing is selected.
 */
SetPlaybackOptionRadios(smoothMouse, humanTyping) {
    global S

    if S.smoothMouseRadio {
        S.smoothMouseRadio.Value := smoothMouse ? 1 : 0
        S.instantMouseRadio.Value := smoothMouse ? 0 : 1
    }

    if S.humanTypingRadio {
        S.humanTypingRadio.Value := humanTyping ? 1 : 0
        S.instantTypingRadio.Value := humanTyping ? 0 : 1
    }
}

/**
 * Reads playback option radio buttons from the main window.
 * @returns {{smooth_mouse: Boolean, human_typing: Boolean}}
 */
ReadPlaybackOptionsFromGui() {
    global C, S

    return {
        smooth_mouse: S.smoothMouseRadio ? S.smoothMouseRadio.Value = 1 : C.defaultSmoothMouse,
        human_typing: S.humanTypingRadio ? S.humanTypingRadio.Value = 1 : C.defaultHumanTyping
    }
}

/**
 * Copies main-window playback option radios into session state.
 */
SyncPlaybackOptionsFromGui() {
    global S

    opts := ReadPlaybackOptionsFromGui()
    S.smoothMouse := opts.smooth_mouse
    S.humanTyping := opts.human_typing
}

/**
 * Loads playback options from the selected preset into radios and session state.
 */
LoadSelectedPresetPlaybackOptions() {
    global C, S

    presetPath := GetSelectedPresetPath()

    if presetPath != "" && FileExist(presetPath) {
        settings := ParsePresetFile(presetPath)
        SetPlaybackOptionRadios(settings.smooth_mouse, settings.human_typing)
        S.smoothMouse := settings.smooth_mouse
        S.humanTyping := settings.human_typing
        return
    }

    SetPlaybackOptionRadios(C.defaultSmoothMouse, C.defaultHumanTyping)
    S.smoothMouse := C.defaultSmoothMouse
    S.humanTyping := C.defaultHumanTyping
}

SetRecordingGuiState(recording) {
    global S

    SetInteractiveState(!recording)

    if S.detectButton
        S.detectButton.Enabled := !recording

    if S.sessionCtrl {
        S.sessionCtrl.Text := recording
            ? "Recording: " DisplayName(S.filePath)
            : "Recording: —"
    }

    SetStatus(recording ? "Recording..." : "Ready")
}

SetApplyGuiState(running) {
    global S
    SetInteractiveState(!running)
}

/**
 * Updates the highlighted status field.
 * @param {String} message Status text shown in the status bar.
 */
SetStatus(message) {
    global S

    if S.statusCtrl
        S.statusCtrl.Text := message
}

ClearTip(*) {
    ToolTip
}

/**
 * Shows a tooltip beside the current cursor position.
 * @param {String} message Tooltip text.
 */
ShowCursorToolTip(message) {
    global C

    MouseGetPos(&cursorX, &cursorY)
    ToolTip message, cursorX + C.cursorTipOffsetX, cursorY + C.cursorTipOffsetY
}

/**
 * Shows the persistent recording tooltip in a fixed screen corner.
 */
ShowRecordingTip() {
    global C

    ToolTip C.recordingTipText, A_ScreenWidth - C.recordingTipOffsetX, C.recordingTipOffsetY
}

/**
 * Hides the recording tooltip and stops refresh timers.
 */
HideRecordingTip() {
    SetTimer MaintainRecordingTip, 0
    SetTimer RestoreRecordingTip, 0
    SetTimer RefreshRecordingShiftDelayTip, 0
    ToolTip
}

/**
 * Keeps the recording tooltip visible while Detect mode is active.
 */
MaintainRecordingTip(*) {
    if IsRecording()
        ShowRecordingTip()
}

/**
 * Restores the persistent recording tooltip after a short transient message.
 */
RestoreRecordingTip(*) {
    if IsRecording()
        ShowRecordingTip()
    else
        ToolTip
}

/**
 * Shows a temporary recording message, then restores the Esc tip.
 * @param {String} message Short status message.
 * @param {Integer} screenX Optional screen X for cursor-adjacent placement.
 * @param {Integer} screenY Optional screen Y for cursor-adjacent placement.
 */
ShowTransientRecordingTip(message, screenX := "", screenY := "") {
    global C

    if screenX != "" && screenY != ""
        ToolTip message, screenX + C.cursorTipOffsetX, screenY + C.cursorTipOffsetY
    else
        ToolTip message

    SetTimer RestoreRecordingTip, -C.recordingTransientTipMs
}

/**
 * Shows a short tooltip when a variable slot is assigned during Detect or Apply.
 * @param {String} variableName Variable identifier such as variable-1.
 * @param {Integer} screenX Target screen X coordinate for tooltip placement.
 * @param {Integer} screenY Target screen Y coordinate for tooltip placement.
 */
ShowVariableAssignmentTip(variableName, screenX, screenY) {
    global C

    if !RegExMatch(variableName, "i)^variable-?(\d+)$", &match)
        return

    ToolTip Format("Assigned Var {1}", match[1]), screenX + C.cursorTipOffsetX, screenY + C.cursorTipOffsetY
    if IsRecording()
        SetTimer RestoreRecordingTip, -C.variableTipMs
    else
        SetTimer ClearTip, -C.variableTipMs
}

/**
 * Marks the main GUI as owner for system dialogs on this thread.
 * AHK v2: +OwnDialogs keeps MsgBox, InputBox, and FileSelect modal and above the GUI.
 */
EnsureManageOwnDialogs() {
    global S

    if S.gui
        S.gui.Opt("+OwnDialogs")
}

/**
 * Shows a MsgBox owned by the main GUI so it stays on top.
 * @param {String} message Dialog body text.
 * @param {String} title Window title.
 * @param {String} options MsgBox option string.
 * @returns {String} Name of the button pressed.
 */
ShowManageMsgBox(message, title := APP_GUI_TITLE, options := "Icon!") {
    EnsureManageOwnDialogs()
    return MsgBox(message, title, options)
}

/**
 * Shows an InputBox owned by the main GUI.
 * @param {String} prompt Field label text.
 * @param {String} title Window title.
 * @param {String} options InputBox option string.
 * @param {String} defaultText Initial edit value.
 * @returns {Object} InputBox result object.
 */
ShowManageInputBox(prompt, title, options := "", defaultText := "") {
    global S

    EnsureManageOwnDialogs()
    if S.gui
        S.gui.Show()
    return InputBox(prompt, title, options, defaultText)
}

/**
 * Shows a FileSelect dialog owned by the main GUI.
 * @param {String} options FileSelect option string.
 * @param {String} initialDir Starting directory or file path.
 * @param {String} prompt Dialog title text.
 * @param {String} filter File-type filter string.
 * @returns {String} Selected path, or empty string if cancelled.
 */
ShowManageFileSelect(options, initialDir := "", prompt := "", filter := "") {
    EnsureManageOwnDialogs()
    return FileSelect(options, initialDir, prompt, filter)
}

/**
 * Binds a child GUI to the main window with +Owner and +AlwaysOnTop.
 * AHK v2: owned windows stay above their owner; +AlwaysOnTop keeps them above other apps.
 * @param {Gui} childGui Child dialog window.
 */
BindManageChildGui(childGui) {
    global S

    childGui.Opt("+AlwaysOnTop")
    ApplyManageAppIcon(childGui)
    if S.gui
        childGui.Opt("+Owner" S.gui.Hwnd)
}

BrowseCsvFile(*) {
    global S

    selected := ShowManageFileSelect("1", S.csvEdit.Value, "Select CSV batch file", "CSV (*.csv;*.txt)")

    if selected = ""
        return

    S.csvEdit.Value := selected
    RememberSelections()
    UpdateSelectionStatus()
}

/**
 * Shows CSV batch format and usage help.
 */
ShowCsvBatchHelp(*) {
    global C

    ShowManageMsgBox C.csvBatchHelpMessage, "CSV batch help", "Iconi"
}

/**
 * Opens CSV batch settings (Ask to run next line).
 */
ShowCsvBatchConfig(*) {
    global S, C, UI

    dlgWidth := 360
    btnW := Floor((dlgWidth - UI.btnGap) / 2)
    btnH := UI.btnHeightSecondary
    savedAsk := S.csvAskNextLine

    dlg := Gui(
        "+ToolWindow -MaximizeBox -MinimizeBox",
        C.csvBatchConfigTitle
    )
    BindManageChildGui(dlg)
    dlg.BackColor := UI.surface
    dlg.SetFont("s" UI.fontSizeBody, UI.fontFamily)
    dlg.MarginX := UI.marginX
    dlg.MarginY := UI.marginY

    askChk := dlg.Add(
        "Checkbox",
        "xm w" dlgWidth " c" UI.textPrimary,
        C.csvAskNextLineLabel
    )
    askChk.Value := savedAsk ? 1 : 0

    okBtn := dlg.Add(
        "Button",
        "xm w" btnW " h" btnH " Default +Background" UI.accent " c" UI.accentText,
        "OK"
    )
    cancelBtn := dlg.Add(
        "Button",
        "x+" UI.btnGap " w" btnW " h" btnH " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Cancel"
    )

    SaveCsvConfig(*) {
        S.csvAskNextLine := askChk.Value ? true : false
        RememberSelections()
        dlg.Destroy()
    }

    CancelCsvConfig(*) {
        S.csvAskNextLine := savedAsk
        dlg.Destroy()
    }

    okBtn.OnEvent("Click", SaveCsvConfig)
    cancelBtn.OnEvent("Click", CancelCsvConfig)
    dlg.OnEvent("Close", CancelCsvConfig)
    dlg.OnEvent("Escape", CancelCsvConfig)

    dlg.Show("Center")
    WinWaitClose("ahk_id " dlg.Hwnd)
}

/**
 * Returns up to five display strings for a CSV row's variables.
 * @param {Object} row Parsed CSV row.
 * @returns {Array<String>}
 */
GetCsvRowDisplayVars(row) {
    global C

    vars := []
    Loop C.csvBatchVarDisplayCount {
        idx := A_Index
        vars.Push(idx <= row.variables.Length ? row.variables[idx] : "")
    }
    return vars
}

/**
 * Creates the always-on-top CSV batch progress table listing all rows.
 * @param {Array<Object>} rows Parsed CSV rows.
 */
ShowCsvBatchProgressTable(rows) {
    global S, C, UI, CSV_BATCH_PROGRESS_COLUMNS

    CloseCsvBatchProgressTable()

    tableGui := Gui(
        "+AlwaysOnTop +ToolWindow -MaximizeBox -MinimizeBox",
        C.csvBatchProgressTitle
    )
    ApplyManageAppIcon(tableGui)
    tableGui.BackColor := UI.bg
    tableGui.SetFont("s" UI.fontSizeBody, UI.fontFamily)
    tableGui.MarginX := UI.marginX
    tableGui.MarginY := UI.marginY

    tableLv := tableGui.Add(
        "ListView",
        "xm w" UI.csvBatchTableWidth " h" UI.csvBatchTableHeight " -Multi +Background" UI.listBg,
        CSV_BATCH_PROGRESS_COLUMNS
    )

    Loop rows.Length {
        row := rows[A_Index]
        displayVars := GetCsvRowDisplayVars(row)
        tableLv.Add(
            "",
            A_Index,
            displayVars[1],
            displayVars[2],
            displayVars[3],
            displayVars[4],
            displayVars[5],
            C.csvBatchStatusPending
        )
    }

    tableLv.ModifyCol(1, 40)
    tableLv.ModifyCol(7, 64)

    S.csvBatchTableGui := tableGui
    S.csvBatchTableLv := tableLv
    tableGui.Show("x24 y80 w" UI.csvBatchTableWidth)
}

/**
 * Updates one row's Status column in the batch progress table.
 * @param {Integer} rowIndex One-based row index in the table.
 * @param {String} status Status text to display.
 */
SetCsvBatchProgressRowStatus(rowIndex, status) {
    global S

    if S.csvBatchTableLv
        S.csvBatchTableLv.Modify(rowIndex, "Col7", status)
}

/**
 * Destroys the CSV batch progress table window.
 */
CloseCsvBatchProgressTable() {
    global S

    if S.csvBatchTableGui {
        try S.csvBatchTableGui.Destroy()
        S.csvBatchTableGui := ""
    }
    S.csvBatchTableLv := ""
}

/**
 * Sets the user's choice on the CSV batch row prompt.
 * @param {String} choice One of the C.csvBatchPromptChoice* constants.
 */
SetCsvBatchPromptChoice(choice, *) {
    global S

    S.csvPromptChoice := choice
}

/**
 * Polls until the user selects a row prompt action or stops the batch.
 * @returns {String} Prompt choice, or C.csvBatchPromptChoiceNone when stopped.
 */
WaitForCsvBatchPromptChoice() {
    global C, S

    while S.csvPromptChoice = C.csvBatchPromptChoiceNone && !S.stopBatch
        Sleep C.csvBatchPromptPollMs

    return S.stopBatch ? C.csvBatchPromptChoiceNone : S.csvPromptChoice
}

/**
 * Shows the per-row CSV batch prompt and waits for Run, Skip, or Run all remaining.
 * @param {Integer} rowIndex One-based row index.
 * @param {Object} row Parsed CSV row.
 * @param {Integer} totalRows Total row count in the batch.
 * @returns {String} Prompt choice constant from C.csvBatchPromptChoice*.
 */
WaitCsvBatchRowPrompt(rowIndex, row, totalRows) {
    global S, C, UI

    CloseCsvBatchRowPrompt()
    S.csvPromptChoice := C.csvBatchPromptChoiceNone

    dlgWidth := UI.csvBatchPromptWidth
    btnW := UI.csvBatchPromptBtnWidth
    btnH := UI.btnHeightSecondary
    displayVars := GetCsvRowDisplayVars(row)

    promptGui := Gui(
        "+AlwaysOnTop +ToolWindow -MaximizeBox -MinimizeBox",
        Format("CSV row {}/{}", rowIndex, totalRows)
    )
    ApplyManageAppIcon(promptGui)
    promptGui.BackColor := UI.surface
    promptGui.SetFont("s" UI.fontSizeBody, UI.fontFamily)
    promptGui.MarginX := UI.marginX
    promptGui.MarginY := UI.marginY

    promptGui.Add(
        "Text",
        "xm w" dlgWidth " c" UI.textPrimary,
        Format("Row label: {1}", row.label)
    )

    Loop C.csvBatchVarDisplayCount {
        idx := A_Index
        if displayVars[idx] != ""
            promptGui.Add(
                "Text",
                "xm w" dlgWidth " c" UI.textMuted,
                Format("Var{1}: {2}", idx, displayVars[idx])
            )
    }

    runBtn := promptGui.Add(
        "Button",
        "xm w" btnW " h" btnH " Default +Background" UI.accent " c" UI.accentText,
        C.csvBatchPromptRun
    )
    skipBtn := promptGui.Add(
        "Button",
        "x+" UI.btnGap " w" btnW " h" btnH " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        C.csvBatchPromptSkip
    )
    runAllBtn := promptGui.Add(
        "Button",
        "xm w" dlgWidth " h" btnH " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        C.csvBatchPromptRunAll
    )

    runBtn.OnEvent("Click", SetCsvBatchPromptChoice.Bind(C.csvBatchPromptChoiceRun))
    skipBtn.OnEvent("Click", SetCsvBatchPromptChoice.Bind(C.csvBatchPromptChoiceSkip))
    runAllBtn.OnEvent("Click", SetCsvBatchPromptChoice.Bind(C.csvBatchPromptChoiceRunAll))
    promptGui.OnEvent("Close", SetCsvBatchPromptChoice.Bind(C.csvBatchPromptChoiceSkip))
    promptGui.OnEvent("Escape", SetCsvBatchPromptChoice.Bind(C.csvBatchPromptChoiceSkip))

    S.csvBatchPromptGui := promptGui

    if S.csvBatchTableLv
        S.csvBatchTableLv.Modify(rowIndex, "Select Focus")

    promptX := 24 + UI.csvBatchTableWidth + 12
    promptGui.Show("x" promptX " y80 w" UI.csvBatchPromptWidth)

    return WaitForCsvBatchPromptChoice()
}

/**
 * Destroys the CSV batch row prompt window.
 */
CloseCsvBatchRowPrompt() {
    global S, C

    if S.csvBatchPromptGui {
        try S.csvBatchPromptGui.Destroy()
        S.csvBatchPromptGui := ""
    }
    S.csvPromptChoice := C.csvBatchPromptChoiceNone
}

RefreshAllLists(restore := false) {
    RefreshRecordingList()
    RefreshPresetList()

    if restore
        RestoreSelections()

    UpdateSelectionStatus()
}

RefreshRecordingList() {
    global C, S

    S.recordingPaths := ListFiles(C.recordingsDir, C.diPrefix "*.log")

    if !S.recordingList
        return

    S.recordingList.Delete()

    for path in S.recordingPaths {
        S.recordingList.Add(
            "",
            FormatRecordingName(path),
            CountRecordingVariableSlots(path)
        )
    }

    if S.recordingPaths.Length {
        S.recordingList.ModifyCol(1, "AutoHdr")
        S.recordingList.ModifyCol(2, "AutoHdr")
    }
}

RefreshPresetList() {
    global C, S

    EnsureDir(C.savesDir)
    S.presetPaths := ListFiles(C.savesDir, "*" C.saveExt)
    names := []

    for path in S.presetPaths
        names.Push(FormatPresetName(path))

    if S.presetList {
        S.presetList.Delete()
        if names.Length
            S.presetList.Add(names)
    }
}

RestoreSelections() {
    global S

    saved := LoadManageState()

    if S.recordingPaths.Length {
        SelectByBaseName(S.recordingList, S.recordingPaths, saved.recording)
        if !GetListControlSelectedIndex(S.recordingList)
            SelectListControlRow(S.recordingList, 1)
    }

    if S.presetPaths.Length {
        SelectByBaseName(S.presetList, S.presetPaths, saved.preset)
        if !S.presetList.Value
            S.presetList.Value := 1
    }

    LoadSelectedPresetPlaybackOptions()

    if S.csvEdit
        S.csvEdit.Value := saved.csv

    S.csvAskNextLine := saved.csvAskNextLine
}

UpdateSelectionStatus() {
    global S

    recording := GetSelectedRecordingPath()
    preset := GetSelectedPresetPath()
    csvPath := Trim(S.csvEdit ? S.csvEdit.Value : "")

    if recording = "" {
        SetStatus("Select a recording first.")
        return
    }

    if csvPath != "" {
        if FileExist(csvPath)
            SetStatus("Ready — " FormatRecordingName(recording) " with CSV batch")
        else
            SetStatus("CSV file not found — " csvPath)
        return
    }

    if preset = "" {
        SetStatus("Select a preset or choose a CSV batch file.")
        return
    }

    SetStatus("Ready — " FormatRecordingName(recording) " with " FormatPresetName(preset))
}

RememberSelections() {
    global S

    SaveManageState(
        GetSelectedPresetPath() ? FileBaseName(GetSelectedPresetPath()) : "",
        GetSelectedRecordingPath() ? FileBaseName(GetSelectedRecordingPath()) : "",
        Trim(S.csvEdit ? S.csvEdit.Value : ""),
        S.csvAskNextLine
    )
}

GetSelectedRecordingPath() {
    global S

    index := GetListControlSelectedIndex(S.recordingList)
    return index && index <= S.recordingPaths.Length ? S.recordingPaths[index] : ""
}

GetSelectedPresetPath() {
    global S

    index := S.presetList ? S.presetList.Value : 0
    return index && index <= S.presetPaths.Length ? S.presetPaths[index] : ""
}

GetSelectedCsvPath() {
    global S
    return Trim(S.csvEdit ? S.csvEdit.Value : "")
}

ApplyFromGui(*) {
    logPath := GetSelectedRecordingPath()
    presetPath := GetSelectedPresetPath()
    csvPath := GetSelectedCsvPath()

    if logPath = "" {
        SetStatus("Select a recording first.")
        return
    }

    RememberSelections()

    if csvPath != "" {
        if !FileExist(csvPath) {
            SetStatus("CSV file not found.")
            ShowManageMsgBox "CSV file not found:`n" csvPath, "Data Entry Autonoma", "Icon!"
            return
        }

        SetStatus("Running CSV batch...")
        SetTimer (ApplyBatchTimer).Bind(logPath, csvPath, presetPath), -1
        return
    }

    if presetPath = "" {
        SetStatus("Select a preset or choose a CSV batch file.")
        return
    }

    SetStatus("Running...")
    SetTimer (ApplySingleTimer).Bind(logPath, presetPath), -1
}

/**
 * Timer wrapper for single preset apply.
 * @param {String} logPath Recording path.
 * @param {String} presetPath Preset path.
 */
ApplySingleTimer(logPath, presetPath, *) {
    try {
        RunApply(logPath, presetPath)
    } catch as err {
        SetStatus("Run error.")
        ShowManageMsgBox "Run failed:`n" err.Message, "Data Entry Autonoma", "Icon!"
    }
}

/**
 * Timer wrapper for CSV batch apply.
 * @param {String} logPath Recording path.
 * @param {String} csvPath CSV batch path.
 * @param {String} presetPath Optional preset for speed settings only.
 */
ApplyBatchTimer(logPath, csvPath, presetPath, *) {
    try {
        RunApplyBatch(logPath, csvPath, presetPath)
    } catch as err {
        SetStatus("Batch run error.")
        ShowManageMsgBox "Batch run failed:`n" err.Message, "Data Entry Autonoma", "Icon!"
    }
}

/**
 * Shows a modal, always-on-top Yes/No dialog for permanent delete confirmation.
 * @param {String} itemLabel Human-readable item name.
 * @param {String} itemKind Short noun such as "recording" or "preset".
 * @returns {Boolean} True when the user confirms deletion.
 */
ConfirmDeleteItem(itemLabel, itemKind) {
    global S, UI

    confirmed := false
    dlgWidth := 360
    btnW := Floor((dlgWidth - UI.btnGap) / 2)
    btnH := UI.btnHeightSecondary

    dlg := Gui(
        "+ToolWindow -MaximizeBox -MinimizeBox",
        Format("Delete {1}", itemKind)
    )
    BindManageChildGui(dlg)
    dlg.BackColor := UI.surface
    dlg.SetFont("s" UI.fontSizeBody, UI.fontFamily)
    dlg.MarginX := UI.marginX
    dlg.MarginY := UI.marginY

    dlg.Add(
        "Text",
        "xm w" dlgWidth " c" UI.textPrimary,
        Format('Delete {1} "{2}"?', itemKind, itemLabel)
    )
    dlg.Add("Text", "xm w" dlgWidth " c" UI.textMuted, "This removes the file permanently.")

    yesBtn := dlg.Add(
        "Button",
        "xm w" btnW " h" btnH " Default +Background" UI.accent " c" UI.accentText,
        "Yes"
    )
    noBtn := dlg.Add(
        "Button",
        "x+" UI.btnGap " w" btnW " h" btnH " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "No"
    )

    ConfirmYes(*) {
        confirmed := true
        dlg.Destroy()
    }

    ConfirmNo(*) {
        confirmed := false
        dlg.Destroy()
    }

    yesBtn.OnEvent("Click", ConfirmYes)
    noBtn.OnEvent("Click", ConfirmNo)
    dlg.OnEvent("Close", ConfirmNo)
    dlg.OnEvent("Escape", ConfirmNo)

    dlg.Show("Center")
    WinWaitClose("ahk_id " dlg.Hwnd)
    return confirmed
}

/**
 * Clears a persisted selection key when it matches a deleted file basename.
 * @param {String} stateKey INI key under the last section (preset or recording).
 * @param {String} deletedBaseName Deleted file basename.
 */
ClearManageStateKeyIfMatches(stateKey, deletedBaseName) {
    global C

    if deletedBaseName = ""
        return

    saved := LoadManageState()
    currentValue := stateKey = C.statePresetKey ? saved.preset : saved.recording

    if StrLower(currentValue) = StrLower(deletedBaseName) {
        if stateKey = C.statePresetKey
            SaveManageState("", saved.recording, saved.csv, saved.csvAskNextLine)
        else
            SaveManageState(saved.preset, "", saved.csv, saved.csvAskNextLine)
    }
}

/**
 * Selects the first list row when the control is non-empty.
 * @param {Gui.ListBox|Gui.ListView} listControl Target list control.
 */
SelectFirstListItem(listControl) {
    SelectListControlRow(listControl, 1)
}

/**
 * Returns the selected row index for a ListBox or ListView control.
 * @param {Gui.ListBox|Gui.ListView} listControl Target list control.
 * @returns {Integer} One-based row index, or 0 when nothing is selected.
 */
GetListControlSelectedIndex(listControl) {
    if !listControl
        return 0

    if HasMethod(listControl, "GetNext") {
        focusedRow := listControl.GetNext(0, "F")
        return focusedRow ? focusedRow : listControl.GetNext(0)
    }

    return listControl.Value
}

/**
 * Selects and focuses one row in a ListBox or ListView control.
 * @param {Gui.ListBox|Gui.ListView} listControl Target list control.
 * @param {Integer} rowIndex One-based row index.
 */
SelectListControlRow(listControl, rowIndex) {
    if !listControl || rowIndex < 1
        return

    if HasMethod(listControl, "Modify") {
        listControl.Modify(0, "-Select -Focus")
        listControl.Modify(rowIndex, "Select Focus")
        return
    }

    listControl.Value := rowIndex
}

/**
 * Closes the recording log editor if it is open.
 */
CloseRecordingLogEditor() {
    global S

    if S.logEditorGui {
        try S.logEditorGui.Destroy()
    }

    S.logEditorGui := ""
    S.editingLogPath := ""
}

/**
 * Releases script-held access to a file before delete or rename.
 * @param {String} filePath Absolute or relative file path.
 */
ReleaseManagedFileAccess(filePath) {
    global S

    if filePath = ""
        return

    if S.filePath != "" && StrLower(S.filePath) = StrLower(filePath)
        CloseLogFile()

    if S.editingLogPath != "" && StrLower(S.editingLogPath) = StrLower(filePath)
        CloseRecordingLogEditor()
}

/**
 * Deletes a managed file using AHK v2 file APIs with retries and fallbacks.
 * Clears read-only attributes first, per FileDelete documentation.
 * @param {String} filePath File to delete.
 */
DeleteManagedFile(filePath) {
    global C

    if filePath = ""
        throw Error("No file path provided.")

    if !FileExist(filePath)
        throw Error("File not found.")

    ReleaseManagedFileAccess(filePath)

    try {
        if InStr(FileGetAttrib(filePath), "R")
            FileSetAttrib("-R", filePath)
    } catch {
    }

    lastErrorMessage := ""

    Loop C.fileDeleteAttempts {
        try {
            FileDelete filePath
            return
        } catch as err {
            lastErrorMessage := err.Message
            if !FileExist(filePath)
                return
            Sleep C.fileDeleteRetryMs
        }
    }

    try {
        FileRecycle filePath
        if !FileExist(filePath)
            return
    } catch as err {
        lastErrorMessage := err.Message
    }

    detail := lastErrorMessage != ""
        ? lastErrorMessage
        : "The file may be open in another program or locked by OneDrive."

    throw Error(Format(
        "Could not delete file after {1} attempt(s). {2}",
        C.fileDeleteAttempts,
        detail
    ))
}

/**
 * Deletes the selected recording after confirmation.
 */
DeleteSelectedRecording(*) {
    global C, S

    if S.recording || S.applying || S.batchRunning
        return

    path := GetSelectedRecordingPath()
    if path = "" {
        SetStatus("Select a recording to delete.")
        return
    }

    label := FormatRecordingName(path)
    if !ConfirmDeleteItem(label, "recording")
        return

    deletedBase := FileBaseName(path)

    try {
        DeleteManagedFile(path)
    } catch as err {
        ShowManageMsgBox "Could not delete recording:`n" err.Message, "Delete Recording", "Icon!"
        SetStatus("Could not delete recording.")
        return
    }

    ClearManageStateKeyIfMatches(C.stateRecordingKey, deletedBase)
    RefreshRecordingList()

    if S.recordingPaths.Length
        SelectFirstListItem(S.recordingList)

    RememberSelections()
    UpdateSelectionStatus()
    SetStatus("Deleted recording — " label)
}

/**
 * Deletes the selected input preset after confirmation.
 */
DeleteSelectedPreset(*) {
    global C, S

    if S.recording || S.applying || S.batchRunning
        return

    path := GetSelectedPresetPath()
    if path = "" {
        SetStatus("Select a preset to delete.")
        return
    }

    label := FormatPresetName(path)
    if !ConfirmDeleteItem(label, "preset")
        return

    deletedBase := FileBaseName(path)

    try {
        DeleteManagedFile(path)
    } catch as err {
        ShowManageMsgBox "Could not delete preset:`n" err.Message, "Delete Preset", "Icon!"
        SetStatus("Could not delete preset.")
        return
    }

    ClearManageStateKeyIfMatches(C.statePresetKey, deletedBase)
    RefreshPresetList()

    if S.presetPaths.Length
        SelectFirstListItem(S.presetList)

    RememberSelections()
    UpdateSelectionStatus()
    SetStatus("Deleted preset — " label)
}

/**
 * Renames the selected recording file (di- prefix enforced).
 */
RenameSelectedRecording(*) {
    global C, S

    if S.recording || S.applying || S.batchRunning
        return

    path := GetSelectedRecordingPath()
    if path = "" {
        SetStatus("Select a recording to rename.")
        return
    }

    result := ShowManageInputBox(
        "Recording name:",
        "Rename Recording",
        "w360 h130",
        FormatRecordingName(path)
    )

    if result.Result != "OK"
        return

    fileName := SafeRecordingFileName(result.Value)
    if fileName = "" {
        SetStatus("Rename cancelled — invalid name.")
        return
    }

    newPath := C.recordingsDir "\" fileName ".log"
    if StrLower(newPath) = StrLower(path) {
        SetStatus("Name unchanged.")
        return
    }

    try {
        FileMove path, newPath, 1
    } catch as err {
        ShowManageMsgBox "Could not rename recording:`n" err.Message, "Rename Recording", "Icon!"
        SetStatus("Could not rename recording.")
        return
    }

    RefreshRecordingList()
    SelectByBaseName(S.recordingList, S.recordingPaths, FileBaseName(newPath))
    RememberSelections()
    UpdateSelectionStatus()
    SetStatus("Renamed to " FormatRecordingName(newPath))
}

/**
 * Opens a simple editor for the selected recording log file.
 */
ShowRecordingLogEditor(*) {
    global S

    if S.recording || S.applying || S.batchRunning
        return

    path := GetSelectedRecordingPath()
    if path = "" {
        SetStatus("Select a recording to edit.")
        return
    }

    if !FileExist(path) {
        SetStatus("Recording file not found.")
        return
    }

    try {
        logContent := FileRead(path, "UTF-8")
    } catch as err {
        ShowManageMsgBox "Could not read recording:`n" err.Message, "Edit Log", "Icon!"
        return
    }

    CloseRecordingLogEditor()

    if S.gui
        S.gui.Hide()

    editor := Gui("+ToolWindow +Resize", "Edit Recording Log")
    BindManageChildGui(editor)
    S.logEditorGui := editor
    S.editingLogPath := path
    editor.SetFont("s10", "Consolas")
    editor.BackColor := "FFFFFF"

    editor.Add("Text", "w520 c1A1A1A", FormatRecordingName(path) " — raw log (UTF-8)")
    logEdit := editor.Add("Edit", "xm w520 h320 VScroll HScroll", logContent)

    saveBtn := editor.Add("Button", "xm w130 h32 Default", "Save")
    closeBtn := editor.Add("Button", "x+8 w130 h32", "Close")

    SaveLog(*) {
        try {
            logFile := FileOpen(path, "w", "UTF-8-RAW")
            if !logFile
                throw Error("Could not open file for writing.")
            logFile.Write(logEdit.Value)
            logFile.Close()
            SetStatus("Saved log — " FormatRecordingName(path))
        } catch as err {
            ShowManageMsgBox "Could not save log:`n" err.Message, "Edit Log", "Icon!"
        }
    }

    CloseLogEditor(*) {
        CloseRecordingLogEditor()
        if S.gui
            S.gui.Show()
    }

    saveBtn.OnEvent("Click", SaveLog)
    closeBtn.OnEvent("Click", CloseLogEditor)
    editor.OnEvent("Close", CloseLogEditor)
    editor.OnEvent("Escape", CloseLogEditor)

    editor.Show("w540 h420")
    logEdit.Focus()
}

ShowPresetEditor(*) {
    global C, S

    selectedPreset := GetSelectedPresetPath()
    originalPresetPath := selectedPreset
    selectedRecording := GetSelectedRecordingPath()
    existingSettings := selectedPreset && FileExist(selectedPreset)
        ? ParsePresetFile(selectedPreset)
        : DefaultSettings()

    variableCount := Max(existingSettings.variables.Length, CountVariablesInLog(selectedRecording), 1)
    while existingSettings.variables.Length < variableCount
        existingSettings.variables.Push("")

    if S.gui
        S.gui.Hide()

    editor := Gui("+ToolWindow", "Edit Preset")
    BindManageChildGui(editor)
    editor.SetFont("s10", "Segoe UI")
    editor.BackColor := "FFFFFF"

    editor.Add("Text", "w430 c1A1A1A", "Preset name")
    nameEdit := editor.Add("Edit", "w430", selectedPreset ? FormatPresetName(selectedPreset) : "default")

    editor.Add("Text", "w430 c1A1A1A", "Speed settings")
    editor.Add("Text", "w180", "Run speed:")
    playbackEdit := editor.Add("Edit", "x+0 w220", existingSettings.playback_speed)
    editor.Add("Text", "xm w180", "Typing speed:")
    typingEdit := editor.Add("Edit", "x+0 w220", existingSettings.typing_speed)
    editor.Add("Text", "xm w180", "Move speed:")
    moveEdit := editor.Add("Edit", "x+0 w220", existingSettings.move_speed)
    editor.Add("Text", "xm w180", "Initial delay (ms):")
    delayEdit := editor.Add("Edit", "x+0 w220", existingSettings.initial_delay)
    editor.Add("Text", "xm w180", "Click pause (ms):")
    clickPauseEdit := editor.Add("Edit", "x+0 w220", existingSettings.click_pause_ms)
    editor.Add("Text", "xm w180", "Step pause (ms):")
    segmentPauseEdit := editor.Add("Edit", "x+0 w220", existingSettings.segment_pause_ms)
    editor.Add("Text", "xm w430 c555555", "Click pause: after move, before click. Step pause: after each target before the next.")
    editor.Add("Text", "xm w430 c555555", "Between steps:")
    presetPausesRadio := editor.Add(
        "Radio",
        "xm" (!existingSettings.use_recorded_timing ? " checked" : ""),
        "Preset pauses only"
    )
    recordedGapsRadio := editor.Add(
        "Radio",
        "x+12" (existingSettings.use_recorded_timing ? " checked" : ""),
        "Recorded gaps"
    )
    editor.Add(
        "Text",
        "xm w430 c555555",
        "Recorded gaps replay seconds between steps from Record. Preset pauses only ignores those."
    )

    editor.Add("Text", "xm w430 c1A1A1A", "Run options")
    editor.Add("Text", "xm w430 c555555", "Mouse movement")
    smoothMouseRadio := editor.Add(
        "Radio",
        "xm" (existingSettings.smooth_mouse ? " checked" : ""),
        "Smooth"
    )
    instantMouseRadio := editor.Add(
        "Radio",
        "x+16" (!existingSettings.smooth_mouse ? " checked" : ""),
        "Instant"
    )
    editor.Add("Text", "xm w430 c555555", "Typing")
    humanTypingRadio := editor.Add(
        "Radio",
        "xm" (existingSettings.human_typing ? " checked" : ""),
        "Human-like"
    )
    instantTypingRadio := editor.Add(
        "Radio",
        "x+16" (!existingSettings.human_typing ? " checked" : ""),
        "Instant"
    )

    editor.Add("Text", "xm w430 c1A1A1A", "Variable inputs")
    editor.Add("Text", "xm w430 c555555", "One value per line. Line 1 = variable-1, line 2 = variable-2, etc.")
    variablesEdit := editor.Add("Edit", "xm w430 r10 Multi", Join(existingSettings.variables, "`n"))

    saveBtn := editor.Add("Button", "xm w130 h32 Default", "Save")
    closeBtn := editor.Add("Button", "x+8 w130 h32", "Close")

    SaveEditor(*) {
        presetName := SafePresetName(nameEdit.Value)
        if presetName = "" {
            ShowManageMsgBox "Enter a preset name.", "Edit Preset", "Icon!"
            return
        }

        settings := {
            playback_speed: SafeFloat(playbackEdit.Value, C.defaultPlaybackSpeed),
            typing_speed: SafeFloat(typingEdit.Value, C.defaultTypingSpeed),
            move_speed: SafeFloat(moveEdit.Value, C.defaultMoveSpeed),
            initial_delay: SafeInteger(delayEdit.Value, C.defaultInitialDelayMs),
            click_pause_ms: SafeInteger(clickPauseEdit.Value, C.defaultClickPauseMs),
            segment_pause_ms: SafeInteger(segmentPauseEdit.Value, C.defaultSegmentPauseMs),
            use_recorded_timing: recordedGapsRadio.Value = 1,
            smooth_mouse: smoothMouseRadio.Value = 1,
            human_typing: humanTypingRadio.Value = 1,
            variables: []
        }

        for line in StrSplit(variablesEdit.Value, "`n", "`r")
            settings.variables.Push(Trim(line))

        while settings.variables.Length && settings.variables[settings.variables.Length] = ""
            settings.variables.Pop()

        presetPath := C.savesDir "\" presetName C.saveExt

        try {
            WritePresetFile(settings, presetPath)

            if originalPresetPath != "" && StrLower(originalPresetPath) != StrLower(presetPath)
                && FileExist(originalPresetPath)
                DeleteManagedFile(originalPresetPath)

            ApplySettings(settings)
            SetPlaybackOptionRadios(settings.smooth_mouse, settings.human_typing)
            RefreshPresetList()
            SelectByBaseName(S.presetList, S.presetPaths, FileBaseName(presetPath))
            RememberSelections()
            UpdateSelectionStatus()
            SetStatus(originalPresetPath != "" && StrLower(originalPresetPath) = StrLower(presetPath)
                ? "Updated preset — " presetName
                : "Saved preset — " presetName)
            CloseEditor()
        } catch as err {
            ShowManageMsgBox "Could not save inputs:`n" err.Message, "Edit Preset", "Icon!"
        }
    }

    CloseEditor(*) {
        editor.Destroy()
        if S.gui
            S.gui.Show()
    }

    saveBtn.OnEvent("Click", SaveEditor)
    closeBtn.OnEvent("Click", CloseEditor)
    editor.OnEvent("Close", CloseEditor)
    editor.OnEvent("Escape", CloseEditor)

    editor.Show()
    nameEdit.Focus()
}


; =============================================================================
; Detect — recording lifecycle
; =============================================================================

StartRecording() {
    global C, S

    if S.recording || S.applying || S.batchRunning
        return

    DirCreate C.recordingsDir
    ResetRecordingState()

    sessionName := C.prefix NextRecordingNumber()
    S.filePath := C.recordingsDir "\" sessionName ".log"
    S.startedAt := A_TickCount

    try {
        S.logFile := FileOpen(S.filePath, "w", "UTF-8-RAW")
        WriteHeader(sessionName)
        InstallRecordHooks()
    } catch as err {
        Cleanup()
        ShowManageMsgBox "Could not start recording:`n" err.Message, "Data Entry Autonoma", "Icon!"
        SetStatus("Ready")
        return
    }

    S.recording := true
    SetRecordingGuiState(true)

    if S.gui
        S.gui.Hide()

    WriteLine("0|meta|recording_started`n")
    SetTimer FlushLog, C.flushIntervalMs

    ShowRecordingTip()
    ShowTransientRecordingTip("Recording... Esc to save · Hold Shift for delay.")
    SetTimer MaintainRecordingTip, C.recordingTipRefreshMs
}

/**
 * Cancels the active recording and deletes the temp log file.
 */
CancelRecording(*) {
    EndRecordingSession(false)
}

/**
 * Saves the active recording and prompts for a final name.
 */
SaveRecording(*) {
    EndRecordingSession(true)
}

/**
 * Ends Detect mode, optionally saving the recording file.
 * @param {Boolean} shouldSave When true, prompts to rename and keep the log.
 */
EndRecordingSession(shouldSave) {
    global S

    if !S.recording
        return

    path := S.filePath

    if S.shiftDelayHeld {
        if shouldSave
            CommitRecordingShiftDelay()
        else
            CancelRecordingShiftDelayState()
    }

    if shouldSave
        WriteLine(Format("{}|meta|recording_stopped`n", Elapsed()))

    S.recording := false
    SetTimer FlushLog, 0
    SetTimer MaintainRecordingTip, 0
    UninstallRecordHooks()
    CloseLogFile()
    HideRecordingTip()
    SetRecordingGuiState(false)

    if S.gui
        S.gui.Show()

    if shouldSave {
        RenameRecording(path)
        RefreshRecordingList()

        if S.recordingList && S.filePath != "" && FileExist(S.filePath)
            SelectByBaseName(S.recordingList, S.recordingPaths, FileBaseName(S.filePath))

        RememberSelections()
        UpdateSelectionStatus()
    } else {
        DiscardRecordingFile(path)
        S.filePath := ""
        RefreshRecordingList()
        SetStatus("Recording cancelled.")
    }
}

StopRecording(*) {
    SaveRecording()
}

ResetRecordingState() {
    global S

    S.filePath := ""
    S.logFile := ""
    S.startedAt := 0
    S.hasOrigin := false
    S.originX := 0
    S.originY := 0
    S.waitingForKey := false
    S.keyIndex := 0
    S.shiftDelayHeld := false
    S.shiftDelayStartedAt := 0
}

/**
 * Returns true for left/right Shift virtual-key codes.
 * @param {Integer} vk Virtual-key code.
 * @returns {Boolean}
 */
IsShiftVirtualKey(vk) {
    global C

    return vk = C.VK_LSHIFT || vk = C.VK_RSHIFT || vk = 0x10
}

/**
 * Starts timing a manual delay while Shift is held during Detect.
 */
BeginRecordingShiftDelay(*) {
    global S, C

    if !S.recording || S.shiftDelayHeld
        return

    S.shiftDelayHeld := true
    S.shiftDelayStartedAt := A_TickCount
    SetTimer RefreshRecordingShiftDelayTip, C.shiftDelayTipRefreshMs
    RefreshRecordingShiftDelayTip()
}

/**
 * Updates the live Shift-hold delay tooltip in seconds.
 */
RefreshRecordingShiftDelayTip(*) {
    global S

    if !S.recording || !S.shiftDelayHeld {
        SetTimer RefreshRecordingShiftDelayTip, 0
        return
    }

    seconds := Round((A_TickCount - S.shiftDelayStartedAt) / 1000, 1)
    ShowCursorToolTip(Format("Recording delay: {1} s", seconds))
}

/**
 * Clears Shift-delay tracking without writing to the log.
 */
CancelRecordingShiftDelayState() {
    global S

    SetTimer RefreshRecordingShiftDelayTip, 0
    S.shiftDelayHeld := false
    S.shiftDelayStartedAt := 0

    if IsRecording()
        ShowRecordingTip()
    else
        ToolTip
}

/**
 * Writes a recorded Shift-hold delay to the log and shows a confirmation tooltip.
 */
CommitRecordingShiftDelay(*) {
    global S, C

    if !S.shiftDelayHeld
        return

    SetTimer RefreshRecordingShiftDelayTip, 0
    durationMs := Max(0, A_TickCount - S.shiftDelayStartedAt)
    S.shiftDelayHeld := false
    S.shiftDelayStartedAt := 0

    if !S.recording {
        ToolTip
        return
    }

    if durationMs < C.minShiftDelayMs {
        ShowRecordingTip()
        return
    }

    WriteLine(Format("{}|meta|delay|{}`n", Elapsed(), durationMs))
    seconds := Round(durationMs / 1000, 1)
    MouseGetPos(&cursorX, &cursorY)
    ShowTransientRecordingTip(Format("Added delay: {1} s", seconds), cursorX, cursorY)
}

IsRecording() {
    global S
    return S.recording
}

Elapsed() {
    global S
    return A_TickCount - S.startedAt
}


; =============================================================================
; Detect — low-level hooks
; =============================================================================

InstallRecordHooks() {
    global C, S

    UninstallRecordHooks()

    S.mouseCallback := CallbackCreate(MouseHookProc, "Fast", 3)
    S.mouseHook := DllCall(
        "SetWindowsHookExW",
        "Int", C.WH_MOUSE_LL,
        "Ptr", S.mouseCallback,
        "Ptr", 0,
        "UInt", 0,
        "Ptr"
    )

    if !S.mouseHook
        throw Error("Mouse hook failed. A_LastError=" A_LastError)

    S.keyboardCallback := CallbackCreate(KeyboardHookProc, "Fast", 3)
    S.keyboardHook := DllCall(
        "SetWindowsHookExW",
        "Int", C.WH_KEYBOARD_LL,
        "Ptr", S.keyboardCallback,
        "Ptr", 0,
        "UInt", 0,
        "Ptr"
    )

    if !S.keyboardHook
        throw Error("Keyboard hook failed. A_LastError=" A_LastError)
}

UninstallRecordHooks() {
    global S

    if S.mouseHook {
        DllCall("UnhookWindowsHookEx", "Ptr", S.mouseHook)
        S.mouseHook := 0
    }

    if S.keyboardHook {
        DllCall("UnhookWindowsHookEx", "Ptr", S.keyboardHook)
        S.keyboardHook := 0
    }

    if S.mouseCallback {
        CallbackFree(S.mouseCallback)
        S.mouseCallback := 0
    }

    if S.keyboardCallback {
        CallbackFree(S.keyboardCallback)
        S.keyboardCallback := 0
    }
}

MouseHookProc(nCode, wParam, lParam) {
    global C, S

    if nCode >= 0 && S.recording {
        x := NumGet(lParam, 0, "Int")
        y := NumGet(lParam, 4, "Int")

        switch wParam {
            case C.WM_LBUTTONDOWN:
                QueueMouseEvent({ type: "click", button: "LButton", x: x, y: y })

            case C.WM_RBUTTONDOWN:
                QueueMouseEvent({ type: "click", button: "RButton", x: x, y: y })

            case C.WM_MBUTTONDOWN:
                QueueMouseEvent({ type: "click", button: "MButton", x: x, y: y })

            case C.WM_XBUTTONDOWN:
                xButton := (NumGet(lParam, 8, "UInt") >> 16) & 0xFFFF
                button := xButton = 1 ? "XButton1" : "XButton2"
                QueueMouseEvent({ type: "click", button: button, x: x, y: y })

            case C.WM_MOUSEWHEEL:
                QueueMouseEvent({
                    type: "scroll",
                    vertical: true,
                    data: NumGet(lParam, 8, "UInt"),
                    x: x,
                    y: y
                })

            case C.WM_MOUSEHWHEEL:
                QueueMouseEvent({
                    type: "scroll",
                    vertical: false,
                    data: NumGet(lParam, 8, "UInt"),
                    x: x,
                    y: y
                })
        }
    }

    return DllCall(
        "CallNextHookEx",
        "Ptr", S.mouseHook,
        "Int", nCode,
        "UPtr", wParam,
        "Ptr", lParam,
        "UPtr"
    )
}

KeyboardHookProc(nCode, wParam, lParam) {
    global C, S

    if nCode >= 0 && S.recording {
        vk := NumGet(lParam, 0, "UInt")
        sc := NumGet(lParam, 4, "UInt")
        isKeyDown := (wParam = C.WM_KEYDOWN || wParam = C.WM_SYSKEYDOWN)
        isKeyUp := (wParam = C.WM_KEYUP || wParam = C.WM_SYSKEYUP)

        if IsShiftVirtualKey(vk) && (isKeyDown || isKeyUp) {
            if isKeyDown
                SetTimer BeginRecordingShiftDelay, -1
            else if !GetKeyState("Shift", "P")
                SetTimer CommitRecordingShiftDelay, -1
            return 1
        }

        if isKeyDown {
            if vk = C.VK_ESCAPE {
                SetTimer SaveRecording, -1
                return 1
            }

            if vk != C.VK_F10
                QueueKeyEvent({ vk: vk, sc: sc })
        }
    }

    return DllCall(
        "CallNextHookEx",
        "Ptr", S.keyboardHook,
        "Int", nCode,
        "UPtr", wParam,
        "Ptr", lParam,
        "UPtr"
    )
}

QueueMouseEvent(event) {
    SetTimer ProcessMouseEvent.Bind(event), -1
}

QueueKeyEvent(event) {
    SetTimer ProcessKeyEvent.Bind(event), -1
}

ProcessMouseEvent(event, *) {
    if !IsRecording()
        return

    if event.type = "click"
        RecordClick(event.button, event.x, event.y)
    else
        RecordScroll(event)
}

ProcessKeyEvent(event, *) {
    if !IsRecording()
        return

    RecordKey(event.vk, event.sc)
}


; =============================================================================
; Detect — event recording
; =============================================================================

RecordClick(button, screenX, screenY) {
    ctx := GetActiveWindowContext()

    if ShouldIgnoreWindow(ctx) {
        Sleep 20
        ctx := GetActiveWindowContext()
    }

    if ShouldIgnoreWindow(ctx)
        return

    SaveOriginMetadataIfNeeded(screenX, screenY)
    coords := BuildCoordinateSnapshot(screenX, screenY, ctx)
    S.lastTargetX := screenX
    S.lastTargetY := screenY
    ArmKeyCapture()
    WriteMouseLine("click", button, coords, ctx)

    ShowTransientRecordingTip("Click saved. Press any key after this click only if you want typed input here.", screenX, screenY)
}

RecordScroll(event) {
    global C

    ctx := GetActiveWindowContext()

    if ShouldIgnoreWindow(ctx)
        return

    delta := SignedHighWord(event.data)
    notches := Max(1, Abs(Round(delta / C.wheelDelta)))

    if event.vertical
        direction := delta > 0 ? "up" : "down"
    else
        direction := delta > 0 ? "right" : "left"

    SaveOriginMetadataIfNeeded(event.x, event.y)
    coords := BuildCoordinateSnapshot(event.x, event.y, ctx)
    S.lastTargetX := event.x
    S.lastTargetY := event.y
    ArmKeyCapture()
    WriteScrollLine(direction, delta, notches, coords, ctx)
}

RecordKey(vk, sc) {
    global S

    if !S.waitingForKey
        return

    S.keyIndex += 1
    S.waitingForKey := false
    ctx := GetActiveWindowContext()

    WriteLine(Format(
        "{}|key|variable-{}|{}|{}|{}|{}|{}|{}`n",
        Elapsed(),
        S.keyIndex,
        vk,
        sc,
        ctx.hwndText,
        ctx.class,
        ctx.title,
        ctx.exe
    ))

    ShowVariableAssignmentTip("variable-" S.keyIndex, S.lastTargetX, S.lastTargetY)
}

ArmKeyCapture() {
    global S
    S.waitingForKey := true
}

SaveOriginMetadataIfNeeded(screenX, screenY) {
    global S

    if S.hasOrigin
        return

    S.originX := screenX
    S.originY := screenY
    S.hasOrigin := true

    WriteLine("# origin: " screenX "," screenY " (metadata only; coordinates are not rewritten)`n")

    ShowTransientRecordingTip("Origin saved. Recording real coordinates.", screenX, screenY)
}

BuildCoordinateSnapshot(screenX, screenY, ctx) {
    clientRelX := screenX - ctx.clientX
    clientRelY := screenY - ctx.clientY
    pctX := ctx.clientW > 0 ? clientRelX / ctx.clientW : 0
    pctY := ctx.clientH > 0 ? clientRelY / ctx.clientH : 0

    return {
        screenX: screenX,
        screenY: screenY,
        clientX: clientRelX,
        clientY: clientRelY,
        pctX: Round(pctX, 6),
        pctY: Round(pctY, 6),
        clientOriginX: ctx.clientX,
        clientOriginY: ctx.clientY,
        clientW: ctx.clientW,
        clientH: ctx.clientH,
        winX: ctx.winX,
        winY: ctx.winY,
        winW: ctx.winW,
        winH: ctx.winH
    }
}

WriteMouseLine(eventName, button, coords, ctx) {
    WriteLine(Format(
        "{}|{}|{}|{}|{}|{}|{}|{:.6f}|{:.6f}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}`n",
        Elapsed(),
        eventName,
        button,
        coords.screenX,
        coords.screenY,
        coords.clientX,
        coords.clientY,
        coords.pctX,
        coords.pctY,
        coords.clientW,
        coords.clientH,
        coords.winX,
        coords.winY,
        coords.winW,
        coords.winH,
        ctx.hwndText,
        ctx.class,
        ctx.title,
        ctx.exe
    ))
}

WriteScrollLine(direction, delta, notches, coords, ctx) {
    WriteLine(Format(
        "{}|scroll|{}|{}|{}|{}|{}|{}|{:.6f}|{:.6f}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}`n",
        Elapsed(),
        direction,
        delta,
        notches,
        coords.screenX,
        coords.screenY,
        coords.clientX,
        coords.clientY,
        coords.pctX,
        coords.pctY,
        coords.clientW,
        coords.clientH,
        coords.winX,
        coords.winY,
        coords.winW,
        coords.winH,
        ctx.hwndText,
        ctx.class,
        ctx.title,
        ctx.exe
    ))
}


; =============================================================================
; Detect — window context and file handling
; =============================================================================

GetActiveWindowContext() {
    hwnd := 0

    try hwnd := WinGetID("A")
    catch {
        return EmptyWindowContext()
    }

    try {
        winTitle := WinGetTitle("ahk_id " hwnd)
        exe := WinGetProcessName("ahk_id " hwnd)
        className := WinGetClass("ahk_id " hwnd)

        WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " hwnd)
        WinGetClientPos(&clientX, &clientY, &clientW, &clientH, "ahk_id " hwnd)

        return {
            hwnd: hwnd,
            hwndText: Format("0x{:X}", hwnd),
            title: CleanField(winTitle),
            exe: CleanField(exe),
            class: CleanField(className),
            winX: NumOrZero(winX),
            winY: NumOrZero(winY),
            winW: NumOrZero(winW),
            winH: NumOrZero(winH),
            clientX: NumOrZero(clientX),
            clientY: NumOrZero(clientY),
            clientW: NumOrZero(clientW),
            clientH: NumOrZero(clientH)
        }
    } catch {
        return EmptyWindowContext()
    }
}

EmptyWindowContext() {
    return {
        hwnd: 0,
        hwndText: "",
        title: "",
        exe: "",
        class: "",
        winX: 0,
        winY: 0,
        winW: 0,
        winH: 0,
        clientX: 0,
        clientY: 0,
        clientW: 0,
        clientH: 0
    }
}

ShouldIgnoreWindow(ctx) {
    global C

    if ctx.exe = ""
        return true

    for exe in C.ignoredExes {
        if StrLower(ctx.exe) = StrLower(exe)
            return true
    }

    return StrLower(ctx.exe) = "explorer.exe" && InStr(ctx.title, "AutoHotkey")
}

WriteHeader(sessionName) {
    WriteLine("# detectInput session " sessionName "`n")
    WriteLine("# format: pipe-delimited UTF-8`n")
    WriteLine("# coordinate mode: absolute screen plus active-window client coordinates`n")
    WriteLine("# origin is metadata only; first input is not rewritten to 0,0`n")
    WriteLine("# click fields:`n")
    WriteLine("# elapsed_ms|click|button|screenX|screenY|clientX|clientY|pctX|pctY|clientW|clientH|winX|winY|winW|winH|hwnd|class|title|exe`n")
    WriteLine("# scroll fields:`n")
    WriteLine("# elapsed_ms|scroll|direction|delta|notches|screenX|screenY|clientX|clientY|pctX|pctY|clientW|clientH|winX|winY|winW|winH|hwnd|class|title|exe`n")
    WriteLine("# key fields:`n")
    WriteLine("# elapsed_ms|key|variable-N|vk|sc|hwnd|class|title|exe`n")
    WriteLine("# delay fields:`n")
    WriteLine("# elapsed_ms|meta|delay|duration_ms`n")
    WriteLine("# playback tip: prefer pctX/pctY against the target window's current client size, then fallback to clientX/clientY, then screenX/screenY.`n")
}

WriteLine(line) {
    global S

    try {
        if S.logFile
            S.logFile.Write(line)
    } catch as err {
        ToolTip "Log write failed:`n" err.Message
        SetTimer ClearTip, -4000
    }
}

FlushLog(*) {
    global S

    try {
        if S.logFile && S.logFile.Handle
            DllCall("FlushFileBuffers", "Ptr", S.logFile.Handle)
    } catch {
    }
}

CloseLogFile() {
    global S

    try {
        if S.logFile {
            FlushLog()
            S.logFile.Close()
        }
    } catch {
    }

    S.logFile := ""
}

NextRecordingNumber() {
    global C

    maxNumber := 0

    Loop Files C.recordingsDir "\" C.prefix "*.log" {
        if RegExMatch(A_LoopFileName, "^" C.prefix "(\d+)\.log$", &match)
            maxNumber := Max(maxNumber, Integer(match[1]))
    }

    return maxNumber + 1
}

RenameRecording(savedPath) {
    global C, S

    result := ShowManageInputBox("Recording name:", "Save Recording", "w360 h130", DisplayName(savedPath))

    if result.Result != "OK" {
        DiscardRecordingFile(savedPath)
        S.filePath := ""
        SetStatus("Recording cancelled.")
        return
    }

    fileName := SafeRecordingFileName(result.Value)

    if fileName = "" {
        DiscardRecordingFile(savedPath)
        S.filePath := ""
        SetStatus("Recording cancelled.")
        return
    }

    newPath := C.recordingsDir "\" fileName ".log"

    try {
        if StrLower(newPath) != StrLower(savedPath)
            FileMove savedPath, newPath, 1

        S.filePath := newPath
        SetStatus("Saved as " DisplayName(newPath))
    } catch as err {
        ShowManageMsgBox "Could not rename file:`n" err.Message, "Save Recording", "Icon!"
        SetStatus("Ready")
    }
}

/**
 * Deletes a discarded recording log after cancel or a rejected save prompt.
 * @param {String} path Recording file path.
 */
DiscardRecordingFile(path) {
    if path = "" || !FileExist(path)
        return

    try {
        if InStr(FileGetAttrib(path), "R")
            FileSetAttrib("-R", path)
        FileDelete path
    } catch {
        try FileRecycle path
    }
}

SafeRecordingFileName(name) {
    global C

    name := Trim(name)
    name := RegExReplace(name, "[\\/:*?`"<>|]", "-")
    name := RegExReplace(name, "i)\.log$", "")

    if name = ""
        return ""

    if !RegExMatch(name, "i)^" C.prefix)
        name := C.prefix name

    return name
}

DisplayName(pathOrName) {
    return FormatRecordingName(pathOrName)
}


; =============================================================================
; Apply — main playback flow
; =============================================================================

/**
 * Replays one recording using variables from a preset file.
 * @param {String} logPath Recording path.
 * @param {String} presetPath Preset path.
 * @returns {Boolean}
 */
RunApply(logPath, presetPath) {
    global S

    if S.applying || S.batchRunning {
        SetStatus("Already running.")
        return false
    }

    if !FileExist(logPath) {
        SetStatus("Recording file not found.")
        ShowManageMsgBox "Recording file not found:`n" logPath, "Data Entry Autonoma", "Icon!"
        return false
    }

    if !FileExist(presetPath) {
        SetStatus("Preset file not found.")
        ShowManageMsgBox "Preset file not found:`n" presetPath, "Data Entry Autonoma", "Icon!"
        return false
    }

    settings := ParsePresetFile(presetPath)
    ApplySettings(settings)
    SyncPlaybackOptionsFromGui()

    parsed := PrepareApplyLog(logPath)
    if parsed = ""
        return false

    if RecordingNeedsVariableValues(parsed) && S.variables.Length = 0 {
        SetStatus("No variables in selected preset.")
        ShowManageMsgBox "This recording expects typed variable values.`n`nUse Edit Preset to add them.", "Data Entry Autonoma", "Icon!"
        return false
    }

    BeginApplySession(parsed, false)

    result := ExecuteApplyPlayback(parsed)
    EndApplySession()

    if result.stopped {
        SetStatus("Stopped.")
        return false
    }

    SetStatus("Done — " result.applied " variable(s), " result.scrolled " scroll(s).")
    return true
}

/**
 * Replays one recording once per CSV row.
 * @param {String} logPath Recording path.
 * @param {String} csvPath CSV batch path.
 * @param {String} presetPath Optional preset used for speed settings only.
 * @returns {Boolean}
 */
RunApplyBatch(logPath, csvPath, presetPath := "") {
    global C, S

    if S.applying || S.batchRunning {
        SetStatus("Already running.")
        return false
    }

    if !FileExist(logPath) {
        SetStatus("Recording file not found.")
        ShowManageMsgBox "Recording file not found:`n" logPath, "Data Entry Autonoma", "Icon!"
        return false
    }

    rows := ParseCsvFile(csvPath)
    if rows.Length = 0 {
        SetStatus("CSV has no data rows.")
        ShowManageMsgBox "The CSV file has no usable data rows.`n`nExpected format:`n1,word,word2,word3`n2,word4,word5,word6",
            "Data Entry Autonoma", "Icon!"
        return false
    }

    settings := presetPath != "" && FileExist(presetPath)
        ? ParsePresetFile(presetPath)
        : DefaultSettings()
    ApplySettings(settings)
    SyncPlaybackOptionsFromGui()

    parsed := PrepareApplyLog(logPath)
    if parsed = ""
        return false

    S.stopBatch := false
    S.batchRunning := true
    SetApplyGuiState(true)

    if S.gui
        S.gui.Hide()

    completedRows := 0
    stopped := false
    totalRows := rows.Length
    askNextLine := S.csvAskNextLine
    S.csvBatchRunAllRemaining := false
    S.csvPromptChoice := C.csvBatchPromptChoiceNone

    if askNextLine
        ShowCsvBatchProgressTable(rows)

    try {
        Loop totalRows {
            rowIndex := A_Index
            row := rows[rowIndex]

            if S.stopBatch {
                stopped := true
                break
            }

            if askNextLine && !S.csvBatchRunAllRemaining {
                choice := WaitCsvBatchRowPrompt(rowIndex, row, totalRows)
                CloseCsvBatchRowPrompt()

                if S.stopBatch {
                    stopped := true
                    break
                }

                if choice = C.csvBatchPromptChoiceSkip {
                    SetCsvBatchProgressRowStatus(rowIndex, C.csvBatchStatusSkipped)
                    continue
                }

                if choice = C.csvBatchPromptChoiceRunAll
                    S.csvBatchRunAllRemaining := true
            }

            S.variables := row.variables.Clone()
            SetStatus(Format("CSV row {}/{} — {} ({} variable(s))", rowIndex, totalRows, row.label, row.variables.Length))

            BeginApplySession(parsed, true)
            result := ExecuteApplyPlayback(parsed)
            EndApplySession(false)

            if result.stopped || S.stopBatch {
                stopped := true
                break
            }

            if result.success
                completedRows += 1

            if askNextLine
                SetCsvBatchProgressRowStatus(rowIndex, C.csvBatchStatusDone)

            if rowIndex < totalRows && !S.stopBatch {
                ResetApplyRuntimeState()
                Sleep C.batchRowPauseMs
            }
        }
    } catch as err {
        stopped := true
        ShowManageMsgBox "Batch run failed:`n" err.Message, "Data Entry Autonoma", "Icon!"
    } finally {
        CloseCsvBatchProgressTable()
        CloseCsvBatchRowPrompt()
        S.csvBatchRunAllRemaining := false
        S.csvPromptChoice := C.csvBatchPromptChoiceNone
        S.batchRunning := false
        S.stopBatch := false
        ResetApplyRuntimeState()
        ToolTip
        SetApplyGuiState(false)

        if S.gui
            S.gui.Show()
    }

    if stopped {
        SetStatus(Format("Batch stopped — completed {}/{} row(s).", completedRows, totalRows))
        return false
    }

    SetStatus(Format("Batch done — completed {}/{} row(s).", completedRows, totalRows))
    return completedRows = totalRows
}

/**
 * Returns true when playback needs preset or CSV variable values.
 * @param {Object} parsed Parsed recording.
 * @returns {Boolean}
 */
RecordingNeedsVariableValues(parsed) {
    for action in parsed.actions {
        if action.type = "apply" && action.variable != ""
            return true
    }
    return false
}

/**
 * Parses and validates a recording for playback.
 * @param {String} logPath Recording path.
 * @returns {Object|String} Parsed log object, or empty string on failure.
 */
PrepareApplyLog(logPath) {
    global S

    parsed := ParseDetectLog(logPath)

    if parsed.actions.Length = 0 {
        if parsed.clickCount > 0 && parsed.keyCount = 0 {
            SetStatus("Recording has clicks but no replayable actions.")
            ShowManageMsgBox "This recording has " parsed.clickCount " click(s) but none could be replayed.", "Data Entry Autonoma", "Icon!"
        } else if parsed.keyCount > 0 && parsed.clickCount = 0 {
            SetStatus("Recording has keys but no click target before them.")
            ShowManageMsgBox "This recording has key events but no click targets before them.", "Data Entry Autonoma", "Icon!"
        } else if parsed.keyCount > 0 && parsed.clickCount > 0 {
            SetStatus("Recording has clicks and keys but no matched steps.")
            ShowManageMsgBox "This recording has clicks and keys, but they are not paired.`n`n"
                . "Each key needs a click immediately before it in the log.",
                "Data Entry Autonoma", "Icon!"
        } else {
            SetStatus("No runnable actions in that recording.")
            ShowManageMsgBox "No click, type, or scroll actions were found in that recording.", "Data Entry Autonoma", "Icon!"
        }
        return ""
    }

    S.originX := parsed.originX
    S.originY := parsed.originY
    S.virtualBounds := GetVirtualScreenBounds()
    return parsed
}

/**
 * Starts one playback session for a parsed recording.
 * @param {Object} parsed Parsed recording.
 * @param {Boolean} batchMode Whether this pass is part of a CSV batch.
 */
BeginApplySession(parsed, batchMode := false) {
    global S

    S.applying := true

    if !batchMode {
        SetApplyGuiState(true)
        if S.gui
            S.gui.Hide()
    }

    ToolTip "Running " parsed.actions.Length " action(s)... Press Esc to stop."
    SetTimer ClearTip, -3500
}

/**
 * Ends one playback session and restores shared runtime state.
 * @param {Boolean} restoreGui Whether to show the main GUI (false during batch rows).
 */
EndApplySession(restoreGui := true) {
    global S

    S.applying := false
    UninstallMouseBlock()
    ToolTip

    if restoreGui {
        SetApplyGuiState(false)
        if S.gui
            S.gui.Show()
    }
}

/**
 * Clears transient playback flags between CSV rows.
 */
ResetApplyRuntimeState() {
    global S

    S.applying := false
    UninstallMouseBlock()
    ToolTip
}

/**
 * Executes one full pass through parsed.actions.
 * @param {Object} parsed Parsed recording.
 * @returns {Object} Result with success, stopped, applied, and scrolled counts.
 */
ExecuteApplyPlayback(parsed) {
    global C, S

    applied := 0
    scrolled := 0
    stopped := false

    try {
        SleepWhileApplying(S.initialDelayMs)

        if C.blockUserMouse && S.applying
            InstallMouseBlock()

        firstElapsed := parsed.actions[1].elapsed
        previousRelativeElapsed := 0

        for action in parsed.actions {
            if !S.applying || S.stopBatch {
                stopped := true
                break
            }

            relativeElapsed := action.elapsed - firstElapsed

            if S.useRecordedTiming {
                delay := Max(0, (relativeElapsed - previousRelativeElapsed) / S.playbackSpeed)
                previousRelativeElapsed := relativeElapsed
                SleepWhileApplying(delay)
            }

            if !S.applying || S.stopBatch {
                stopped := true
                break
            }

            if action.type = "apply" {
                ReplayApply(action)
                applied += 1
            } else if action.type = "scroll" {
                ReplayScroll(action)
                scrolled += 1
            } else if action.type = "delay" && !S.useRecordedTiming {
                SleepWhileApplying(action.delayMs)
            }
        }
    } catch as err {
        stopped := true
        throw err
    } finally {
        S.applying := false
        UninstallMouseBlock()
    }

    return {
        success: !stopped,
        stopped: stopped,
        applied: applied,
        scrolled: scrolled
    }
}

ReplayApply(action) {
    global C, S

    text := action.variable != "" ? ResolveVariableText(action.variable) : ""
    point := ResolveTargetPoint(action.target)

    if text != ""
        ShowVariableAssignmentTip(action.variable, point.x, point.y)

    if S.smoothMouse
        NaturalMouseMove(point.x, point.y)
    else
        MoveMouseInstant(point.x, point.y)

    if !S.applying || S.stopBatch
        return

    SleepWhileApplying(S.clickPauseMs)

    if !S.applying || S.stopBatch
        return

    ClickPoint(point.x, point.y)

    if !S.applying || S.stopBatch
        return

    if text != "" {
        if S.humanTyping
            TypeTextHuman(text)
        else
            SendText text
    }

    SleepWhileApplying(S.segmentPauseMs)
}

ReplayScroll(action) {
    global C, S

    point := ResolveTargetPoint(action.target)

    if S.smoothMouse
        NaturalMouseMove(point.x, point.y)
    else
        MoveMouseInstant(point.x, point.y)

    if !S.applying || S.stopBatch
        return

    SleepWhileApplying(50)

    wheelCommand := MapWheel(action.direction)
    steps := Max(1, action.notches)

    if action.delta != 0
        steps := Max(1, Integer(Abs(action.delta) / C.wheelDelta))

    Loop steps {
        if !S.applying || S.stopBatch
            return
        Send wheelCommand
    }
}

RequestStop(*) {
    global S

    if S.applying
        S.applying := false

    if S.batchRunning
        S.stopBatch := true
}

IsApplying() {
    global S
    return S.applying
}

IsBatchRunning() {
    global S
    return S.batchRunning
}

SleepWhileApplying(delayMs) {
    global S

    delayMs := Round(delayMs)

    while delayMs > 0 && S.applying && !S.stopBatch {
        chunk := Min(delayMs, 50)
        Sleep chunk
        delayMs -= chunk
    }
}

Cleanup(*) {
    global S

    S.recording := false
    S.applying := false
    S.batchRunning := false
    S.stopBatch := false

    CloseCsvBatchProgressTable()
    CloseCsvBatchRowPrompt()

    SetTimer FlushLog, 0
    UninstallRecordHooks()
    CloseLogFile()
    UninstallMouseBlock()
    HideRecordingTip()
}


; =============================================================================
; Apply — CSV parsing
; =============================================================================

/**
 * Parses a CSV batch file into row objects.
 * First column is treated as a row label; remaining columns map to variable-1, variable-2, ...
 * Single-column rows map that value to variable-1.
 * @param {String} filePath CSV file path.
 * @returns {Array<Object>}
 */
ParseCsvFile(filePath) {
    rows := []

    Loop Read filePath {
        line := Trim(A_LoopReadLine)

        if line = "" || SubStr(line, 1, 1) = "#"
            continue

        columns := []
        for field in StrSplit(line, ",")
            columns.Push(Trim(field))

        if columns.Length = 0
            continue

        if columns.Length = 1 {
            rows.Push({ label: "1", variables: [columns[1]] })
            continue
        }

        variables := []
        Loop columns.Length - 1
            variables.Push(columns[A_Index + 1])

        rows.Push({ label: columns[1], variables: variables })
    }

    return rows
}


; =============================================================================
; Apply — log parsing
; =============================================================================

ParseDetectLog(filePath) {
    parsed := {
        originX: 0,
        originY: 0,
        hasOrigin: false,
        coordinateMode: "relative",
        recordingStartedAt: 0,
        clickCount: 0,
        keyCount: 0,
        usedClickOnlyFallback: false,
        clicks: [],
        actions: []
    }

    pendingClick := ""

    Loop Read filePath {
        line := Trim(A_LoopReadLine)
        if line = ""
            continue

        if SubStr(line, 1, 1) = "#" {
            ParseCommentLine(line, parsed)
            continue
        }

        for eventLine in SplitMergedLogLines(line)
            pendingClick := ProcessDetectLogEvent(eventLine, parsed, pendingClick)
    }

    FinalizeDetectLogActions(parsed, pendingClick)
    return parsed
}

/**
 * Queues a click-only replay when no variable key was recorded for that target.
 * @param {Object} parsed Parsed recording accumulator.
 * @param {Object} clickTarget Click target metadata.
 */
PushClickOnlyApplyAction(parsed, clickTarget) {
    parsed.actions.Push({
        type: "apply",
        elapsed: clickTarget.elapsed,
        variable: "",
        target: clickTarget
    })
}

FinalizeDetectLogActions(parsed, pendingClick := "") {
    if pendingClick != ""
        PushClickOnlyApplyAction(parsed, pendingClick)
}

SplitMergedLogLines(line) {
    repairedLine := RegExReplace(line, "i)\.exe(\d+\|(click|scroll|key|meta)\|)", ".exe`n$1")
    lines := []
    remainder := repairedLine

    while remainder != "" {
        if !RegExMatch(remainder, "(\d+)\|(click|scroll|key|meta)\|", &match) {
            if Trim(remainder) != ""
                lines.Push(Trim(remainder))
            break
        }

        startPos := match.Pos
        searchFrom := startPos + match.Len
        nextPos := 0

        if RegExMatch(SubStr(remainder, searchFrom), "(\d+)\|(click|scroll|key|meta)\|", &nextMatch, 1)
            nextPos := searchFrom + nextMatch.Pos - 1

        eventLine := nextPos
            ? SubStr(remainder, startPos, nextPos - startPos)
            : SubStr(remainder, startPos)

        lines.Push(Trim(eventLine))
        remainder := nextPos ? SubStr(remainder, nextPos) : ""
    }

    return lines
}

ProcessDetectLogEvent(line, parsed, pendingClick) {
    parts := StrSplit(line, "|")
    if parts.Length < 3
        return pendingClick

    elapsedMs := SafeInteger(parts[1], 0)
    eventType := parts[2]

    if eventType = "meta" {
        if parts.Length >= 3 && parts[3] = "recording_started"
            parsed.recordingStartedAt := elapsedMs
        else if parts.Length >= 4 && parts[3] = "delay" {
            delayMs := SafeInteger(parts[4], 0)
            if delayMs > 0 {
                parsed.actions.Push({
                    type: "delay",
                    elapsed: elapsedMs,
                    delayMs: delayMs
                })
            }
        }
        return pendingClick
    }

    if eventType = "click" {
        clickTarget := ParseClickTarget(parts, parsed.coordinateMode)
        if clickTarget != "" {
            clickTarget.elapsed := elapsedMs
            parsed.clickCount += 1
            parsed.clicks.Push(clickTarget)

            if pendingClick != ""
                PushClickOnlyApplyAction(parsed, pendingClick)

            return clickTarget
        }
        return pendingClick
    }

    if eventType = "scroll" {
        if pendingClick != ""
            PushClickOnlyApplyAction(parsed, pendingClick)

        scrollTarget := ParseScrollTarget(parts, parsed.coordinateMode)
        if scrollTarget != "" {
            parsed.actions.Push({
                type: "scroll",
                elapsed: elapsedMs,
                direction: parts.Length >= 4 ? parts[3] : "down",
                delta: parts.Length >= 5 ? SafeInteger(parts[4], 0) : 0,
                notches: parts.Length >= 6 ? SafeInteger(parts[5], 1) : 1,
                target: scrollTarget
            })
        }
        return ""
    }

    if eventType = "key" && parts.Length >= 3 && RegExMatch(parts[3], "i)^variable-\d+$") {
        parsed.keyCount += 1

        if pendingClick != "" {
            parsed.actions.Push({
                type: "apply",
                elapsed: elapsedMs,
                variable: parts[3],
                target: pendingClick
            })
            return ""
        }
    }

    return pendingClick
}

ParseCommentLine(line, parsed) {
    if RegExMatch(line, "i)logged x,y are relative|relative to this point|coordinates are relative")
        parsed.coordinateMode := "relative"
    else if RegExMatch(line, "i)coordinate mode:\s*absolute|absolute screen")
        parsed.coordinateMode := "absolute"

    if RegExMatch(line, "i)origin:.*?(-?\d+),(-?\d+)", &origin) {
        parsed.originX := Integer(origin[1])
        parsed.originY := Integer(origin[2])
        parsed.hasOrigin := true
    }
}

ParseClickTarget(parts, coordinateMode) {
    if parts.Length >= 19 && IsNumericText(parts[4]) && IsNumericText(parts[5]) {
        return MakeTarget(
            "rich",
            SafeInteger(parts[4], 0),
            SafeInteger(parts[5], 0),
            SafeInteger(parts[6], ""),
            SafeInteger(parts[7], ""),
            SafeFloat(parts[8], ""),
            SafeFloat(parts[9], ""),
            SafeInteger(parts[10], ""),
            SafeInteger(parts[11], ""),
            SafeInteger(parts[12], ""),
            SafeInteger(parts[13], ""),
            SafeInteger(parts[14], ""),
            SafeInteger(parts[15], ""),
            parts[16],
            parts[17],
            parts[18],
            parts[19]
        )
    }

    if parts.Length >= 5 && IsNumericText(parts[4]) && IsNumericText(parts[5]) {
        return MakeTarget(
            coordinateMode,
            SafeInteger(parts[4], 0),
            SafeInteger(parts[5], 0),
            "", "", "", "", "", "", "", "", "",
            "", "",
            parts.Length >= 6 ? parts[6] : "",
            parts.Length >= 7 ? parts[7] : ""
        )
    }

    return ""
}

ParseScrollTarget(parts, coordinateMode) {
    if parts.Length >= 21 && IsNumericText(parts[6]) && IsNumericText(parts[7]) {
        return MakeTarget(
            "rich",
            SafeInteger(parts[6], 0),
            SafeInteger(parts[7], 0),
            SafeInteger(parts[8], ""),
            SafeInteger(parts[9], ""),
            SafeFloat(parts[10], ""),
            SafeFloat(parts[11], ""),
            SafeInteger(parts[12], ""),
            SafeInteger(parts[13], ""),
            SafeInteger(parts[14], ""),
            SafeInteger(parts[15], ""),
            SafeInteger(parts[16], ""),
            SafeInteger(parts[17], ""),
            parts[18],
            parts[19],
            parts[20],
            parts[21]
        )
    }

    if parts.Length >= 7 && IsNumericText(parts[6]) && IsNumericText(parts[7]) {
        return MakeTarget(
            coordinateMode,
            SafeInteger(parts[6], 0),
            SafeInteger(parts[7], 0),
            "", "", "", "", "", "", "", "", "",
            "", "",
            parts.Length >= 8 ? parts[8] : "",
            parts.Length >= 9 ? parts[9] : ""
        )
    }

    return ""
}

MakeTarget(mode, screenX, screenY, clientX := "", clientY := "", pctX := "", pctY := "", clientW := "", clientH := "", winX := "", winY := "", winW := "", winH := "", hwnd := "", className := "", title := "", exe := "") {
    return {
        mode: mode,
        screenX: screenX,
        screenY: screenY,
        clientX: clientX,
        clientY: clientY,
        pctX: pctX,
        pctY: pctY,
        clientW: clientW,
        clientH: clientH,
        winX: winX,
        winY: winY,
        winW: winW,
        winH: winH,
        hwnd: hwnd,
        className: className,
        title: title,
        exe: exe
    }
}

CountVariablesInLog(filePath) {
    maxIndex := 0

    if filePath = "" || !FileExist(filePath)
        return 0

    Loop Read filePath {
        line := Trim(A_LoopReadLine)
        if line = "" || SubStr(line, 1, 1) = "#"
            continue

        for eventLine in SplitMergedLogLines(line) {
            parts := StrSplit(eventLine, "|")
            if parts.Length >= 3 && parts[2] = "key" && RegExMatch(parts[3], "i)^variable-(\d+)$", &m)
                maxIndex := Max(maxIndex, Integer(m[1]))
        }
    }

    return maxIndex
}

/**
 * Counts click targets in a recording log.
 * @param {String} filePath Recording path.
 * @returns {Integer}
 */
CountRecordingClickTargets(filePath) {
    clickCount := 0

    if filePath = "" || !FileExist(filePath)
        return 0

    Loop Read filePath {
        line := Trim(A_LoopReadLine)
        if line = "" || SubStr(line, 1, 1) = "#"
            continue

        for eventLine in SplitMergedLogLines(line) {
            parts := StrSplit(eventLine, "|")
            if parts.Length >= 3 && parts[2] = "click"
                clickCount += 1
        }
    }

    return clickCount
}

/**
 * Returns how many variable slots a recording uses (keyed targets only).
 * @param {String} filePath Recording path.
 * @returns {Integer}
 */
CountRecordingVariableSlots(filePath) {
    return CountVariablesInLog(filePath)
}


; =============================================================================
; Apply — coordinate resolution
; =============================================================================

ResolveTargetPoint(target) {
    global S

    hwnd := FindTargetWindow(target)
    if hwnd && target.pctX != "" && target.pctY != "" {
        try {
            WinActivate "ahk_id " hwnd
            WinGetClientPos(&clientLeft, &clientTop, &clientW, &clientH, "ahk_id " hwnd)

            if clientW > 0 && clientH > 0 {
                return ClampPoint(
                    clientLeft + Round(target.pctX * clientW),
                    clientTop + Round(target.pctY * clientH)
                )
            }
        }
    }

    if target.mode = "relative"
        return ClampPoint(S.originX + target.screenX, S.originY + target.screenY)

    return ClampPoint(target.screenX, target.screenY)
}

FindTargetWindow(target) {
    if target.hwnd != "" {
        try {
            hwndValue := Integer(target.hwnd)
            if WinExist("ahk_id " hwndValue)
                return hwndValue
        }
    }

    queries := []

    if target.className != "" && target.exe != ""
        queries.Push("ahk_class " target.className " ahk_exe " target.exe)

    if target.exe != ""
        queries.Push("ahk_exe " target.exe)

    if target.className != ""
        queries.Push("ahk_class " target.className)

    if target.title != ""
        queries.Push(target.title)

    for query in queries {
        try {
            hwnd := WinExist(query)
            if hwnd
                return hwnd
        }
    }

    return 0
}

GetVirtualScreenBounds() {
    global C

    return {
        left: SysGet(C.SM_XVIRTUALSCREEN),
        top: SysGet(C.SM_YVIRTUALSCREEN),
        right: SysGet(C.SM_XVIRTUALSCREEN) + SysGet(C.SM_CXVIRTUALSCREEN) - 1,
        bottom: SysGet(C.SM_YVIRTUALSCREEN) + SysGet(C.SM_CYVIRTUALSCREEN) - 1
    }
}

ClampPoint(x, y) {
    global S

    if S.virtualBounds = ""
        S.virtualBounds := GetVirtualScreenBounds()

    return {
        x: Max(S.virtualBounds.left, Min(S.virtualBounds.right, Round(x))),
        y: Max(S.virtualBounds.top, Min(S.virtualBounds.bottom, Round(y)))
    }
}


; =============================================================================
; Apply — mouse and keyboard playback
; =============================================================================

ClickPoint(x, y) {
    global S

    point := ClampPoint(x, y)
    DllCall("SetCursorPos", "Int", point.x, "Int", point.y)
    Sleep 15

    if !S.applying || S.stopBatch
        return

    DllCall("mouse_event", "UInt", 0x0002, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0)
    DllCall("mouse_event", "UInt", 0x0004, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0)
}

/**
 * Moves the cursor directly to a target point without animation.
 * @param {Number} targetX Screen X coordinate.
 * @param {Number} targetY Screen Y coordinate.
 */
MoveMouseInstant(targetX, targetY) {
    target := ClampPoint(targetX, targetY)
    DllCall("SetCursorPos", "Int", target.x, "Int", target.y)
}

NaturalMouseMove(targetX, targetY) {
    global C, S

    MouseGetPos(&startX, &startY)
    target := ClampPoint(targetX, targetY)
    targetX := target.x
    targetY := target.y

    if Abs(startX - targetX) < 2 && Abs(startY - targetY) < 2 {
        DllCall("SetCursorPos", "Int", targetX, "Int", targetY)
        return
    }

    distance := Sqrt((targetX - startX) ** 2 + (targetY - startY) ** 2)
    durationMs := GetMoveDuration(distance)

    curveOffset := Max(C.curveMinOffset, Min(C.curveMaxOffset, distance * C.curveOffsetRatio))
    length := Max(distance, 1)
    deltaX := targetX - startX
    deltaY := targetY - startY
    perpX := -deltaY / length
    perpY := deltaX / length

    offset1 := Random(-curveOffset, curveOffset)
    offset2 := Random(-curveOffset, curveOffset)

    c1x := startX + deltaX * 0.33 + perpX * offset1
    c1y := startY + deltaY * 0.33 + perpY * offset1
    c2x := startX + deltaX * 0.66 + perpX * offset2
    c2y := startY + deltaY * 0.66 + perpY * offset2

    steps := Max(C.moveStepsMin, Ceil(distance * C.moveStepsPerPx))
    sleepMs := durationMs / steps

    ; Too many steps makes per-step sleep round to 0 ms, which teleports the cursor.
    if sleepMs < C.moveStepMinSleepMs {
        steps := Max(C.moveStepsMin, Ceil(durationMs / C.moveStepMinSleepMs))
        sleepMs := Max(C.moveStepMinSleepMs, durationMs / steps)
    }

    Loop steps {
        if !S.applying || S.stopBatch
            return

        t := EaseInOutCubic(A_Index / steps)
        inv := 1 - t

        x := inv ** 3 * startX
            + 3 * inv ** 2 * t * c1x
            + 3 * inv * t ** 2 * c2x
            + t ** 3 * targetX

        y := inv ** 3 * startY
            + 3 * inv ** 2 * t * c1y
            + 3 * inv * t ** 2 * c2y
            + t ** 3 * targetY

        point := ClampPoint(x, y)
        DllCall("SetCursorPos", "Int", point.x, "Int", point.y)
        SleepWhileApplying(sleepMs)
    }

    if S.applying && !S.stopBatch
        DllCall("SetCursorPos", "Int", targetX, "Int", targetY)
}

GetMoveDuration(distance) {
    global C, S
    return Max(C.moveMinMs, Min(C.moveMaxMs, distance * C.moveMsPerPx)) / S.moveSpeed
}

EaseInOutCubic(t) {
    return t < 0.5
        ? 4 * t ** 3
        : 1 - ((-2 * t + 2) ** 3) / 2
}

TypeTextHuman(text) {
    global C, S

    textBuffer := ""

    for char in StrSplit(text) {
        if !S.applying || S.stopBatch
            return

        switch char {
            case " ":
                textBuffer .= " "

            case "`r":
                continue

            case "`n":
                SleepWhileApplying(RandomDelay(C.minEnterDelayMs, C.maxEnterDelayMs))
                if !S.applying || S.stopBatch
                    return
                SendInput "{Enter}"
                textBuffer := ""

            default:
                SleepWhileApplying(RandomDelay(C.minKeyDelayMs, C.maxKeyDelayMs))
                if !S.applying || S.stopBatch
                    return
                SendText textBuffer . char
                textBuffer := ""
        }
    }

    if textBuffer != "" && S.applying && !S.stopBatch
        SendText textBuffer
}

RandomDelay(minMs, maxMs) {
    global S
    return Max(0, Random(minMs / S.typingSpeed, maxMs / S.typingSpeed))
}

MapWheel(direction) {
    switch StrLower(direction) {
        case "up": return "{WheelUp}"
        case "down": return "{WheelDown}"
        case "left": return "{WheelLeft}"
        case "right": return "{WheelRight}"
        default: return "{WheelDown}"
    }
}

InstallMouseBlock() {
    global C, S

    if S.mouseBlockHook
        return

    S.mouseBlockCallback := CallbackCreate(MouseBlockProc, "Fast", 3)
    S.mouseBlockHook := DllCall(
        "SetWindowsHookExW",
        "Int", C.WH_MOUSE_LL,
        "Ptr", S.mouseBlockCallback,
        "Ptr", 0,
        "UInt", 0,
        "Ptr"
    )
}

UninstallMouseBlock() {
    global S

    if S.mouseBlockHook {
        DllCall("UnhookWindowsHookEx", "Ptr", S.mouseBlockHook)
        S.mouseBlockHook := 0
    }

    if S.mouseBlockCallback {
        CallbackFree(S.mouseBlockCallback)
        S.mouseBlockCallback := 0
    }
}

MouseBlockProc(nCode, wParam, lParam) {
    global C, S

    if nCode >= 0 && S.applying {
        flags := NumGet(lParam, 12, "UInt")
        if !(flags & C.LLMHF_INJECTED)
            return 1
    }

    return DllCall("CallNextHookEx", "Ptr", S.mouseBlockHook, "Int", nCode, "UPtr", wParam, "Ptr", lParam, "UPtr")
}


; =============================================================================
; Apply — presets and persisted state
; =============================================================================

DefaultSettings() {
    global C

    return {
        playback_speed: C.defaultPlaybackSpeed,
        typing_speed: C.defaultTypingSpeed,
        move_speed: C.defaultMoveSpeed,
        initial_delay: C.defaultInitialDelayMs,
        click_pause_ms: C.defaultClickPauseMs,
        segment_pause_ms: C.defaultSegmentPauseMs,
        use_recorded_timing: C.defaultUseRecordedTiming,
        smooth_mouse: C.defaultSmoothMouse,
        human_typing: C.defaultHumanTyping,
        variables: []
    }
}

ParsePresetFile(filePath) {
    settings := DefaultSettings()

    if !FileExist(filePath)
        return settings

    Loop Read filePath {
        line := Trim(A_LoopReadLine)

        if line = "" || SubStr(line, 1, 1) = "#"
            continue

        if RegExMatch(line, "i)^([\w_]+)\s*=\s*(.*)$", &m) {
            key := StrLower(m[1])
            value := Trim(m[2])

            switch key {
                case "playback_speed":
                    settings.playback_speed := SafeFloat(value, settings.playback_speed)
                case "typing_speed":
                    settings.typing_speed := SafeFloat(value, settings.typing_speed)
                case "move_speed":
                    settings.move_speed := SafeFloat(value, settings.move_speed)
                case "initial_delay":
                    settings.initial_delay := SafeInteger(value, settings.initial_delay)
                case "click_pause_ms":
                    settings.click_pause_ms := SafeInteger(value, settings.click_pause_ms)
                case "segment_pause_ms":
                    settings.segment_pause_ms := SafeInteger(value, settings.segment_pause_ms)
                case "use_recorded_timing":
                    settings.use_recorded_timing := SafeBool(value, settings.use_recorded_timing)
                case "smooth_mouse":
                    settings.smooth_mouse := SafeBool(value, settings.smooth_mouse)
                case "human_typing":
                    settings.human_typing := SafeBool(value, settings.human_typing)
            }

            continue
        }

        if RegExMatch(line, "i)^variable")
            continue

        settings.variables := []
        for field in StrSplit(line, ",")
            settings.variables.Push(Trim(field))
        break
    }

    return settings
}

ApplySettings(settings) {
    global S

    S.playbackSpeed := Max(0.05, settings.playback_speed)
    S.typingSpeed := Max(0.05, settings.typing_speed)
    S.moveSpeed := Max(0.05, settings.move_speed)
    S.initialDelayMs := Max(0, settings.initial_delay)
    S.clickPauseMs := Max(0, settings.click_pause_ms)
    S.segmentPauseMs := Max(0, settings.segment_pause_ms)
    S.useRecordedTiming := settings.use_recorded_timing
    S.smoothMouse := settings.smooth_mouse
    S.humanTyping := settings.human_typing
    S.variables := settings.variables.Clone()
}

WritePresetFile(settings, filePath) {
    EnsureParentDir(filePath)

    presetFile := FileOpen(filePath, "w", "UTF-8")
    if !presetFile
        throw Error("Could not open preset for writing: " filePath)

    presetFile.Write(SerializePreset(settings))
    presetFile.Close()
}

SerializePreset(settings) {
    return ""
        . "# timing — ms pauses; speeds: higher = faster`n"
        . "playback_speed=" settings.playback_speed "`n"
        . "typing_speed=" settings.typing_speed "`n"
        . "move_speed=" settings.move_speed "`n"
        . "initial_delay=" settings.initial_delay "`n"
        . "click_pause_ms=" settings.click_pause_ms "`n"
        . "segment_pause_ms=" settings.segment_pause_ms "`n"
        . "use_recorded_timing=" (settings.use_recorded_timing ? 1 : 0) "`n"
        . "smooth_mouse=" (settings.smooth_mouse ? 1 : 0) "`n"
        . "human_typing=" (settings.human_typing ? 1 : 0) "`n"
        . "`n"
        . "# variable-1, variable-2, variable-3 ...`n"
        . Join(settings.variables, ",") "`n"
}

ResolveVariableText(variableName) {
    global S

    if !RegExMatch(variableName, "i)^variable-?(\d+)$", &m)
        return ""

    index := Integer(m[1])
    return index >= 1 && index <= S.variables.Length ? S.variables[index] : ""
}

LoadManageState() {
    global C

    return {
        preset: Trim(IniRead(C.stateFile, C.stateSection, C.statePresetKey, "")),
        recording: Trim(IniRead(C.stateFile, C.stateSection, C.stateRecordingKey, "")),
        csv: Trim(IniRead(C.stateFile, C.stateSection, C.stateCsvKey, "")),
        csvAskNextLine: IniRead(C.stateFile, C.stateSection, C.stateCsvAskNextLineKey, "0") = "1"
    }
}

SaveManageState(presetName, recordingName, csvPath := "", csvAskNextLine := false) {
    global C

    EnsureParentDir(C.stateFile)
    IniWrite presetName, C.stateFile, C.stateSection, C.statePresetKey
    IniWrite recordingName, C.stateFile, C.stateSection, C.stateRecordingKey
    IniWrite csvPath, C.stateFile, C.stateSection, C.stateCsvKey
    IniWrite csvAskNextLine ? "1" : "0", C.stateFile, C.stateSection, C.stateCsvAskNextLineKey
}


; =============================================================================
; Shared helpers
; =============================================================================

/**
 * When a second launch finds an existing Data Entry Autonoma window, show it and exit
 * so #SingleInstance Force does not replace the running instance.
 * Restores the main GUI if it was hidden during Detect or Apply.
 */
ActivateExistingManageInstance() {
    global APP_GUI_TITLE

    DetectHiddenWindows true
    hwnd := WinExist(APP_GUI_TITLE)
    DetectHiddenWindows false

    if !hwnd
        return

    try {
        if WinGetMinMax("ahk_id " hwnd) = -1
            WinRestore "ahk_id " hwnd
        WinShow "ahk_id " hwnd
        WinActivate "ahk_id " hwnd
    }

    ExitApp 0
}

ListFiles(dir, pattern) {
    paths := []

    if !DirExist(dir)
        return paths

    Loop Files dir "\" pattern
        paths.Push(A_LoopFileFullPath)

    return paths
}

FileBaseName(path) {
    return RegExReplace(path, ".*\\", "")
}

FormatRecordingName(pathOrName) {
    global C

    name := FileBaseName(pathOrName)
    name := RegExReplace(name, "i)\.log$", "")
    name := RegExReplace(name, "i)^" C.diPrefix, "")
    return name
}

FormatPresetName(pathOrName) {
    global C

    name := FileBaseName(pathOrName)
    return RegExReplace(name, "i)\" C.saveExt "$", "")
}

SafePresetName(name) {
    global C

    name := Trim(name)
    name := RegExReplace(name, "[\\/:*?`"<>|]", "-")
    name := RegExReplace(name, "i)\" C.saveExt "$", "")
    return name
}

SelectByBaseName(listControl, paths, wantedBaseName) {
    if !listControl || wantedBaseName = ""
        return false

    for index, path in paths {
        if StrLower(FileBaseName(path)) = StrLower(wantedBaseName) {
            SelectListControlRow(listControl, index)
            return true
        }
    }

    return false
}

Join(values, delimiter) {
    text := ""

    for index, value in values {
        if index > 1
            text .= delimiter
        text .= value
    }

    return text
}

EnsureDir(dir) {
    if dir != ""
        DirCreate dir
}

EnsureParentDir(filePath) {
    parent := RegExReplace(filePath, "\\[^\\]+$", "")
    if parent != "" && parent != filePath
        DirCreate parent
}

CleanField(value) {
    value := StrReplace(value, "|", " ")
    value := StrReplace(value, "`n", " ")
    value := StrReplace(value, "`r", " ")
    return Trim(value)
}

NumOrZero(value) {
    try {
        return value + 0
    } catch {
        return 0
    }
}

SignedHighWord(value) {
    high := (value >> 16) & 0xFFFF
    return high >= 0x8000 ? high - 0x10000 : high
}

SafeInteger(value, fallback := 0) {
    try {
        if value = ""
            return fallback
        return Integer(value)
    } catch {
        return fallback
    }
}

SafeFloat(value, fallback := 0.0) {
    try {
        if value = ""
            return fallback
        return Float(value)
    } catch {
        return fallback
    }
}

/**
 * Parses a boolean preset value.
 * @param {String} value Raw text from a preset file.
 * @param {Boolean} fallback Value when parsing fails.
 * @returns {Boolean}
 */
SafeBool(value, fallback := false) {
    value := StrLower(Trim(value))

    if value = "1" || value = "true" || value = "yes" || value = "on"
        return true

    if value = "0" || value = "false" || value = "no" || value = "off"
        return false

    return fallback
}

IsNumericText(value) {
    return RegExMatch(value, "^-?\d+(\.\d+)?$")
}

EnableDpiAwareness() {
    static DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 := -4
    static PROCESS_PER_MONITOR_DPI_AWARE := 2

    try {
        DllCall("SetProcessDpiAwarenessContext", "Ptr", DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2, "Int")
    } catch {
        try DllCall("SetProcessDpiAwareness", "Int", PROCESS_PER_MONITOR_DPI_AWARE)
    }

    try DllCall("SetThreadDpiAwarenessContext", "Ptr", DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2, "Int")
}
