#!/bin/bash
# Build dist/Focus.app and dist/Focus.dmg (universal, ad-hoc signed).
# Usage: scripts/build-app.sh [version]   (default: latest git tag, else 0.1.0)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$REPO_DIR/dist"
APP="$DIST/Focus.app"
version="${1:-$(git -C "$REPO_DIR" describe --tags --abbrev=0 2>/dev/null || echo 0.1.0)}"
version="${version#v}"

swift build --package-path "$REPO_DIR/app" -c release --arch arm64 --arch x86_64
binary="$(swift build --package-path "$REPO_DIR/app" -c release --arch arm64 --arch x86_64 --show-bin-path)/Focus"

rm -rf "$DIST"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/scripts"
cp "$binary" "$APP/Contents/MacOS/Focus"
cp "$REPO_DIR"/src/*.sh "$APP/Contents/Resources/scripts/"
cp "$REPO_DIR/sites.example.txt" "$APP/Contents/Resources/"

# Icon: render once at 1024 px, scale down for the iconset
work="$(mktemp -d)"
swift "$REPO_DIR/scripts/make-icon.swift" "$work/icon.png"
mkdir "$work/AppIcon.iconset"
for px in 16 32 128 256 512; do
    sips -z $px $px "$work/icon.png" --out "$work/AppIcon.iconset/icon_${px}x${px}.png" >/dev/null
    sips -z $((px * 2)) $((px * 2)) "$work/icon.png" --out "$work/AppIcon.iconset/icon_${px}x${px}@2x.png" >/dev/null
done
iconutil -c icns "$work/AppIcon.iconset" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$work"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.klemen.focus.app</string>
    <key>CFBundleName</key>
    <string>Focus</string>
    <key>CFBundleDisplayName</key>
    <string>Focus</string>
    <key>CFBundleExecutable</key>
    <string>Focus</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$version</string>
    <key>CFBundleVersion</key>
    <string>$version</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>Focus asks for your administrator password to change /etc/hosts.</string>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP"

staging="$(mktemp -d)"
cp -R "$APP" "$staging/"
ln -s /Applications "$staging/Applications"
hdiutil create -volname Focus -srcfolder "$staging" -ov -format UDZO "$DIST/Focus.dmg" >/dev/null
rm -rf "$staging"

echo "Built $APP and $DIST/Focus.dmg (version $version)"
