#!/bin/bash
# FinderNew build script (no Xcode required — Command Line Tools only).
# Compiles SharedCore + host app + Finder Sync extension with swiftc,
# assembles bundles, ad-hoc signs. Runs SharedCore tests when RUN_TESTS=1.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CORE="$ROOT/Packages/SharedCore"
BUILD="$ROOT/build"
APP="$BUILD/FinderNew.app"
MACOS_TARGET="arm64-apple-macos13.0"
SWIFT_FLAGS=(-O -swift-version 5 -target "$MACOS_TARGET")
CORE_SRC=("$CORE/Sources/SharedCore/Template.swift" "$CORE/Sources/SharedCore/FileCreation.swift")

if [[ "${RUN_TESTS:-0}" == "1" ]]; then
  echo "==> Running SharedCore tests"
  (cd "$CORE" && swift run sharedcore-tests)
fi

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" \
         "$APP/Contents/Resources/OfficeTemplates" \
         "$APP/Contents/PlugIns/FinderNewExtension.appex/Contents/MacOS"

echo "==> Generating template manifest"
(cd "$CORE" && swift run -q gen-manifest "$APP/Contents/Resources/templates.json")

echo "==> Copying bundled Office templates"
cp "$ROOT/Resources/OfficeTemplates/blank.docx" "$ROOT/Resources/OfficeTemplates/blank.xlsx" "$ROOT/Resources/OfficeTemplates/blank.pptx" \
   "$APP/Contents/Resources/OfficeTemplates/"

echo "==> Building Finder Sync extension"
swiftc "${SWIFT_FLAGS[@]}" -parse-as-library \
  -module-name FinderNewExtension \
  "${CORE_SRC[@]}" \
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
  "${CORE_SRC[@]}" \
  "$ROOT/Sources/HostApp/FinderNewApp.swift" \
  "$ROOT/Sources/HostApp/ContentView.swift" \
  "$ROOT/Sources/HostApp/HostModel.swift" \
  "$ROOT/Sources/HostApp/TemplateRepository.swift" \
  -framework SwiftUI -framework AppKit \
  -o "$APP/Contents/MacOS/FinderNew"

cp "$ROOT/Resources/HostApp-Info.plist" "$APP/Contents/Info.plist"

echo "==> Signing host app (ad-hoc)"
codesign --force --sign - "$APP"

echo "==> Verifying"
codesign --verify --strict "$APP"
codesign --verify --strict "$APP/Contents/PlugIns/FinderNewExtension.appex"

echo "Done: $APP"
