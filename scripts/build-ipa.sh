#!/bin/sh

set -eu

ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-}"
EXPORT_METHOD="${EXPORT_METHOD:-development}"
BUILD_DIR="${BUILD_DIR:-$ROOT/build}"
DERIVED_DATA_PATH="$BUILD_DIR/DerivedData"
ARCHIVE_PATH="$BUILD_DIR/SolaPlayer.xcarchive"
EXPORT_PATH="$BUILD_DIR/ipa"
EXPORT_OPTIONS_PLIST="$BUILD_DIR/ExportOptions.plist"
COMMIT_SHA="$(git rev-parse --short=12 HEAD)"

if ! xcodebuild -version >/dev/null 2>&1; then
  echo "error: Xcode is required. Run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
  exit 1
fi

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "error: xcodegen is required. Install with: brew install xcodegen" >&2
  exit 1
fi

mkdir -p "$BUILD_DIR" "$EXPORT_PATH"

echo "==> Generating Xcode project"
xcodegen generate

if [ -n "$DEVELOPMENT_TEAM" ]; then
  IPA_NAME="SolaPlayer-${COMMIT_SHA}.ipa"
  IPA_PATH="$EXPORT_PATH/$IPA_NAME"

  /usr/libexec/PlistBuddy -c "Clear dict" "$EXPORT_OPTIONS_PLIST" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :method string $EXPORT_METHOD" "$EXPORT_OPTIONS_PLIST"
  /usr/libexec/PlistBuddy -c "Add :signingStyle string automatic" "$EXPORT_OPTIONS_PLIST"
  /usr/libexec/PlistBuddy -c "Add :teamID string $DEVELOPMENT_TEAM" "$EXPORT_OPTIONS_PLIST"
  /usr/libexec/PlistBuddy -c "Add :stripSwiftSymbols bool true" "$EXPORT_OPTIONS_PLIST"

  echo "==> Archiving signed build (Release, commit $COMMIT_SHA)"
  set -o pipefail
  xcodebuild \
    -project SolaPlayer.xcodeproj \
    -scheme SolaPlayer \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE_PATH" \
    DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
    CODE_SIGN_STYLE=Automatic \
    archive

  echo "==> Exporting signed IPA ($EXPORT_METHOD)"
  set -o pipefail
  xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

  DEFAULT_IPA="$EXPORT_PATH/SolaPlayer.ipa"
  if [ ! -f "$DEFAULT_IPA" ]; then
    echo "error: Export succeeded but IPA was not found at $DEFAULT_IPA" >&2
    exit 1
  fi

  mv "$DEFAULT_IPA" "$IPA_PATH"
else
  IPA_NAME="SolaPlayer-${COMMIT_SHA}-unsigned.ipa"
  IPA_PATH="$EXPORT_PATH/$IPA_NAME"
  PAYLOAD_DIR="$EXPORT_PATH/Payload"

  echo "==> Building unsigned app (Release, commit $COMMIT_SHA)"
  set -o pipefail
  xcodebuild \
    -project SolaPlayer.xcodeproj \
    -scheme SolaPlayer \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="" \
    build

  APP_PATH="$(find "$DERIVED_DATA_PATH" -path '*/Release-iphoneos/SolaPlayer.app' -type d | head -1)"
  if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
    echo "error: Unsigned app bundle was not found under $DERIVED_DATA_PATH" >&2
    exit 1
  fi

  echo "==> Packaging unsigned IPA"
  rm -rf "$PAYLOAD_DIR"
  mkdir -p "$PAYLOAD_DIR"
  ditto "$APP_PATH" "$PAYLOAD_DIR/SolaPlayer.app"

  rm -f "$IPA_PATH"
  (
    cd "$EXPORT_PATH"
    zip -qr "$IPA_NAME" Payload
  )
  rm -rf "$PAYLOAD_DIR"
fi

echo "IPA ready: $IPA_PATH"
