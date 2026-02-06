#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/package-app.sh [--skip-build] [--output-dir <dir>] [--no-zip]

Builds and packages LumeBar as a macOS .app bundle.

Options:
  --skip-build        Reuse existing release build artifacts.
  --output-dir <dir>  Output directory (default: dist).
  --no-zip            Do not create a .zip archive.
EOF
}

output_dir="dist"
skip_build=0
create_zip=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-build)
      skip_build=1
      shift
      ;;
    --output-dir)
      output_dir="${2:-}"
      if [[ -z "$output_dir" ]]; then
        echo "error: --output-dir requires a value"
        exit 1
      fi
      shift 2
      ;;
    --no-zip)
      create_zip=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

app_name="LumeBar"
binary_path=".build/release/${app_name}"
plist_path="Sources/LumeBar/Resources/Info.plist"
app_path="${output_dir}/${app_name}.app"
zip_path="${output_dir}/${app_name}.zip"

if [[ "$skip_build" -eq 0 ]]; then
  echo "[package] building release binary"
  swift build -c release
fi

if [[ ! -x "$binary_path" ]]; then
  echo "error: release binary not found at ${binary_path}"
  echo "hint: run with build enabled or run 'swift build -c release' first."
  exit 1
fi

if [[ ! -f "$plist_path" ]]; then
  echo "error: missing Info.plist at ${plist_path}"
  exit 1
fi

resource_bundle_path="$(
  find .build -type d -path '*/release/*_LumeBar.bundle' -print -quit
)"
if [[ -z "$resource_bundle_path" ]]; then
  echo "error: SwiftPM resource bundle not found in .build/release."
  exit 1
fi

echo "[package] creating app bundle at ${app_path}"
rm -rf "$app_path"
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"

cp "$binary_path" "$app_path/Contents/MacOS/${app_name}"
cp "$plist_path" "$app_path/Contents/Info.plist"
cp -R "$resource_bundle_path" "$app_path/Contents/Resources/"
chmod +x "$app_path/Contents/MacOS/${app_name}"

if [[ "$create_zip" -eq 1 ]]; then
  echo "[package] creating zip archive at ${zip_path}"
  rm -f "$zip_path"
  ditto -c -k --sequesterRsrc --keepParent "$app_path" "$zip_path"
fi

echo "[package] done"
echo "  app: $(cd "$output_dir" && pwd)/${app_name}.app"
if [[ "$create_zip" -eq 1 ]]; then
  echo "  zip: $(cd "$output_dir" && pwd)/${app_name}.zip"
fi
