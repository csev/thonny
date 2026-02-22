#!/bin/bash
# Ad-hoc code signing for local development builds.
# Uses -s - (ad-hoc) so no developer certificate is needed.
# The app will run on your Mac but is not suitable for distribution.
# For distribution builds, use sign_bundle_in_build.sh with a Developer ID.

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

if [ ! -d "build/Thonny.app" ]; then
    echo "Error: build/Thonny.app not found. Run prepare_dist_bundle_local.sh first."
    exit 1
fi

echo "Ad-hoc signing Thonny.app (no certificate required)..."

# Remove invalid signatures from copied/modified binaries
rm -rf build/Thonny.app/Contents/Frameworks/Python.framework/Versions/3.12/_CodeSignature 2>/dev/null || true
rm -rf build/Thonny.app/Contents/Frameworks/Python.framework/Versions/3.12/Resources/Python.app/Contents/_CodeSignature 2>/dev/null || true
find build -name ".DS_Store" -delete

# Ad-hoc sign: -s - means use ad-hoc identity (no cert needed)
# Sign deepest components first (libraries, then executables, then bundle)

# Sign all .so and .dylib files
find build/Thonny.app -type f \( -name "*.so" -o -name "*.dylib" \) -exec codesign -s - -f {} \;

# Use minimal entitlements (no apple-events, camera, or microphone) to avoid permission prompts
ENTITLEMENTS="thonny.entitlements.local"
[ ! -f "$ENTITLEMENTS" ] && ENTITLEMENTS="thonny.entitlements"

# Sign Python binaries (entitlements needed for JIT/debugging)
codesign -s - -f --entitlements "$ENTITLEMENTS" \
    build/Thonny.app/Contents/Frameworks/Python.framework/Versions/3.12/bin/python3.12

codesign -s - -f --entitlements "$ENTITLEMENTS" \
    build/Thonny.app/Contents/Frameworks/Python.framework/Versions/3.12/Resources/Python.app/Contents/MacOS/Python

# Sign the Python framework (includes main Python library)
codesign -s - -f --entitlements "$ENTITLEMENTS" \
    build/Thonny.app/Contents/Frameworks/Python.framework

# Sign the Swift launcher and app bundle
codesign -s - -f --entitlements "$ENTITLEMENTS" \
    build/Thonny.app/Contents/MacOS/thonny

codesign -s - -f --entitlements "$ENTITLEMENTS" \
    build/Thonny.app

echo "Signing complete."
