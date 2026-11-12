#!/bin/bash
# FinderNew build script (no Xcode required — Command Line Tools only).
# Compiles host app + Finder Sync extension with swiftc, assembles bundles, ad-hoc signs.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/build"
APP="$BUILD/FinderNew.app"
MACOS_TARGET="arm64-apple-macos13.0"
SWIFT_FLAGS=(-O -swift-version 5 -target "$MACOS_TARGET")

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" \
         "$APP/Contents/Resources" \
         "$APP/Contents/PlugIns/FinderNewExtension.appex/Contents/MacOS"

echo "==> Building Finder Sync extension"
swiftc "${SWIFT_FLAGS[@]}" -parse-as-library \
  -module-name FinderNewExtension \
  "$ROOT/Sources/Shared/FileCreation.swift" \
  "$ROOT/Sources/FinderSyncExtension/FinderSyncController.swift" \
  -framework FinderSync -framework AppKit \
  -Xlinker -e -Xlinker _NSExtensionMain \
  -o "$APP/Contents/PlugIns/FinderNewExtension.appex/Contents/MacOS/FinderNewExtension"

cp "$ROOT/Resources/Extension-Info.plist" "$APP/Contents/PlugIns/FinderNewExtension.appex/Contents/Info.plist"

echo "==> Signing extension (ad-hoc + sandbox entitlements)"
codesign --force --sign - \
  --entitlements "$ROOT/Resources/Extension.entitlements" \
  "$APP/Contents/PlugIns/FinderNewExtension.appex"

echo "==> Building host app"
swiftc "${SWIFT_FLAGS[@]}" -parse-as-library \
  -module-name FinderNew \
  "$ROOT/Sources/Shared/FileCreation.swift" \
  "$ROOT/Sources/HostApp/FinderNewApp.swift" \
  "$ROOT/Sources/HostApp/ContentView.swift" \
  "$ROOT/Sources/HostApp/HostModel.swift" \
  -framework SwiftUI -framework AppKit \
  -o "$APP/Contents/MacOS/FinderNew"

cp "$ROOT/Resources/HostApp-Info.plist" "$APP/Contents/Info.plist"

echo "==> Signing host app (ad-hoc)"
codesign --force --sign - "$APP"

echo "==> Verifying"
codesign --verify --strict --verbose=1 "$APP"
codesign --verify --strict --verbose=1 "$APP/Contents/PlugIns/FinderNewExtension.appex"

echo "Done: $APP"
