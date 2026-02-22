#!/usr/bin/env bash
#
# Build Thonny as a standalone macOS .app bundle.
#
# Prerequisites:
#   1. Python 3.12 from python.org installed to /Library/Frameworks/Python.framework
#   2. Xcode command line tools (for Swift compiler)
#
# Optional: Minny at ../minny if you want MicroPython/CircuitPython support from source.
#   Otherwise minny will be installed from PyPI.
#
# Output: packaging/mac/build/Thonny.app (double-click to launch)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAC_PACKAGING="$SCRIPT_DIR/packaging/mac"
cd "$SCRIPT_DIR"

# Check for Python 3.12 framework
if [ ! -d "/Library/Frameworks/Python.framework/Versions/3.12" ]; then
    echo "Error: Python 3.12 not found at /Library/Frameworks/Python.framework"
    echo "Please install from https://www.python.org/downloads/"
    echo "Use the 'macOS 64-bit universal2 installer' for best compatibility."
    exit 1
fi

echo "=== Step 1: Create base bundle (if not exists) ==="
if [ ! -d "$HOME/thonny_template_build_312/Thonny.app" ]; then
    echo "Creating base bundle at ~/thonny_template_build_312 ..."
    cd "$MAC_PACKAGING"
    ./prepare_base_bundle.sh
    cd "$SCRIPT_DIR"
else
    echo "Base bundle already exists at ~/thonny_template_build_312"
fi

echo ""
echo "=== Step 2: Compile Swift launcher ==="
cd "$MAC_PACKAGING/launcher"
mkdir -p ../Thonny.app.initial_template/Contents/MacOS
# Compile for current architecture only (simpler than universal)
if [[ $(uname -m) == "arm64" ]]; then
    swiftc -target arm64-apple-macosx11.0 -o ../Thonny.app.initial_template/Contents/MacOS/thonny launcher.swift
else
    swiftc -target x86_64-apple-macosx10.9 -o ../Thonny.app.initial_template/Contents/MacOS/thonny launcher.swift
fi
cd "$SCRIPT_DIR"

echo ""
echo "=== Step 3: Build Thonny app bundle ==="
cd "$MAC_PACKAGING"
./prepare_dist_bundle_local.sh

echo ""
echo "=== Step 4: Code sign (ad-hoc, for local use) ==="
./sign_bundle_local.sh
cd "$SCRIPT_DIR"

echo ""
echo "=== Done! ==="
echo "Thonny.app is at: $MAC_PACKAGING/build/Thonny.app"
echo "You can launch it by double-clicking or: open $MAC_PACKAGING/build/Thonny.app"
