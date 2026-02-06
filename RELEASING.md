# Releasing LumeBar

This document defines the release flow used for `1.0.0-beta` and later versions.

## 1) Pre-flight
- Ensure working tree is clean.
- Ensure `CHANGELOG.md`, `README.md`, and `Sources/LumeBar/Resources/Info.plist` are updated.
- Verify license and notices (`LICENSE`, `THIRD_PARTY_NOTICES.md`).

## 2) Validate
```bash
swift build
swift build -c release
plutil -lint Sources/LumeBar/Resources/Info.plist
```

## 3) Commit
```bash
git add -A
git commit -m "Release 1.0.0-beta"
```

## 4) Tag
```bash
git tag -a v1.0.0-beta -m "LumeBar 1.0.0-beta"
```

## 5) Push
```bash
git push origin main
git push origin v1.0.0-beta
```

## 6) Publish GitHub release
- Create a new release from tag `v1.0.0-beta`.
- Title: `LumeBar 1.0.0-beta`
- Body: use `release-notes/1.0.0-beta.md`.
- Mark as pre-release.

## 7) Post-release
- Confirm issue templates are enabled.
- Open a tracking issue for `1.0.0-beta` feedback triage.
