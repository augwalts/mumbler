#!/bin/bash
set -euo pipefail

APP_NAME="Mumbler"
BUNDLE_ID="com.augustine.mumbler"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"

echo "Building ${APP_NAME}..."
swift build -c release 2>&1

echo ""
echo "Creating app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy binary
cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Copy icon
cp "Sources/Mumbler/Resources/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"

# Create PkgInfo
echo -n "APPL????" > "${APP_BUNDLE}/Contents/PkgInfo"

# Create Info.plist
cat > "${APP_BUNDLE}/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Mumbler</string>
    <key>CFBundleDisplayName</key>
    <string>Mumbler</string>
    <key>CFBundleIdentifier</key>
    <string>com.augustine.mumbler</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleExecutable</key>
    <string>Mumbler</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>Mumbler needs microphone access to record your voice for transcription.</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>Mumbler needs speech recognition access to transcribe your voice recordings.</string>
</dict>
</plist>
PLIST

# Codesign with persistent identity (Accessibility permission survives rebuilds)
SIGN_IDENTITY="Mumbler Dev"
echo "Signing app bundle with '${SIGN_IDENTITY}'..."
codesign --force --sign "${SIGN_IDENTITY}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
codesign --force --sign "${SIGN_IDENTITY}" "${APP_BUNDLE}"

# Install to ~/Applications (ad-hoc signed apps can't use /Applications on macOS 26+)
INSTALL_DIR="${HOME}/Applications"
mkdir -p "${INSTALL_DIR}"

# Kill running instance before replacing
pkill -x "${APP_NAME}" 2>/dev/null || true

# Remove stale installs
rm -rf "${INSTALL_DIR}/${APP_BUNDLE}"
rm -rf "/Applications/${APP_BUNDLE}" 2>/dev/null || true

cp -r "${APP_BUNDLE}" "${INSTALL_DIR}/"

echo ""
echo "Build complete: ${INSTALL_DIR}/${APP_BUNDLE}"
echo ""
echo "To launch:"
echo "  open ~/Applications/${APP_BUNDLE}"
echo "  # Or with logs: ~/Applications/${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
echo ""
echo "On first launch, grant these permissions:"
echo "  1. Microphone (auto-prompted)"
echo "  2. Speech Recognition (auto-prompted)"
echo "  3. Accessibility (System Settings > Privacy & Security > Accessibility)"
