#!/bin/bash
set -e

APP_NAME="Transparency"
APP_DIR="${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "==> Building ${APP_NAME}..."

# Create App Bundle Structure
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Compile Swift sources
swiftc -O -parse-as-library main.swift -o "${MACOS_DIR}/${APP_NAME}"

# Copy Icon
if [ -f "AppIcon.icns" ]; then
    cp "AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

# Create Info.plist
cat <<EOF > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.ayush.Transparency</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>Transparency requires microphone access to pass through ambient audio with ultra-low latency.</string>
    <key>NSAlwaysAllowMicrophoneModeControl</key>
    <true/>
</dict>
</plist>
EOF

# Sign with entitlements
if [ -f "entitlements.plist" ]; then
    codesign --force --deep --sign - --entitlements entitlements.plist "${APP_DIR}"
else
    codesign --force --deep --sign - "${APP_DIR}"
fi

echo "==> Successfully built ${APP_DIR}"
