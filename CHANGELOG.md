# Changelog

All notable changes to **Data Entry Autonoma** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2026-05-26

### Added

- Version history (`CHANGELOG.md`) and `VERSION` file for releases
- App version shown in the main window title (`Data Entry Autonoma v1.0.1`)

### Changed

- Install wizard upgrades existing installations in place: overwrites the exe, assets, LICENSE, README, and wizard scripts while preserving `recordings\` and `saved-inputs\` user data
- Install wizard shows **Upgrading existing installation** when reinstalling to a folder that already contains `DataEntryAutonoma.exe`

## [1.0.0] - 2026-05-26

### Added

- Record and Run workflow: capture mouse clicks, scrolls, and keyboard input once, then replay with presets or CSV batches
- Input presets with configurable mouse movement, typing speed, pauses, and variable text values
- CSV batch mode: run the same recording once per row with different variable values
- Shift-hold delays during recording for manual pauses between steps
- Graphical install wizard (`runInstallWizard.ps1`) for end-user setup with Desktop and Start Menu shortcuts
- Standalone `DataEntryAutonoma.exe` (no AutoHotkey required on target PCs)
- MIT license with required attribution

[1.0.1]: https://github.com/Jayrr-Dev/DataEntryAutonoma/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/Jayrr-Dev/DataEntryAutonoma/releases/tag/v1.0.0
