#!/bin/bash
set -e

# Simplified build for local development - creates a standalone Thonny.app
# Uses native architecture (no universal2), installs thonny from local source.
# For official release builds, use prepare_dist_bundle.sh instead.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
THONNY_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"
VERSION=$(cat "$THONNY_ROOT/thonny/VERSION")
PREFIX=$HOME/thonny_template_build_312
REQ_FILE="$SCRIPT_DIR/../requirements-regular-bundle.txt"

echo "Building Thonny $VERSION from $THONNY_ROOT"

# prepare working folder
rm -rf build
mkdir -p build

# copy template
cp -R -H $PREFIX/Thonny.app build

# update template
cp $SCRIPT_DIR/Thonny.app.initial_template/Contents/MacOS/* \
    build/Thonny.app/Contents/MacOS
cp $SCRIPT_DIR/Thonny.app.initial_template/Contents/Resources/* \
    build/Thonny.app/Contents/Resources
cp $SCRIPT_DIR/Thonny.app.initial_template/Contents/Info.plist \
    build/Thonny.app/Contents

FRAMEWORKS=build/Thonny.app/Contents/Frameworks
PYTHON_CURRENT=$FRAMEWORKS/Python.framework/Versions/3.12

# install - use system Python to install into bundle (bundled Python may hang in headless env)
SITEPACKAGES=$PYTHON_CURRENT/lib/python3.12/site-packages
SYSTEM_PYTHON=/Library/Frameworks/Python.framework/Versions/3.12/bin/python3.12
if [ ! -x "$SYSTEM_PYTHON" ]; then
    echo "Error: System Python 3.12 not found at $SYSTEM_PYTHON"
    exit 1
fi

export MACOSX_DEPLOYMENT_TARGET=10.9
echo "Using system Python to install into bundle site-packages"
$SYSTEM_PYTHON -m pip install --no-cache-dir --target "$SITEPACKAGES" wheel

echo "Installing dependencies from $REQ_FILE"
$SYSTEM_PYTHON -m pip install --no-cache-dir --target "$SITEPACKAGES" \
    --no-binary mypy -r "$REQ_FILE" 2>/dev/null || \
$SYSTEM_PYTHON -m pip install --no-cache-dir --target "$SITEPACKAGES" \
    -r "$REQ_FILE"

$SYSTEM_PYTHON -m pip install --no-cache-dir --target "$SITEPACKAGES" certifi

# Minny is required by Thonny
if [ -d "$THONNY_ROOT/../minny" ]; then
    echo "Installing minny from local source (../minny)..."
    $SYSTEM_PYTHON -m pip install --no-cache-dir --target "$SITEPACKAGES" --no-deps "$THONNY_ROOT/../minny"
else
    echo "Installing minny from PyPI..."
    $SYSTEM_PYTHON -m pip install --no-cache-dir --target "$SITEPACKAGES" minny
fi

echo "Installing Thonny from local source..."
$SYSTEM_PYTHON -m pip install --no-cache-dir --target "$SITEPACKAGES" --no-deps "$THONNY_ROOT"

rm -f $PYTHON_CURRENT/bin/thonny  # Thonny is not supposed to run from there

# save some space
rm -rf $FRAMEWORKS/Tcl.framework/Versions/8.6/Tcl_debug
rm -rf $FRAMEWORKS/Tk.framework/Versions/8.6/Tk_debug
rm -rf $FRAMEWORKS/Tk.framework/Versions/8.6/Resources/Scripts/demos
rm -rf $FRAMEWORKS/Tcl.framework/Versions/8.6/Resources/Documentation
rm -rf $FRAMEWORKS/Tk.framework/Versions/8.6/Resources/Documentation
rm -rf $PYTHON_CURRENT/Resources/English.lproj/Documentation
rm -rf $PYTHON_CURRENT/share
rm -rf $PYTHON_CURRENT/lib/python3.12/test
rm -rf $PYTHON_CURRENT/lib/python3.12/distutils/test
rm -rf $PYTHON_CURRENT/lib/python3.12/lib2to3/test
rm -rf $PYTHON_CURRENT/lib/python3.12/unittest/test
rm -rf $PYTHON_CURRENT/lib/python3.12/idlelib
rm -f $PYTHON_CURRENT/bin/idle3 $PYTHON_CURRENT/bin/idle3.12
rm -rf $PYTHON_CURRENT/lib/python3.12/site-packages/pylint/test
rm -rf $PYTHON_CURRENT/lib/python3.12/site-packages/mypy/test

find $PYTHON_CURRENT/lib -name '*.pyc' -delete
find $PYTHON_CURRENT/lib -name '*.exe' -delete

# notarizer doesn't like txt files in some packages
find $PYTHON_CURRENT/lib/python3.12/site-packages/lxml -name '*.txt' -delete 2>/dev/null || true
find $PYTHON_CURRENT/lib/python3.12/site-packages/matplotlib -name '*.txt' -delete 2>/dev/null || true

# create link to Python.app interpreter
cd build/Thonny.app/Contents/MacOS
ln -sf ../Frameworks/Python.framework/Versions/3.12/Resources/Python.app/Contents/MacOS/Python Python
cd $SCRIPT_DIR

# copy the token signifying Thonny-private Python
cp thonny_python.ini $PYTHON_CURRENT/bin

./make_scripts_relocatable.py "$PYTHON_CURRENT/bin"

# set version info
sed -i '' "s/VERSION/$VERSION/g" build/Thonny.app/Contents/Info.plist

echo "Build complete: build/Thonny.app"
