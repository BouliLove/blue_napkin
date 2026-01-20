#!/bin/bash
# Script to create icon files from icon.svg
# Requires ImageMagick (install with: brew install imagemagick)

if ! command -v convert &> /dev/null; then
    echo "ImageMagick not found. Please install it:"
    echo "  macOS: brew install imagemagick"
    echo "  Ubuntu: sudo apt-get install imagemagick"
    echo "  Or use an online SVG to PNG converter"
    exit 1
fi

echo "Creating icon files..."
convert icon.svg -resize 16x16 icon16.png
convert icon.svg -resize 48x48 icon48.png
convert icon.svg -resize 128x128 icon128.png
echo "Done! Created icon16.png, icon48.png, and icon128.png"
