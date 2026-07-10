#!/bin/sh

set -eu

info_plist="$TARGET_BUILD_DIR/$INFOPLIST_PATH"
commit_sha="$(git -C "$SRCROOT" rev-parse --short=12 HEAD)"

if [ ! -f "$info_plist" ]; then
  echo "error: Built Info.plist not found at $info_plist" >&2
  exit 1
fi

if ! /usr/libexec/PlistBuddy -c "Set :GitCommitSHA $commit_sha" "$info_plist" >/dev/null 2>&1; then
  /usr/libexec/PlistBuddy -c "Add :GitCommitSHA string $commit_sha" "$info_plist"
fi
