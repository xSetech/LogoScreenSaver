#!/bin/bash
# Generate macOS app icons from icon.svg
# Requires: rsvg-convert (brew install librsvg)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SVG_SOURCE="$PROJECT_DIR/Core/Resources/Logos/icon.svg"
TEMP_DIR=$(mktemp -d)
ICONSET_DIR="$TEMP_DIR/AppIcon.iconset"

echo "Generating icons from: $SVG_SOURCE"

# Check for rsvg-convert
if ! command -v rsvg-convert &> /dev/null; then
    echo "Error: rsvg-convert not found. Install with: brew install librsvg"
    exit 1
fi

# Check source exists
if [ ! -f "$SVG_SOURCE" ]; then
    echo "Error: $SVG_SOURCE not found"
    exit 1
fi

# Create temp iconset directory
mkdir -p "$ICONSET_DIR"

# Convert SVG to 1024x1024 PNG
echo "Converting SVG to PNG..."
rsvg-convert -w 1024 -h 1024 "$SVG_SOURCE" -o "$TEMP_DIR/AppIcon.png"

# Generate all required sizes for macOS iconset
echo "Generating icon sizes..."
sips -z 16 16     "$TEMP_DIR/AppIcon.png" --out "$ICONSET_DIR/icon_16x16.png"      > /dev/null
sips -z 32 32     "$TEMP_DIR/AppIcon.png" --out "$ICONSET_DIR/icon_16x16@2x.png"   > /dev/null
sips -z 32 32     "$TEMP_DIR/AppIcon.png" --out "$ICONSET_DIR/icon_32x32.png"      > /dev/null
sips -z 64 64     "$TEMP_DIR/AppIcon.png" --out "$ICONSET_DIR/icon_32x32@2x.png"   > /dev/null
sips -z 128 128   "$TEMP_DIR/AppIcon.png" --out "$ICONSET_DIR/icon_128x128.png"    > /dev/null
sips -z 256 256   "$TEMP_DIR/AppIcon.png" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null
sips -z 256 256   "$TEMP_DIR/AppIcon.png" --out "$ICONSET_DIR/icon_256x256.png"    > /dev/null
sips -z 512 512   "$TEMP_DIR/AppIcon.png" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null
sips -z 512 512   "$TEMP_DIR/AppIcon.png" --out "$ICONSET_DIR/icon_512x512.png"    > /dev/null
sips -z 1024 1024 "$TEMP_DIR/AppIcon.png" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null

# Convert iconset to icns
echo "Creating .icns file..."
iconutil -c icns "$ICONSET_DIR" -o "$TEMP_DIR/AppIcon.icns"

# Generate screen saver thumbnail for System Settings
# Standard thumbnail size is 90x58 (1x) and 180x116 (2x)
echo "Generating screen saver thumbnail..."
sips -z 116 180 "$TEMP_DIR/AppIcon.png" --out "$TEMP_DIR/thumbnail@2x.png" > /dev/null
sips -z 58 90   "$TEMP_DIR/AppIcon.png" --out "$TEMP_DIR/thumbnail.png"    > /dev/null

# Copy to target locations
echo "Copying to App/ and ScreenSaver/..."
cp "$TEMP_DIR/AppIcon.icns" "$PROJECT_DIR/App/AppIcon.icns"
cp "$TEMP_DIR/AppIcon.icns" "$PROJECT_DIR/ScreenSaver/AppIcon.icns"
cp "$TEMP_DIR/AppIcon.icns" "$PROJECT_DIR/AppIcon.icns"
cp "$TEMP_DIR/thumbnail.png" "$PROJECT_DIR/ScreenSaver/thumbnail.png"
cp "$TEMP_DIR/thumbnail@2x.png" "$PROJECT_DIR/ScreenSaver/thumbnail@2x.png"

echo ""
echo "Done! Icons updated:"
echo "  - $PROJECT_DIR/App/AppIcon.icns"
echo "  - $PROJECT_DIR/ScreenSaver/AppIcon.icns"
echo "  - $PROJECT_DIR/ScreenSaver/thumbnail.png"
echo "  - $PROJECT_DIR/ScreenSaver/thumbnail@2x.png"
echo ""
echo "Temporary files available at: $TEMP_DIR"
echo "  - $TEMP_DIR/AppIcon.png (1024x1024 source)"
echo "  - $TEMP_DIR/AppIcon.iconset/ (all sizes)"
echo ""
echo "Run 'rm -rf $TEMP_DIR' to clean up when done."
