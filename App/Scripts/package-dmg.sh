#!/usr/bin/env bash
#
# package-dmg.sh — build a signed, Developer ID Release of mise and wrap it
# in a distributable .dmg.
#
# This is a REFERENCE script. It is correct and runnable once you have a
# Developer ID Application certificate in your keychain and set DEVELOPMENT_TEAM.
# It does NOT notarize — run Scripts/notarize.sh on the produced .dmg afterward.
#
# Pipeline:
#   xcodebuild archive            -> Mise.xcarchive
#   xcodebuild -exportArchive     -> Mise.app (Developer ID signed)
#   hdiutil / create-dmg          -> Mise-<version>.dmg
#
# Usage:
#   DEVELOPMENT_TEAM=ABCDE12345 ./Scripts/package-dmg.sh
#
# Env vars:
#   DEVELOPMENT_TEAM   (required) 10-char Apple Developer Team ID.
#   SCHEME             (optional) Xcode scheme.        Default: Mise
#   CONFIGURATION      (optional) Build config.        Default: Release
#   BUILD_DIR          (optional) Output directory.    Default: ./build
#   SIGN_IDENTITY      (optional) Codesign identity.   Default: "Developer ID Application"
#
set -euo pipefail

# Resolve repo App dir regardless of where the script is invoked from.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$APP_DIR"

SCHEME="${SCHEME:-Mise}"
CONFIGURATION="${CONFIGURATION:-Release}"
BUILD_DIR="${BUILD_DIR:-$APP_DIR/build}"
SIGN_IDENTITY="${SIGN_IDENTITY:-Developer ID Application}"
PROJECT="$APP_DIR/Mise.xcodeproj"

if [[ -z "${DEVELOPMENT_TEAM:-}" ]]; then
  echo "error: DEVELOPMENT_TEAM is not set (your 10-char Apple Team ID)." >&2
  echo "       e.g. DEVELOPMENT_TEAM=ABCDE12345 $0" >&2
  exit 1
fi

# Regenerate the Xcode project from project.yml if xcodegen is available,
# so the build always reflects the source of truth.
if command -v xcodegen >/dev/null 2>&1; then
  echo "==> xcodegen generate"
  xcodegen generate
fi

ARCHIVE_PATH="$BUILD_DIR/Mise.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
EXPORT_PLIST="$BUILD_DIR/ExportOptions.plist"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$EXPORT_DIR"

echo "==> Archiving ($CONFIGURATION)"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=macOS" \
  -archivePath "$ARCHIVE_PATH" \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  CODE_SIGN_STYLE=Automatic \
  archive

# ExportOptions for Developer ID (direct distribution, not the App Store).
echo "==> Writing ExportOptions.plist"
cat > "$EXPORT_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>developer-id</string>
  <key>teamID</key>
  <string>${DEVELOPMENT_TEAM}</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <!-- Let Xcode strip swift libs / sign embedded content for hardened runtime. -->
</dict>
</plist>
PLIST

echo "==> Exporting archive (Developer ID)"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_PLIST"

APP_PATH="$EXPORT_DIR/Mise.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "error: expected app not found at $APP_PATH" >&2
  exit 1
fi

# Derive a version string for the dmg filename from the built app.
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
  "$APP_PATH/Contents/Info.plist" 2>/dev/null || echo "0.0.0")"
DMG_PATH="$BUILD_DIR/Mise-${VERSION}.dmg"

echo "==> Verifying signature / hardened runtime"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
codesign -dvv "$APP_PATH" 2>&1 | grep -i "flags=.*runtime" \
  || { echo "error: hardened runtime flag not set on the app." >&2; exit 1; }

echo "==> Building DMG -> $DMG_PATH"
rm -f "$DMG_PATH"
if command -v create-dmg >/dev/null 2>&1; then
  # create-dmg (brew install create-dmg) gives a nicer layout with an
  # /Applications drop target. It returns nonzero (2) when it can't notarize
  # inline; we notarize separately, so tolerate that.
  create-dmg \
    --volname "Mise" \
    --window-size 520 320 \
    --icon-size 110 \
    --icon "Mise.app" 130 150 \
    --app-drop-link 390 150 \
    "$DMG_PATH" \
    "$APP_PATH" || true
else
  # Fallback: plain hdiutil. Stage the .app (and an /Applications symlink)
  # into a folder, then create a compressed read-only image.
  STAGE="$BUILD_DIR/dmg-stage"
  rm -rf "$STAGE"; mkdir -p "$STAGE"
  cp -R "$APP_PATH" "$STAGE/"
  ln -s /Applications "$STAGE/Applications"
  hdiutil create \
    -volname "Mise" \
    -srcfolder "$STAGE" \
    -ov \
    -format UDZO \
    "$DMG_PATH"
fi

echo
echo "Done. Unsigned-for-distribution DMG at:"
echo "  $DMG_PATH"
echo
echo "Next: notarize it ->  ./Scripts/notarize.sh \"$DMG_PATH\""
