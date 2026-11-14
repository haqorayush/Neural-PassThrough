#!/bin/bash
set -e

APP_NAME="Transparency"
DMG_NAME="${APP_NAME}.dmg"
STAGING_DIR="dmg_staging"

echo "==> Ensuring app is built..."
./build.sh

echo "==> Packaging ${DMG_NAME}..."
rm -rf "${STAGING_DIR}" "${DMG_NAME}"
mkdir -p "${STAGING_DIR}"

# Copy application bundle
cp -R "${APP_NAME}.app" "${STAGING_DIR}/"

# Create Applications symlink for drag-and-drop installation
ln -s /Applications "${STAGING_DIR}/Applications"

# Create compressed DMG disk image
hdiutil create -volname "${APP_NAME}" -srcfolder "${STAGING_DIR}" -ov -format UDZO "${DMG_NAME}"

# Clean up staging directory
rm -rf "${STAGING_DIR}"

echo "==> Successfully created ${DMG_NAME}"
