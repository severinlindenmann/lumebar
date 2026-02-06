# LumeBar

LumeBar is a macOS menu bar app that lists Lume virtual machines and lets you control them from the menu bar.

Release status: `1.0.0-beta`

## Features
- List available VMs and show running status
- Start or stop a VM using the local `lume` CLI
- Open Screen Sharing when VNC info is available
- Show VM details (CPU, memory, disk, IP, OS, storage, display, created)
- Display snapshot VNC thumbnails for running VMs when menu opens
- Support headless starts via Settings

## Requirements
- macOS 26+
- Swift 6.2 (SwiftPM)
- Lume CLI installed and available at runtime (for start/stop)
- Lume service running locally for list/details APIs (default `http://localhost:7777`)
- Lume docs: https://cua.ai/docs/lume/guide/getting-started/quickstart

## Getting Started
1. Ensure the Lume service is running locally. The app will attempt to start it by running `lume serve` if it cannot connect.
2. Build the app:

```bash
swift build -c release
```

3. Run the app:

```bash
swift run LumeBar
```

## Package as a `.app`
Create a local app bundle and zip archive:

```bash
scripts/package-app.sh
```

Artifacts:
- `dist/LumeBar.app`
- `dist/LumeBar.zip`

For signed distribution (Developer ID + notarization):

```bash
scripts/sign-and-notarize.sh \
  --identity "Developer ID Application: Your Name (TEAMID)" \
  --keychain-profile "<notarytool-profile>"
```

## Configuration
- Base URL: set in Settings (default `http://localhost:7777`).
- Start headless: toggle in Settings to run VMs without display.

## Troubleshooting
- If Start/Stop shows `no such file or directory`, ensure `lume` is installed (commonly `/opt/homebrew/bin/lume` on Apple Silicon).
- If VM thumbnails appear black during early boot, wait for guest display initialization and reopen the menu to refresh snapshots.

## Third-Party Notices
See `THIRD_PARTY_NOTICES.md`.

## License
MIT. See `LICENSE`.
