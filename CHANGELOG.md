# Changelog

## [Unreleased]

## [1.0.0-beta] - 2026-02-06
### Added
- Menu bar UI for listing Lume VMs and viewing running state.
- VM controls from the menu bar, including Start/Stop and Screen Sharing launch.
- Snapshot thumbnail preview for running VMs when opening the menu.
- Settings for Lume base URL and headless start mode.

### Changed
- VM start/stop now uses direct `lume` CLI commands instead of API mutation endpoints.
- Start command is detached so VMs continue running after the menu bar app exits.
- Details panel uses full-row click target and dynamic menu sizing.
- App and menu bar icons refreshed.

### Fixed
- Menu bar icon rendering and template handling.
- Thumbnail rendering stability and layout sizing issues during boot.
- CLI executable path resolution in app runtime context.

### Compatibility
- Platform target is macOS 26+.
- Lume CLI (`lume`) must be installed locally.

### Known Issues
- Very early VM boot frames can still appear black in snapshot mode until guest display is initialized.
