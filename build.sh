#!/bin/bash
set -e

COUNT=$(git rev-list --count HEAD)
cat > BlueNapkin/Version.swift << EOF
let appVersion = "$COUNT"
EOF

echo "Building BlueNapkin v$COUNT..."
swift build -c release 2>&1

pkill -x BlueNapkin 2>/dev/null || true
sleep 0.3
cp .build/release/BlueNapkin /Applications/BlueNapkin.app/Contents/MacOS/BlueNapkin
open /Applications/BlueNapkin.app
echo "Launched BlueNapkin v$COUNT"
