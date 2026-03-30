# Klipi

A macOS clipboard history manager.

## Installation

```bash
# Build the app
swift build -c release

# Create app bundle
mkdir -p /Applications/Klipi.app/Contents/MacOS
mkdir -p /Applications/Klipi.app/Contents/Resources
cp .build/release/Klipi /Applications/Klipi.app/Contents/MacOS/Klipi
cp -r Assets.xcassets /Applications/Klipi.app/Contents/Resources/

# Create Info.plist (with Input Monitoring permission)
cat > /Applications/Klipi.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Klipi</string>
    <key>CFBundleIdentifier</key>
    <string>com.klipi.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Klipi</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright 2024. All rights reserved.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Klipi needs access to monitor keyboard events for clipboard history.</string>
</dict>
</plist>
EOF

# Create PkgInfo
echo "1\nAPPL????" > /Applications/Klipi.app/Contents/PkgInfo

# Remove quarantine and code-sign
xattr -cr /Applications/Klipi.app
codesign --force --deep --sign - /Applications/Klipi.app
```

## Usage

- Press `Alt+Cmd+.` to open the clipboard history popup
- Use arrow keys to navigate, Enter to copy
- Or click on an item to copy it

#

#
