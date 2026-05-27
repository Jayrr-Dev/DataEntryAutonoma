#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn
SendMode "Input"
SetMouseDelay -1
SetKeyDelay -1

; dataEntryAutonoma.ahk
; Data Entry Autonoma v1.0.6 — record clicks, scrolls, and keys; replay with presets or CSV batches.
; Copyright (c) 2026 Jayrr Dev — https://github.com/Jayrr-Dev/DataEntryAutonoma
; SPDX-License-Identifier: MIT
; Unified Record and Run module with CSV batch support.
; Recordings: recordings\di-*.log
; Presets: saved-inputs\*.txt
; CSV batches: csv-batches\*.csv
; Bundles: Share as folder or optional ZIP; Import from manifest.json folder or .zip
; Esc saves recording (Cancel on the save dialog discards). Esc stops Run or a CSV batch.

EnableDpiAwareness()
CoordMode "Mouse", "Screen"
CoordMode "ToolTip", "Screen"

; =============================================================================
; Constants
; =============================================================================

C := {
    appVersion: "1.0.6", ; keep in sync with VERSION at project root
    recordingsDir: A_ScriptDir "\recordings",
    savesDir: A_ScriptDir "\saved-inputs",
    csvBatchesDir: A_ScriptDir "\csv-batches",
    appIconFile: A_ScriptDir "\assets\dataEntryAutonoma.ico",
    stateFile: A_ScriptDir "\apply-state.ini",
    saveExt: ".txt",
    csvExt: ".csv",
    ; Portable bundle (Share / Import ZIP)
    bundleFormatId: "data-entry-autonoma-bundle",
    bundleFormatVersion: 1,
    bundleManifestFileName: "manifest.json",
    bundleZipExt: ".dea.zip",
    bundleRecordingZipName: "recording.log",
    bundlePresetZipName: "data-input.txt",
    bundleCsvZipName: "batch.csv",
    bundleImportTempPrefix: "dea-import-",
    bundleStagingTempPrefix: "dea-bundle-stage-",

    bundlePowerShellExe: A_WinDir "\System32\WindowsPowerShell\v1.0\powershell.exe",
    bundleTarExe: A_WinDir "\System32\tar.exe",

    prefix: "di-",
    diPrefix: "di-",
    wheelDelta: 120,
    flushIntervalMs: 1000,
    batchRowPauseMs: 750,
    recordingsTabHelpTitle: "Recordings help",
    presetsTabHelpTitle: "Data Inputs help",
    csvBatchHelpTitle: "Bulk Inputs help",
    runOptionsTabHelpTitle: "Run Options help",
    speedSettingsTabHelpTitle: "Speed Settings help",
    presetVariablesHelpTitle: "Data input variables help",
    presetVariablesHelpMessage: "
    (
One row per variable in the table. Row 1 = variable-1, row 2 = variable-2, and so on.

Columns: Slot (variable-N), Label (optional note, stripped at run time), and Value (typed text).
Click Label or Value in the table to edit inline, or use Selected row below.
Add row inserts after the selected row; Delete row removes the selected row (at least one row required).

Labels can include spaces (Label Drawing Number, Value 281435 types 281435).

Escape a comma in a value with backslash:
  Label Developed_By, Value I\, LEE types I, LEE
  Use \\ for a literal backslash
    )",
    recordingLogEventsHelpTitle: "Recording events help",
    recordingLogEventsHelpMessage: "
    (
Edit Recording Log, Events tab (top to bottom)

(i) next to Recording events
Opens this help.

Recording events table
One row per logged event. Columns: #, Ms (elapsed ms), Type, Label, Summary.

Selected row
Edit Elapsed (ms) and the fields shown for that event type (click, key, scroll, shortcut, and so on).
Label is an optional note, ignored during Run and playback.

Apply row
Updates the table from Selected row. Double-click a row to apply quickly.
Switching rows or Save also commits the current row.

Label storage
Stored as |note|your text at the end of the log line. Does not affect Run.

Raw log tab
Read-only preview built from the Events table. Save writes the table back to the log file.

Description (top of window)
Free-form notes in the log header. Hover the recording on the main Recordings list to preview as a tooltip.

Save / Close
Save updates the recording file. Close leaves the file unchanged if you did not save.
    )",
    recordingsTabHelpMessage: "
    (
Recordings tab (top to bottom)

(i) next to Saved recordings
Opens this help.

Saved recordings list
Select a recording here before Run.
- Name: file name
- Variable count: how many typed values the recording expects
Hover a row to preview its description (set in Edit Log).

Rename
Change the selected recording's file name.

Edit Log
Adjust timing, description, optional row labels, and events in a table, or preview the raw log.

Delete
Remove the selected recording.

Record (bottom)
Start capturing clicks, keys, and delays for a new recording.

Run (bottom)
Replay the selected recording. Supply variable values on the Data Inputs or Bulk Inputs tab first.

While recording
- Esc saves (Cancel on the save dialog discards)
- Normal clicks stay clicks
- Hold Caps Lock to record a delay (Caps Lock is suppressed while recording)
- Hold or drag left-click for Excel-style selection
- Ctrl, Shift, or Alt shortcuts are recorded and replayed
- Type any character (a, b, c) to add a variable placeholder

Run: press Esc to stop playback.
    )",
    presetsTabHelpMessage: "
    (
Data Inputs tab (top to bottom)

(i) next to Run input source
Opens this help.

Use data input for Run
Supply variable values from the selected data input when you Run a recording. Only one input source can be active (Data Inputs or Bulk Inputs).

Saved data inputs list
Stored in saved-inputs\. Columns: Name, Variable count.
Hover a row to preview its optional description (set in Edit Data Input).

Add Data Input
Create a new data input (opens the editor with a suggested name).

Edit Data Input
Edit the name, optional description, and variable values.
- Table: one row per variable (row 1 = variable-1, row 2 = variable-2, ...).
- Columns: Slot, Label (optional note), Value (typed text).
- Click Label or Value to edit inline, or use Selected row and Apply row.
- Add row / Delete row adjust slots (at least one row required).

Delete Data Input
Remove the selected data input.

Variable values
Label is for your notes only and is stripped at run time. Values are what Run types.
Labels can include spaces (Label Drawing Number, Value 281435 types 281435).
Comma in a value: use backslash (Value I\, LEE types I, LEE).
Use \\ for a literal backslash.
Plain values with no label still work.

Other tabs
Speed Settings: speed multipliers and initial delay.
Run Options: mouse movement, typing style, and timing pauses.

Run (bottom)
Replay uses the selected data input's values. Esc stops playback.
    )",
    csvBatchHelpMessage: "
    (
Bulk Inputs tab (top to bottom)

(i) next to Saved CSV files
Opens this help.

Use bulk inputs for Run
Replay the selected recording once per CSV data row. Only one input source can be active (Data Inputs or Bulk Inputs).

Config
- Ask to run next line before each row: progress table, then Run, Skip, or Run all remaining
- Run all rows automatically: no prompt between rows

Saved CSV files
Stored in csv-batches\. List columns: Name, Line, Var Count.

Edit CSV
Table editor for the selected file (or a new file). Row 1 is the header. Click a cell to edit inline. Add row / Delete row / Add col / Delete col. Commas and backslashes in values are escaped automatically on Save.

Rename
Change the selected file name.

Delete
Remove the selected file.

Browse
Pick an external CSV path (optional import into csv-batches\).

Refresh
Reload all lists.

File format
Row 1: header (column labels; not typed during Run).
Column A on data rows: row label (display only in prompts).
Columns B onward: variable-1, variable-2, and so on.

Example:
  row,name,qty,region
  1,Alice,100,East
  2,Bob,250,West

Comma in a value: Smith\, Jones runs as Smith, Jones.
Use \\ for a literal backslash.
Single variable column: header value, then one value per row.
Blank lines and lines starting with # are ignored.

Run (bottom)
Each row supplies values for that pass. Esc stops the whole batch.
    )",
    runOptionsTabHelpMessage: "
    (
These options apply to the next Run.

Mouse movement:
- Smooth: curved, natural mouse movement
- Instant: jump directly to each target

Typing:
- Human-like: per-key delays
- Instant: send text immediately

Timing & pauses:
Click pause: after move, before click (ms)
Step pause: after each target before the next (ms)

Between steps:
- Fixed pauses only: use click and step pause values; ignore recorded gaps
- Recorded gaps: replay seconds between steps from Record

For speed multipliers and initial delay, use the Speed Settings tab.
    )",
    speedSettingsTabHelpMessage: "
    (
These options apply to the next Run.

Run speed: overall playback speed multiplier
Typing speed: how fast typed variable values are sent
Move speed: how fast the mouse moves between targets
Initial delay: wait time (ms) before playback starts

Higher speed values run faster.
    )",
    recordingTipText: "Esc = Save · Click = click · Hold Caps Lock = delay · Hold/drag LMB = hold",
    recordingTipOffsetX: 240,
    recordingTipOffsetY: 16,
    cursorTipOffsetX: 12,
    cursorTipOffsetY: 12,
    mouseHoldIndicatorText: "HOLD",
    recordingDelayIndicatorText: "DELAY",
    hotkeyTipPrefix: "Hotkey:",
    recordingTipRefreshMs: 1000,
    recordingTransientTipMs: 3000,
    ; Main window list hover tooltips for recording / data input descriptions (Edit dialogs).
    manageListTooltipPollMs: 350,
    manageListTooltipMaxLen: 420,
    manageListTooltipMaxWidth: 360,
    manageListTooltipGapAbove: 8,
    manageListTooltipPadX: 10,
    manageListTooltipPadY: 8,
    manageListTooltipMissHide: 3,
    manageListTooltipMouseMoveMinMs: 50,
    manageListTooltipShowDelayMs: 500,
    minRecordedDelayMs: 200,
    mouseHoldDragThresholdPx: 5,
    mouseHoldTipRefreshMs: 100,
    fileDeleteAttempts: 5,
    fileDeleteRetryMs: 250,

    stateSection: "last",
    statePresetKey: "preset",
    stateRecordingKey: "recording",
    stateCsvKey: "csv",
    stateCsvAskNextLineKey: "csvAskNextLine",
    inputSourcePreset: "preset",
    inputSourceCsv: "csv",

    csvAskNextLineLabel: "Ask to run next line before each row",
    csvRunAllRowsLabel: "Run all rows automatically",
    csvBatchConfigSectionLabel: "Config",
    csvBatchProgressTitle: "CSV batch progress",
    csvBatchStatusPending: "",
    csvBatchStatusDone: "✓",
    csvBatchStatusSkipped: "Skipped",
    csvBatchPromptChoiceNone: "",
    csvBatchPromptChoiceRun: "run",
    csvBatchPromptChoiceSkip: "skip",
    csvBatchPromptChoiceRunAll: "runAll",
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
    WM_LBUTTONUP: 0x202,
    WM_MOUSEMOVE: 0x200,
    WM_RBUTTONDOWN: 0x204,
    WM_RBUTTONUP: 0x205,
    WM_MBUTTONDOWN: 0x207,
    WM_XBUTTONDOWN: 0x20B,
    WM_MOUSEWHEEL: 0x20A,
    WM_MOUSEHWHEEL: 0x20E,

    WM_KEYDOWN: 0x100,
    WM_KEYUP: 0x101,
    WM_SYSKEYDOWN: 0x104,
    WM_SYSKEYUP: 0x105,

    VK_CAPITAL: 0x14,
    VK_ESCAPE: 0x1B,
    VK_F9: 0x78,
    VK_F10: 0x79,
    VK_LSHIFT: 0xA0,
    VK_RSHIFT: 0xA1,
    VK_LCONTROL: 0xA2,
    VK_RCONTROL: 0xA3,
    VK_LMENU: 0xA4,
    VK_RMENU: 0xA5,

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
    listTooltipBg: "FFFFFF",
    listTooltipText: "6B7280",
    secondaryBtnBg: "FFFFFF",
    secondaryBtnText: "374151",
    fontFamily: "Segoe UI",
    fontSizeTitle: 11,
    fontSizeBody: 10,
    fontSizeSmall: 9,
    contentWidth: 420,
    tabContentWidth: 404,
    tabListWidth: 378,
    tabButtonRowInset: 4,
    recordingColNameWidth: 255,
    recordingColVarCountWidth: 118,
    presetColNameWidth: 255,
    presetColVarCountWidth: 118,
    csvColNameWidth: 230,
    csvColLineWidth: 54,
    csvColVarCountWidth: 90,
    recordingListHeight: 300,
    presetListHeight: 285,
    marginX: 18,
    marginY: 2,
    btnGap: 10,
    btnHeightSecondary: 26,
    btnHeightTool: 28,
    btnHeightPrimary: 30,
    infoBtnSize: 14,
    infoBtnFontSize: 7,
    infoBtnBg: "EEF2FF",
    listMinH: 120,
    tabRadioRowH: 28,
    tabStripHeight: 36,
    tabInnerPad: 52,
    manageTabPanelHeight: 400,
    tabRowGap: 8,
    tabLabelHeight: 16,
    tabPanelSafetyPad: 12,
    recordingColName: "Name",
    recordingColVarCount: "Variable count",
    presetColName: "Name",
    presetColVarCount: "Variable count",
    csvColName: "Name",
    csvColLine: "Line",
    csvColVarCount: "Var Count",
    statusHeight: 30,
    csvEditWidth: 300,
    csvEditorWidth: 600,
    csvEditorListWidth: 560,
    csvEditorListHeight: 250,
    csvEditorMaxCols: 1000,
    csvEditorRowNumberColWidth: 40,
    csvEditorDataColWidth: 72,
    csvEditorInlineMinWidth: 40,
    csvEditorInlineMaxWidth: 140,
    csvEditorMarginX: 12,
    csvEditorMarginY: 4,
    csvEditorNameEditH: 24,
    csvEditorHelpTextH: 36,
    csvEditorButtonWidth: 72,
    csvEditorButtonHeight: 24,
    csvEditorButtonGap: 2,
    csvEditorButtonGroupGap: 6,
    csvEditorListToButtonsGap: -2,
    csvEditorButtonsToSaveGap: 4,
    csvEditorSaveButtonWidth: 120,
    csvEditorSaveButtonHeight: 28,
    csvEditorSaveButtonGap: 6,
    csvEditorBottomPad: 10,
    csvEditorOuterPad: 14,
    csvBatchTableWidth: 560,
    csvBatchTableHeight: 190,
    csvBatchPromptDetailsLines: 5,
    csvBatchPromptBtnWidth: 118,
    presetEditorWidth: 690,
    presetEditorFieldWidth: 690,
    presetEditorLabelWidth: 180,
    presetEditorValueWidth: 220,
    presetEditorInlineLabelMaxWidth: 160,
    presetEditorInlineValueMaxWidth: 220,
    presetEditorListHeight: 270,
    ; Variable-inputs block height (header → Save/Close). 0 = auto from parts; >0 scales ListView too.
    presetEditorTabHeight: 300,
    presetEditorApplyRowHeight: 32,
    presetEditorDetailLabelWidth: 80,
    presetEditorDetailValueWidth: 400,
    presetEditorHelpHeight: 40,
    presetEditorSectionRowHeight: 28,
    presetEditorEditRowHeight: 28,
    presetEditorSaveSectionGap: 14,
    presetEditorButtonRowHeight: 44,
    presetEditorBottomPad: 20,
    presetEditorOuterPad: 32,
    presetEditorSafetyPad: 24,
    recordingLogEditorWidth: 580,
    recordingLogEditorTabHeight: 520,
    recordingLogEditorListHeight: 240,
    recordingLogEditorDetailLabelWidth: 108,
    recordingLogEditorDetailValueWidth: 432,
    recordingLogEditorButtonRowHeight: 40,
    recordingLogEditorOuterPad: 32,
    recordingLogEditorDescLabelH: 16,
    recordingLogEditorDescEditH: 52,
    presetEditorDescLabelH: 16,
    presetEditorDescEditH: 52,
}

; Recording log header / event format (must initialize before CreateManageGui → RefreshRecordingList).
/** Trailing log field marker for optional editor note labels (ignored during playback). */
RECORDING_LOG_NOTE_FIELD := "note"
/** Stored in one header line instead of newline characters (`PeelRecordingDescriptionFromHeader`). */
RECORDING_LOG_DESC_DISPLAY_SEP := " · "
/** Stable prefix matched when reading or rewriting description header lines (no trailing space). */
RECORDING_LOG_DESC_HEADER_LINE_PREFIX := "# description: "

; Main window title — must match CreateManageGui; used for #SingleInstance rediscovery.
APP_GUI_TITLE := "Data Entry Autonoma v" C.appVersion
AUTHOR_NAME := "Jayrr"
AUTHOR_GITHUB_URL := "https://github.com/Jayrr-Dev"
AUTHOR_COPYRIGHT_YEAR := "2026"

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
    inputSourceMode: "preset",

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
    leftHoldPending: false,
    leftHoldActive: false,
    leftHoldDownAt: 0,
    leftHoldActiveStartedAt: 0,
    leftHoldDownX: 0,
    leftHoldDownY: 0,
    leftHoldEndX: 0,
    leftHoldEndY: 0,
    capsLockHoldPending: false,
    capsLockHoldActive: false,
    capsLockHoldDownAt: 0,
    modCtrlDown: false,
    modShiftDown: false,
    modAltDown: false,
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
    csvList: "",
    csvPaths: [],
    csvEdit: "",
    detectButton: "",
    applyButton: "",
    importBundleButton: "",
    shareBundleButton: "",
    editButton: "",
    addPresetButton: "",
    browseCsvButton: "",
    csvBatchInfoButton: "",
    csvAskNextLineRadio: "",
    csvRunAllRowsRadio: "",
    csvBatchRunAllRemaining: false,
    csvBatchTableGui: "",
    csvBatchTableLv: "",
    csvBatchStatusColumnIndex: 0,
    csvBatchProgressTableWidth: 0,
    csvBatchPromptDetails: "",
    csvBatchRunBtn: "",
    csvBatchSkipBtn: "",
    csvBatchRunAllBtn: "",
    renameRecordingButton: "",
    editRecordingButton: "",
    deleteRecordingButton: "",
    refreshCsvButton: "",
    deletePresetButton: "",
    editCsvButton: "",
    renameCsvButton: "",
    deleteCsvButton: "",
    usePresetRadio: "",
    useCsvRadio: "",
    smoothMouseRadio: "",
    instantMouseRadio: "",
    humanTypingRadio: "",
    instantTypingRadio: "",
    playbackSpeedEdit: "",
    typingSpeedEdit: "",
    moveSpeedEdit: "",
    initialDelayEdit: "",
    clickPauseEdit: "",
    segmentPauseEdit: "",
    fixedPausesRadio: "",
    recordedGapsRadio: "",
    recordingInfoButton: "",
    presetInfoButton: "",
    runOptionsInfoButton: "",
    speedSettingsInfoButton: "",
    mainTab: "",
    listTooltipShownText: "",
    listTooltipRecordingRow: 0,
    listTooltipPresetRow: 0,
    listDescOverlayGui: "",
    listDescOverlayText: "",
    listDescOverlayShown: false,
    listDescOverlayLastText: "",
    listDescOverlayLastX: 0,
    listDescOverlayLastY: 0,
    listTooltipMissStreak: 0,
    listTooltipHoverKey: "",
    listTooltipHoverSince: 0,
    listTooltipPendingTip: "",
    listTooltipPendingKind: "",
    listTooltipPendingRow: 0,
    listTooltipPendingX: 0,
    listTooltipPendingY: 0,
    presetEditorEnterCallback: "",
    recordingDescCache: Map(),
    presetDescCache: Map()
}

ActivateExistingManageInstance()
ApplyManageStartupIcon()

CreateManageGui()
EnsureDir(C.savesDir)
EnsureDir(C.csvBatchesDir)
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
 * Forces a Tab3 control onto one tab row (scroll arrows when labels overflow).
 * @param {Gui.Tab} tabCtrl Tab3 control.
 */
ApplyManageTabControlSingleRow(tabCtrl) {
    if !tabCtrl
        return

    TCS_MULTILINE := 0x0200
    GWL_STYLE := -16
    SWP_FLAGS := 0x0027

    style := DllCall("GetWindowLongPtr", "Ptr", tabCtrl.Hwnd, "Int", GWL_STYLE, "Ptr")
    if style & TCS_MULTILINE {
        DllCall("SetWindowLongPtr", "Ptr", tabCtrl.Hwnd, "Int", GWL_STYLE, "Ptr", style & ~TCS_MULTILINE, "Ptr")
        DllCall(
            "SetWindowPos",
            "Ptr", tabCtrl.Hwnd, "Ptr", 0,
            "Int", 0, "Int", 0, "Int", 0, "Int", 0,
            "UInt", SWP_FLAGS,
            "Int", 0, "Int", 0
        )
    }
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
 * Adds a tab section label row with optional inline info button.
 * Use as the first control on a tab page so Section anchors xs lists to the tab-left margin.
 * Never use xm inside Tab pages; xm is the window margin, not the tab interior (Gui Tab docs).
 * @param {String} labelText Label text.
 * @param {Func} helpHandler Optional Click handler for the info button.
 * @returns {Gui.Button|""} Info button, or empty string when helpHandler is omitted.
 */
AddManageTabSectionLabel(labelText, helpHandler := "") {
    global UI, S

    S.gui.SetFont("s" UI.fontSizeSmall, UI.fontFamily)
    S.gui.Add("Text", "Section c" UI.textMuted, labelText)
    if !helpHandler
        return ""

    btn := AddManageTabInfoButton()
    btn.OnEvent("Click", helpHandler)
    return btn
}

/**
 * Returns Gui Add options for a full-width list on the current tab below a Section label row.
 * xs keeps X at the tab section anchor; xm must not be used inside Tab pages.
 * @param {Integer} height Control height in pixels.
 * @param {String} extraOpts Extra control options (for example "-Multi").
 * @returns {String}
 */
BuildManageTabListOptions(height, extraOpts := "") {
    global UI

    opts := "xs w" UI.tabListWidth " h" height " +Background" UI.listBg
    extraOpts := Trim(extraOpts)
    return extraOpts != "" ? opts " " extraOpts : opts
}

/**
 * Adds a circular tab help info button beside a section label.
 * @param {String} options Gui Add options after position (default x+2).
 * @returns {Gui.Button}
 */
AddManageTabInfoButton(options := "x+2") {
    global UI, S

    btn := S.gui.Add("Button", options " w" UI.infoBtnSize " h" UI.infoBtnSize " -Theme", "i")
    ApplyManageCircularInfoButton(btn)
    return btn
}

/**
 * Adds a circular info button on a child dialog or editor window.
 * @param {Gui} gui Target window.
 * @param {String} options Gui Add options after position (default x+2).
 * @returns {Gui.Button}
 */
AddManageChildInfoButton(gui, options := "x+2") {
    global UI

    btn := gui.Add("Button", options " w" UI.infoBtnSize " h" UI.infoBtnSize " -Theme", "i")
    ApplyManageCircularInfoButton(btn)
    return btn
}

/**
 * Shows a help message in a modal dialog.
 * @param {String} message Help body text.
 * @param {String} title Dialog title.
 */
ShowManageHelpMessage(message, title) {
    ShowManageMsgBox message, title, "Iconi"
}

/**
 * Applies ListView column widths and formats for the recordings list.
 */
ApplyManageRecordingListColumns() {
    global UI, S

    if !S.recordingList
        return

    S.recordingList.ModifyCol(1, UI.recordingColNameWidth)
    S.recordingList.ModifyCol(2, UI.recordingColVarCountWidth)
    S.recordingList.ModifyCol(2, "Integer")
}

/**
 * Applies ListView column widths and formats for the data inputs list.
 */
ApplyManagePresetListColumns() {
    global UI, S

    if !S.presetList
        return

    S.presetList.ModifyCol(1, UI.presetColNameWidth)
    S.presetList.ModifyCol(2, UI.presetColVarCountWidth)
    S.presetList.ModifyCol(2, "Integer")
    SetManageListViewColumnIntegerSort(S.presetList, 2)
}

/**
 * Applies ListView column widths and formats for the bulk CSV file list.
 */
ApplyManageCsvListColumns() {
    global UI, S

    if !S.csvList
        return

    S.csvList.ModifyCol(1, UI.csvColNameWidth)
    S.csvList.ModifyCol(2, UI.csvColLineWidth)
    S.csvList.ModifyCol(3, UI.csvColVarCountWidth)
    S.csvList.ModifyCol(2, "Integer")
    S.csvList.ModifyCol(3, "Integer")
    SetManageListViewColumnIntegerSort(S.csvList, 2)
    SetManageListViewColumnIntegerSort(S.csvList, 3)
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
    return Floor((UI.tabListWidth - UI.btnGap * 2 - UI.tabButtonRowInset) / 3)
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
 * Returns fixed chrome and list heights so tab lists fill the panel evenly.
 * @returns {Object}
 */
GetManageInputTabMetrics() {
    global UI

    recordingChrome := UI.tabLabelHeight + UI.tabRowGap + UI.tabRowGap + UI.btnHeightSecondary
    presetChrome := UI.tabLabelHeight + UI.tabRowGap + UI.tabRadioRowH + UI.tabRowGap
        + UI.tabRowGap + UI.btnHeightTool
    csvChrome := UI.tabLabelHeight + UI.tabRowGap
        + UI.tabRadioRowH + UI.tabRowGap
        + UI.tabLabelHeight + UI.tabRowGap
        + UI.tabRadioRowH + UI.tabRowGap
        + UI.tabRadioRowH + UI.tabRowGap
        + UI.tabLabelHeight + UI.tabRowGap
        + UI.tabRowGap + UI.btnHeightTool + UI.tabRowGap + UI.btnHeightTool + UI.tabRowGap + UI.btnHeightTool
    playbackContent := UI.tabLabelHeight + UI.tabRowGap + (UI.tabLabelHeight + UI.tabRowGap + 24) * 2 + UI.tabRowGap + 36
    runOptionsChrome := playbackContent + UI.tabLabelHeight + UI.tabRowGap
        + (UI.tabLabelHeight + UI.tabRowGap + 24) * 2 + UI.tabRowGap
        + UI.tabLabelHeight + UI.tabRowGap + UI.tabRadioRowH + UI.tabRowGap + 36
    speedChrome := UI.tabLabelHeight + UI.tabRowGap
        + (UI.tabLabelHeight + UI.tabRowGap + 24) * 4 + UI.tabRowGap + 36

    recordingTabContentH := recordingChrome + UI.recordingListHeight
    presetTabContentH := presetChrome + UI.presetListHeight
    autoTabContentH := Max(csvChrome + UI.listMinH, runOptionsChrome, speedChrome, recordingTabContentH, presetTabContentH)
    tabChromeH := UI.tabStripHeight + UI.tabInnerPad + UI.tabPanelSafetyPad + 8
    tabContentH := UI.manageTabPanelHeight > 0
        ? Max(UI.listMinH, UI.manageTabPanelHeight - tabChromeH)
        : autoTabContentH
    listRecordingH := UI.recordingListHeight
    listPresetH := UI.presetListHeight
    listCsvH := Max(UI.listMinH, tabContentH - csvChrome)

    return {
        tabContentH: tabContentH,
        listRecordingH: listRecordingH,
        listPresetH: listPresetH,
        listCsvH: listCsvH
    }
}

/**
 * Returns Tab3 height (tab strip + page content). Uses UI.manageTabPanelHeight when > 0.
 * @returns {Integer}
 */
GetManageTabPanelHeight() {
    global UI

    if UI.manageTabPanelHeight > 0
        return UI.manageTabPanelHeight
    metrics := GetManageInputTabMetrics()
    return UI.tabStripHeight + UI.tabInnerPad + metrics.tabContentH + UI.tabPanelSafetyPad + 8
}

/**
 * Vertical chrome in Edit Data Input from "Variable inputs" through Save/Close (excludes ListView).
 * @returns {Integer}
 */
GetPresetEditorVariableSectionChromeHeight() {
    global UI

    editRowH := UI.presetEditorEditRowHeight
    return UI.presetEditorSectionRowHeight + UI.tabRowGap
        + UI.presetEditorHelpHeight + UI.tabRowGap
        + UI.btnHeightTool + UI.tabRowGap
        + UI.tabLabelHeight + UI.tabRowGap
        + (editRowH + UI.tabRowGap) * 3
        + UI.presetEditorApplyRowHeight + UI.tabRowGap
        + UI.presetEditorSaveSectionGap + UI.presetEditorButtonRowHeight
}

/**
 * ListView height for Edit Data Input. When UI.presetEditorTabHeight > 0, grows/shrinks with that knob.
 * @returns {Integer}
 */
GetPresetEditorListHeightForShow() {
    global UI

    if UI.presetEditorTabHeight > 0
        return Max(UI.listMinH, UI.presetEditorTabHeight - GetPresetEditorVariableSectionChromeHeight())
    return UI.presetEditorListHeight
}

/**
 * Variable-inputs section height for Edit Data Input (matches recordingLogEditorTabHeight role).
 * @returns {Integer}
 */
GetPresetEditorVariableSectionHeight() {
    global UI

    if UI.presetEditorTabHeight > 0
        return UI.presetEditorTabHeight
    return GetPresetEditorVariableSectionChromeHeight() + UI.presetEditorListHeight + UI.tabRowGap
}

/**
 * Returns Edit Data Input dialog height (name + description + variable section + padding).
 * @returns {Integer}
 */
GetPresetEditorWindowHeight() {
    global UI

    editRowH := UI.presetEditorEditRowHeight
    nameBlock := UI.tabLabelHeight + UI.tabRowGap + editRowH + UI.tabRowGap
    descBlock := UI.presetEditorDescLabelH + UI.tabRowGap + UI.presetEditorDescEditH + UI.tabRowGap

    return nameBlock + descBlock + GetPresetEditorVariableSectionHeight()
        + UI.presetEditorBottomPad + UI.presetEditorOuterPad + UI.presetEditorSafetyPad + (UI.marginY * 2)
}

/**
 * Adds a centered copyright footer; author name opens GitHub in the default browser.
 * @param {Gui} gui Parent manage window.
 */
AddManageAuthorFooter(gui) {
    global UI, AUTHOR_NAME, AUTHOR_GITHUB_URL, AUTHOR_COPYRIGHT_YEAR

    gui.SetFont("s" UI.fontSizeSmall, UI.fontFamily)
    gui.Add("Text", "xm w" UI.contentWidth " h1", "")
    footerHtml := "© " AUTHOR_COPYRIGHT_YEAR ' <a href="' AUTHOR_GITHUB_URL '">' AUTHOR_NAME "</a>"
    gui.Add("Link", "xm w" UI.contentWidth " c" UI.textMuted " Center", footerHtml)
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
    tabMetrics := GetManageInputTabMetrics()

    S.gui := Gui("+AlwaysOnTop -MaximizeBox", APP_GUI_TITLE)
    ApplyManageGuiTheme(S.gui)
    S.gui.OnEvent("Close", GuiClosed)

    bundleBtnW := 76
    titleRowW := UI.contentWidth - (bundleBtnW * 2) - (UI.btnGap * 2)

    S.gui.SetFont("s" UI.fontSizeTitle, UI.fontFamily)
    S.gui.Add("Text", "xm w" titleRowW " c" UI.textPrimary . " Section", "Data Entry Autonoma")
    S.importBundleButton := S.gui.Add(
        "Button",
        "x+" UI.btnGap " yp w" bundleBtnW " h" hSec " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Import"
    )
    S.importBundleButton.OnEvent("Click", ImportDataEntryBundle)
    S.shareBundleButton := S.gui.Add(
        "Button",
        "x+" UI.btnGap " yp w" bundleBtnW " h" hSec " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Share"
    )
    S.shareBundleButton.OnEvent("Click", ShareDataEntryBundle)

    S.gui.SetFont("s" UI.fontSizeBody, UI.fontFamily)
    S.gui.Add(
        "Text",
        "xm w" UI.contentWidth " c" UI.textMuted,
        "Record once. Run with data inputs or CSV batches.  v" C.appVersion
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
        ["Recordings", "Data Inputs", "Bulk Inputs", "Run Options", "Speed Settings"]
    )
    ApplyManageTabControlSingleRow(S.mainTab)

    ; --- Recording tab ---
    S.mainTab.UseTab(1)
    S.recordingInfoButton := AddManageTabSectionLabel("Saved recordings", ShowRecordingsTabHelp)
    S.gui.SetFont("s" UI.fontSizeBody, UI.fontFamily)
    S.recordingList := S.gui.Add(
        "ListView",
        BuildManageTabListOptions(tabMetrics.listRecordingH, "-Multi"),
        [UI.recordingColName, UI.recordingColVarCount]
    )
    S.recordingList.OnEvent("ItemSelect", (*) => (RememberSelections(), UpdateSelectionStatus()))
    ApplyManageRecordingListColumns()

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

    ; --- Data Inputs tab ---
    S.mainTab.UseTab(2)
    S.presetInfoButton := AddManageTabSectionLabel("Run input source", ShowPresetsTabHelp)
    S.gui.SetFont("s" UI.fontSizeBody, UI.fontFamily)
    S.usePresetRadio := S.gui.Add("Radio", "xs Checked", "Use data input for Run")
    S.usePresetRadio.OnEvent("Click", (*) => SetInputSourceMode(C.inputSourcePreset))

    S.presetList := S.gui.Add(
        "ListView",
        BuildManageTabListOptions(tabMetrics.listPresetH),
        [UI.presetColName, UI.presetColVarCount]
    )
    S.presetList.OnEvent("ItemSelect", OnPresetListChange)
    ApplyManagePresetListColumns()

    S.addPresetButton := S.gui.Add(
        "Button",
        "xs w" threeBtnW " h" hTool " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Add Data Input"
    )
    S.addPresetButton.OnEvent("Click", (*) => ShowPresetEditor(true))

    S.editButton := S.gui.Add(
        "Button",
        "x+" btnGap " w" threeBtnW " h" hTool " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Edit Data Input"
    )
    S.editButton.OnEvent("Click", (*) => ShowPresetEditor(false))

    S.deletePresetButton := S.gui.Add(
        "Button",
        "x+" btnGap " w" threeBtnW " h" hTool " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Delete Data Input"
    )
    S.deletePresetButton.OnEvent("Click", DeleteSelectedPreset)

    ; --- Bulk Inputs tab ---
    S.mainTab.UseTab(3)
    S.gui.SetFont("s" UI.fontSizeSmall, UI.fontFamily)
    S.gui.Add("Text", "Section c" UI.textMuted, "Run input source")
    S.gui.SetFont("s" UI.fontSizeBody, UI.fontFamily)
    S.useCsvRadio := S.gui.Add("Radio", "xs", "Use bulk inputs for Run")
    S.useCsvRadio.OnEvent("Click", (*) => SetInputSourceMode(C.inputSourceCsv))

    S.gui.SetFont("s" UI.fontSizeSmall, UI.fontFamily)
    S.gui.Add("Text", "xs Section c" UI.textMuted, C.csvBatchConfigSectionLabel)
    S.gui.SetFont("s" UI.fontSizeBody, UI.fontFamily)
    S.csvAskNextLineRadio := S.gui.Add("Radio", "xs", C.csvAskNextLineLabel)
    S.csvAskNextLineRadio.OnEvent("Click", OnCsvBatchRunModeChange)
    S.csvRunAllRowsRadio := S.gui.Add("Radio", "xs -Group", C.csvRunAllRowsLabel)
    S.csvRunAllRowsRadio.OnEvent("Click", OnCsvBatchRunModeChange)

    S.gui.SetFont("s" UI.fontSizeSmall, UI.fontFamily)
    S.gui.Add("Text", "xs c" UI.textMuted, "Saved CSV files")
    S.csvBatchInfoButton := AddManageTabInfoButton("x+2")
    S.csvBatchInfoButton.OnEvent("Click", ShowCsvBatchHelp)
    S.gui.SetFont("s" UI.fontSizeBody, UI.fontFamily)
    S.csvList := S.gui.Add(
        "ListView",
        BuildManageTabListOptions(tabMetrics.listCsvH),
        [UI.csvColName, UI.csvColLine, UI.csvColVarCount]
    )
    S.csvList.OnEvent("ItemSelect", OnCsvListChange)
    ApplyManageCsvListColumns()

    S.editCsvButton := S.gui.Add(
        "Button",
        "xs w" threeBtnW " h" hTool " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Edit CSV"
    )
    S.editCsvButton.OnEvent("Click", ShowCsvEditor)

    S.renameCsvButton := S.gui.Add(
        "Button",
        "x+" btnGap " w" threeBtnW " h" hTool " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Rename"
    )
    S.renameCsvButton.OnEvent("Click", RenameSelectedCsv)

    S.deleteCsvButton := S.gui.Add(
        "Button",
        "x+" btnGap " w" threeBtnW " h" hTool " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Delete"
    )
    S.deleteCsvButton.OnEvent("Click", DeleteSelectedCsv)

    S.csvEdit := S.gui.Add(
        "Edit",
        "xs w" UI.csvEditWidth " +Background" UI.editBg,
        ""
    )
    S.browseCsvButton := S.gui.Add(
        "Button",
        "x+" btnGap " w" (UI.tabListWidth - UI.csvEditWidth - btnGap) " h" hTool
        " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Browse..."
    )
    S.browseCsvButton.OnEvent("Click", BrowseCsvFile)

    S.refreshCsvButton := S.gui.Add(
        "Button",
        "xs w" threeBtnW " h" hTool " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Refresh"
    )
    S.refreshCsvButton.OnEvent("Click", (*) => RefreshAllLists(true))

    ; --- Run Options tab ---
    S.mainTab.UseTab(4)
    S.runOptionsInfoButton := AddManageTabSectionLabel("Run options", ShowRunOptionsTabHelp)
    S.gui.SetFont("s" UI.fontSizeBody, UI.fontFamily)
    S.gui.Add("Text", "xs w" UI.tabListWidth " c" UI.textMuted, "Mouse movement")
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
    S.gui.SetFont("s" UI.fontSizeSmall, UI.fontFamily)
    S.gui.Add("Text", "xs Section c" UI.textMuted, "Timing & pauses")
    S.gui.SetFont("s" UI.fontSizeBody, UI.fontFamily)
    S.gui.Add("Text", "xs w" UI.tabListWidth " c" UI.textMuted, "Click pause (ms)")
    S.clickPauseEdit := S.gui.Add("Edit", "xs w" UI.tabListWidth " +Background" UI.editBg, C.defaultClickPauseMs)
    S.gui.Add("Text", "xs w" UI.tabListWidth " c" UI.textMuted, "Step pause (ms)")
    S.segmentPauseEdit := S.gui.Add("Edit", "xs w" UI.tabListWidth " +Background" UI.editBg, C.defaultSegmentPauseMs)
    S.gui.SetFont("s" UI.fontSizeSmall, UI.fontFamily)
    S.gui.Add(
        "Text",
        "xs w" UI.tabListWidth " c" UI.textHint,
        "Click pause: after move, before click. Step pause: after each target before the next."
    )
    S.gui.SetFont("s" UI.fontSizeBody, UI.fontFamily)
    S.gui.Add("Text", "xs w" UI.tabListWidth " c" UI.textMuted, "Between steps")
    S.fixedPausesRadio := S.gui.Add(
        "Radio",
        "xs" (!C.defaultUseRecordedTiming ? " Checked" : ""),
        "Fixed pauses only"
    )
    S.recordedGapsRadio := S.gui.Add(
        "Radio",
        "x+16" (C.defaultUseRecordedTiming ? " Checked" : ""),
        "Recorded gaps"
    )
    S.gui.SetFont("s" UI.fontSizeSmall, UI.fontFamily)
    S.gui.Add(
        "Text",
        "xs w" UI.tabListWidth " c" UI.textHint,
        "Recorded gaps replay seconds between steps from Record. Fixed pauses only ignores those."
    )
    S.gui.SetFont("s" UI.fontSizeBody, UI.fontFamily)

    ; --- Speed Settings tab ---
    S.mainTab.UseTab(5)
    S.speedSettingsInfoButton := AddManageTabSectionLabel("Speed settings", ShowSpeedSettingsTabHelp)
    S.gui.SetFont("s" UI.fontSizeBody, UI.fontFamily)
    S.gui.Add("Text", "xs w" UI.tabListWidth " c" UI.textMuted, "Run speed")
    S.playbackSpeedEdit := S.gui.Add("Edit", "xs w" UI.tabListWidth " +Background" UI.editBg, C.defaultPlaybackSpeed)
    S.gui.Add("Text", "xs w" UI.tabListWidth " c" UI.textMuted, "Typing speed")
    S.typingSpeedEdit := S.gui.Add("Edit", "xs w" UI.tabListWidth " +Background" UI.editBg, C.defaultTypingSpeed)
    S.gui.Add("Text", "xs w" UI.tabListWidth " c" UI.textMuted, "Move speed")
    S.moveSpeedEdit := S.gui.Add("Edit", "xs w" UI.tabListWidth " +Background" UI.editBg, C.defaultMoveSpeed)
    S.gui.Add("Text", "xs w" UI.tabListWidth " c" UI.textMuted, "Initial delay (ms)")
    S.initialDelayEdit := S.gui.Add("Edit", "xs w" UI.tabListWidth " +Background" UI.editBg, C.defaultInitialDelayMs)
    S.gui.SetFont("s" UI.fontSizeSmall, UI.fontFamily)
    S.gui.Add(
        "Text",
        "xs w" UI.tabListWidth " c" UI.textHint,
        "Higher speed values run faster. Initial delay waits before playback starts."
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
        "Record: Esc saves, hold Caps Lock for delay, type any char (a,b,c) to add Var. Run: Esc stops."
    )
    AddManageAuthorFooter(S.gui)

    S.gui.Show()
    ApplyManageAppIcon(S.gui)
    EnsureManageOwnDialogs()
    SyncRunSettingsFromGui()
    SetManageMainListTooltipPolling(true)
    RefreshAllLists(true)
}

GuiClosed(*) {
    global S

    if S.recording
        CancelRecording()
    else if S.applying || S.batchRunning
        RequestStop()
    else {
        SetManageMainListTooltipPolling(false)
        ExitApp()
    }
}

/**
 * Enables or disables interactive controls while recording or applying.
 * @param {Boolean} enabled Whether controls should accept input.
 */
SetInteractiveState(enabled) {
    global S

    for ctrl in [S.detectButton, S.applyButton, S.importBundleButton, S.shareBundleButton,
        S.addPresetButton, S.refreshCsvButton, S.editButton,
        S.renameRecordingButton, S.editRecordingButton, S.deleteRecordingButton,
        S.deletePresetButton, S.recordingList, S.presetList, S.csvList, S.csvEdit, S.browseCsvButton,
        S.editCsvButton, S.renameCsvButton, S.deleteCsvButton,
        S.usePresetRadio, S.useCsvRadio,
        S.recordingInfoButton, S.presetInfoButton, S.csvBatchInfoButton, S.runOptionsInfoButton,
        S.speedSettingsInfoButton,
        S.csvAskNextLineRadio, S.csvRunAllRowsRadio,
        S.smoothMouseRadio, S.instantMouseRadio, S.humanTypingRadio, S.instantTypingRadio,
        S.playbackSpeedEdit, S.typingSpeedEdit, S.moveSpeedEdit, S.initialDelayEdit,
        S.clickPauseEdit, S.segmentPauseEdit, S.fixedPausesRadio, S.recordedGapsRadio,
        S.mainTab] {
        if ctrl
            ctrl.Enabled := enabled
    }

    if enabled
        ApplyInputSourceControlState()
}

/**
 * Clears the selected data input.
 */
ClearPresetSelection() {
    global S

    if !S.presetList
        return

    if HasMethod(S.presetList, "Modify")
        S.presetList.Modify(0, "-Select -Focus")
    else
        S.presetList.Value := 0
}

/**
 * Clears the selected CSV batch path and list selection.
 */
ClearCsvSelection() {
    global S

    if S.csvList {
        if HasMethod(S.csvList, "Modify")
            S.csvList.Modify(0, "-Select -Focus")
        else
            S.csvList.Value := 0
    }
    if S.csvEdit
        S.csvEdit.Value := ""
}

/**
 * Switches between preset and CSV batch as the run input source.
 * @param {String} mode Input source mode: preset or csv.
 * @param {Boolean} persist When true, saves state and refreshes status text.
 */
SetInputSourceMode(mode, persist := true) {
    global C, S

    mode := mode = C.inputSourceCsv ? C.inputSourceCsv : C.inputSourcePreset
    S.inputSourceMode := mode

    if mode = C.inputSourcePreset
        ClearCsvSelection()
    else
        ClearPresetSelection()

    ApplyInputSourceControlState()

    if persist {
        RememberSelections()
        UpdateSelectionStatus()
    }
}

/**
 * Enables preset or CSV controls based on the active input source mode.
 */
ApplyInputSourceControlState() {
    global C, S

    presetMode := S.inputSourceMode != C.inputSourceCsv

    if S.usePresetRadio
        S.usePresetRadio.Value := presetMode ? 1 : 0
    if S.useCsvRadio
        S.useCsvRadio.Value := presetMode ? 0 : 1

    for ctrl in [S.presetList, S.addPresetButton, S.editButton, S.deletePresetButton]
        if ctrl
            ctrl.Enabled := presetMode

    for ctrl in [
        S.csvList, S.csvEdit, S.browseCsvButton, S.editCsvButton, S.renameCsvButton,
        S.deleteCsvButton, S.refreshCsvButton, S.csvAskNextLineRadio, S.csvRunAllRowsRadio,
        S.useCsvRadio
    ]
        if ctrl
            ctrl.Enabled := !presetMode

    if S.usePresetRadio
        S.usePresetRadio.Enabled := true
    if S.useCsvRadio
        S.useCsvRadio.Enabled := true
}

/**
 * Syncs CSV batch run-mode radios with persisted state.
 */
SyncCsvBatchRunModeFromState() {
    global S

    if S.csvAskNextLineRadio
        S.csvAskNextLineRadio.Value := S.csvAskNextLine ? 1 : 0
    if S.csvRunAllRowsRadio
        S.csvRunAllRowsRadio.Value := S.csvAskNextLine ? 0 : 1
}

/**
 * Persists CSV batch run mode when an inline radio is selected.
 */
OnCsvBatchRunModeChange(*) {
    global S

    if S.csvAskNextLineRadio && S.csvAskNextLineRadio.Value {
        S.csvAskNextLine := true
        RememberSelections()
        return
    }

    if S.csvRunAllRowsRadio && S.csvRunAllRowsRadio.Value {
        S.csvAskNextLine := false
        RememberSelections()
    }
}

/**
 * Handles preset list selection and switches run input to preset mode.
 */
OnPresetListChange(*) {
    global C, S

    if !S.presetList || !GetListControlSelectedIndex(S.presetList)
        return

    if S.inputSourceMode != C.inputSourcePreset
        SetInputSourceMode(C.inputSourcePreset, false)

    ClearCsvSelection()
    RememberSelections()
    UpdateSelectionStatus()
}

/**
 * Handles CSV list selection and switches run input to CSV batch mode.
 */
OnCsvListChange(*) {
    global C, S

    if !S.csvList || !GetListControlSelectedIndex(S.csvList)
        return

    if S.inputSourceMode != C.inputSourceCsv
        SetInputSourceMode(C.inputSourceCsv, false)

    ClearPresetSelection()
    LoadSelectedCsvFromList()
    RememberSelections()
    UpdateSelectionStatus()
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
    SyncRunSettingsFromGui()
}

/**
 * Reads speed fields from the Speed Settings tab and pause/timing fields from the Run Options tab.
 * @returns {{playback_speed: Float, typing_speed: Float, move_speed: Float, initial_delay: Integer,
 *     click_pause_ms: Integer, segment_pause_ms: Integer, use_recorded_timing: Boolean}}
 */
ReadRunTimingSettingsFromGui() {
    global C, S

    return {
        playback_speed: SafeFloat(S.playbackSpeedEdit ? S.playbackSpeedEdit.Value : "", C.defaultPlaybackSpeed),
        typing_speed: SafeFloat(S.typingSpeedEdit ? S.typingSpeedEdit.Value : "", C.defaultTypingSpeed),
        move_speed: SafeFloat(S.moveSpeedEdit ? S.moveSpeedEdit.Value : "", C.defaultMoveSpeed),
        initial_delay: SafeInteger(S.initialDelayEdit ? S.initialDelayEdit.Value : "", C.defaultInitialDelayMs),
        click_pause_ms: SafeInteger(S.clickPauseEdit ? S.clickPauseEdit.Value : "", C.defaultClickPauseMs),
        segment_pause_ms: SafeInteger(S.segmentPauseEdit ? S.segmentPauseEdit.Value : "", C.defaultSegmentPauseMs),
        use_recorded_timing: S.recordedGapsRadio ? S.recordedGapsRadio.Value = 1 : C.defaultUseRecordedTiming
    }
}

/**
 * Merges data-input variables and optional description with Run Options and Speed Settings tab values.
 * @param {String} presetPath Path to a saved data input file, or "" for timing-only defaults.
 * @returns {Object} Full settings object for ApplySettings and WritePresetFile (`description` may be "").
 */
BuildRunSettings(presetPath := "") {
    global C

    presetSettings := presetPath != "" && FileExist(presetPath)
        ? ParsePresetFile(presetPath)
        : DefaultSettings()
    timing := ReadRunTimingSettingsFromGui()
    playback := ReadPlaybackOptionsFromGui()

    return {
        playback_speed: timing.playback_speed,
        typing_speed: timing.typing_speed,
        move_speed: timing.move_speed,
        initial_delay: timing.initial_delay,
        click_pause_ms: timing.click_pause_ms,
        segment_pause_ms: timing.segment_pause_ms,
        use_recorded_timing: timing.use_recorded_timing,
        smooth_mouse: playback.smooth_mouse,
        human_typing: playback.human_typing,
        description: presetSettings.description,
        variables: presetSettings.variables
    }
}

/**
 * Copies all run-related GUI controls into session state (timing, playback style; not variables).
 */
SyncRunSettingsFromGui() {
    global S

    timing := ReadRunTimingSettingsFromGui()
    playback := ReadPlaybackOptionsFromGui()
    S.playbackSpeed := Max(0.05, timing.playback_speed)
    S.typingSpeed := Max(0.05, timing.typing_speed)
    S.moveSpeed := Max(0.05, timing.move_speed)
    S.initialDelayMs := Max(0, timing.initial_delay)
    S.clickPauseMs := Max(0, timing.click_pause_ms)
    S.segmentPauseMs := Max(0, timing.segment_pause_ms)
    S.useRecordedTiming := timing.use_recorded_timing
    S.smoothMouse := playback.smooth_mouse
    S.humanTyping := playback.human_typing
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
 * Shows a hold indicator immediately to the right of the cursor.
 */
ShowMouseHoldCursorTip() {
    global C, S

    if !S.leftHoldActive || S.leftHoldDownAt = 0
        return

    heldSec := Round((A_TickCount - S.leftHoldDownAt) / 1000, 1)
    ShowCursorToolTip(C.mouseHoldIndicatorText " " heldSec "s")
}

/**
 * Shows a hotkey confirmation beside the cursor during recording.
 * @param {String} displayLabel Human-readable shortcut label such as Ctrl + c.
 */
ShowShortcutRecordingTip(displayLabel) {
    global C

    ShowCursorToolTip(C.hotkeyTipPrefix " " displayLabel)

    if IsRecording()
        SetTimer RestoreRecordingTip, -C.recordingTransientTipMs
}

/**
 * Restores the correct recording tooltip for the current hold state.
 */
RestoreRecordingStatusTip() {
    global S

    if !IsRecording() {
        ToolTip
        return
    }

    if S.leftHoldActive
        RefreshRecordingLeftMouseHoldTip()
    else if S.capsLockHoldActive
        RefreshRecordingCapsLockDelayTip()
    else
        ShowRecordingTip()
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
    SetTimer RefreshRecordingLeftMouseHoldTip, 0
    SetTimer CheckLeftMouseHoldRecording, 0
    SetTimer RefreshRecordingCapsLockDelayTip, 0
    SetTimer CheckCapsLockHoldRecording, 0
    ToolTip
}

/**
 * Keeps the recording tooltip visible while Detect mode is active.
 */
MaintainRecordingTip(*) {
    RestoreRecordingStatusTip()
}

RestoreRecordingTip(*) {
    RestoreRecordingStatusTip()
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
    global S, C

    selected := ShowManageFileSelect("1", S.csvEdit.Value, "Select CSV batch file", "CSV (*.csv;*.txt)")

    if selected = ""
        return

    SetInputSourceMode(C.inputSourceCsv, false)
    S.csvEdit.Value := selected

    if !SelectCsvListByPath(selected) && S.csvList
        S.csvList.Modify(0, "-Select -Focus")

    if !IsManagedCsvPath(selected) {
        importAnswer := ShowManageMsgBox(
            "Load this external CSV into csv-batches so you can edit, rename, and delete it later?",
            "Import CSV",
            "YesNo Icon?"
        )
        if importAnswer = "Yes"
            ImportCsvToLibrary(selected)
    }

    RememberSelections()
    UpdateSelectionStatus()
}

/**
 * Shows help for the Recordings tab.
 */
ShowRecordingsTabHelp(*) {
    global C

    ShowManageHelpMessage(C.recordingsTabHelpMessage, C.recordingsTabHelpTitle)
}

/**
 * Shows help for the Data Inputs tab.
 */
ShowPresetsTabHelp(*) {
    global C

    ShowManageHelpMessage(C.presetsTabHelpMessage, C.presetsTabHelpTitle)
}

/**
 * Shows CSV batch format and usage help.
 */
ShowCsvBatchHelp(*) {
    global C

    ShowManageHelpMessage(C.csvBatchHelpMessage, C.csvBatchHelpTitle)
}

/**
 * Shows help for the Run Options tab.
 */
ShowRunOptionsTabHelp(*) {
    global C

    ShowManageHelpMessage(C.runOptionsTabHelpMessage, C.runOptionsTabHelpTitle)
}

/**
 * Shows help for the Speed Settings tab.
 */
ShowSpeedSettingsTabHelp(*) {
    global C

    ShowManageHelpMessage(C.speedSettingsTabHelpMessage, C.speedSettingsTabHelpTitle)
}

/**
 * Shows help for the recording events table in Edit Log.
 */
ShowRecordingLogEventsHelp(*) {
    global C

    ShowManageHelpMessage(C.recordingLogEventsHelpMessage, C.recordingLogEventsHelpTitle)
}

/**
 * Shows help for data input variable inputs in Edit Data Input.
 */
ShowPresetVariablesHelp(*) {
    global C

    ShowManageHelpMessage(C.presetVariablesHelpMessage, C.presetVariablesHelpTitle)
}

/**
 * Returns the maximum variable count across parsed CSV batch rows.
 * @param {Array<Object>} rows Parsed CSV rows.
 * @returns {Integer}
 */
GetCsvBatchMaxVariableCount(rows) {
    maxCount := 0

    for row in rows
        maxCount := Max(maxCount, row.variables.Length)

    return maxCount
}

/**
 * Builds ListView column titles for the CSV batch progress table.
 * @param {Integer} variableCount Number of variable columns to include.
 * @param {Array<String>} variableLabels Optional header labels from row 1 of the CSV.
 * @param {String} rowLabelHeader Header text for column 1 from row 1 of the CSV.
 * @returns {Array<String>}
 */
BuildCsvBatchProgressColumns(variableCount, variableLabels := [], rowLabelHeader := "Row") {
    columns := [rowLabelHeader != "" ? rowLabelHeader : "Row"]

    Loop variableCount {
        label := A_Index <= variableLabels.Length ? variableLabels[A_Index] : ""
        columns.Push(label != "" ? label : "Var" A_Index)
    }

    columns.Push("Status")
    return columns
}

/**
 * Returns a ListView width that fits all variable columns.
 * @param {Integer} variableCount Number of variable columns.
 * @returns {Integer}
 */
GetCsvBatchProgressTableWidth(variableCount) {
    global UI

    return Max(UI.csvBatchTableWidth, 44 + (variableCount * 72) + 64)
}

/**
 * Returns display values for a CSV row padded to the table column count.
 * @param {Object} row Parsed CSV row.
 * @param {Integer} variableCount Number of variable columns in the table.
 * @returns {Array<String>}
 */
GetCsvRowDisplayVars(row, variableCount) {
    vars := []

    Loop variableCount {
        idx := A_Index
        vars.Push(idx <= row.variables.Length ? row.variables[idx] : "")
    }

    return vars
}

/**
 * Builds the current-row preview text for the CSV batch window.
 * @param {Object} row Parsed CSV row.
 * @param {Array<String>} variableLabels Header labels from row 1 of the CSV.
 * @returns {String}
 */
BuildCsvBatchRowPromptText(row, variableLabels := []) {
    lines := [Format("Row label: {1}", row.label)]

    Loop row.variables.Length {
        label := A_Index <= variableLabels.Length && variableLabels[A_Index] != ""
            ? variableLabels[A_Index]
            : "Var" A_Index
        lines.Push(Format("{1}: {2}", label, row.variables[A_Index]))
    }

    return Join(lines, "`n")
}

/**
 * Enables or disables CSV batch row prompt buttons.
 * @param {Boolean} enabled Whether prompt actions are available.
 */
SetCsvBatchPromptButtonsEnabled(enabled) {
    global S

    for btn in [S.csvBatchRunBtn, S.csvBatchSkipBtn, S.csvBatchRunAllBtn] {
        if btn
            btn.Enabled := enabled
    }
}

/**
 * Handles Close/Escape on the unified CSV batch progress window.
 */
OnCsvBatchWindowClose(*) {
    global S, C

    if !S.batchRunning
        return

    if S.csvBatchRunBtn && S.csvBatchRunBtn.Enabled
        SetCsvBatchPromptChoice(C.csvBatchPromptChoiceSkip)
    else
        S.stopBatch := true
}

/**
 * Creates the always-on-top CSV batch progress table listing all rows.
 * @param {Array<Object>} rows Parsed CSV rows.
 * @param {Array<String>} variableLabels Header labels from row 1 of the CSV.
 * @param {String} rowLabelHeader Header text for column 1 from row 1 of the CSV.
 */
ShowCsvBatchProgressTable(rows, variableLabels := [], rowLabelHeader := "Row") {
    global S, C, UI

    CloseCsvBatchProgressTable()

    variableCount := Max(GetCsvBatchMaxVariableCount(rows), variableLabels.Length)
    columns := BuildCsvBatchProgressColumns(variableCount, variableLabels, rowLabelHeader)
    tableWidth := GetCsvBatchProgressTableWidth(variableCount)
    S.csvBatchStatusColumnIndex := columns.Length
    S.csvBatchProgressTableWidth := tableWidth

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
        "xm w" tableWidth " h" UI.csvBatchTableHeight " -Multi +Background" UI.listBg,
        columns
    )

    Loop rows.Length {
        row := rows[A_Index]
        displayVars := GetCsvRowDisplayVars(row, variableCount)
        rowValues := [A_Index]
        for value in displayVars
            rowValues.Push(value)
        rowValues.Push(C.csvBatchStatusPending)
        tableLv.Add("", rowValues*)
    }

    tableLv.ModifyCol(1, 40)
    tableLv.ModifyCol(S.csvBatchStatusColumnIndex, 64)
    SetManageListViewColumnIntegerSort(tableLv, 1)

    tableGui.Add("Text", "xm w" tableWidth " Section c" UI.textPrimary, "Current row")
    S.csvBatchPromptDetails := tableGui.Add(
        "Edit",
        "xs w" tableWidth " r" UI.csvBatchPromptDetailsLines " ReadOnly Multi -TabStop +Background" UI.statusBg,
        ""
    )

    btnW := UI.csvBatchPromptBtnWidth
    btnH := UI.btnHeightSecondary
    S.csvBatchRunBtn := tableGui.Add(
        "Button",
        "xm w" btnW " h" btnH " Default +Background" UI.accent " c" UI.accentText,
        C.csvBatchPromptRun
    )
    S.csvBatchSkipBtn := tableGui.Add(
        "Button",
        "x+" UI.btnGap " w" btnW " h" btnH " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        C.csvBatchPromptSkip
    )
    S.csvBatchRunAllBtn := tableGui.Add(
        "Button",
        "xm w" tableWidth " h" btnH " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        C.csvBatchPromptRunAll
    )

    S.csvBatchRunBtn.OnEvent("Click", SetCsvBatchPromptChoice.Bind(C.csvBatchPromptChoiceRun))
    S.csvBatchSkipBtn.OnEvent("Click", SetCsvBatchPromptChoice.Bind(C.csvBatchPromptChoiceSkip))
    S.csvBatchRunAllBtn.OnEvent("Click", SetCsvBatchPromptChoice.Bind(C.csvBatchPromptChoiceRunAll))
    tableGui.OnEvent("Close", OnCsvBatchWindowClose)
    tableGui.OnEvent("Escape", OnCsvBatchWindowClose)

    S.csvBatchTableGui := tableGui
    S.csvBatchTableLv := tableLv
    SetCsvBatchPromptButtonsEnabled(false)
    tableGui.Show("x24 y80 w" tableWidth)
}

/**
 * Updates one row's Status column in the batch progress table.
 * @param {Integer} rowIndex One-based row index in the table.
 * @param {String} status Status text to display.
 */
SetCsvBatchProgressRowStatus(rowIndex, status) {
    global S

    if S.csvBatchTableLv && S.csvBatchStatusColumnIndex {
        visualRowIndex := FindManageListViewVisualRow(S.csvBatchTableLv, rowIndex, 1)
        if !visualRowIndex
            visualRowIndex := rowIndex
        S.csvBatchTableLv.Modify(visualRowIndex, "Col" S.csvBatchStatusColumnIndex, status)
    }
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
    S.csvBatchStatusColumnIndex := 0
    S.csvBatchProgressTableWidth := 0
    S.csvBatchPromptDetails := ""
    S.csvBatchRunBtn := ""
    S.csvBatchSkipBtn := ""
    S.csvBatchRunAllBtn := ""
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
 * @param {Array<String>} variableLabels Header labels from row 1 of the CSV.
 * @returns {String} Prompt choice constant from C.csvBatchPromptChoice*.
 */
WaitCsvBatchRowPrompt(rowIndex, row, totalRows, variableLabels := []) {
    global S, C

    S.csvPromptChoice := C.csvBatchPromptChoiceNone

    if S.csvBatchTableGui
        S.csvBatchTableGui.Title := Format("CSV row {}/{}", rowIndex, totalRows)

    if S.csvBatchPromptDetails
        S.csvBatchPromptDetails.Value := BuildCsvBatchRowPromptText(row, variableLabels)

    if S.csvBatchTableLv
        SelectManageListViewDataRow(S.csvBatchTableLv, rowIndex, 1)

    SetCsvBatchPromptButtonsEnabled(true)

    return WaitForCsvBatchPromptChoice()
}

/**
 * Clears the pending CSV batch row prompt choice and disables prompt buttons.
 */
CloseCsvBatchRowPrompt() {
    global S, C

    SetCsvBatchPromptButtonsEnabled(false)
    S.csvPromptChoice := C.csvBatchPromptChoiceNone
}

RefreshAllLists(restore := false) {
    RefreshRecordingList()
    RefreshPresetList()
    RefreshCsvList()

    if restore
        RestoreSelections()

    UpdateSelectionStatus()
}

RefreshRecordingList() {
    global C, S, UI

    S.recordingPaths := ListFiles(C.recordingsDir, C.diPrefix "*.log")

    if !S.recordingList
        return

    S.recordingList.Delete()

    S.recordingDescCache := Map()

    for path in S.recordingPaths {
        S.recordingList.Add(
            "",
            FormatRecordingName(path),
            CountRecordingVariableSlots(path)
        )
        quickDesc := Trim(ReadRecordingDescriptionQuick(path))
        if quickDesc != ""
            S.recordingDescCache[path] := quickDesc
    }

    ApplyManageRecordingListColumns()
}

RefreshPresetList() {
    global C, S

    EnsureDir(C.savesDir)
    S.presetPaths := ListFiles(C.savesDir, "*" C.saveExt)
    S.presetDescCache := Map()

    if !S.presetList
        return

    S.presetList.Delete()

    for path in S.presetPaths {
        parsedPreset := ParsePresetFile(path)
        S.presetList.Add("", FormatPresetName(path), parsedPreset.variables.Length)
        pd := Trim(parsedPreset.description)
        if pd != ""
            S.presetDescCache[path] := pd
    }

    ApplyManagePresetListColumns()
}

/**
 * Reloads saved CSV batch files from csv-batches\.
 */
RefreshCsvList() {
    global C, S

    EnsureDir(C.csvBatchesDir)
    S.csvPaths := ListFiles(C.csvBatchesDir, "*" C.csvExt)

    if !S.csvList
        return

    S.csvList.Delete()

    for path in S.csvPaths {
        parsed := ParseCsvFile(path)
        S.csvList.Add(
            "",
            FormatCsvName(path),
            parsed.rows.Length,
            parsed.variableLabels.Length
        )
    }

    ApplyManageCsvListColumns()
}

RestoreSelections() {
    global C, S

    saved := LoadManageState()

    if S.recordingPaths.Length {
        SelectByBaseName(S.recordingList, S.recordingPaths, saved.recording)
        if !GetListControlSelectedIndex(S.recordingList)
            SelectListControlRow(S.recordingList, 1)
    }

    if S.presetPaths.Length && saved.csv = "" {
        SelectByBaseName(S.presetList, S.presetPaths, saved.preset)
        if !GetListControlSelectedIndex(S.presetList)
            SelectListControlRow(S.presetList, 1)
    }

    if saved.csv != "" {
        if S.csvEdit
            S.csvEdit.Value := saved.csv
        SelectCsvListByPath(saved.csv)
    }

    S.inputSourceMode := saved.csv != "" ? C.inputSourceCsv : C.inputSourcePreset
    if S.inputSourceMode = C.inputSourcePreset {
        ClearCsvSelection()
    } else {
        ClearPresetSelection()
    }

    ApplyInputSourceControlState()
    S.csvAskNextLine := saved.csvAskNextLine
    SyncCsvBatchRunModeFromState()
}

UpdateSelectionStatus() {
    global C, S

    recording := GetSelectedRecordingPath()
    preset := GetSelectedPresetPath()
    csvPath := GetSelectedCsvPath()
    presetMode := S.inputSourceMode != C.inputSourceCsv

    if recording = "" {
        SetStatus("Select a recording first.")
        return
    }

    if !presetMode {
        if csvPath = "" {
            SetStatus("Select a CSV batch file.")
            return
        }

        if FileExist(csvPath)
            SetStatus("Ready — " FormatRecordingName(recording) " with CSV " FormatCsvName(csvPath))
        else
            SetStatus("CSV file not found — " csvPath)
        return
    }

    if preset = "" {
        SetStatus("Select a data input.")
        return
    }

    SetStatus("Ready — " FormatRecordingName(recording) " with " FormatPresetName(preset))
}

RememberSelections() {
    global C, S

    presetMode := S.inputSourceMode != C.inputSourceCsv

    SaveManageState(
        presetMode && GetSelectedPresetPath() ? FileBaseName(GetSelectedPresetPath()) : "",
        GetSelectedRecordingPath() ? FileBaseName(GetSelectedRecordingPath()) : "",
        presetMode ? "" : Trim(S.csvEdit ? S.csvEdit.Value : ""),
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

    index := S.presetList ? GetListControlSelectedIndex(S.presetList) : 0
    return index && index <= S.presetPaths.Length ? S.presetPaths[index] : ""
}

GetSelectedCsvPath() {
    global S

    return Trim(S.csvEdit ? S.csvEdit.Value : "")
}

/**
 * Returns the selected saved CSV path from the CSV list.
 * @returns {String}
 */
GetSelectedManagedCsvPath() {
    global S

    index := S.csvList ? GetListControlSelectedIndex(S.csvList) : 0
    return index && index <= S.csvPaths.Length ? S.csvPaths[index] : ""
}

/**
 * Loads the selected saved CSV into the batch path field.
 */
LoadSelectedCsvFromList() {
    global S

    path := GetSelectedManagedCsvPath()
    if path != "" && S.csvEdit
        S.csvEdit.Value := path
}

/**
 * Selects a saved CSV row when its full path matches.
 * @param {String} csvPath Full CSV file path.
 * @returns {Boolean}
 */
SelectCsvListByPath(csvPath) {
    global S

    if !S.csvList || csvPath = ""
        return false

    for index, savedPath in S.csvPaths {
        if StrLower(savedPath) = StrLower(csvPath) {
            SelectListControlRow(S.csvList, index)
            return true
        }
    }

    return false
}

ApplyFromGui(*) {
    global C, S

    logPath := GetSelectedRecordingPath()
    presetPath := GetSelectedPresetPath()
    csvPath := GetSelectedCsvPath()
    presetMode := S.inputSourceMode != C.inputSourceCsv

    if logPath = "" {
        SetStatus("Select a recording first.")
        return
    }

    RememberSelections()

    if !presetMode {
        if csvPath = "" {
            SetStatus("Select a CSV batch file.")
            return
        }

        if !FileExist(csvPath) {
            SetStatus("CSV file not found.")
            ShowManageMsgBox "CSV file not found:`n" csvPath, "Data Entry Autonoma", "Icon!"
            return
        }

        SetStatus("Running CSV batch...")
        SetTimer (ApplyBatchTimer).Bind(logPath, csvPath, ""), -1
        return
    }

    if presetPath = "" {
        SetStatus("Select a data input.")
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
 * Deletes the selected data input after confirmation.
 */
DeleteSelectedPreset(*) {
    global C, S

    if S.recording || S.applying || S.batchRunning
        return

    path := GetSelectedPresetPath()
    if path = "" {
        SetStatus("Select a data input to delete.")
        return
    }

    label := FormatPresetName(path)
    if !ConfirmDeleteItem(label, "data input")
        return

    deletedBase := FileBaseName(path)

    try {
        DeleteManagedFile(path)
    } catch as err {
        ShowManageMsgBox "Could not delete data input:`n" err.Message, "Delete Data Input", "Icon!"
        SetStatus("Could not delete data input.")
        return
    }

    ClearManageStateKeyIfMatches(C.statePresetKey, deletedBase)
    RefreshPresetList()

    if S.presetPaths.Length
        SelectFirstListItem(S.presetList)

    RememberSelections()
    UpdateSelectionStatus()
    SetStatus("Deleted data input — " label)
}

/**
 * Deletes the selected saved CSV batch after confirmation.
 */
DeleteSelectedCsv(*) {
    global C, S

    if S.recording || S.applying || S.batchRunning
        return

    path := GetSelectedManagedCsvPath()
    if path = "" {
        SetStatus("Select a saved CSV to delete.")
        return
    }

    label := FormatCsvName(path)
    if !ConfirmDeleteItem(label, "CSV batch")
        return

    try {
        DeleteManagedFile(path)
    } catch as err {
        ShowManageMsgBox "Could not delete CSV:`n" err.Message, "Delete CSV", "Icon!"
        SetStatus("Could not delete CSV.")
        return
    }

    ClearCsvStateIfMatches(path)
    RefreshCsvList()

    if S.csvPaths.Length {
        SelectFirstListItem(S.csvList)
        LoadSelectedCsvFromList()
    } else if S.csvEdit {
        S.csvEdit.Value := ""
        SetInputSourceMode(C.inputSourcePreset)
    }

    RememberSelections()
    UpdateSelectionStatus()
    SetStatus("Deleted CSV — " label)
}

/**
 * Renames the selected saved CSV batch file.
 */
RenameSelectedCsv(*) {
    global C, S

    if S.recording || S.applying || S.batchRunning
        return

    path := GetSelectedManagedCsvPath()
    if path = "" {
        SetStatus("Select a saved CSV to rename.")
        return
    }

    result := ShowManageInputBox(
        "CSV name:",
        "Rename CSV",
        "w360 h130",
        FormatCsvName(path)
    )

    if result.Result != "OK"
        return

    fileName := SafeCsvName(result.Value)
    if fileName = "" {
        SetStatus("Rename cancelled — invalid name.")
        return
    }

    newPath := C.csvBatchesDir "\" fileName C.csvExt
    if StrLower(newPath) = StrLower(path) {
        SetStatus("Name unchanged.")
        return
    }

    try {
        FileMove path, newPath, 1
    } catch as err {
        ShowManageMsgBox "Could not rename CSV:`n" err.Message, "Rename CSV", "Icon!"
        SetStatus("Could not rename CSV.")
        return
    }

    if StrLower(GetSelectedCsvPath()) = StrLower(path) && S.csvEdit
        S.csvEdit.Value := newPath

    RefreshCsvList()
    SelectByBaseName(S.csvList, S.csvPaths, FileBaseName(newPath))
    LoadSelectedCsvFromList()
    RememberSelections()
    UpdateSelectionStatus()
    SetStatus("Renamed CSV — " FormatCsvName(newPath))
}

/**
 * Parses CSV editor text into editable row arrays. Blank and comment lines are skipped.
 * @param {String} content CSV file content.
 * @param {Integer} maxCols Maximum editable columns.
 * @returns {Array<Array<String>>}
 */
ParseCsvEditorRows(content, maxCols) {
    rows := []

    Loop Parse content, "`n", "`r" {
        line := Trim(A_LoopField)
        if line = "" || SubStr(line, 1, 1) = "#"
            continue

        parsed := SplitManageCsvLine(line)
        row := []
        Loop Min(parsed.Length, maxCols)
            row.Push(parsed[A_Index])
        rows.Push(row)
    }

    if rows.Length = 0
        rows.Push(["row", "col1", "col2", "col3"])

    return rows
}

/**
 * Returns Edit CSV dialog height from layout constants (no fixed empty footer).
 * @returns {Integer}
 */
GetCsvEditorWindowHeight() {
    global UI

    rowGap := UI.csvEditorMarginY
    return rowGap
        + UI.tabLabelHeight + rowGap
        + UI.csvEditorNameEditH + rowGap
        + UI.csvEditorHelpTextH + rowGap
        + UI.csvEditorListHeight + rowGap + UI.csvEditorListToButtonsGap
        + UI.csvEditorButtonHeight + rowGap + UI.csvEditorButtonsToSaveGap
        + UI.csvEditorSaveButtonHeight
        + UI.csvEditorBottomPad + UI.csvEditorOuterPad
}

/**
 * Returns editable column count for the CSV editor table.
 * @param {Array<Array<String>>} rows Editable rows.
 * @param {Integer} maxCols Maximum allowed columns.
 * @returns {Integer}
 */
GetCsvEditorColumnCount(rows, maxCols) {
    colCount := 4

    for row in rows
        colCount := Max(colCount, row.Length)

    return Min(Max(colCount, 1), maxCols)
}

/**
 * Converts a one-based column index to Excel-style letters (A, B, ..., AA).
 * @param {Integer} colIndex One-based column index.
 * @returns {String}
 */
FormatSpreadsheetColumnName(colIndex) {
    name := ""
    colIndex := Max(1, Integer(colIndex))

    while colIndex > 0 {
        colIndex--
        name := Chr(65 + Mod(colIndex, 26)) name
        colIndex := Floor(colIndex / 26)
    }

    return name
}

/**
 * Builds fixed ListView columns for the CSV editor.
 * @param {Integer} colCount Number of editable columns.
 * @returns {Array<String>}
 */
BuildCsvEditorListColumns(colCount) {
    columns := ["#"]

    Loop colCount
        columns.Push(FormatSpreadsheetColumnName(A_Index))

    return columns
}

/**
 * Populates the CSV editor ListView from editable row arrays.
 * @param {Gui.ListView} listView Target ListView.
 * @param {Array<Array<String>>} rows Editable rows.
 * @param {Integer} colCount Number of editable columns.
 */
PopulateCsvEditorList(listView, rows, colCount) {
    global UI

    listView.Delete()

    Loop rows.Length
        RefreshCsvEditorListRow(listView, A_Index, rows[A_Index], colCount, true)

    listView.ModifyCol(1, UI.csvEditorRowNumberColWidth)
    Loop colCount
        listView.ModifyCol(A_Index + 1, UI.csvEditorDataColWidth)
    SetManageListViewColumnIntegerSort(listView, 1)
}

/**
 * Refreshes or adds a single CSV editor ListView row.
 * @param {Gui.ListView} listView Target ListView.
 * @param {Integer} rowIndex Stable row number.
 * @param {Array<String>} row Editable row values.
 * @param {Integer} colCount Number of editable columns.
 * @param {Boolean} append When true, appends instead of modifying.
 */
RefreshCsvEditorListRow(listView, rowIndex, row, colCount, append := false) {
    values := [rowIndex]

    Loop colCount
        values.Push(A_Index <= row.Length ? row[A_Index] : "")

    if append {
        listView.Add("", values*)
        return
    }

    visualRowIndex := FindManageListViewVisualRow(listView, rowIndex, 1)
    if !visualRowIndex
        visualRowIndex := rowIndex

    listView.Modify(visualRowIndex, "", values*)
}

/**
 * Serializes CSV editor rows back into stored CSV content.
 * @param {Array<Array<String>>} rows Editable rows.
 * @returns {String}
 */
SerializeCsvEditorRows(rows) {
    lines := []

    for row in rows {
        copy := []
        for value in row
            copy.Push(Trim(value))

        while copy.Length > 1 && copy[copy.Length] = ""
            copy.Pop()

        if copy.Length = 1 && copy[1] = ""
            continue

        lines.Push(JoinManageDelimitedFields(copy))
    }

    return Join(lines, "`n")
}

/**
 * Opens the CSV batch editor to create or update a saved CSV file.
 */
ShowCsvEditor(*) {
    global C, S, UI

    selectedPath := GetSelectedManagedCsvPath()
    if selectedPath = "" {
        currentPath := GetSelectedCsvPath()
        selectedPath := IsManagedCsvPath(currentPath) ? currentPath : ""
    }

    originalPath := selectedPath
    existingContent := selectedPath && FileExist(selectedPath)
        ? ReadTextFile(selectedPath)
        : DefaultCsvTemplate()

    csvEditorMaxCols := UI.csvEditorMaxCols
    csvEditorRows := ParseCsvEditorRows(existingContent, csvEditorMaxCols)
    csvEditorColCount := GetCsvEditorColumnCount(csvEditorRows, csvEditorMaxCols)

    if S.gui
        S.gui.Hide()

    editor := Gui("+ToolWindow", "Edit CSV")
    BindManageChildGui(editor)
    editor.MarginX := UI.csvEditorMarginX
    editor.MarginY := UI.csvEditorMarginY
    editor.SetFont("s10", "Segoe UI")
    editor.BackColor := "FFFFFF"

    editorW := UI.csvEditorWidth
    listW := UI.csvEditorListWidth

    editor.Add("Text", "w" listW " c1A1A1A", "CSV name")
    nameEdit := editor.Add(
        "Edit",
        "w" listW " h" UI.csvEditorNameEditH,
        selectedPath ? FormatCsvName(selectedPath) : "batch-1"
    )
    editor.Add(
        "Text",
        "xm w" listW " h" UI.csvEditorHelpTextH " c555555",
        "Row 1 is the header. Click a cell to edit inline. Commas and backslashes are escaped automatically."
    )
    csvList := editor.Add(
        "ListView",
        "xm w" listW " h" UI.csvEditorListHeight " -Multi +Background" UI.listBg,
        BuildCsvEditorListColumns(csvEditorColCount)
    )
    PopulateCsvEditorList(csvList, csvEditorRows, csvEditorColCount)
    csvInlineEdit := editor.Add("Edit", "Hidden w10 h22")

    addRowBtn := editor.Add(
        "Button",
        "xm y+" UI.csvEditorListToButtonsGap " w" UI.csvEditorButtonWidth " h" UI.csvEditorButtonHeight
            " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Add row"
    )
    deleteRowBtn := editor.Add(
        "Button",
        "x+" UI.csvEditorButtonGap " w" UI.csvEditorButtonWidth " h" UI.csvEditorButtonHeight
            " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Delete row"
    )
    addColBtn := editor.Add(
        "Button",
        "x+" UI.csvEditorButtonGroupGap " w" UI.csvEditorButtonWidth " h" UI.csvEditorButtonHeight
            " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Add col"
    )
    deleteColBtn := editor.Add(
        "Button",
        "x+" UI.csvEditorButtonGap " w" UI.csvEditorButtonWidth " h" UI.csvEditorButtonHeight
            " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Delete col"
    )

    saveBtn := editor.Add(
        "Button",
        "xm y+" UI.csvEditorButtonsToSaveGap " w" UI.csvEditorSaveButtonWidth
            " h" UI.csvEditorSaveButtonHeight " Default",
        "Save"
    )
    closeBtn := editor.Add(
        "Button",
        "x+" UI.csvEditorSaveButtonGap " w" UI.csvEditorSaveButtonWidth
            " h" UI.csvEditorSaveButtonHeight,
        "Close"
    )
    selectedCsvRowIndex := 0
    csvInlineRow := 0
    csvInlineCol := 0
    csvInlineOriginal := ""

    CommitCsvInlineEdit(*) {
        if csvInlineRow < 1 || csvInlineCol < 2
            return

        try {
            if !csvInlineEdit.Visible
                return
        } catch {
            return
        }

        csvInlineEdit.Visible := false
        dataCol := csvInlineCol - 1

        if csvInlineRow >= 1 && csvInlineRow <= csvEditorRows.Length
            && dataCol >= 1 && dataCol <= csvEditorColCount {
            row := csvEditorRows[csvInlineRow]
            while row.Length < dataCol
                row.Push("")
            row[dataCol] := Trim(csvInlineEdit.Value)
            RefreshCsvEditorListRow(csvList, csvInlineRow, row, csvEditorColCount)
        }

        csvInlineRow := 0
        csvInlineCol := 0
        csvInlineOriginal := ""
    }

    StartCsvInlineEdit(visualRowIndex, colIndex) {
        if colIndex < 2 || colIndex > csvEditorColCount + 1
            return

        CommitCsvInlineEdit()

        dataRowIndex := GetManageListViewDataRowIndex(csvList, visualRowIndex, 1)
        if dataRowIndex < 1 || dataRowIndex > csvEditorRows.Length
            return

        ControlGetPos &listX, &listY, , , csvList
        rect := GetManageListViewSubItemRect(csvList, visualRowIndex, colIndex)
        editW := Min(Max(rect.right - rect.left, UI.csvEditorInlineMinWidth), UI.csvEditorInlineMaxWidth)
        editH := Max(rect.bottom - rect.top, 22)

        csvInlineRow := dataRowIndex
        csvInlineCol := colIndex
        csvInlineOriginal := csvList.GetText(visualRowIndex, colIndex)
        csvInlineEdit.Move(listX + rect.left, listY + rect.top, editW, editH)
        csvInlineEdit.Value := csvInlineOriginal
        csvInlineEdit.Visible := true
        csvInlineEdit.Focus()
    }

    OnCsvEditorListClick(ctl, item, *) {
        if !item
            return

        ControlGetPos &listX, &listY, , , csvList
        CoordMode "Mouse", "Client"
        MouseGetPos &mouseX, &mouseY, , &controlHwnd, 2
        if controlHwnd != csvList.Hwnd
            return

        hit := GetManageListViewHitSubItem(csvList, mouseX - listX, mouseY - listY)
        if hit.row < 1
            return

        selectedCsvRowIndex := GetManageListViewDataRowIndex(csvList, hit.row, 1)
        csvList.Modify(hit.row, "Select Focus")
        StartCsvInlineEdit(hit.row, hit.col)
    }

    LoadCsvEditorRow(rowIndex) {
        if !(csvInlineEdit.Visible && rowIndex = csvInlineRow)
            CommitCsvInlineEdit()
        selectedCsvRowIndex := rowIndex
    }

    RefreshCsvEditorTableAndSelection(rowIndex := 0) {
        PopulateCsvEditorList(csvList, csvEditorRows, csvEditorColCount)
        if rowIndex >= 1 {
            SelectManageListViewDataRow(csvList, rowIndex)
            selectedCsvRowIndex := rowIndex
        }
    }

    AddCsvEditorRow(*) {
        CommitCsvInlineEdit()
        insertIndex := selectedCsvRowIndex >= 1
            ? Min(selectedCsvRowIndex + 1, csvEditorRows.Length + 1)
            : csvEditorRows.Length + 1
        firstCol := insertIndex = 1 ? "row" : String(insertIndex - 1)
        csvEditorRows.InsertAt(insertIndex, [firstCol])
        RefreshCsvEditorTableAndSelection(insertIndex)
    }

    AddCsvEditorColumn(*) {
        CommitCsvInlineEdit()
        if csvEditorColCount >= csvEditorMaxCols {
            ShowManageMsgBox "The CSV editor supports up to column "
                FormatSpreadsheetColumnName(csvEditorMaxCols) ".", "Edit CSV", "Icon!"
            return
        }

        csvEditorColCount++
        csvList.InsertCol(
            csvEditorColCount + 1,
            String(UI.csvEditorDataColWidth),
            FormatSpreadsheetColumnName(csvEditorColCount)
        )
        for rowIndex, row in csvEditorRows {
            while row.Length < csvEditorColCount
                row.Push("")
            if rowIndex = 1
                row[csvEditorColCount] := FormatSpreadsheetColumnName(csvEditorColCount)
        }

        RefreshCsvEditorTableAndSelection(selectedCsvRowIndex)
    }

    DeleteCsvEditorColumn(*) {
        CommitCsvInlineEdit()
        if csvEditorColCount <= 1 {
            ShowManageMsgBox "At least one column is required.", "Edit CSV", "Icon!"
            return
        }

        confirm := ShowManageMsgBox(
            "Delete column " FormatSpreadsheetColumnName(csvEditorColCount) " from every row?",
            "Edit CSV",
            "YesNo Icon?"
        )
        if confirm != "Yes"
            return

        for row in csvEditorRows {
            if row.Length >= csvEditorColCount
                row.RemoveAt(csvEditorColCount)
        }
        csvList.DeleteCol(csvEditorColCount + 1)
        csvEditorColCount--

        RefreshCsvEditorTableAndSelection(selectedCsvRowIndex)
    }

    DeleteCsvEditorRow(*) {
        CommitCsvInlineEdit()
        if selectedCsvRowIndex < 1 || selectedCsvRowIndex > csvEditorRows.Length
            return
        if selectedCsvRowIndex = 1 {
            ShowManageMsgBox "Row 1 is the header row and cannot be deleted.", "Edit CSV", "Icon!"
            return
        }

        csvEditorRows.RemoveAt(selectedCsvRowIndex)
        nextRow := Min(selectedCsvRowIndex, csvEditorRows.Length)
        RefreshCsvEditorTableAndSelection(nextRow)
    }

    OnCsvEditorListSelect(*) {
        LoadCsvEditorRow(GetManageListViewSelectedDataRowIndex(csvList))
    }

    SaveCsvEditor(*) {
        CommitCsvInlineEdit()

        csvName := SafeCsvName(nameEdit.Value)
        if csvName = "" {
            ShowManageMsgBox "Enter a CSV name.", "Edit CSV", "Icon!"
            return
        }

        csvPath := C.csvBatchesDir "\" csvName C.csvExt
        content := SerializeCsvEditorRows(csvEditorRows)

        if content = "" {
            ShowManageMsgBox "Enter at least one CSV row.", "Edit CSV", "Icon!"
            return
        }

        try {
            EnsureDir(C.csvBatchesDir)
            WriteTextFile(content, csvPath)

            if originalPath != "" && StrLower(originalPath) != StrLower(csvPath) && FileExist(originalPath)
                DeleteManagedFile(originalPath)
        } catch as err {
            ShowManageMsgBox "Could not save CSV:`n" err.Message, "Edit CSV", "Icon!"
            return
        }

        editor.Destroy()

        if S.gui
            S.gui.Show()

        RefreshCsvList()
        SelectByBaseName(S.csvList, S.csvPaths, FileBaseName(csvPath))

        if S.csvEdit
            S.csvEdit.Value := csvPath

        SetInputSourceMode(C.inputSourceCsv)
        SetStatus(originalPath != "" && StrLower(originalPath) = StrLower(csvPath)
            ? "Updated CSV — " csvName
            : "Saved CSV — " csvName)
    }

    CloseCsvEditor(*) {
        editor.Destroy()
        if S.gui
            S.gui.Show()
    }

    csvList.OnEvent("ItemSelect", OnCsvEditorListSelect)
    csvList.OnEvent("Click", OnCsvEditorListClick)
    csvList.OnEvent("DoubleClick", OnCsvEditorListClick)
    csvInlineEdit.OnEvent("LoseFocus", CommitCsvInlineEdit)
    addRowBtn.OnEvent("Click", AddCsvEditorRow)
    deleteRowBtn.OnEvent("Click", DeleteCsvEditorRow)
    addColBtn.OnEvent("Click", AddCsvEditorColumn)
    deleteColBtn.OnEvent("Click", DeleteCsvEditorColumn)
    saveBtn.OnEvent("Click", SaveCsvEditor)
    closeBtn.OnEvent("Click", CloseCsvEditor)
    editor.OnEvent("Close", CloseCsvEditor)
    editor.OnEvent("Escape", CloseCsvEditor)

    if csvEditorRows.Length {
        SelectManageListViewDataRow(csvList, 1)
        LoadCsvEditorRow(1)
    }

    editor.Show("w" editorW " h" GetCsvEditorWindowHeight())
    csvList.Focus()
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
 * Returns Edit Recording Log dialog height (tab panel + button row + outer padding).
 * @returns {Integer}
 */
GetRecordingLogEditorWindowHeight() {
    global UI

    return UI.recordingLogEditorDescLabelH + UI.tabRowGap + UI.recordingLogEditorDescEditH + UI.tabRowGap
        + UI.recordingLogEditorTabHeight + UI.recordingLogEditorButtonRowHeight + UI.recordingLogEditorOuterPad
}

/**
 * Restores editor/tooltip description from one stored header fragment (CR stripped; display sep → LF).
 * @param {String} stored Text after `# description:` on disk.
 * @returns {String}
 */
DecodeRecordingLogDescriptionStoredFragment(stored) {
    global RECORDING_LOG_DESC_DISPLAY_SEP

    t := Trim(StrReplace(stored, "`r", ""))
    return StrReplace(t, RECORDING_LOG_DESC_DISPLAY_SEP, "`n")
}

/**
 * Returns the optional note label stored on one recording log event row.
 * @param {Array} parts Pipe-delimited log fields.
 * @returns {String}
 */
GetRecordingLogEventNote(parts) {
    global RECORDING_LOG_NOTE_FIELD

    if parts.Length >= 3 && parts[parts.Length - 1] = RECORDING_LOG_NOTE_FIELD
        return parts[parts.Length]
    return ""
}

/**
 * Sets or clears the optional note label on one recording log event row.
 * @param {Array} parts Pipe-delimited log fields.
 * @param {String} noteLabel Note text; blank removes the label.
 * @returns {Array}
 */
SetRecordingLogEventNote(parts, noteLabel) {
    global RECORDING_LOG_NOTE_FIELD

    noteLabel := Trim(noteLabel)
    if parts.Length >= 3 && parts[parts.Length - 1] = RECORDING_LOG_NOTE_FIELD
        parts.Length -= 2
    if noteLabel != ""
        parts.Push(RECORDING_LOG_NOTE_FIELD, noteLabel)
    return parts
}

/**
 * Builds a short summary string for one recording log event row.
 * @param {Array} parts Pipe-delimited log fields.
 * @returns {String}
 */
BuildRecordingLogEditorSummary(parts) {
    if parts.Length < 3
        return Trim(parts[1])

    eventType := parts[2]

    switch eventType {
        case "click":
            pctX := parts.Length >= 9 ? parts[8] : ""
            pctY := parts.Length >= 10 ? parts[9] : ""
            return pctX != "" && pctY != ""
                ? Format("{} @ {},{}", parts[3], pctX, pctY)
                : Format("{} click", parts[3])
        case "key":
            return parts[3]
        case "shortcut":
            return parts.Length >= 5
                ? Format("{} -> {}", parts[4], parts[3])
                : parts[3]
        case "scroll":
            return parts.Length >= 6
                ? Format("{} delta {} x{}", parts[3], parts[4], parts[5])
                : parts[3]
        case "mouse_hold":
            return parts.Length >= 5
                ? Format("{} {} ms", parts[3], parts[4])
                : parts[3]
        case "meta":
            if parts.Length >= 4 && parts[3] = "delay"
                return Format("delay {} ms", parts[4])
            return parts.Length >= 3 ? parts[3] : "meta"
        default:
            return eventType
    }
}

/**
 * Returns editable field definitions for a recording log event row.
 * @param {Array} parts Pipe-delimited log fields.
 * @returns {Array<Object>}
 */
GetRecordingLogEditorDetailFields(parts) {
    if parts.Length < 3
        return []

    eventType := parts[2]
    fields := []

    switch eventType {
        case "click":
            fields.Push({ label: "Button", partIndex: 3 })
            if parts.Length >= 9
                fields.Push({ label: "Pct X", partIndex: 8 })
            if parts.Length >= 10
                fields.Push({ label: "Pct Y", partIndex: 9 })
        case "key":
            fields.Push({ label: "Variable", partIndex: 3 })
        case "shortcut":
            fields.Push({ label: "Send text", partIndex: 3 })
            if parts.Length >= 5
                fields.Push({ label: "Display label", partIndex: 4 })
        case "scroll":
            fields.Push({ label: "Direction", partIndex: 3 })
            if parts.Length >= 5
                fields.Push({ label: "Delta", partIndex: 4 })
            if parts.Length >= 6
                fields.Push({ label: "Notches", partIndex: 5 })
        case "mouse_hold":
            fields.Push({ label: "Button", partIndex: 3 })
            if parts.Length >= 5
                fields.Push({ label: "Duration (ms)", partIndex: 4 })
        default:
            if eventType = "meta" && parts.Length >= 4 && parts[3] = "delay"
                fields.Push({ label: "Delay (ms)", partIndex: 4 })
    }

    validFields := []
    for field in fields {
        if field.partIndex >= 1 && field.partIndex <= parts.Length
            validFields.Push(field)
    }

    return validFields
}

/**
 * Parses a recording log into header lines and editable event rows.
 * @param {String} filePath Recording log path.
 * @returns {{headerLines: Array<String>, events: Array<Object>}}
 */
ParseRecordingLogForEditor(filePath) {
    headerLines := []
    events := []

    Loop Read filePath {
        line := A_LoopReadLine
        trimmed := Trim(line)

        if trimmed = "" || SubStr(trimmed, 1, 1) = "#" {
            headerLines.Push(line)
            continue
        }

        for eventLine in SplitMergedLogLines(trimmed) {
            parts := StrSplit(eventLine, "|")
            if parts.Length >= 3
                events.Push({ parts: parts })
        }
    }

    return { headerLines: headerLines, events: events }
}

/**
 * Serializes header lines and event rows back into a recording log file body.
 * @param {Array<String>} headerLines Header and comment lines.
 * @param {Array<Object>} events Parsed event rows.
 * @returns {String}
 */
SerializeRecordingLogFromEditor(headerLines, events) {
    lines := []

    for line in headerLines
        lines.Push(line)

    for event in events
        lines.Push(Join(event.parts, "|"))

    return Join(lines, "`n")
}

/**
 * Copies header lines so preview serialization can safely inject without mutating the editor array.
 * @param {Array<String>} headerLines Source header lines from the recording editor.
 * @returns {Array<String>}
 */
CloneRecordingLogHeaderLines(headerLines) {
    copy := []

    for line in headerLines
        copy.Push(line)

    return copy
}

/**
 * Removes `# description:` lines from the header block and restores the editable description text.
 * @param {Array<String>} headerLines Recording header lines (pass with & at call site).
 * @returns {String} Multi-line description for the Description field (may be "").
 */
PeelRecordingDescriptionFromHeader(&headerLines) {
    desc := ""
    kept := []

    for line in headerLines {
        t := Trim(line)
        if RegExMatch(t, "i)^#\s*description:\s*(.*)$", &m) {
            frag := DecodeRecordingLogDescriptionStoredFragment(m[1])
            if frag != ""
                desc .= (desc = "" ? frag : "`n" frag)
            continue
        }
        kept.Push(line)
    }

    headerLines := kept
    return desc
}

/**
 * Writes `# description:` into headers as one line (` · ` substitutes for newlines), replacing any existing block.
 * @param {Array<String>} headerLines Recording header lines (pass with & at call site).
 * @param {String} rawDescription Text from the Description edit control.
 */
InjectRecordingDescriptionIntoHeader(&headerLines, rawDescription) {
    global RECORDING_LOG_DESC_HEADER_LINE_PREFIX, RECORDING_LOG_DESC_DISPLAY_SEP

    PeelRecordingDescriptionFromHeader(&headerLines)
    txt := Trim(StrReplace(rawDescription, "`r", ""))
    if txt = ""
        return

    headerLines.Push(RECORDING_LOG_DESC_HEADER_LINE_PREFIX StrReplace(txt, "`n", RECORDING_LOG_DESC_DISPLAY_SEP))
}

/**
 * Reads `# description:` from the top-of-file recording header comment block (fast scan for tooltips).
 * @param {String} filePath Path to `.log`.
 * @returns {String}
 */
ReadRecordingDescriptionQuick(filePath) {
    if filePath = "" || !FileExist(filePath)
        return ""

    desc := ""

    Loop Read filePath {
        trimmed := Trim(A_LoopReadLine)

        if trimmed = ""
            continue
        if SubStr(trimmed, 1, 1) != "#"
            break
        if RegExMatch(trimmed, "i)^#\s*description:\s*(.*)$", &m) {
            frag := DecodeRecordingLogDescriptionStoredFragment(m[1])
            if frag != ""
                desc .= (desc = "" ? frag : "`n" frag)
        }
    }

    return desc
}

/**
 * Builds serialized log text reflecting the Events table plus the Description field (for Raw log tab).
 * @param {Array<String>} headerLines Non-description header lines maintained by the Events editor.
 * @param {Array<Object>} events Event rows from the Events table.
 * @param {String} rawDescription Text from the Description edit control.
 * @returns {String}
 */
BuildRecordingLogEditorSerializedPreview(headerLines, events, rawDescription) {
    copy := CloneRecordingLogHeaderLines(headerLines)
    InjectRecordingDescriptionIntoHeader(&copy, rawDescription)
    return SerializeRecordingLogFromEditor(copy, events)
}

/**
 * Populates the recording log events ListView.
 * @param {Gui.ListView} listView Target ListView control.
 * @param {Array<Object>} events Parsed event rows.
 */
PopulateRecordingLogEventsList(listView, events) {
    listView.Delete()

    Loop events.Length {
        parts := events[A_Index].parts
        listView.Add(
            "",
            A_Index,
            parts[1],
            parts[2],
            GetRecordingLogEventNote(parts),
            BuildRecordingLogEditorSummary(parts)
        )
    }

    listView.ModifyCol(1, 36)
    listView.ModifyCol(2, 72)
    listView.ModifyCol(3, 84)
    listView.ModifyCol(4, 120)
    listView.ModifyCol(5, 240)
    SetManageListViewColumnIntegerSort(listView, 1)
    SetManageListViewColumnIntegerSort(listView, 2)
}

/**
 * Refreshes one row in the recording log events ListView.
 * @param {Gui.ListView} listView Target ListView control.
 * @param {Integer} rowIndex One-based ListView row index.
 * @param {Object} event Parsed event row.
 */
RefreshRecordingLogEditorListRow(listView, rowIndex, event) {
    parts := event.parts
    visualRowIndex := FindManageListViewVisualRow(listView, rowIndex, 1)
    if !visualRowIndex
        visualRowIndex := rowIndex

    listView.Modify(
        visualRowIndex,
        "",
        rowIndex,
        parts[1],
        parts[2],
        GetRecordingLogEventNote(parts),
        BuildRecordingLogEditorSummary(parts)
    )
}

/**
 * Returns the ListView row and column under client coordinates.
 * @param {Gui.ListView} listView Target ListView control.
 * @param {Integer} clientX Mouse X relative to the ListView client area.
 * @param {Integer} clientY Mouse Y relative to the ListView client area.
 * @returns {{row: Integer, col: Integer}}
 */
GetManageListViewHitSubItem(listView, clientX, clientY) {
    static LVM_SUBITEMHITTEST := 0x1039

    info := Buffer(24, 0)
    NumPut("int", clientX, info, 0)
    NumPut("int", clientY, info, 4)
    DllCall(
        "SendMessage",
        "Ptr", listView.Hwnd,
        "UInt", LVM_SUBITEMHITTEST,
        "Ptr", 0,
        "Ptr", info,
        "Ptr"
    )

    rowIndex := NumGet(info, 12, "Int") + 1
    colIndex := NumGet(info, 16, "Int") + 1
    if rowIndex < 1
        return { row: 0, col: 0 }

    return { row: rowIndex, col: colIndex }
}

/**
 * Returns one-based ListBox item index under client coordinates, or 0 when none / outside list.
 * @param {Integer} hwnd ListBox HWND.
 * @param {Integer} clientX Mouse X relative to the ListBox client area.
 * @param {Integer} clientY Mouse Y relative to the ListBox client area.
 * @returns {Integer}
 */
ManageListBoxHitItem1Based(hwnd, clientX, clientY) {
    static LB_ITEMFROMPOINT := 0x1A9

    packed := ((clientY & 0xFFFF) << 16) | (clientX & 0xFFFF)
    r := DllCall(
        "SendMessage",
        "Ptr", hwnd,
        "UInt", LB_ITEMFROMPOINT,
        "Ptr", 0,
        "Ptr", packed,
        "Ptr"
    )
    idx := r & 0xFFFF
    dist := (r >> 16) & 0xFFFF
    if idx = 0xFFFF
        return 0
    if dist != 0
        return 0

    return idx + 1
}

/**
 * Converts screen MouseGetPos coords to window client-space coordinates for hit testing child controls.
 * @param {Integer} hwnd Target window hwnd.
 * @param {Integer} screenX Screen X.
 * @param {Integer} screenY Screen Y.
 * @returns {Boolean} False when ScreenToClient fails.
 */
ManageScreenCoordsToClient(hwnd, screenX, screenY, &clientXOut, &clientYOut) {
    pt := Buffer(8, 0)
    NumPut("int", screenX, pt, 0)
    NumPut("int", screenY, pt, 4)
    if !DllCall("ScreenToClient", "Ptr", hwnd, "Ptr", pt)
        return false

    clientXOut := NumGet(pt, 0, "int")
    clientYOut := NumGet(pt, 4, "int")
    return true
}

/**
 * Returns the root HWND for nested child controls inside a Gui.
 * @param {Integer} hwnd Any hwnd in that tree.
 * @returns {Integer} Root window hwnd (typically the top-level Gui).
 */
GetManageWindowRootHwnd(hwnd) {
    return DllCall("GetAncestor", "Ptr", hwnd, "UInt", 2, "Ptr")
}

/**
 * Returns screen bounds for a Gui control (left, top, right, bottom).
 * @param {Gui.Control} guiCtrl Target control.
 * @param {Integer} leftOut Screen left edge.
 * @param {Integer} topOut Screen top edge.
 * @param {Integer} rightOut Screen right edge.
 * @param {Integer} bottomOut Screen bottom edge.
 * @returns {Boolean} False when the control cannot be measured.
 */
ManageGetGuiControlScreenRect(guiCtrl, &leftOut, &topOut, &rightOut, &bottomOut) {
    leftOut := 0
    topOut := 0
    rightOut := 0
    bottomOut := 0

    if !guiCtrl
        return false

    try {
        guiCtrl.GetPos(&cx, &cy, &cw, &ch)
        guiHw := guiCtrl.Gui.Hwnd
    } catch {
        return false
    }

    if cw < 1 || ch < 1 || !guiHw
        return false

    pt := Buffer(8, 0)
    NumPut("int", cx, pt, 0)
    NumPut("int", cy, pt, 4)
    if !DllCall("ClientToScreen", "Ptr", guiHw, "Ptr", pt)
        return false

    leftOut := NumGet(pt, 0, "int")
    topOut := NumGet(pt, 4, "int")
    NumPut("int", cx + cw, pt, 0)
    NumPut("int", cy + ch, pt, 4)
    if !DllCall("ClientToScreen", "Ptr", guiHw, "Ptr", pt)
        return false

    rightOut := NumGet(pt, 0, "int")
    bottomOut := NumGet(pt, 4, "int")
    return rightOut > leftOut && bottomOut > topOut
}

/**
 * True when the cursor is inside a Gui control's screen bounds.
 * @param {Gui.Control} guiCtrl Target control.
 * @returns {Boolean}
 */
ManageIsMouseInGuiControl(guiCtrl) {
    if !ManageGetGuiControlScreenRect(guiCtrl, &left, &top, &right, &bottom)
        return false

    CoordMode("Mouse", "Screen")
    MouseGetPos(&mx, &my)
    return mx >= left && mx < right && my >= top && my < bottom
}

/**
 * Resolves a ListView row index from client Y when subitem hit-test misses.
 * @param {Gui.ListView} listView Target ListView control.
 * @param {Integer} clientY Mouse Y relative to the ListView client area.
 * @returns {Integer} One-based row index, or 0 when none.
 */
ManageGetListViewRowFromClientY(listView, clientY) {
    static LVM_GETTOPINDEX := 0x1027
    static LVM_GETITEMRECT := 0x100E
    static LVM_GETITEMCOUNT := 0x1004

    try listHw := listView.Hwnd
    catch
        return 0

    count := DllCall(
        "SendMessage",
        "Ptr", listHw,
        "UInt", LVM_GETITEMCOUNT,
        "Ptr", 0,
        "Ptr", 0,
        "Ptr"
    )
    if count < 1
        return 0

    rect := Buffer(16, 0)
    NumPut("int", 0, rect, 0)
    if !DllCall(
        "SendMessage",
        "Ptr", listHw,
        "UInt", LVM_GETITEMRECT,
        "Ptr", 0,
        "Ptr", rect,
        "Ptr"
    )
        return 0

    firstTop := NumGet(rect, 4, "int")
    firstBottom := NumGet(rect, 12, "int")
    itemH := firstBottom - firstTop
    if itemH < 8
        itemH := 17

    if clientY < firstTop
        return 0

    topIndex := DllCall(
        "SendMessage",
        "Ptr", listHw,
        "UInt", LVM_GETTOPINDEX,
        "Ptr", 0,
        "Ptr", 0,
        "Ptr"
    )
    rowIndex := topIndex + Floor((clientY - firstTop) / itemH) + 1
    return rowIndex >= 1 && rowIndex <= count ? rowIndex : 0
}

/**
 * Resolves a ListView row index under screen coordinates.
 * @param {Gui.ListView} listView Target ListView control.
 * @param {Integer} screenX Screen X.
 * @param {Integer} screenY Screen Y.
 * @returns {Integer} One-based row index, or 0 when none.
 */
ManageGetListViewRowAtScreenPos(listView, screenX, screenY) {
    if !listView
        return 0

    try listHw := listView.Hwnd
    catch
        return 0

    if !ManageScreenCoordsToClient(listHw, screenX, screenY, &clx, &cly)
        return 0

    hit := GetManageListViewHitSubItem(listView, clx, cly)
    if hit.row >= 1
        return hit.row

    return ManageGetListViewRowFromClientY(listView, cly)
}

/**
 * Creates the owned list-description overlay once (above +AlwaysOnTop main window).
 */
EnsureManageListDescOverlay() {
    global C, S, UI

    if S.HasProp("listDescOverlayGui") && S.listDescOverlayGui
        return

    overlay := Gui("+AlwaysOnTop -Caption +ToolWindow +Border -MaximizeBox -MinimizeBox +LastFound +E0x20")
    overlay.BackColor := UI.listTooltipBg
    overlay.SetFont("s" UI.fontSizeSmall, UI.fontFamily)
    S.listDescOverlayText := overlay.Add(
        "Text",
        "x" C.manageListTooltipPadX " y" C.manageListTooltipPadY " w" C.manageListTooltipMaxWidth,
        ""
    )
    S.listDescOverlayText.Opt("c" UI.listTooltipText)
    BindManageChildGui(overlay)
    S.listDescOverlayGui := overlay
}

/**
 * Hides the list-description overlay popup.
 */
HideManageListDescOverlay() {
    global S

    try {
        if S.HasProp("listDescOverlayGui") && S.listDescOverlayGui
            S.listDescOverlayGui.Hide()
    } catch {
    }

    S.listDescOverlayShown := false
    S.listDescOverlayLastText := ""
    S.listDescOverlayLastX := 0
    S.listDescOverlayLastY := 0
}

/**
 * Shows list description text in an owned overlay above the cursor.
 * Standard ToolTip() can render behind a +AlwaysOnTop owner window.
 * @param {String} message Tooltip body.
 * @param {Integer} screenX Screen X.
 * @param {Integer} screenY Screen Y.
 */
ShowManageListDescOverlay(message, screenX, screenY) {
    global C, S

    EnsureManageListDescOverlay()
    text := ManageTruncateTooltipText(message)
    if text = "" {
        HideManageListDescOverlay()
        return
    }

    S.listDescOverlayText.Value := text
    contentW := C.manageListTooltipMaxWidth
    contentH := EstimateManageToolTipHeight(text)
    winW := contentW + (C.manageListTooltipPadX * 2)
    winH := contentH + (C.manageListTooltipPadY * 2)
    tipX := screenX + C.cursorTipOffsetX
    tipY := screenY - winH - C.manageListTooltipGapAbove

    if tipY < 0
        tipY := 0
    if tipX + winW > A_ScreenWidth
        tipX := Max(0, A_ScreenWidth - winW)

    if S.listDescOverlayShown
        && S.listDescOverlayLastText = text
        && S.listDescOverlayLastX = tipX
        && S.listDescOverlayLastY = tipY
        return

    S.listDescOverlayGui.Show(Format("x{} y{} w{} h{} NoActivate", tipX, tipY, winW, winH))
    S.listDescOverlayShown := true
    S.listDescOverlayLastText := text
    S.listDescOverlayLastX := tipX
    S.listDescOverlayLastY := tipY
}

/**
 * Truncates long tooltip text before passing to ToolTip().
 * @param {String} text Tooltip body.
 * @param {Integer} limit Max grapheme roughly by StrLen().
 * @returns {String}
 */
ManageTruncateTooltipText(text, limit := 0) {
    global C

    if limit = 0
        limit := C.manageListTooltipMaxLen

    text := Trim(text)
    if StrLen(text) <= limit
        return text

    return SubStr(text, 1, Max(limit - 1, 3)) Chr(8230)
}

/**
 * Estimates ToolTip height in pixels for placement above the cursor.
 * @param {String} text Tooltip body (may include newlines).
 * @returns {Integer}
 */
EstimateManageToolTipHeight(text) {
    lineCount := Max(1, StrSplit(text, "`n").Length)
    charsPerLine := 52

    for , line in StrSplit(text, "`n")
        lineCount := Max(lineCount, Ceil(Max(StrLen(line), 1) / charsPerLine))

    return lineCount * 18 + 12
}

/**
 * Cancels a pending delayed list-description overlay show.
 */
CancelManageListDescShowTimer() {
    SetTimer(DelayedShowManageListDescOverlay, 0)
}

/**
 * Timer callback: show overlay after hover delay if the pointer is still on the same row.
 */
DelayedShowManageListDescOverlay(*) {
    global S

    CoordMode("Mouse", "Screen")
    MouseGetPos(&mx, &my)

    row := S.listTooltipPendingRow
    kind := S.listTooltipPendingKind
    tip := S.listTooltipPendingTip

    if row < 1 || tip = "" || kind = ""
        return

    try activeTab := S.mainTab.Value
    catch
        return

    if kind = "recording" {
        if activeTab != 1 || !ManageIsMouseInGuiControl(S.recordingList)
            return
        currentRow := ManageGetListViewRowAtScreenPos(S.recordingList, mx, my)
        if currentRow != row || ManageGetRecordingListDescTip(row) != tip
            return
    } else if kind = "preset" {
        if activeTab != 2 || !ManageIsMouseInGuiControl(S.presetList)
            return
        currentRow := ManageGetListViewRowAtScreenPos(S.presetList, mx, my)
        if currentRow != row || ManageGetPresetListDescTip(row) != tip
            return
    } else {
        return
    }

    ManageShowListDescTipForRow(tip, mx, my, row, kind)
}

/**
 * Tracks hover on a list row; shows overlay after a delay, repositions when already visible.
 * @param {String} tip Description text.
 * @param {Integer} screenX Screen X.
 * @param {Integer} screenY Screen Y.
 * @param {Integer} row One-based ListView row index.
 * @param {String} listKind "recording" or "preset".
 */
ManageTrackListDescHover(tip, screenX, screenY, row, listKind) {
    global C, S

    hoverKey := listKind . "|" . row

    if hoverKey != S.listTooltipHoverKey {
        S.listTooltipHoverKey := hoverKey
        S.listTooltipHoverSince := A_TickCount
        S.listTooltipPendingTip := tip
        S.listTooltipPendingKind := listKind
        S.listTooltipPendingRow := row
        HideManageListDescOverlay()
        S.listTooltipShownText := ""
        S.listTooltipRecordingRow := 0
        S.listTooltipPresetRow := 0
        CancelManageListDescShowTimer()
        SetTimer(DelayedShowManageListDescOverlay, -C.manageListTooltipShowDelayMs)
    }

    S.listTooltipPendingX := screenX
    S.listTooltipPendingY := screenY
    S.listTooltipPendingTip := tip

    if S.listDescOverlayShown && S.listTooltipShownText = tip {
        if listKind = "recording" && row = S.listTooltipRecordingRow {
            ShowManageListDescOverlay(ManageTruncateTooltipText(tip), screenX, screenY)
            return
        }
        if listKind = "preset" && row = S.listTooltipPresetRow {
            ShowManageListDescOverlay(ManageTruncateTooltipText(tip), screenX, screenY)
            return
        }
    }

    if !S.listDescOverlayShown && (A_TickCount - S.listTooltipHoverSince >= C.manageListTooltipShowDelayMs)
        ManageShowListDescTipForRow(tip, screenX, screenY, row, listKind)
}

/**
 * Hides hover tooltips for main list controls and resets tracking state.
 */
ManageHideMainListTooltips(*) {
    global S

    CancelManageListDescShowTimer()
    HideManageListDescOverlay()
    S.listTooltipMissStreak := 0
    S.listTooltipHoverKey := ""
    S.listTooltipHoverSince := 0
    S.listTooltipPendingTip := ""
    S.listTooltipPendingKind := ""
    S.listTooltipPendingRow := 0
    if S.HasProp("listTooltipShownText")
        S.listTooltipShownText := ""
    if S.HasProp("listTooltipRecordingRow")
        S.listTooltipRecordingRow := 0
    if S.HasProp("listTooltipPresetRow")
        S.listTooltipPresetRow := 0
}

/**
 * WM_MOUSEMOVE on main-window tree: refresh list description overlay (debounced).
 */
ManageOnMainWindowMouseMove(wParam, lParam, msg, hwnd) {
    global C, S

    static lastMoveTick := 0

    try mainHw := S.gui.Hwnd
    catch
        return

    if !mainHw || GetManageWindowRootHwnd(hwnd) != mainHw
        return

    if A_TickCount - lastMoveTick < C.manageListTooltipMouseMoveMinMs
        return

    lastMoveTick := A_TickCount
    ManagePollMainWindowListTooltips()
}

/**
 * Resolves description text for a hovered recordings-list row.
 * @param {Integer} row One-based ListView row index.
 * @returns {String}
 */
ManageGetRecordingListDescTip(row) {
    global S

    if row < 1 || row > S.recordingPaths.Length
        return ""

    path := S.recordingPaths[row]
    if path = "" || !S.recordingDescCache.Has(path)
        return ""

    return Trim(S.recordingDescCache[path])
}

/**
 * Resolves description text for a hovered data-inputs-list row.
 * @param {Integer} row One-based ListView row index.
 * @returns {String}
 */
ManageGetPresetListDescTip(row) {
    global S

    if row < 1 || row > S.presetPaths.Length
        return ""

    path := S.presetPaths[row]
    if path = "" || !S.presetDescCache.Has(path)
        return ""

    return Trim(S.presetDescCache[path])
}

/**
 * Shows or keeps the list description overlay for the current hover target.
 * @param {String} tip Description text.
 * @param {Integer} screenX Screen X.
 * @param {Integer} screenY Screen Y.
 * @param {Integer} row One-based ListView row index.
 * @param {String} listKind "recording" or "preset".
 */
ManageShowListDescTipForRow(tip, screenX, screenY, row, listKind) {
    global S

    truncated := ManageTruncateTooltipText(tip)
    if row = S.listTooltipRecordingRow && tip = S.listTooltipShownText && listKind = "recording" {
        ShowManageListDescOverlay(truncated, screenX, screenY)
        return
    }
    if row = S.listTooltipPresetRow && tip = S.listTooltipShownText && listKind = "preset" {
        ShowManageListDescOverlay(truncated, screenX, screenY)
        return
    }

    S.listTooltipShownText := tip
    S.listTooltipRecordingRow := listKind = "recording" ? row : 0
    S.listTooltipPresetRow := listKind = "preset" ? row : 0
    ShowManageListDescOverlay(truncated, screenX, screenY)
}

/**
 * Periodic poll: owned overlay above cursor when hovering a row with optional description text.
 */
ManagePollMainWindowListTooltips(*) {
    global C, S

    CoordMode("Mouse", "Screen")
    MouseGetPos(&mx, &my)

    try mainHw := S.gui.Hwnd
    catch {
        ManageHideMainListTooltips()
        return
    }

    if !mainHw || !WinExist("ahk_id " mainHw) {
        ManageHideMainListTooltips()
        return
    }

    if WinGetMinMax("ahk_id " mainHw) = -1 {
        ManageHideMainListTooltips()
        return
    }

    activeTab := 0
    try activeTab := S.mainTab.Value

    if activeTab = 1 && ManageIsMouseInGuiControl(S.recordingList) {
        row := ManageGetListViewRowAtScreenPos(S.recordingList, mx, my)
        tip := ManageGetRecordingListDescTip(row)

        if row < 1 || tip = "" {
            S.listTooltipMissStreak++
            if S.listTooltipMissStreak >= C.manageListTooltipMissHide
                ManageHideMainListTooltips()
            return
        }

        S.listTooltipMissStreak := 0
        ManageTrackListDescHover(tip, mx, my, row, "recording")
        return
    }

    if activeTab = 2 && ManageIsMouseInGuiControl(S.presetList) {
        prow := ManageGetListViewRowAtScreenPos(S.presetList, mx, my)
        ptip := ManageGetPresetListDescTip(prow)

        if prow < 1 || ptip = "" {
            S.listTooltipMissStreak++
            if S.listTooltipMissStreak >= C.manageListTooltipMissHide
                ManageHideMainListTooltips()
            return
        }

        S.listTooltipMissStreak := 0
        ManageTrackListDescHover(ptip, mx, my, prow, "preset")
        return
    }

    ManageHideMainListTooltips()
}

/**
 * Enables or disables the main-window list Tooltip timer.
 * @param {Boolean} enabled When false, hides any visible hover tooltip immediately.
 */
SetManageMainListTooltipPolling(enabled) {
    global C

    if enabled {
        SetTimer(ManagePollMainWindowListTooltips, C.manageListTooltipPollMs)
        OnMessage(C.WM_MOUSEMOVE, ManageOnMainWindowMouseMove)
    } else {
        SetTimer(ManagePollMainWindowListTooltips, 0)
        OnMessage(C.WM_MOUSEMOVE, ManageOnMainWindowMouseMove, 0)
        ManageHideMainListTooltips()
    }
}

/**
 * Reads the stable data row id stored in a ListView key column.
 * @param {Gui.ListView} listView Target ListView control.
 * @param {Integer} visualRowIndex One-based visual row index in the ListView.
 * @param {Integer} keyColumnIndex One-based column that stores the stable row id.
 * @returns {Integer}
 */
GetManageListViewDataRowIndex(listView, visualRowIndex, keyColumnIndex := 1) {
    if visualRowIndex < 1
        return 0

    return SafeInteger(listView.GetText(visualRowIndex, keyColumnIndex), 0)
}

/**
 * Returns the stable data row id for the currently selected ListView row.
 * @param {Gui.ListView} listView Target ListView control.
 * @param {Integer} keyColumnIndex One-based column that stores the stable row id.
 * @returns {Integer}
 */
GetManageListViewSelectedDataRowIndex(listView, keyColumnIndex := 1) {
    visualRowIndex := listView.GetNext(0, "Focused")
    if !visualRowIndex
        visualRowIndex := listView.GetNext(0, "Selected")

    return GetManageListViewDataRowIndex(listView, visualRowIndex, keyColumnIndex)
}

/**
 * Finds the visual ListView row that displays a stable data row id.
 * @param {Gui.ListView} listView Target ListView control.
 * @param {Integer} dataRowIndex Stable row id stored in the key column.
 * @param {Integer} keyColumnIndex One-based column that stores the stable row id.
 * @returns {Integer}
 */
FindManageListViewVisualRow(listView, dataRowIndex, keyColumnIndex := 1) {
    if dataRowIndex < 1
        return 0

    Loop listView.GetCount() {
        if SafeInteger(listView.GetText(A_Index, keyColumnIndex), 0) = dataRowIndex
            return A_Index
    }

    return 0
}

/**
 * Selects a ListView row by stable data row id.
 * @param {Gui.ListView} listView Target ListView control.
 * @param {Integer} dataRowIndex Stable row id stored in the key column.
 * @param {Integer} keyColumnIndex One-based column that stores the stable row id.
 */
SelectManageListViewDataRow(listView, dataRowIndex, keyColumnIndex := 1) {
    visualRowIndex := FindManageListViewVisualRow(listView, dataRowIndex, keyColumnIndex)
    if visualRowIndex
        listView.Modify(visualRowIndex, "Select Focus")
}

/**
 * Enables numeric sorting for one ListView column.
 * @param {Gui.ListView} listView Target ListView control.
 * @param {Integer} columnIndex One-based column index.
 */
SetManageListViewColumnIntegerSort(listView, columnIndex) {
    listView.ModifyCol(columnIndex, "Integer")
}

/**
 * Returns the bounding rectangle of one ListView subitem in client coordinates.
 * @param {Gui.ListView} listView Target ListView control.
 * @param {Integer} rowIndex One-based row index.
 * @param {Integer} colIndex One-based column index.
 * @returns {{left: Integer, top: Integer, right: Integer, bottom: Integer}}
 */
GetManageListViewSubItemRect(listView, rowIndex, colIndex) {
    static LVM_GETSUBITEMRECT := 0x1038

    rect := Buffer(16, 0)
    ; RECT.left requests the bounds rectangle; RECT.top supplies the zero-based subitem.
    NumPut("int", 0, rect, 0)
    NumPut("int", colIndex - 1, rect, 4)
    if !DllCall(
        "SendMessage",
        "Ptr", listView.Hwnd,
        "UInt", LVM_GETSUBITEMRECT,
        "Ptr", rowIndex - 1,
        "Ptr", rect,
        "Ptr"
    )
        return { left: 0, top: 0, right: 0, bottom: 0 }

    return {
        left: NumGet(rect, 0, "Int"),
        top: NumGet(rect, 4, "Int"),
        right: NumGet(rect, 8, "Int"),
        bottom: NumGet(rect, 12, "Int")
    }
}

/**
 * Returns the recording variable slot name for a one-based row index.
 * @param {Integer} rowIndex One-based variable row.
 * @returns {String}
 */
FormatPresetVariableSlot(rowIndex) {
    return "variable-" rowIndex
}

/**
 * Splits one preset variable line into optional label and typed value parts.
 * @param {String} rawValue Stored preset variable text.
 * @returns {{label: String, value: String}}
 */
ParseManageVariableParts(rawValue) {
    rawValue := Trim(rawValue)
    if rawValue = ""
        return { label: "", value: "" }

    if RegExMatch(rawValue, "i)^[A-Za-z]:\\")
        return { label: "", value: rawValue }

    if RegExMatch(rawValue, "i)^https?://")
        return { label: "", value: rawValue }

    if RegExMatch(rawValue, "^(?<label>[A-Za-z_][A-Za-z0-9_ ]*)\s*:\s*(?<value>.+)$", &match)
        return { label: Trim(match.label), value: Trim(match.value) }

    return { label: "", value: rawValue }
}

/**
 * Combines label and value back into one stored preset variable line.
 * @param {String} label Optional note label.
 * @param {String} value Typed value text.
 * @returns {String}
 */
FormatManageVariableStorage(label, value) {
    label := Trim(label)
    value := Trim(value)
    if value = ""
        return ""
    if label = ""
        return value
    return label ":" value
}

/**
 * Populates the preset variables ListView.
 * @param {Gui.ListView} listView Target ListView control.
 * @param {Array<Object>} variableRows Parsed variable rows.
 */
PopulatePresetVariablesList(listView, variableRows) {
    listView.Delete()

    Loop variableRows.Length {
        row := variableRows[A_Index]
        listView.Add("", A_Index, FormatPresetVariableSlot(A_Index), row.label, row.value)
    }

    listView.ModifyCol(1, 40)
    listView.ModifyCol(2, 100)
    listView.ModifyCol(3, 180)
    listView.ModifyCol(4, 340)
    SetManageListViewColumnIntegerSort(listView, 1)
}

/**
 * Refreshes one row in the preset variables ListView.
 * @param {Gui.ListView} listView Target ListView control.
 * @param {Integer} rowIndex One-based ListView row index.
 * @param {Object} row Parsed variable row.
 */
RefreshPresetVariableListRow(listView, rowIndex, row) {
    visualRowIndex := FindManageListViewVisualRow(listView, rowIndex, 1)
    if !visualRowIndex
        visualRowIndex := rowIndex

    listView.Modify(visualRowIndex, "", rowIndex, FormatPresetVariableSlot(rowIndex), row.label, row.value)
}

/**
 * Opens a table editor for the selected recording log file.
 */
ShowRecordingLogEditor(*) {
    global S, UI

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
        parsedLog := ParseRecordingLogForEditor(path)
    } catch as err {
        ShowManageMsgBox "Could not read recording:`n" err.Message, "Edit Log", "Icon!"
        return
    }

    headerLines := parsedLog.headerLines
    events := parsedLog.events
    logDesc := PeelRecordingDescriptionFromHeader(&headerLines)

    CloseRecordingLogEditor()

    if S.gui
        S.gui.Hide()

    editor := Gui("+ToolWindow +Resize", "Edit Recording Log")
    BindManageChildGui(editor)
    S.logEditorGui := editor
    S.editingLogPath := path
    editor.SetFont("s10", "Segoe UI")
    editor.BackColor := "FFFFFF"

    editor.Add("Text", "xm w" UI.recordingLogEditorWidth " c1A1A1A", FormatRecordingName(path))
    editor.Add("Text", "xm w" UI.recordingLogEditorWidth " c555555 Section", "Description (optional)")
    descEdit := editor.Add(
        "Edit",
        "xs w" UI.recordingLogEditorWidth " h" UI.recordingLogEditorDescEditH " Multi +Background" UI.editBg,
        logDesc
    )

    editorTab := editor.Add(
        "Tab3",
        "xm w" UI.recordingLogEditorWidth " h" UI.recordingLogEditorTabHeight,
        ["Events", "Raw log"]
    )

    editorTab.UseTab(1)
    editor.Add("Text", "Section c1A1A1A", "Recording events")
    recordingLogEventsInfoButton := AddManageChildInfoButton(editor, "x+2")
    recordingLogEventsInfoButton.OnEvent("Click", ShowRecordingLogEventsHelp)
    logList := editor.Add(
        "ListView",
        "xs w" UI.recordingLogEditorWidth " h" UI.recordingLogEditorListHeight " -Multi +Background" UI.listBg,
        ["#", "Ms", "Type", "Label", "Summary"]
    )
    PopulateRecordingLogEventsList(logList, events)

    editor.Add("Text", "xs w" UI.recordingLogEditorWidth " c1A1A1A", "Selected row")
    editor.Add("Text", "xs w" UI.recordingLogEditorDetailLabelWidth " c555555", "Elapsed (ms):")
    msEdit := editor.Add("Edit", "x+0 w120 ReadOnly", "")
    editor.Add("Text", "xs w" UI.recordingLogEditorDetailLabelWidth " c555555", "Label:")
    noteEdit := editor.Add("Edit", "x+0 w" UI.recordingLogEditorDetailValueWidth, "")
    detailField1Label := editor.Add("Text", "xs w" UI.recordingLogEditorDetailLabelWidth " c555555", "")
    detailField1Edit := editor.Add("Edit", "x+0 w" UI.recordingLogEditorDetailValueWidth, "")
    detailField2Label := editor.Add("Text", "xs w" UI.recordingLogEditorDetailLabelWidth " c555555", "")
    detailField2Edit := editor.Add("Edit", "x+0 w" UI.recordingLogEditorDetailValueWidth, "")
    detailField3Label := editor.Add("Text", "xs w" UI.recordingLogEditorDetailLabelWidth " c555555", "")
    detailField3Edit := editor.Add("Edit", "x+0 w" UI.recordingLogEditorDetailValueWidth, "")
    applyRowBtn := editor.Add(
        "Button",
        "xs w120 h28 +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Apply row"
    )

    editorTab.UseTab(2)
    editor.Add("Text", "Section c1A1A1A", "Raw log preview")
    editor.Add(
        "Text",
        "xs w" UI.recordingLogEditorWidth " c555555",
        "Read-only preview generated from the Events table. Save writes the table back to the log file."
    )
    rawPreview := editor.Add(
        "Edit",
        "xs w" UI.recordingLogEditorWidth " r14 Multi ReadOnly -TabStop +Background" UI.statusBg,
        BuildRecordingLogEditorSerializedPreview(headerLines, events, descEdit.Value)
    )

    editorTab.UseTab()

    saveBtn := editor.Add("Button", "xm w130 h32 Default", "Save")
    closeBtn := editor.Add("Button", "x+8 w130 h32", "Close")

    detailLabels := [detailField1Label, detailField2Label, detailField3Label]
    detailEdits := [detailField1Edit, detailField2Edit, detailField3Edit]
    selectedRowIndex := 0
    detailFieldDefs := []

    UpdateRawPreview(*) {
        rawPreview.Value := BuildRecordingLogEditorSerializedPreview(headerLines, events, descEdit.Value)
    }

    SyncSelectedLogRowFromDetailPanel() {
        if selectedRowIndex < 1 || selectedRowIndex > events.Length
            return

        event := events[selectedRowIndex]
        parts := event.parts
        parts[1] := Trim(msEdit.Value)

        Loop detailFieldDefs.Length {
            fieldDef := detailFieldDefs[A_Index]
            if fieldDef.partIndex >= 1 && fieldDef.partIndex <= parts.Length
                parts[fieldDef.partIndex] := Trim(detailEdits[A_Index].Value)
        }

        SetRecordingLogEventNote(parts, noteEdit.Value)
        RefreshRecordingLogEditorListRow(logList, selectedRowIndex, event)
        UpdateRawPreview()
    }

    LoadDetailPanel(rowIndex) {
        SyncSelectedLogRowFromDetailPanel()
        selectedRowIndex := rowIndex
        detailFieldDefs := []

        if rowIndex < 1 || rowIndex > events.Length {
            msEdit.Value := ""
            msEdit.ReadOnly := true
            noteEdit.Value := ""
            Loop 3 {
                detailLabels[A_Index].Text := ""
                detailLabels[A_Index].Visible := false
                detailEdits[A_Index].Value := ""
                detailEdits[A_Index].Visible := false
            }
            return
        }

        event := events[rowIndex]
        parts := event.parts
        msEdit.ReadOnly := false
        msEdit.Value := parts[1]
        noteEdit.Value := GetRecordingLogEventNote(parts)
        detailFieldDefs := GetRecordingLogEditorDetailFields(parts)

        Loop 3 {
            if A_Index <= detailFieldDefs.Length {
                fieldDef := detailFieldDefs[A_Index]
                detailLabels[A_Index].Text := fieldDef.label ":"
                detailLabels[A_Index].Visible := true
                detailEdits[A_Index].Value := parts[fieldDef.partIndex]
                detailEdits[A_Index].Visible := true
            } else {
                detailLabels[A_Index].Text := ""
                detailLabels[A_Index].Visible := false
                detailEdits[A_Index].Value := ""
                detailEdits[A_Index].Visible := false
            }
        }
    }

    ApplySelectedRow(*) {
        if selectedRowIndex < 1 || selectedRowIndex > events.Length
            return

        SyncSelectedLogRowFromDetailPanel()
        SetStatus(Format("Updated log row {} — {}", selectedRowIndex, BuildRecordingLogEditorSummary(events[selectedRowIndex].parts)))
    }

    OnLogListSelect(*) {
        LoadDetailPanel(GetManageListViewSelectedDataRowIndex(logList))
    }

    SaveLog(*) {
        SyncSelectedLogRowFromDetailPanel()

        try {
            logFile := FileOpen(path, "w", "UTF-8-RAW")
            if !logFile
                throw Error("Could not open file for writing.")
            ; Clone before inject: ByRef from nested SaveLog into global Inject can fail to rebind outer headerLines in some cases.
            linesForFile := CloneRecordingLogHeaderLines(headerLines)
            InjectRecordingDescriptionIntoHeader(&linesForFile, descEdit.Value)
            logFile.Write(SerializeRecordingLogFromEditor(linesForFile, events))
            logFile.Close()
            headerLines := linesForFile
            UpdateRawPreview()
            RefreshAllLists(false)
            SetStatus("Saved log — " FormatRecordingName(path))
            CloseLogEditor()
            return
        } catch as err {
            ShowManageMsgBox "Could not save log:`n" err.Message, "Edit Log", "Icon!"
        }
    }

    CloseLogEditor(*) {
        CloseRecordingLogEditor()
        if S.gui
            S.gui.Show()
    }

    logList.OnEvent("ItemSelect", OnLogListSelect)
    logList.OnEvent("DoubleClick", ApplySelectedRow)
    applyRowBtn.OnEvent("Click", ApplySelectedRow)
    saveBtn.OnEvent("Click", SaveLog)
    closeBtn.OnEvent("Click", CloseLogEditor)
    editor.OnEvent("Close", CloseLogEditor)
    editor.OnEvent("Escape", CloseLogEditor)
    descEdit.OnEvent("Change", UpdateRawPreview)

    if events.Length {
        SelectManageListViewDataRow(logList, 1)
        LoadDetailPanel(1)
    } else {
        LoadDetailPanel(0)
    }

    editor.Show("w" (UI.recordingLogEditorWidth + 24) " h" GetRecordingLogEditorWindowHeight())
    logList.Focus()
}

/**
 * Returns an unused data input file base name for Add Data Input.
 * @returns {String}
 */
SuggestNewPresetName() {
    global C

    if !FileExist(C.savesDir "\default" C.saveExt)
        return "default"

    presetNumber := 2
    while FileExist(C.savesDir "\preset-" presetNumber C.saveExt)
        presetNumber++
    return "preset-" presetNumber
}

/**
 * Top-level Enter handler for preset editor inline edit.
 * Hotkey must not target nested editor functions (AHK v2 .Call errors).
 */
PresetEditorInlineEnterHotkey(*) {
    global S

    if !S.presetEditorEnterCallback
        return

    if Type(S.presetEditorEnterCallback) != "Func"
        return

    try S.presetEditorEnterCallback.Call()
}

/**
 * Enables Enter-to-commit while a preset variable cell is being edited inline.
 * @param {Func} commitFn Nested CommitVariableInlineEdit from the open editor.
 */
EnablePresetEditorInlineEnterHotkey(commitFn) {
    global S

    if Type(commitFn) != "Func"
        return

    DisablePresetEditorInlineEnterHotkey()
    S.presetEditorEnterCallback := commitFn
    Hotkey "Enter", PresetEditorInlineEnterHotkey, "On"
}

/**
 * Disables Enter-to-commit for preset editor inline edit.
 */
DisablePresetEditorInlineEnterHotkey() {
    global S

    S.presetEditorEnterCallback := ""
    try Hotkey "Enter", PresetEditorInlineEnterHotkey, "Off"
}

/**
 * Opens the data input editor for the selected data input or a new data input.
 * @param {Boolean} createNew When true, opens a blank editor with a suggested name.
 */
ShowPresetEditor(createNew := false, *) {
    global C, S, UI

    if createNew && S.presetList
        ClearPresetSelection()

    selectedPreset := createNew ? "" : GetSelectedPresetPath()
    if !createNew && selectedPreset = "" {
        ShowManageMsgBox "Select a data input first, then click Edit Data Input.", "Edit Data Input", "Icon!"
        return
    }

    originalPresetPath := selectedPreset
    selectedRecording := GetSelectedRecordingPath()
    existingSettings := selectedPreset && FileExist(selectedPreset)
        ? ParsePresetFile(selectedPreset)
        : DefaultSettings()

    variableCount := Max(existingSettings.variables.Length, CountVariablesInLog(selectedRecording), 1)
    editorVariableRows := []
    for variableValue in existingSettings.variables
        editorVariableRows.Push(ParseManageVariableParts(variableValue))
    while editorVariableRows.Length < variableCount
        editorVariableRows.Push({ label: "", value: "" })

    if S.gui
        S.gui.Hide()

    editor := Gui("+ToolWindow", "Edit Data Input")
    BindManageChildGui(editor)
    editor.MarginX := UI.marginX
    editor.MarginY := UI.marginY
    editor.SetFont("s10", "Segoe UI")
    editor.BackColor := "FFFFFF"

    editor.Add("Text", "xm w" UI.presetEditorWidth " c1A1A1A", "Data input name")
    nameEdit := editor.Add(
        "Edit",
        "xs w" UI.presetEditorWidth,
        createNew ? SuggestNewPresetName()
            : (selectedPreset ? FormatPresetName(selectedPreset) : "default")
    )
    editor.Add("Text", "xs w" UI.presetEditorWidth " c555555 Section", "Description (optional)")
    descEdit := editor.Add(
        "Edit",
        "xs w" UI.presetEditorWidth " h" UI.presetEditorDescEditH " Multi +Background" UI.editBg,
        Trim(existingSettings.description)
    )
    editor.Add("Text", "xs w" UI.presetEditorWidth " c1A1A1A Section", "Variable inputs")
    presetVariablesInfoButton := AddManageChildInfoButton(editor, "x+2")
    presetVariablesInfoButton.OnEvent("Click", ShowPresetVariablesHelp)
    editor.Add(
        "Text",
        "xs w" UI.presetEditorWidth " c555555",
        "Click Label or Value to edit inline, or use Selected row below. Add row / Delete row adjust variable slots."
    )
    addRowBtn := editor.Add(
        "Button",
        "xs w100 h28 +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Add row"
    )
    deleteRowBtn := editor.Add(
        "Button",
        "x+8 w100 h28 +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Delete row"
    )
    variablesList := editor.Add(
        "ListView",
        "xs w" UI.presetEditorWidth " h" GetPresetEditorListHeightForShow() " -Multi +Background" UI.listBg,
        ["#", "Slot", "Label", "Value"]
    )
    PopulatePresetVariablesList(variablesList, editorVariableRows)
    inlineEditCtrl := editor.Add("Edit", "Hidden w10 h22")

    editor.Add("Text", "xs w" UI.presetEditorWidth " c1A1A1A", "Selected row")
    editor.Add("Text", "xs w" UI.presetEditorDetailLabelWidth " c555555", "Slot:")
    slotEdit := editor.Add("Edit", "x+0 w120 ReadOnly", "")
    editor.Add("Text", "xs w" UI.presetEditorDetailLabelWidth " c555555", "Label:")
    labelEdit := editor.Add("Edit", "x+0 w" UI.presetEditorDetailValueWidth, "")
    editor.Add("Text", "xs w" UI.presetEditorDetailLabelWidth " c555555", "Value:")
    valueEdit := editor.Add("Edit", "x+0 w" UI.presetEditorDetailValueWidth, "")

    applyRowBtn := editor.Add(
        "Button",
        "xm w120 h" UI.presetEditorApplyRowHeight " +Background" UI.secondaryBtnBg " c" UI.secondaryBtnText,
        "Apply row"
    )
    saveBtn := editor.Add("Button", "x+8 w130 h32 Default", "Save")
    closeBtn := editor.Add("Button", "x+8 w130 h32", "Close")

    selectedRowIndex := 0
    inlineEditRow := 0
    inlineEditCol := 0
    inlineEditOriginal := ""
    presetVarColLabel := 3
    presetVarColValue := 4
    presetEditorActive := true
    editorHwnd := editor.Hwnd

    DisablePresetInlineEditHotkeys() {
        presetEditorActive := false
        DisablePresetEditorInlineEnterHotkey()
    }

    CommitVariableInlineEdit(*) {
        if !presetEditorActive || inlineEditRow < 1
            return

        try {
            if !inlineEditCtrl.Visible
                return
        } catch {
            return
        }

        newText := Trim(inlineEditCtrl.Value)
        inlineEditCtrl.Visible := false

        if inlineEditRow >= 1 && inlineEditRow <= editorVariableRows.Length {
            if inlineEditCol = presetVarColLabel
                editorVariableRows[inlineEditRow].label := newText
            else if inlineEditCol = presetVarColValue
                editorVariableRows[inlineEditRow].value := newText
            RefreshPresetVariableListRow(variablesList, inlineEditRow, editorVariableRows[inlineEditRow])

            if selectedRowIndex = inlineEditRow {
                labelEdit.Value := editorVariableRows[inlineEditRow].label
                valueEdit.Value := editorVariableRows[inlineEditRow].value
            }
        }

        inlineEditRow := 0
        inlineEditCol := 0
        inlineEditOriginal := ""
        DisablePresetEditorInlineEnterHotkey()
    }

    CancelVariableInlineEdit(*) {
        if !presetEditorActive
            return

        try {
            if !inlineEditCtrl.Visible
                return
        } catch {
            return
        }

        inlineEditCtrl.Value := inlineEditOriginal
        inlineEditCtrl.Visible := false
        inlineEditRow := 0
        inlineEditCol := 0
        inlineEditOriginal := ""
        DisablePresetEditorInlineEnterHotkey()
    }

    StartVariableInlineEdit(visualRowIndex, colIndex) {
        if colIndex != presetVarColLabel && colIndex != presetVarColValue
            return

        CommitVariableInlineEdit()

        dataRowIndex := GetManageListViewDataRowIndex(variablesList, visualRowIndex, 1)
        if dataRowIndex < 1
            return

        ControlGetPos &listX, &listY, , , variablesList
        rect := GetManageListViewSubItemRect(variablesList, visualRowIndex, colIndex)
        maxEditW := colIndex = presetVarColLabel
            ? UI.presetEditorInlineLabelMaxWidth
            : UI.presetEditorInlineValueMaxWidth
        editW := Min(Max(rect.right - rect.left, 40), maxEditW)
        editH := Max(rect.bottom - rect.top, 22)

        inlineEditRow := dataRowIndex
        inlineEditCol := colIndex
        inlineEditOriginal := variablesList.GetText(visualRowIndex, colIndex)
        inlineEditCtrl.Move(listX + rect.left, listY + rect.top, editW, editH)
        inlineEditCtrl.Value := inlineEditOriginal
        inlineEditCtrl.Visible := true
        inlineEditCtrl.Focus()
        EnablePresetEditorInlineEnterHotkey(CommitVariableInlineEdit)
    }

    LoadVariableDetailPanel(rowIndex) {
        if !(inlineEditCtrl.Visible && rowIndex = inlineEditRow)
            CommitVariableInlineEdit()
        selectedRowIndex := rowIndex

        if rowIndex < 1 || rowIndex > editorVariableRows.Length {
            slotEdit.Value := ""
            labelEdit.Value := ""
            valueEdit.Value := ""
            return
        }

        row := editorVariableRows[rowIndex]
        slotEdit.Value := FormatPresetVariableSlot(rowIndex)
        labelEdit.Value := row.label
        valueEdit.Value := row.value
    }

    ApplySelectedVariableRow(*) {
        CommitVariableInlineEdit()
        if selectedRowIndex < 1 || selectedRowIndex > editorVariableRows.Length
            return

        row := editorVariableRows[selectedRowIndex]
        row.label := Trim(labelEdit.Value)
        row.value := Trim(valueEdit.Value)
        RefreshPresetVariableListRow(variablesList, selectedRowIndex, row)
        SetStatus(Format("Updated data input row {} — {}", selectedRowIndex, FormatPresetVariableSlot(selectedRowIndex)))
    }

    SyncSelectedVariableRowFromDetailPanel() {
        if selectedRowIndex < 1 || selectedRowIndex > editorVariableRows.Length
            return

        row := editorVariableRows[selectedRowIndex]
        row.label := Trim(labelEdit.Value)
        row.value := Trim(valueEdit.Value)
    }

    AddPresetVariableRow(*) {
        CommitVariableInlineEdit()
        SyncSelectedVariableRowFromDetailPanel()

        insertIndex := selectedRowIndex >= 1
            ? Min(selectedRowIndex + 1, editorVariableRows.Length + 1)
            : editorVariableRows.Length + 1
        editorVariableRows.InsertAt(insertIndex, { label: "", value: "" })
        PopulatePresetVariablesList(variablesList, editorVariableRows)
        SelectManageListViewDataRow(variablesList, insertIndex)
        LoadVariableDetailPanel(insertIndex)
        SetStatus(Format("Added data input row {} — {}", insertIndex, FormatPresetVariableSlot(insertIndex)))
    }

    DeletePresetVariableRow(*) {
        CommitVariableInlineEdit()
        SyncSelectedVariableRowFromDetailPanel()

        if editorVariableRows.Length <= 1 {
            ShowManageMsgBox "At least one variable row is required.", "Edit Data Input", "Icon!"
            return
        }

        rowIndex := selectedRowIndex
        if rowIndex < 1
            rowIndex := GetManageListViewSelectedDataRowIndex(variablesList)
        if rowIndex < 1
            return

        editorVariableRows.RemoveAt(rowIndex)
        PopulatePresetVariablesList(variablesList, editorVariableRows)

        nextRowIndex := Min(rowIndex, editorVariableRows.Length)
        SelectManageListViewDataRow(variablesList, nextRowIndex)
        LoadVariableDetailPanel(nextRowIndex)
        SetStatus(Format("Deleted data input row {} — {} row(s) remain", rowIndex, editorVariableRows.Length))
    }

    OnVariablesListSelect(*) {
        LoadVariableDetailPanel(GetManageListViewSelectedDataRowIndex(variablesList))
    }

    OnVariablesListClick(ctl, item, *) {
        if !item
            return

        ControlGetPos &listX, &listY, , , variablesList
        CoordMode "Mouse", "Client"
        MouseGetPos &mouseX, &mouseY, , &controlHwnd, 2
        if controlHwnd != variablesList.Hwnd
            return

        hit := GetManageListViewHitSubItem(variablesList, mouseX - listX, mouseY - listY)
        if hit.row < 1
            return

        dataRowIndex := GetManageListViewDataRowIndex(variablesList, hit.row, 1)
        if dataRowIndex < 1
            return

        variablesList.Modify(hit.row, "Select Focus")
        LoadVariableDetailPanel(dataRowIndex)
        StartVariableInlineEdit(hit.row, hit.col)
    }

    SaveEditor(*) {
        CommitVariableInlineEdit()
        DisablePresetEditorInlineEnterHotkey()
        SyncSelectedVariableRowFromDetailPanel()

        if selectedRowIndex >= 1 && selectedRowIndex <= editorVariableRows.Length
            RefreshPresetVariableListRow(variablesList, selectedRowIndex, editorVariableRows[selectedRowIndex])

        presetName := SafePresetName(nameEdit.Value)
        if presetName = "" {
            ShowManageMsgBox "Enter a data input name.", "Edit Data Input", "Icon!"
            return
        }

        presetBasis := originalPresetPath != "" && FileExist(originalPresetPath) ? originalPresetPath : ""
        settings := BuildRunSettings(presetBasis)
        settings.variables := []

        for row in editorVariableRows
            settings.variables.Push(FormatManageVariableStorage(row.label, row.value))

        while settings.variables.Length && settings.variables[settings.variables.Length] = ""
            settings.variables.Pop()

        settings.description := Trim(descEdit.Value)

        if settings.variables.Length = 0 {
            ShowManageMsgBox "Enter at least one variable value.", "Edit Data Input", "Icon!"
            return
        }

        presetPath := C.savesDir "\" presetName C.saveExt

        try {
            WritePresetFile(settings, presetPath)
        } catch as err {
            ShowManageMsgBox "Could not write the data input file:`n" err.Message, "Edit Data Input", "Icon!"
            return
        }

        if originalPresetPath != "" && StrLower(originalPresetPath) != StrLower(presetPath)
            && FileExist(originalPresetPath) {
            try DeleteManagedFile(originalPresetPath)
            catch as err {
                ShowManageMsgBox "Saved as " presetName ", but could not remove the old file:`n" err.Message,
                    "Edit Data Input", "Icon!"
            }
        }

        ApplySettings(settings)
        SyncRunSettingsFromGui()
        RefreshPresetList()
        SelectByBaseName(S.presetList, S.presetPaths, FileBaseName(presetPath))
        RememberSelections()
        UpdateSelectionStatus()
        SetStatus(originalPresetPath != "" && StrLower(originalPresetPath) = StrLower(presetPath)
            ? "Updated data input — " presetName
            : "Saved data input — " presetName)
        CloseEditor()
    }

    CloseEditor(*) {
        DisablePresetInlineEditHotkeys()
        try editor.Destroy()
        if S.gui
            S.gui.Show()
    }

    OnEditorEscape(*) {
        if presetEditorActive {
            try {
                if inlineEditCtrl.Visible {
                    CancelVariableInlineEdit()
                    return
                }
            } catch {
            }
        }
        CloseEditor()
    }

    saveBtn.OnEvent("Click", SaveEditor)
    closeBtn.OnEvent("Click", CloseEditor)
    editor.OnEvent("Close", CloseEditor)
    editor.OnEvent("Escape", OnEditorEscape)
    variablesList.OnEvent("ItemSelect", OnVariablesListSelect)
    variablesList.OnEvent("Click", OnVariablesListClick)
    variablesList.OnEvent("DoubleClick", OnVariablesListClick)
    inlineEditCtrl.OnEvent("LoseFocus", CommitVariableInlineEdit)
    applyRowBtn.OnEvent("Click", ApplySelectedVariableRow)
    addRowBtn.OnEvent("Click", AddPresetVariableRow)
    deleteRowBtn.OnEvent("Click", DeletePresetVariableRow)

    if editorVariableRows.Length {
        SelectManageListViewDataRow(variablesList, 1)
        LoadVariableDetailPanel(1)
    } else {
        LoadVariableDetailPanel(0)
    }

    editor.Show("w" (UI.presetEditorWidth + 24) " h" GetPresetEditorWindowHeight())
    if editorVariableRows.Length
        variablesList.Focus()
    else
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
    ShowTransientRecordingTip("Recording... Click = click. Hold Caps Lock = delay. Hold/drag left-click = mouse hold. Ctrl/Shift/Alt shortcuts supported.")
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
    global C, S

    if !S.recording
        return

    path := S.filePath

    if S.leftHoldPending || S.leftHoldActive {
        if shouldSave && S.leftHoldActive
            CommitRecordingLeftMouseHold()
        else
            CancelRecordingLeftMouseHoldState()
    }

    if S.capsLockHoldPending || S.capsLockHoldActive {
        if shouldSave && (S.capsLockHoldActive || (S.capsLockHoldDownAt > 0
            && (A_TickCount - S.capsLockHoldDownAt) >= C.minRecordedDelayMs))
            CommitRecordingCapsLockDelay(Max(0, A_TickCount - S.capsLockHoldDownAt))
        else
            CancelRecordingCapsLockDelayState()
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
    S.leftHoldPending := false
    S.leftHoldActive := false
    S.leftHoldDownAt := 0
    S.leftHoldActiveStartedAt := 0
    S.leftHoldDownX := 0
    S.leftHoldDownY := 0
    S.leftHoldEndX := 0
    S.leftHoldEndY := 0
    S.capsLockHoldPending := false
    S.capsLockHoldActive := false
    S.capsLockHoldDownAt := 0
    ClearRecordedModifierState()
}

/**
 * Clears tracked Ctrl/Shift/Alt state for recording.
 */
ClearRecordedModifierState() {
    global S

    S.modCtrlDown := false
    S.modShiftDown := false
    S.modAltDown := false
}

/**
 * Updates tracked modifier state from a low-level keyboard event.
 * @param {Integer} vk Virtual-key code.
 * @param {Boolean} isDown True on key down, false on key up.
 */
UpdateRecordedModifierState(vk, isDown) {
    global C, S

    if vk = C.VK_LSHIFT || vk = C.VK_RSHIFT || vk = 0x10 {
        S.modShiftDown := isDown
        return
    }

    if vk = C.VK_LCONTROL || vk = C.VK_RCONTROL || vk = 0x11 {
        S.modCtrlDown := isDown
        return
    }

    if vk = C.VK_LMENU || vk = C.VK_RMENU || vk = 0x12
        S.modAltDown := isDown
}

/**
 * Returns the currently tracked modifier state for shortcut capture.
 * @returns {Object}
 */
GetRecordedModifierSnapshot() {
    global S

    return {
        ctrl: S.modCtrlDown,
        shift: S.modShiftDown,
        alt: S.modAltDown
    }
}

/**
 * Returns true when tracked Ctrl, Shift, or Alt is currently held.
 * @param {Object} modifiers Optional modifier snapshot captured at key down.
 * @returns {Boolean}
 */
HasRecordedModifierPressed(modifiers := "") {
    if modifiers != "" && modifiers is Object
        return modifiers.ctrl || modifiers.shift || modifiers.alt

    snapshot := GetRecordedModifierSnapshot()
    return snapshot.ctrl || snapshot.shift || snapshot.alt
}

/**
 * Returns pixel distance moved during the current left-button hold tracking.
 * @returns {Number}
 */
GetMouseHoldMoveDistance() {
    global S

    return Sqrt((S.leftHoldEndX - S.leftHoldDownX) ** 2 + (S.leftHoldEndY - S.leftHoldDownY) ** 2)
}

/**
 * Returns true when the tracked left-button gesture moved enough to count as a drag.
 * @returns {Boolean}
 */
HasMouseHoldDragged() {
    global C

    return GetMouseHoldMoveDistance() >= C.mouseHoldDragThresholdPx
}

/**
 * Marks drag/hold recording active and shows the HOLD cursor indicator.
 */
ActivateRecordingLeftMouseHold() {
    global S, C

    if S.leftHoldActive
        return

    S.leftHoldActive := true
    S.leftHoldActiveStartedAt := A_TickCount
    SetTimer CheckLeftMouseHoldRecording, 0
    SetTimer RefreshRecordingLeftMouseHoldTip, C.mouseHoldTipRefreshMs
    RefreshRecordingLeftMouseHoldTip()
}

/**
 * Tracks mouse position during a pending or active left-button hold.
 * @param {Number} x Screen X coordinate.
 * @param {Number} y Screen Y coordinate.
 */
UpdateRecordingLeftMouseHoldTracking(x, y) {
    global S, C

    if !S.leftHoldPending && !S.leftHoldActive
        return

    S.leftHoldEndX := x
    S.leftHoldEndY := y

    if S.leftHoldPending && !S.leftHoldActive && ShouldRecordLeftMouseHold()
        ActivateRecordingLeftMouseHold()
    else if S.leftHoldActive
        RefreshRecordingLeftMouseHoldTip()
}

/**
 * Returns true when the current left-button gesture should be recorded as a hold.
 * @returns {Boolean}
 */
ShouldRecordLeftMouseHold() {
    global S, C

    return HasMouseHoldDragged() || (A_TickCount - S.leftHoldDownAt) >= C.minRecordedDelayMs
}

/**
 * Shows the HOLD indicator once a hold or drag is detected.
 */
CheckLeftMouseHoldRecording(*) {
    global S

    if !S.recording || !S.leftHoldPending || S.leftHoldActive
        return

    if !GetKeyState("LButton", "P") {
        CancelRecordingLeftMouseHoldState()
        return
    }

    if ShouldRecordLeftMouseHold()
        ActivateRecordingLeftMouseHold()
}

/**
 * Updates the active hold indicator beside the cursor.
 */
RefreshRecordingLeftMouseHoldTip(*) {
    global S

    if !S.recording || !S.leftHoldActive {
        SetTimer RefreshRecordingLeftMouseHoldTip, 0
        return
    }

    ShowMouseHoldCursorTip()
}

/**
 * Clears left-hold tracking without writing to the log.
 */
CancelRecordingLeftMouseHoldState() {
    global S

    SetTimer CheckLeftMouseHoldRecording, 0
    SetTimer RefreshRecordingLeftMouseHoldTip, 0
    S.leftHoldPending := false
    S.leftHoldActive := false
    S.leftHoldDownAt := 0
    S.leftHoldActiveStartedAt := 0
    S.leftHoldDownX := 0
    S.leftHoldDownY := 0
    S.leftHoldEndX := 0
    S.leftHoldEndY := 0

    if IsRecording()
        RestoreRecordingStatusTip()
    else
        ToolTip
}

/**
 * Writes a recorded left-button hold/drag to the log.
 */
CommitRecordingLeftMouseHold(*) {
    global S, C

    if !S.leftHoldActive
        return

    SetTimer RefreshRecordingLeftMouseHoldTip, 0

    durationMs := Max(0, A_TickCount - S.leftHoldDownAt)
    startX := S.leftHoldDownX
    startY := S.leftHoldDownY
    endX := S.leftHoldEndX
    endY := S.leftHoldEndY
    dragged := HasMouseHoldDragged()

    S.leftHoldPending := false
    S.leftHoldActive := false
    S.leftHoldDownAt := 0
    S.leftHoldActiveStartedAt := 0
    S.leftHoldDownX := 0
    S.leftHoldDownY := 0
    S.leftHoldEndX := 0
    S.leftHoldEndY := 0

    if !S.recording {
        ToolTip
        return
    }

    if !dragged && durationMs < C.minRecordedDelayMs {
        RestoreRecordingStatusTip()
        return
    }

    ctx := GetActiveWindowContext()
    SaveOriginMetadataIfNeeded(startX, startY)
    startCoords := BuildCoordinateSnapshot(startX, startY, ctx)
    S.lastTargetX := endX
    S.lastTargetY := endY
    ArmKeyCapture()
    WriteMouseHoldLine("LButton", durationMs, startCoords, endX, endY, ctx)

    seconds := Round(durationMs / 1000, 1)
    ShowTransientRecordingTip(Format("HOLD saved: {1} s", seconds), endX, endY)
}

/**
 * Returns true for the Caps Lock virtual-key code.
 * @param {Integer} vk Virtual-key code.
 * @returns {Boolean}
 */
IsCapsLockVirtualKey(vk) {
    global C

    return vk = C.VK_CAPITAL
}

/**
 * Marks Caps Lock delay recording active and shows the DELAY cursor indicator.
 */
ActivateRecordingCapsLockDelay() {
    global S, C

    if S.capsLockHoldActive
        return

    S.capsLockHoldActive := true
    SetTimer CheckCapsLockHoldRecording, 0
    SetTimer RefreshRecordingCapsLockDelayTip, C.mouseHoldTipRefreshMs
    RefreshRecordingCapsLockDelayTip()
}

/**
 * Shows the DELAY indicator once Caps Lock has been held long enough.
 */
CheckCapsLockHoldRecording(*) {
    global S, C

    if !S.recording || !S.capsLockHoldPending || S.capsLockHoldActive
        return

    if !GetKeyState("CapsLock", "P") {
        CancelRecordingCapsLockDelayState()
        return
    }

    if (A_TickCount - S.capsLockHoldDownAt) >= C.minRecordedDelayMs
        ActivateRecordingCapsLockDelay()
}

/**
 * Updates the active Caps Lock delay indicator beside the cursor.
 */
RefreshRecordingCapsLockDelayTip(*) {
    global S, C

    if !S.recording || !S.capsLockHoldActive || S.capsLockHoldDownAt = 0 {
        SetTimer RefreshRecordingCapsLockDelayTip, 0
        return
    }

    heldSec := Round((A_TickCount - S.capsLockHoldDownAt) / 1000, 1)
    ShowCursorToolTip(C.recordingDelayIndicatorText " " heldSec "s")
}

/**
 * Clears Caps Lock delay tracking without writing to the log.
 */
CancelRecordingCapsLockDelayState() {
    global S

    SetTimer CheckCapsLockHoldRecording, 0
    SetTimer RefreshRecordingCapsLockDelayTip, 0
    S.capsLockHoldPending := false
    S.capsLockHoldActive := false
    S.capsLockHoldDownAt := 0

    if IsRecording()
        RestoreRecordingStatusTip()
    else
        ToolTip
}

/**
 * Writes a recorded Caps Lock hold as a meta delay line.
 * @param {Integer} durationMs Hold duration in milliseconds.
 */
CommitRecordingCapsLockDelay(durationMs) {
    global S, C

    durationMs := Max(0, durationMs)
    S.capsLockHoldPending := false
    S.capsLockHoldActive := false
    S.capsLockHoldDownAt := 0
    SetTimer RefreshRecordingCapsLockDelayTip, 0

    if !S.recording {
        ToolTip
        return
    }

    if durationMs < C.minRecordedDelayMs {
        RestoreRecordingStatusTip()
        return
    }

    ArmKeyCapture()
    WriteRecordingDelayLine(durationMs)

    seconds := Round(durationMs / 1000, 1)
    ShowTransientRecordingTip(Format("Delay saved: {1} s", seconds))
}

/**
 * Writes a manual delay marker to the recording log.
 * @param {Integer} durationMs Delay duration in milliseconds.
 */
WriteRecordingDelayLine(durationMs) {
    WriteLine(Format("{}|meta|delay|{}`n", Elapsed(), durationMs))
}

/**
 * Returns true for left/right Shift, Ctrl, or Alt virtual-key codes.
 * @param {Integer} vk Virtual-key code.
 * @returns {Boolean}
 */
IsModifierVirtualKey(vk) {
    global C

    return vk = C.VK_LSHIFT || vk = C.VK_RSHIFT || vk = 0x10
        || vk = C.VK_LCONTROL || vk = C.VK_RCONTROL || vk = 0x11
        || vk = C.VK_LMENU || vk = C.VK_RMENU || vk = 0x12
}

/**
 * Returns true when a key press should be stored as a shortcut instead of a variable key.
 * @param {Integer} vk Virtual-key code.
 * @param {Object} modifiers Modifier snapshot captured at key down.
 * @returns {Boolean}
 */
ShouldRecordAsShortcut(vk, modifiers := "") {
    if IsModifierVirtualKey(vk)
        return false

    return HasRecordedModifierPressed(modifiers)
}

/**
 * Builds an AutoHotkey Send string and display label for a shortcut.
 * @param {Integer} vk Virtual-key code.
 * @param {Object} modifiers Modifier snapshot captured at key down.
 * @returns {Object}
 */
BuildShortcutPayload(vk, modifiers := "") {
    sendPrefix := ""
    displayParts := []

    if modifiers = "" || !(modifiers is Object)
        modifiers := GetRecordedModifierSnapshot()

    if modifiers.ctrl {
        sendPrefix .= "^"
        displayParts.Push("Ctrl")
    }
    if modifiers.shift {
        sendPrefix .= "+"
        displayParts.Push("Shift")
    }
    if modifiers.alt {
        sendPrefix .= "!"
        displayParts.Push("Alt")
    }

    keyName := GetKeyName(Format("vk{:02X}", vk))
    if keyName = ""
        keyName := Format("vk{:02X}", vk)

    displayParts.Push(keyName)

    return {
        sendText: sendPrefix . "{" . keyName . "}",
        displayLabel: JoinShortcutLabel(displayParts)
    }
}

/**
 * Joins shortcut label parts with plus signs.
 * @param {Array} parts Label segments.
 * @returns {String}
 */
JoinShortcutLabel(parts) {
    label := ""
    for part in parts {
        label := label = "" ? part : label . " + " . part
    }
    return label
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
                S.leftHoldPending := true
                S.leftHoldDownAt := A_TickCount
                S.leftHoldDownX := x
                S.leftHoldDownY := y
                S.leftHoldEndX := x
                S.leftHoldEndY := y
                SetTimer CheckLeftMouseHoldRecording, -C.minRecordedDelayMs

            case C.WM_LBUTTONUP:
                if S.leftHoldPending || S.leftHoldActive {
                    SetTimer CheckLeftMouseHoldRecording, 0
                    S.leftHoldEndX := x
                    S.leftHoldEndY := y

                    if S.leftHoldActive || ShouldRecordLeftMouseHold() {
                        if !S.leftHoldActive
                            ActivateRecordingLeftMouseHold()
                        CommitRecordingLeftMouseHold()
                    } else {
                        QueueMouseEvent({
                            type: "click",
                            button: "LButton",
                            x: S.leftHoldDownX,
                            y: S.leftHoldDownY
                        })
                        CancelRecordingLeftMouseHoldState()
                    }
                }

            case C.WM_MOUSEMOVE:
                if S.leftHoldPending || S.leftHoldActive
                    UpdateRecordingLeftMouseHoldTracking(x, y)

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

        if IsCapsLockVirtualKey(vk) {
            if isKeyDown {
                if !S.capsLockHoldPending && !S.capsLockHoldActive {
                    S.capsLockHoldPending := true
                    S.capsLockHoldDownAt := A_TickCount
                    SetTimer CheckCapsLockHoldRecording, -C.minRecordedDelayMs
                }
            } else if isKeyUp && (S.capsLockHoldPending || S.capsLockHoldActive) {
                SetTimer CheckCapsLockHoldRecording, 0
                CommitRecordingCapsLockDelay(Max(0, A_TickCount - S.capsLockHoldDownAt))
            }
            return 1
        }

        if IsModifierVirtualKey(vk) {
            if isKeyDown
                UpdateRecordedModifierState(vk, true)
            else if isKeyUp
                UpdateRecordedModifierState(vk, false)
        } else if isKeyDown {
            if vk = C.VK_ESCAPE {
                SetTimer SaveRecording, -1
                return 1
            }

            if vk != C.VK_F10
                QueueKeyEvent({ vk: vk, sc: sc, modifiers: GetRecordedModifierSnapshot() })
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

    modifiers := event.HasProp("modifiers") ? event.modifiers : GetRecordedModifierSnapshot()

    if ShouldRecordAsShortcut(event.vk, modifiers)
        RecordShortcut(event.vk, event.sc, modifiers)
    else
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

    ShowTransientRecordingTip(
        button = "LButton"
            ? "Click saved. Press any key after this click only if you want typed input here."
            : "Click saved (" button "). Press any key after this click only if you want typed input here.",
        screenX,
        screenY
    )
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

/**
 * Records a Ctrl/Shift/Alt keyboard shortcut during Detect.
 * @param {Integer} vk Virtual-key code.
 * @param {Integer} sc Scan code.
 * @param {Object} modifiers Modifier snapshot captured at key down.
 */
RecordShortcut(vk, sc, modifiers := "") {
    global S

    S.waitingForKey := false
    ctx := GetActiveWindowContext()
    payload := BuildShortcutPayload(vk, modifiers)

    WriteLine(Format(
        "{}|shortcut|{}|{}|{}|{}|{}|{}|{}|{}`n",
        Elapsed(),
        payload.sendText,
        payload.displayLabel,
        vk,
        sc,
        ctx.hwndText,
        ctx.class,
        ctx.title,
        ctx.exe
    ))

    ShowShortcutRecordingTip(payload.displayLabel)
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

/**
 * Writes a mouse-hold/drag event to the recording log.
 * @param {String} button Mouse button name.
 * @param {Integer} durationMs Hold duration after activation.
 * @param {Object} startCoords Start coordinate snapshot.
 * @param {Number} endScreenX End screen X coordinate.
 * @param {Number} endScreenY End screen Y coordinate.
 * @param {Object} ctx Active window context.
 */
WriteMouseHoldLine(button, durationMs, startCoords, endScreenX, endScreenY, ctx) {
    WriteLine(Format(
        "{}|mouse_hold|{}|{}|{}|{}|{}|{}|{:.6f}|{:.6f}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}`n",
        Elapsed(),
        button,
        durationMs,
        startCoords.screenX,
        startCoords.screenY,
        startCoords.clientX,
        startCoords.clientY,
        startCoords.pctX,
        startCoords.pctY,
        startCoords.clientW,
        startCoords.clientH,
        startCoords.winX,
        startCoords.winY,
        startCoords.winW,
        startCoords.winH,
        ctx.hwndText,
        ctx.class,
        ctx.title,
        ctx.exe,
        endScreenX,
        endScreenY
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
    WriteLine("# shortcut fields:`n")
    WriteLine("# elapsed_ms|shortcut|sendText|displayLabel|vk|sc|hwnd|class|title|exe`n")
    WriteLine("# mouse_hold fields:`n")
    WriteLine("# elapsed_ms|mouse_hold|button|duration_ms|startScreenX|startScreenY|clientX|clientY|pctX|pctY|clientW|clientH|winX|winY|winW|winH|hwnd|class|title|exe|endScreenX|endScreenY`n")
    WriteLine("# delay fields:`n")
    WriteLine("# elapsed_ms|meta|delay|duration_ms`n")
    WriteLine("# optional trailing note (Edit Log only, ignored during playback): |note|your label text`n")
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
        SetStatus("Data input file not found.")
        ShowManageMsgBox "Data input file not found:`n" presetPath, "Data Entry Autonoma", "Icon!"
        return false
    }

    settings := BuildRunSettings(presetPath)
    ApplySettings(settings)
    SyncRunSettingsFromGui()

    parsed := PrepareApplyLog(logPath)
    if parsed = ""
        return false

    if RecordingNeedsVariableValues(parsed) && S.variables.Length = 0 {
        SetStatus("No variables in selected data input.")
        ShowManageMsgBox "This recording expects typed variable values.`n`nUse Edit Data Input to add them.", "Data Entry Autonoma", "Icon!"
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
    if rows.rows.Length = 0 {
        SetStatus("CSV has no data rows.")
        ShowManageMsgBox "The CSV file has no usable data rows.`n`nExpected format:`nrow,name,qty`n1,Alice,100`n2,Bob,250",
            "Data Entry Autonoma", "Icon!"
        return false
    }

    csvRows := rows.rows
    csvVariableLabels := rows.variableLabels
    csvRowLabelHeader := rows.rowLabelHeader

    settings := BuildRunSettings(presetPath)
    ApplySettings(settings)
    SyncRunSettingsFromGui()

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
    totalRows := csvRows.Length
    askNextLine := S.csvAskNextLine
    S.csvBatchRunAllRemaining := false
    S.csvPromptChoice := C.csvBatchPromptChoiceNone

    if askNextLine
        ShowCsvBatchProgressTable(csvRows, csvVariableLabels, csvRowLabelHeader)

    try {
        Loop totalRows {
            rowIndex := A_Index
            row := csvRows[rowIndex]

            if S.stopBatch {
                stopped := true
                break
            }

            if askNextLine && !S.csvBatchRunAllRemaining {
                choice := WaitCsvBatchRowPrompt(rowIndex, row, totalRows, csvVariableLabels)
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

            if askNextLine
                SetCsvBatchPromptButtonsEnabled(false)

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
            } else if action.type = "mouse_hold" {
                ReplayMouseHold(action)
                applied += 1
            } else if action.type = "shortcut" {
                ReplayShortcut(action)
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

    ClickPoint(point.x, point.y, action.target.button)

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

/**
 * Replays a recorded mouse hold or drag (button down, move or wait, button up).
 * @param {Object} action Parsed mouse_hold action.
 */
ReplayMouseHold(action) {
    global C, S

    startPoint := ResolveTargetPoint(action.startTarget)
    endPoint := ResolveTargetPoint(action.endTarget)

    if S.smoothMouse
        NaturalMouseMove(startPoint.x, startPoint.y)
    else
        MoveMouseInstant(startPoint.x, startPoint.y)

    if !S.applying || S.stopBatch
        return

    SleepWhileApplying(S.clickPauseMs)

    if !S.applying || S.stopBatch
        return

    ShowCursorToolTip(C.mouseHoldIndicatorText)

    MouseButtonDown(action.button)

    if !S.applying || S.stopBatch
        return

    if startPoint.x != endPoint.x || startPoint.y != endPoint.y {
        if S.smoothMouse
            NaturalMouseMove(endPoint.x, endPoint.y)
        else
            MoveMouseInstant(endPoint.x, endPoint.y)
    } else if action.durationMs > 0 {
        SleepWhileApplying(action.durationMs)
    }

    if !S.applying || S.stopBatch
        return

    MouseButtonUp(action.button)
    ToolTip
    SleepWhileApplying(S.segmentPauseMs)
}

/**
 * Replays a recorded keyboard shortcut.
 * @param {Object} action Parsed shortcut action.
 */
ReplayShortcut(action) {
    global S

    if !S.applying || S.stopBatch
        return

    SendInput action.sendText
    SleepWhileApplying(S.segmentPauseMs)
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
 * Removes an optional note prefix before the first colon (for example name:Alice -> Alice).
 * Used for preset variable lines only.
 * @param {String} rawValue Raw preset line text.
 * @returns {String}
 */
StripManageVariableLabel(rawValue) {
    return ParseManageVariableParts(rawValue).value
}

/**
 * Escapes commas and backslashes for comma-joined preset and CSV field storage.
 * @param {String} value Raw field text.
 * @returns {String}
 */
EscapeManageDelimitedField(value) {
    value := StrReplace(value, "\", "\\")
    value := StrReplace(value, ",", "\,")
    return value
}

/**
 * Restores escaped commas and backslashes in a preset variable value.
 * @param {String} value Stored or edited field text.
 * @returns {String}
 */
UnescapeManageDelimitedField(value) {
    result := ""
    i := 1
    valueLength := StrLen(value)

    while i <= valueLength {
        ch := SubStr(value, i, 1)

        if ch = "\" {
            if i < valueLength {
                nextCh := SubStr(value, i + 1, 1)
                if nextCh = "," || nextCh = "\" {
                    result .= nextCh
                    i += 2
                    continue
                }
            }

            result .= ch
            i++
            continue
        }

        result .= ch
        i++
    }

    return result
}

/**
 * Joins preset variable values into one comma-separated line with escaping.
 * @param {Array<String>} fields Variable values in order.
 * @returns {String}
 */
JoinManageDelimitedFields(fields) {
    escaped := []

    for field in fields
        escaped.Push(EscapeManageDelimitedField(String(field)))

    return Join(escaped, ",")
}

/**
 * Splits one CSV batch line into fields. Commas divide fields; use \, for a literal comma and \\ for a literal backslash.
 * @param {String} line One CSV line without trailing newline.
 * @returns {Array<String>}
 */
SplitManageCsvLine(line) {
    fields := []
    current := ""
    i := 1
    lineLength := StrLen(line)

    while i <= lineLength {
        ch := SubStr(line, i, 1)

        if ch = "\" {
            if i < lineLength {
                nextCh := SubStr(line, i + 1, 1)
                if nextCh = "," || nextCh = "\" {
                    current .= nextCh
                    i += 2
                    continue
                }
            }

            current .= ch
            i++
            continue
        }

        if ch = "," {
            fields.Push(Trim(current))
            current := ""
            i++
            continue
        }

        current .= ch
        i++
    }

    fields.Push(Trim(current))
    return fields
}

/**
 * Parses a CSV batch file into header labels and row objects.
 * Row 1 is the header (column labels for notes). Data rows start on row 2.
 * @param {String} filePath CSV file path.
 * @returns {{rowLabelHeader: String, variableLabels: Array<String>, rows: Array<Object>}}
 */
ParseCsvFile(filePath) {
    rowLabelHeader := "Row"
    variableLabels := []
    rows := []
    headerParsed := false

    Loop Read filePath {
        line := Trim(A_LoopReadLine)

        if line = "" || SubStr(line, 1, 1) = "#"
            continue

        columns := SplitManageCsvLine(line)

        if columns.Length = 0
            continue

        if !headerParsed {
            rowLabelHeader := columns[1]
            if columns.Length = 1
                variableLabels := [columns[1]]
            else {
                variableLabels := []
                Loop columns.Length - 1
                    variableLabels.Push(columns[A_Index + 1])
            }
            headerParsed := true
            continue
        }

        if columns.Length = 1 {
            rows.Push({ label: String(rows.Length + 1), variables: [columns[1]] })
            continue
        }

        variables := []
        Loop columns.Length - 1
            variables.Push(columns[A_Index + 1])

        rows.Push({ label: columns[1], variables: variables })
    }

    return { rowLabelHeader: rowLabelHeader, variableLabels: variableLabels, rows: rows }
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
    repairedLine := RegExReplace(line, "i)\.exe(\d+\|(click|scroll|key|meta|shortcut|mouse_hold)\|)", ".exe`n$1")
    lines := []
    remainder := repairedLine

    while remainder != "" {
        if !RegExMatch(remainder, "(\d+)\|(click|scroll|key|meta|shortcut|mouse_hold)\|", &match) {
            if Trim(remainder) != ""
                lines.Push(Trim(remainder))
            break
        }

        startPos := match.Pos
        searchFrom := startPos + match.Len
        nextPos := 0

        if RegExMatch(SubStr(remainder, searchFrom), "(\d+)\|(click|scroll|key|meta|shortcut|mouse_hold)\|", &nextMatch, 1)
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

    if eventType = "mouse_hold" {
        if pendingClick != ""
            PushClickOnlyApplyAction(parsed, pendingClick)

        holdAction := ParseMouseHoldAction(parts, parsed.coordinateMode)
        if holdAction != "" {
            parsed.actions.Push({
                type: "mouse_hold",
                elapsed: elapsedMs,
                button: holdAction.button,
                durationMs: holdAction.durationMs,
                startTarget: holdAction.startTarget,
                endTarget: holdAction.endTarget
            })
        }
        return ""
    }

    if eventType = "shortcut" && parts.Length >= 5 {
        if pendingClick != ""
            PushClickOnlyApplyAction(parsed, pendingClick)

        parsed.actions.Push({
            type: "shortcut",
            elapsed: elapsedMs,
            sendText: parts[3],
            displayLabel: parts[4]
        })
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

/**
 * Parses a mouse_hold log line into replay metadata.
 * @param {Array} parts Pipe-delimited log fields.
 * @param {String} coordinateMode Relative or absolute coordinate mode.
 * @returns {Object|String}
 */
ParseMouseHoldAction(parts, coordinateMode) {
    if parts.Length < 22 || !IsNumericText(parts[5]) || !IsNumericText(parts[6])
        return ""

    startTarget := MakeTarget(
        "rich",
        SafeInteger(parts[5], 0),
        SafeInteger(parts[6], 0),
        SafeInteger(parts[7], ""),
        SafeInteger(parts[8], ""),
        SafeFloat(parts[9], ""),
        SafeFloat(parts[10], ""),
        SafeInteger(parts[11], ""),
        SafeInteger(parts[12], ""),
        SafeInteger(parts[13], ""),
        SafeInteger(parts[14], ""),
        SafeInteger(parts[15], ""),
        SafeInteger(parts[16], ""),
        parts[17],
        parts[18],
        parts[19],
        parts[20],
        NormalizeRecordedButton(parts[3])
    )

    endTarget := MakeTarget(
        "absolute",
        SafeInteger(parts[21], 0),
        SafeInteger(parts[22], 0)
    )

    return {
        button: NormalizeRecordedButton(parts[3]),
        durationMs: SafeInteger(parts[4], 0),
        startTarget: startTarget,
        endTarget: endTarget
    }
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

/**
 * Returns true when a log field names a supported mouse button.
 * @param {String} value Raw log field value.
 * @returns {Boolean}
 */
IsRecordedMouseButton(value) {
    normalized := StrLower(Trim(value))
    return normalized = "lbutton" || normalized = "left"
        || normalized = "rbutton" || normalized = "right"
        || normalized = "mbutton" || normalized = "middle"
        || normalized = "xbutton1" || normalized = "x1"
        || normalized = "xbutton2" || normalized = "x2"
}

/**
 * Normalizes a recorded mouse button name for replay metadata.
 * @param {String} button Raw or canonical button name.
 * @returns {String}
 */
NormalizeRecordedButton(button) {
    normalized := StrLower(Trim(button))

    switch normalized {
        case "rbutton", "right":
            return "RButton"
        case "mbutton", "middle":
            return "MButton"
        case "xbutton1", "x1":
            return "XButton1"
        case "xbutton2", "x2":
            return "XButton2"
        default:
            return "LButton"
    }
}

/**
 * Reads the mouse button from a click log line.
 * @param {Array} parts Pipe-delimited log fields.
 * @returns {String}
 */
ParseClickButtonFromParts(parts) {
    if parts.Length < 4
        return "LButton"

    candidate := parts[3]
    return IsRecordedMouseButton(candidate) ? NormalizeRecordedButton(candidate) : "LButton"
}

ParseClickTarget(parts, coordinateMode) {
    button := ParseClickButtonFromParts(parts)

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
            parts[19],
            button
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
            parts.Length >= 7 ? parts[7] : "",
            button
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

MakeTarget(mode, screenX, screenY, clientX := "", clientY := "", pctX := "", pctY := "", clientW := "", clientH := "", winX := "", winY := "", winW := "", winH := "", hwnd := "", className := "", title := "", exe := "", button := "LButton") {
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
        exe: exe,
        button: NormalizeRecordedButton(button)
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

/**
 * Returns how many variable values a data input file defines.
 * @param {String} filePath Data input file path.
 * @returns {Integer}
 */
CountPresetVariableSlots(filePath) {
    if filePath = "" || !FileExist(filePath)
        return 0

    return ParsePresetFile(filePath).variables.Length
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

/**
 * Presses a mouse button down at the current cursor position.
 * @param {String} button Recorded button name.
 */
MouseButtonDown(button := "LButton") {
    normalized := NormalizeRecordedButton(button)
    downFlag := 0x0002
    xData := 0

    switch normalized {
        case "RButton":
            downFlag := 0x0008
        case "MButton":
            downFlag := 0x0020
        case "XButton1":
            downFlag := 0x0080
            xData := 0x0001
        case "XButton2":
            downFlag := 0x0080
            xData := 0x0002
    }

    DllCall("mouse_event", "UInt", downFlag, "UInt", 0, "UInt", 0, "UInt", xData, "UPtr", 0)
}

/**
 * Releases a mouse button at the current cursor position.
 * @param {String} button Recorded button name.
 */
MouseButtonUp(button := "LButton") {
    normalized := NormalizeRecordedButton(button)
    upFlag := 0x0004
    xData := 0

    switch normalized {
        case "RButton":
            upFlag := 0x0010
        case "MButton":
            upFlag := 0x0040
        case "XButton1":
            upFlag := 0x0100
            xData := 0x0001
        case "XButton2":
            upFlag := 0x0100
            xData := 0x0002
    }

    DllCall("mouse_event", "UInt", upFlag, "UInt", 0, "UInt", 0, "UInt", xData, "UPtr", 0)
}

/**
 * Moves to a screen point and performs the requested mouse button click.
 * @param {Number} x Screen X coordinate.
 * @param {Number} y Screen Y coordinate.
 * @param {String} button Recorded button name (LButton, RButton, MButton, XButton1, XButton2).
 */
ClickPoint(x, y, button := "LButton") {
    global S

    point := ClampPoint(x, y)
    DllCall("SetCursorPos", "Int", point.x, "Int", point.y)
    Sleep 15

    if !S.applying || S.stopBatch
        return

    MouseButtonDown(button)

    if !S.applying || S.stopBatch
        return

    MouseButtonUp(button)
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
        description: "",
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
                case "description":
                    settings.description := Trim(value)
            }

            continue
        }

        if RegExMatch(line, "i)^variable")
            continue

        settings.variables := []
        for field in SplitManageCsvLine(line)
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
    S.variables := []
    for rawValue in settings.variables
        S.variables.Push(UnescapeManageDelimitedField(StripManageVariableLabel(rawValue)))
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
    desc := Trim(settings.HasProp("description") ? settings.description : "")
    desc := StrReplace(StrReplace(desc, "`r", ""), "`n", " ")
    while InStr(desc, "  ")
        desc := StrReplace(desc, "  ", " ")

    presetBody := ""
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
    if desc != ""
        presetBody .= "`n# optional description shown as tooltip on the Data Inputs list row`ndescription="
            . desc . "`n"

    presetBody .= "`n# variable-1, variable-2, variable-3 ... (optional note labels; escape commas with \\,)`n"
        . JoinManageDelimitedFields(settings.variables) . "`n"
    return presetBody
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

/**
 * Returns the display name for a saved CSV batch file.
 * @param {String} pathOrName File path or basename.
 * @returns {String}
 */
FormatCsvName(pathOrName) {
    global C

    name := FileBaseName(pathOrName)
    return RegExReplace(name, "i)\" C.csvExt "$", "")
}

/**
 * Sanitizes a CSV batch filename without its extension.
 * @param {String} name Raw CSV name.
 * @returns {String}
 */
SafeCsvName(name) {
    global C

    name := Trim(name)
    name := RegExReplace(name, "[\\/:*?`"<>|]", "-")
    name := RegExReplace(name, "i)\" C.csvExt "$", "")
    return name
}

/**
 * Sanitizes a bundle folder name for Share (Windows path rules).
 * @param {String} name User-facing bundle label.
 * @returns {String}
 */
SafeBundleDirName(name) {
    name := Trim(name)
    name := RegExReplace(name, "[\\/:*?`"<>|]", "-")
    name := RegExReplace(name, "^\.+", "")
    name := RegExReplace(name, "\.+$", "")
    name := Trim(RegExReplace(name, "-+", "-"), "-")
    name := Trim(name)
    return name != "" ? name : "dea-bundle"
}

/**
 * Resolves `parentDir\folderStem`; when that folder exists, uses `-2`, `-3`, … suffixes.
 * @param {String} parentDir Parent directory.
 * @param {String} folderStem Sanitized bundle folder stem.
 * @returns {String}
 */
ResolveUniqueBundleDirPath(parentDir, folderStem) {
    cand := parentDir "\" folderStem
    if !DirExist(cand)
        return cand

    suffix := 2
    while DirExist(parentDir "\" folderStem "-" suffix)
        suffix++

    return parentDir "\" folderStem "-" suffix
}

/**
 * Returns true when a path points to a file in csv-batches\.
 * @param {String} filePath Full file path.
 * @returns {Boolean}
 */
IsManagedCsvPath(filePath) {
    global C

    if filePath = ""
        return false

    return StrLower(SubStr(filePath, 1, StrLen(C.csvBatchesDir))) = StrLower(C.csvBatchesDir)
}

/**
 * Copies an external CSV file into csv-batches\ and selects it.
 * @param {String} sourcePath External CSV path.
 */
ImportCsvToLibrary(sourcePath) {
    global C, S

    if sourcePath = "" || !FileExist(sourcePath)
        return

    baseName := SafeCsvName(FormatCsvName(sourcePath))
    if baseName = ""
        baseName := "imported-batch"

    targetPath := C.csvBatchesDir "\" baseName C.csvExt
    if FileExist(targetPath) {
        suffix := 2
        while FileExist(C.csvBatchesDir "\" baseName "-" suffix C.csvExt)
            suffix++
        targetPath := C.csvBatchesDir "\" baseName "-" suffix C.csvExt
    }

    try {
        FileCopy sourcePath, targetPath, 1
    } catch as err {
        ShowManageMsgBox "Could not import CSV:`n" err.Message, "Import CSV", "Icon!"
        return
    }

    RefreshCsvList()
    SelectByBaseName(S.csvList, S.csvPaths, FileBaseName(targetPath))

    if S.csvEdit
        S.csvEdit.Value := targetPath

    SetInputSourceMode(C.inputSourceCsv)
    SetStatus("Imported CSV — " FormatCsvName(targetPath))
}

/**
 * Escapes a string for JSON scalar output (double quotes, backslashes, CR/LF/tab).
 * @param {String} value Raw string.
 * @returns {String}
 */
EscapeJsonScalar(value) {
    value := StrReplace(value, "\", "\\")
    value := StrReplace(value, '"', '\"')
    value := StrReplace(value, "`r", "\r")
    value := StrReplace(value, "`n", "\n")
    value := StrReplace(value, "`t", "\t")
    return value
}

/**
 * Extracts `"key": value` pairs from a portable bundle manifest JSON (minimal parser).
 * @param {String} manifestText Full manifest file body.
 * @returns {Map}
 */
ParseBundleManifest(manifestText) {

    out := Map(
        "format", "",
        "formatVersion", "",
        "appVersion", "",
        "exportedAt", "",
        "bundleName", "",
        "inputMode", "",
        "recordingFile", "",
        "presetFile", "",
        "csvFile", "",
        "recordingDisplayName", "",
        "presetDisplayName", "",
        "csvDisplayName", "",
        "variableSlotCount", "",
        "presetVariableCount", "",
        "presetSlotMismatchWarning", ""
    )

    for key, _ignored in out {
        if key = "formatVersion" || key = "variableSlotCount" || key = "presetVariableCount" {
            if RegExMatch(manifestText, '"\Q' key '\E"\s*:\s*(-?\d+)', &m)
                out[key] := m[1]
        } else {
            if RegExMatch(manifestText, '"\Q' key '\E"\s*:\s*"((?:[^"\\]|\\.)*)"', &m)
                out[key] := JsonUnescapeString(m[1])
        }
    }

    return out
}

/**
 * Unescapes `\"`, `\\`, and common JSON escapes inside a extracted JSON string literal.
 * @param {String} raw Escaped substring (without surrounding quotes).
 * @returns {String}
 */
JsonUnescapeString(raw) {
    out := ""
    i := 1
    while i <= StrLen(raw) {
        ch := SubStr(raw, i, 1)
        if ch != "\" || i >= StrLen(raw) {
            out .= ch
            i++
            continue
        }

        nx := SubStr(raw, i + 1, 1)
        switch nx {
            case '"', "\\":
                out .= nx
            case 'n':
                out .= "`n"
            case 'r':
                out .= "`r"
            case 't':
                out .= "`t"
            default:
                out .= nx
        }

        i += 2
    }

    return out
}

/**
 * Returns the destination path inside a directory using `-2`, `-3` suffixes when occupied.
 * @param {String} dir Library directory path.
 * @param {String} stem Base filename without extension.
 * @param {String} ext File extension starting with '.'.
 * @returns {String} Full destination path.
 */
ResolveUniqueStemPath(dir, stem, ext) {
    cand := dir "\" stem ext
    if !FileExist(cand)
        return cand

    suffix := 2
    while FileExist(dir "\" stem "-" suffix ext)
        suffix++

    return dir "\" stem "-" suffix ext
}

/**
 * Doubles single quotes for safe embedding in a PowerShell single-quoted string.
 * @param {String} path File or directory path.
 * @returns {String}
 */
EscapePowerShellSingleQuoted(path) {
    return StrReplace(path, "'", "''")
}

/**
 * Runs PowerShell 5+ Compress-Archive (bundle ZIP export).
 * @param {String} folderSrc Staging directory (files at top level).
 * @param {String} zipDest Output .zip path.
 * @returns {Integer} Child process exit code (0 = success).
 */
RunPowerShellCompressArchiveFolder(folderSrc, zipDest) {
    global C

    if !FileExist(C.bundlePowerShellExe)
        return 1

    ps1 := A_Temp "\dea-compress-" A_TickCount ".ps1"
    script := "$ErrorActionPreference = 'Stop'`r`n"
        . "Compress-Archive -Path '" EscapePowerShellSingleQuoted(folderSrc) "\*' -DestinationPath '"
        EscapePowerShellSingleQuoted(zipDest) "' -Force`r`n"

    exitCode := 1
    try {
        WriteTextFile(script, ps1)
        pwshLine := "`"" C.bundlePowerShellExe "`" -NoProfile -ExecutionPolicy Bypass -File `"" ps1 "`""
        exitCode := RunWait(pwshLine, , "Hide")
    } catch {
        exitCode := 1
    } finally {
        if FileExist(ps1)
            try FileDelete ps1
    }
    return exitCode
}

/**
 * Runs PowerShell 5+ Expand-Archive (legacy bundle .zip import).
 * @param {String} zipPath Source archive path.
 * @param {String} folderDest Extraction folder.
 * @returns {Integer} Child process exit code (use 0 as success).
 */
RunPowerShellExpandArchive(zipPath, folderDest) {
    global C

    if !FileExist(C.bundlePowerShellExe)
        return 1

    ps1 := A_Temp "\dea-expand-" A_TickCount ".ps1"
    script := "$ErrorActionPreference = 'Stop'`r`n"
        . "Expand-Archive -LiteralPath '" EscapePowerShellSingleQuoted(zipPath) "' -DestinationPath '"
        EscapePowerShellSingleQuoted(folderDest) "' -Force`r`n"

    exitCode := 1
    try {
        WriteTextFile(script, ps1)
        pwshLine := "`"" C.bundlePowerShellExe "`" -NoProfile -ExecutionPolicy Bypass -File `"" ps1 "`""
        exitCode := RunWait(pwshLine, , "Hide")
    } catch {
        exitCode := 1
    } finally {
        if FileExist(ps1)
            try FileDelete ps1
    }
    return exitCode
}

/**
 * Zips staging folder contents using Windows built-in tar (ZIP on Windows 10 1903+).
 * @param {String} folderSrc Directory whose files become the archive root.
 * @param {String} zipDest Output .zip path.
 * @returns {Integer} Process exit code.
 */
RunTarCompressArchiveFolder(folderSrc, zipDest) {
    global C

    if folderSrc = "" || zipDest = "" || !DirExist(folderSrc)
        return 1
    if !FileExist(C.bundleTarExe)
        return 1

    cmd := "`"" C.bundleTarExe "`" -cf `"" zipDest "`" -C `"" folderSrc "`" ."
    try
        return RunWait(cmd, , "Hide")
    catch
        return 1
}

/**
 * Extracts a .zip archive into an existing folder using Windows tar.
 * @param {String} zipPath Archive path.
 * @param {String} folderDest Destination folder.
 * @returns {Integer} Process exit code.
 */
RunTarExpandArchive(zipPath, folderDest) {
    global C

    if zipPath = "" || folderDest = "" || !FileExist(zipPath)
        return 1
    if !DirExist(folderDest)
        return 1
    if !FileExist(C.bundleTarExe)
        return 1

    cmd := "`"" C.bundleTarExe "`" -xf `"" zipPath "`" -C `"" folderDest `""
    try
        return RunWait(cmd, , "Hide")
    catch
        return 1
}

/**
 * Creates a ZIP of folderSrc: Compress-Archive when PowerShell is present, otherwise tar.exe.
 * @param {String} folderSrc Staging directory.
 * @param {String} zipDest Output .zip path.
 * @returns {Integer} 0 on success with zip present, otherwise non-zero.
 */
RunManageCompressArchiveFolder(folderSrc, zipDest) {
    global C

    if FileExist(zipDest)
        try FileDelete(zipDest)

    if FileExist(C.bundlePowerShellExe) {
        psCode := RunPowerShellCompressArchiveFolder(folderSrc, zipDest)
        if psCode = 0 && FileExist(zipDest)
            return 0
    }

    try FileDelete(zipDest)
    tarCode := RunTarCompressArchiveFolder(folderSrc, zipDest)
    return tarCode = 0 && FileExist(zipDest) ? 0 : (tarCode != 0 ? tarCode : 1)
}

/**
 * Extracts ZIP to folderDest: Expand-Archive first, then tar xf if needed.
 * @param {String} zipPath Source archive.
 * @param {String} folderDest Empty or reusable folder path.
 * @returns {Integer} 0 on success.
 */
RunManageExpandArchive(zipPath, folderDest) {
    global C

    if FileExist(C.bundlePowerShellExe) {
        psCode := RunPowerShellExpandArchive(zipPath, folderDest)
        if psCode = 0
            return 0
    }

    RemoveDirTree(folderDest)
    DirCreate(folderDest)

    tarCode := RunTarExpandArchive(zipPath, folderDest)
    return tarCode = 0 ? 0 : tarCode
}

/**
 * Recursively removes a directory tree (best effort).
 * @param {String} dirPath Directory to remove.
 */
RemoveDirTree(dirPath) {
    if dirPath = "" || !DirExist(dirPath)
        return

    try {
        DirDelete dirPath, 1
    } catch {
    }
}

/**
 * Modal dialog: bundle label, Folder vs ZIP export.
 * @param {String} defaultFullLabel Pre-filled suggested name when the edit is blank on OK.
 * @returns {{ ok: Boolean, bundleLabel: String, useZip: Boolean }}
 */
ShowShareBundleDialog(defaultFullLabel) {
    global S, UI

    out := { ok: false, bundleLabel: "", useZip: false }
    hidMain := false

    if S.gui {
        hidMain := true
        try S.gui.Hide()
    }

    dlgInnerW := Min(UI.contentWidth, 436)

    dlg := Gui("+ToolWindow", "Share bundle")
    BindManageChildGui(dlg)
    dlg.MarginX := UI.marginX
    dlg.MarginY := UI.marginY
    dlg.BackColor := UI.bg
    dlg.SetFont("s" UI.fontSizeBody, UI.fontFamily)

    dlg.Add(
        "Text",
        "xm w" dlgInnerW,
        "Use a name below, or keep the suggestion.`n`nHow do you want to save this bundle?"
    )
    nameEdit := dlg.Add("Edit", "xm w" dlgInnerW, defaultFullLabel)

    rFolder := dlg.Add(
        "Radio",
        "xm Group Checked",
        "Folder — a new folder with all the files inside (easiest to open or copy)"
    )
    rZip := dlg.Add(
        "Radio",
        "xm",
        "One zip file — easier to email or move as a single file"
    )

    dlg.SetFont("s" UI.fontSizeBody, UI.fontFamily)
    okBtn := dlg.Add("Button", "xm w92 Default", "OK")
    cxBtn := dlg.Add("Button", "x+" UI.btnGap " w92", "Cancel")

    closed := false

    ShutdownShareBundleDlg(submitOk) {
        global S

        if closed
            return
        closed := true

        if submitOk {
            lbl := Trim(nameEdit.Value)
            out.ok := true
            out.bundleLabel := lbl != "" ? lbl : defaultFullLabel
            out.useZip := (rFolder.Value = 2)
        }

        try dlg.Destroy()
        if hidMain && S.gui
            try S.gui.Show()
    }

    okBtn.OnEvent("Click", (*) => ShutdownShareBundleDlg(true))
    cxBtn.OnEvent("Click", (*) => ShutdownShareBundleDlg(false))
    dlg.OnEvent("Close", (*) => ShutdownShareBundleDlg(false))
    dlg.OnEvent("Escape", (*) => ShutdownShareBundleDlg(false))

    dlg.Show()
    WinWaitClose("ahk_id " dlg.Hwnd)

    return out
}

/**
 * Prompts for bundle label and Folder vs ZIP, then writes bundle output.
 */
ShareDataEntryBundle(*) {
    global C, S

    if S.recording || S.applying || S.batchRunning {
        SetStatus("Wait until recording or Run has finished before sharing.")
        return
    }

    logPath := GetSelectedRecordingPath()
    if logPath = "" || !FileExist(logPath) {
        SetStatus("Choose a recording in the list first.")
        ShowManageMsgBox "Choose a recording in the list, then try Share again.", "Share bundle", "Icon!"
        return
    }

    presetMode := S.inputSourceMode != C.inputSourceCsv

    presetPath := ""
    csvPath := ""

    if presetMode {
        presetPath := GetSelectedPresetPath()
        if presetPath = "" || !FileExist(presetPath) {
            SetStatus("Pick a data input first, or switch to CSV mode if you meant to share a CSV batch.")
            ShowManageMsgBox "Pick a data input in the list first (Bulk Inputs tab if you need a CSV).", "Share bundle", "Icon!"
            return
        }
    } else {
        csvPath := GetSelectedCsvPath()
        if csvPath = "" {
            SetStatus("Pick a CSV batch file first.")
            ShowManageMsgBox "Pick a CSV batch file, then try Share again.", "Share bundle", "Icon!"
            return
        }

        if !FileExist(csvPath) {
            SetStatus("That CSV file is missing.")
            ShowManageMsgBox "That CSV path no longer exists:`n" csvPath, "Share bundle", "Icon!"
            return
        }
    }

    defaultName := FormatRecordingName(logPath)
    bundlePcStem := RegExReplace(StrReplace(A_ComputerName, " ", "-"), "[\\/:*?`"<>|]", "-")
    bundlePcStem := RegExReplace(bundlePcStem, "i)^desktop-+", "")
    bundlePcStem := RegExReplace(bundlePcStem, "i)^desktop$", "")
    bundlePcStem := Trim(RegExReplace(bundlePcStem, "-+", "-"), "-")
    if bundlePcStem = ""
        bundlePcStem := "unknown-pc"
    bundleDateSuffix := "-" bundlePcStem "-" FormatTime(A_Now, "MMddyy")
    defaultFullLabel := defaultName bundleDateSuffix
    bundleOpts := ShowShareBundleDialog(defaultFullLabel)
    if !bundleOpts.ok {
        SetStatus("Share cancelled.")
        return
    }
    bundleLabel := bundleOpts.bundleLabel
    useZip := bundleOpts.useZip

    variableSlots := CountRecordingVariableSlots(logPath)
    recordingDisplay := FormatRecordingName(logPath)

    presetDisplay := ""
    csvDisplay := ""
    presetVarCount := ""
    mismatchWarning := ""

    inputMode := presetMode ? "preset" : "csv"
    presetFileKey := ""
    csvFileKey := ""

    if presetMode {
        presetDisplay := FormatPresetName(presetPath)
        parsed := ParsePresetFile(presetPath)
        presetVarCount := parsed.variables.Length

        if variableSlots != presetVarCount && variableSlots > 0
            mismatchWarning := Format(
                "Recording declares {1} typed variable slot(s) but preset has {2} value column(s)",
                variableSlots,
                presetVarCount
            )

        presetFileKey := Format('  "presetFile": "{1}",`n', C.bundlePresetZipName)
    } else {
        csvDisplay := FormatCsvName(csvPath)
        csvFileKey := Format('  "csvFile": "{1}",`n', C.bundleCsvZipName)
    }

    exportedAt := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")

    manifest := ""
    manifest .= "{`n"
    manifest .= Format('  "format": "{1}",`n', C.bundleFormatId)
    manifest .= Format('  "formatVersion": {1},`n', C.bundleFormatVersion)
    manifest .= Format('  "appVersion": "{1}",`n', EscapeJsonScalar(C.appVersion))
    manifest .= Format('  "exportedAt": "{1}",`n', EscapeJsonScalar(exportedAt))
    manifest .= Format('  "bundleName": "{1}",`n', EscapeJsonScalar(bundleLabel))
    manifest .= Format('  "inputMode": "{1}",`n', inputMode)
    manifest .= Format('  "recordingFile": "{1}",`n', C.bundleRecordingZipName)
    manifest .= presetFileKey
    manifest .= csvFileKey
    manifest .= Format('  "recordingDisplayName": "{1}",`n', EscapeJsonScalar(recordingDisplay))

    if presetMode
        manifest .= Format('  "presetDisplayName": "{1}",`n', EscapeJsonScalar(presetDisplay))
    else
        manifest .= Format('  "csvDisplayName": "{1}",`n', EscapeJsonScalar(csvDisplay))

    manifest .= Format('  "variableSlotCount": {1}', variableSlots)

    if presetMode
        manifest .= Format(',`n  "presetVariableCount": {1}', presetVarCount)

    if mismatchWarning != ""
        manifest .= Format(',`n  "presetSlotMismatchWarning": "{1}"', EscapeJsonScalar(mismatchWarning))

    manifest .= "`n}`n"

    if useZip {
        staging := A_Temp "\" C.bundleStagingTempPrefix A_TickCount
        zipTemp := A_Temp "\" C.bundleStagingTempPrefix A_TickCount ".zip"

        try {
            DirCreate(staging)
            WriteTextFile(manifest, staging "\" C.bundleManifestFileName)
            FileCopy logPath, staging "\" C.bundleRecordingZipName, 1

            if presetMode
                FileCopy presetPath, staging "\" C.bundlePresetZipName, 1
            else
                FileCopy csvPath, staging "\" C.bundleCsvZipName, 1

            if FileExist(zipTemp)
                FileDelete(zipTemp)

            bundleZipExit := RunManageCompressArchiveFolder(staging, zipTemp)
            if bundleZipExit != 0 || !FileExist(zipTemp) {
                SetStatus("Could not create the zip file.")
                ShowManageMsgBox "This PC couldn't make the zip file. Try saving as a folder instead, or update Windows and try again.", "Share bundle", "Icon!"
                return
            }

            saveDefault := SafeCsvName(bundleLabel) C.bundleZipExt
            savePath := ShowManageFileSelect(
                "S16",
                A_ScriptDir "\" saveDefault,
                "Save bundle",
                "Data Entry Autonoma bundle (*" C.bundleZipExt ";*.zip)"
            )

            if savePath = "" {
                SetStatus("Save cancelled.")
                return
            }

            EnsureParentDir(savePath)
            if FileExist(savePath)
                FileDelete(savePath)
            FileMove zipTemp, savePath, 1

            SetStatus("Saved — " FileBaseName(savePath))
            ShowManageMsgBox "Saved here:`n`n" savePath, "Share bundle", "Iconi"
        } catch as err {
            SetStatus("Share didn't finish.")
            ShowManageMsgBox "Something went wrong while saving:`n" err.Message, "Share bundle", "Icon!"
        } finally {
            RemoveDirTree(staging)
            if FileExist(zipTemp)
                try FileDelete(zipTemp)
        }
        return
    }

    parentDir := ShowManageFileSelect("D", A_ScriptDir, "Pick where to create the new folder")
    if parentDir = "" {
        SetStatus("Share cancelled.")
        return
    }

    folderStem := SafeBundleDirName(bundleLabel)
    bundleDir := ResolveUniqueBundleDirPath(parentDir, folderStem)

    try {
        DirCreate(bundleDir)
        WriteTextFile(manifest, bundleDir "\" C.bundleManifestFileName)
        FileCopy logPath, bundleDir "\" C.bundleRecordingZipName, 1

        if presetMode
            FileCopy presetPath, bundleDir "\" C.bundlePresetZipName, 1
        else
            FileCopy csvPath, bundleDir "\" C.bundleCsvZipName, 1

        SetStatus("Saved — folder " FileBaseName(bundleDir))
        ShowManageMsgBox "Your bundle is in this folder:`n`n" bundleDir, "Share bundle", "Iconi"
    } catch as err {
        SetStatus("Share didn't finish.")
        ShowManageMsgBox "Something went wrong while saving:`n" err.Message, "Share bundle", "Icon!"
    }
}

/**
 * Imports a bundle from a picked folder or a `.zip`.
 * Copies the recording plus data-input or CSV from the bundle into the app's library folders (same names as Shared), not unrelated files beside them.
 */
ImportDataEntryBundle(*) {
    global C, S

    if S.recording || S.applying || S.batchRunning {
        SetStatus("Wait until recording or Run has finished before importing.")
        return
    }

    how := ShowManageMsgBox(
        "Was this bundle saved as a folder, or one zip file?`n`n"
        . "Yes — pick the bundle folder.`n"
        . "No — pick the .zip file.",
        "Import a bundle",
        "Icon? YesNoCancel"
    )

    if S.gui
        S.gui.Show()

    if how != "Yes" && how != "No" {
        SetStatus("Import cancelled.")
        return
    }

    extractDir := ""
    tempBundleExtract := false

    if how = "Yes" {
        bundleParent := ShowManageFileSelect("D", A_ScriptDir, "Pick the bundle folder")
        if bundleParent = "" {
            SetStatus("Import cancelled.")
            return
        }

        extractDir := RTrim(bundleParent, "\\")
        bundleManifestFull := extractDir "\" C.bundleManifestFileName
        if !FileExist(bundleManifestFull) {
            SetStatus("No bundle info in that folder.")
            ShowManageMsgBox "That folder doesn't contain " C.bundleManifestFileName ".`n`n"
                . "Choose the folder that Share created — the one that holds the listing file, recording, and data files together.",
                "Import bundle", "Icon!"
            return
        }

        tempBundleExtract := false

    }
    ; how = No — zip
    else {

        picked := ShowManageFileSelect(
            "1",
            A_ScriptDir,
            "Pick the bundle zip",
            "Zip|*.dea.zip;*.zip"
        )

        if picked = "" {
            SetStatus("Import cancelled.")
            return
        }

        if !FileExist(picked) {
            SetStatus("That file wasn't found.")
            ShowManageMsgBox "Could not find:`n" picked, "Import bundle", "Icon!"
            return
        }

        extractDir := A_Temp "\" C.bundleImportTempPrefix A_TickCount
        DirCreate extractDir
        tempBundleExtract := true
        expandPsExitCode := RunManageExpandArchive(picked, extractDir)
        if expandPsExitCode != 0 {
            RemoveDirTree(extractDir)
            SetStatus("Could not open that zip.")
            ShowManageMsgBox "That zip could not be opened. It may be damaged, or your PC could not unpack it.", "Import bundle", "Icon!"
            return
        }
    }

    try {
        manifestPath := extractDir "\" C.bundleManifestFileName
        if !FileExist(manifestPath) {
            SetStatus("This doesn't look like a bundle.")
            ShowManageMsgBox "This folder or zip doesn't contain the bundle info file the app expects.", "Import bundle", "Icon!"
            return
        }

        manifestText := ReadTextFile(manifestPath)
        man := ParseBundleManifest(manifestText)

        if man["format"] != C.bundleFormatId {
            SetStatus("Not a bundle from this app.")
            ShowManageMsgBox "This isn't a bundle from Data Entry Autonoma.", "Import bundle", "Icon!"
            return
        }

        fv := Trim(man["formatVersion"])
        try fvNum := Integer(fv)
        catch {
            fvNum := -1
        }

        if fvNum != C.bundleFormatVersion {
            SetStatus("This bundle doesn't match this app version.")
            ShowManageMsgBox "This bundle needs a matching app version.", "Import bundle", "Icon!"
            return
        }

        if man["recordingFile"] = "" || man["recordingFile"] != C.bundleRecordingZipName {
            SetStatus("This bundle looks damaged.")
            ShowManageMsgBox "The bundle info doesn't match what this app expects. Try exporting again.", "Import bundle", "Icon!"
            return
        }

        inputMode := StrLower(Trim(man["inputMode"]))
        if inputMode != "preset" && inputMode != "csv" {
            SetStatus("This bundle looks damaged.")
            ShowManageMsgBox "The bundle info doesn't describe a valid preset or CSV setup.", "Import bundle", "Icon!"
            return
        }

        recSrc := extractDir "\" C.bundleRecordingZipName
        if !FileExist(recSrc) {
            SetStatus("This bundle is missing the recording file.")
            ShowManageMsgBox "The recording file is missing from this bundle.", "Import bundle", "Icon!"
            return
        }

        presetSrc := ""
        csvSrc := ""

        if inputMode = "preset" {
            if man["presetFile"] != C.bundlePresetZipName {
                SetStatus("This bundle looks damaged.")
                ShowManageMsgBox "The bundle info doesn't list the data-input file this app expects.", "Import bundle", "Icon!"
                return
            }

            presetSrc := extractDir "\" C.bundlePresetZipName
            if !FileExist(presetSrc) {
                SetStatus("Missing data-input file in bundle.")
                ShowManageMsgBox "The data-input file is missing from this folder or zip.", "Import bundle", "Icon!"
                return
            }
        } else {
            if man["csvFile"] != C.bundleCsvZipName {
                SetStatus("This bundle looks damaged.")
                ShowManageMsgBox "The bundle info doesn't list the spreadsheet file this app expects.", "Import bundle", "Icon!"
                return
            }

            csvSrc := extractDir "\" C.bundleCsvZipName
            if !FileExist(csvSrc) {
                SetStatus("Missing spreadsheet in bundle.")
                ShowManageMsgBox "The spreadsheet (CSV) file is missing from this folder or zip.", "Import bundle", "Icon!"
                return
            }
        }

        recDisplay := Trim(man["recordingDisplayName"])
        if recDisplay = ""
            recDisplay := "imported-recording"

        recordingStem := SafeRecordingFileName(recDisplay)
        destRecording := ResolveUniqueStemPath(C.recordingsDir, recordingStem, ".log")

        destPreset := ""
        destCsv := ""

        if inputMode = "preset" {
            presetDisplay := Trim(man["presetDisplayName"])
            if presetDisplay = ""
                presetDisplay := "imported-data-input"

            presetStem := SafePresetName(presetDisplay)
            if presetStem = ""
                presetStem := "imported-data-input"

            destPreset := ResolveUniqueStemPath(C.savesDir, presetStem, C.saveExt)
        } else {
            csvDisplay := Trim(man["csvDisplayName"])
            if csvDisplay = ""
                csvDisplay := "imported-batch"

            csvStem := SafeCsvName(csvDisplay)
            if csvStem = ""
                csvStem := "imported-batch"

            destCsv := ResolveUniqueStemPath(C.csvBatchesDir, csvStem, C.csvExt)
        }

        EnsureDir(C.recordingsDir)
        EnsureDir(C.savesDir)
        EnsureDir(C.csvBatchesDir)

        FileCopy recSrc, destRecording, 1

        if inputMode = "preset"
            FileCopy presetSrc, destPreset, 1
        else
            FileCopy csvSrc, destCsv, 1

        RefreshRecordingList()

        slotCountImported := CountRecordingVariableSlots(destRecording)

        if inputMode = "preset" {
            RefreshPresetList()
            SetInputSourceMode(C.inputSourcePreset, false)
            SelectByBaseName(S.recordingList, S.recordingPaths, FileBaseName(destRecording))
            SelectByBaseName(S.presetList, S.presetPaths, FileBaseName(destPreset))
            ClearCsvSelection()
        } else {
            RefreshCsvList()
            SetInputSourceMode(C.inputSourceCsv, false)
            SelectByBaseName(S.recordingList, S.recordingPaths, FileBaseName(destRecording))
            if S.csvEdit
                S.csvEdit.Value := destCsv
            SelectCsvListByPath(destCsv)
        }

        RememberSelections()
        UpdateSelectionStatus()
        summary := FormatRecordingName(destRecording) . (inputMode = "preset" ? " · " FormatPresetName(destPreset)
            : " · " FormatCsvName(destCsv))

        SetStatus("Success — " summary)

        noteBlock := ""

        if inputMode = "preset" {
            warn := Trim(man["presetSlotMismatchWarning"])
            presetCols := ParsePresetFile(destPreset).variables.Length

            if warn != ""
                noteBlock := warn
            else if slotCountImported != presetCols
                noteBlock := Format(
                    "The recording uses {1} space(s) for typed text, but this data input has {2} row(s). You can edit the data input before Run if those should match.",
                    slotCountImported,
                    presetCols
                )
        }

        msg := "SUCCESS — your bundle was imported.`n`n"
            . summary "`n`n"
            . "These are now selected in the app. You can click Run when you're ready."

        if noteBlock != ""
            msg .= "`n`n---`nFYI (not an error):`n" noteBlock

        ShowManageMsgBox msg, "Import — success", "Iconi"

    } catch as err {
        SetStatus("Import didn't finish.")
        ShowManageMsgBox "Something went wrong while importing:`n" err.Message, "Import bundle", "Icon!"
    } finally {
        if tempBundleExtract
            RemoveDirTree(extractDir)
    }
}

/**
 * Clears the persisted CSV path when it matches a deleted file.
 * @param {String} deletedPath Deleted CSV full path.
 */
ClearCsvStateIfMatches(deletedPath) {
    global C, S

    saved := LoadManageState()
    if StrLower(Trim(saved.csv)) = StrLower(deletedPath) {
        SaveManageState(saved.preset, saved.recording, "", saved.csvAskNextLine)
        if S.csvEdit
            S.csvEdit.Value := ""
    }
}

/**
 * Returns starter content for a new CSV batch file.
 * @returns {String}
 */
DefaultCsvTemplate() {
    return "# row,name,qty,region`nrow,name,qty,region`n1,Alice,100,East`n2,Bob,250,West"
}

/**
 * Reads a text file as a single string.
 * @param {String} filePath File path.
 * @returns {String}
 */
ReadTextFile(filePath) {
    content := ""

    Loop Read filePath {
        content .= (content = "" ? "" : "`n") A_LoopReadLine
    }

    return content
}

/**
 * Writes text content to a UTF-8 file.
 * @param {String} content File body.
 * @param {String} filePath Destination path.
 */
WriteTextFile(content, filePath) {
    EnsureParentDir(filePath)
    outputFile := FileOpen(filePath, "w", "UTF-8")
    if !outputFile
        throw Error("Could not open file for writing: " filePath)
    outputFile.Write(content)
    outputFile.Close()
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
 * @returns {Boolean}d
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
