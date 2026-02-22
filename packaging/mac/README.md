# Building Thonny as a Standalone macOS Application

This guide explains how to build Thonny as a double-clickable `.app` bundle for macOS.

## Quick Start (Recommended)

From the Thonny project root, run:

```bash
./build_mac_app.sh
```

The resulting app will be at `packaging/mac/build/Thonny.app`.

## Prerequisites

### 1. Python 3.12 from python.org

The packaging currently requires **Python 3.12** specifically. Install it from [python.org/downloads](https://www.python.org/downloads/) (you can have multiple versions side-by-side). Use the **"macOS 64-bit universal2 installer"** for best compatibility.

The installer must place Python at `/Library/Frameworks/Python.framework`. Verify with:

```bash
ls /Library/Frameworks/Python.framework/Versions/3.12
```

If you only have Python 3.13 or 3.14, you will need to install 3.12 as well.

### 2. Xcode Command Line Tools

Required for compiling the Swift launcher. Install with:

```bash
xcode-select --install
```

### 3. Optional: Local Minny

If you develop Minny alongside Thonny, place it at `../minny` (sibling to the thonny directory). The build will use it. Otherwise, Minny is installed from PyPI automatically.

## Build Steps (What the Script Does)

1. **Create base bundle** – Copies Python.framework into an app structure at `~/thonny_template_build_312`. Only runs once per Python version.

2. **Compile launcher** – Builds the Swift launcher binary for your Mac’s architecture (Intel or Apple Silicon).

3. **Build Thonny app** – Installs dependencies and Thonny into the bundle, producing `build/Thonny.app`.

## Manual Build (Advanced)

If you need more control, you can run the steps separately:

```bash
cd packaging/mac

# One-time: create base Python bundle
./prepare_base_bundle.sh

# Compile launcher (run after launcher changes)
cd launcher && ./compile.sh && cd ..

# Build Thonny into the bundle
./prepare_dist_bundle_local.sh   # local development
# OR
./prepare_dist_bundle.sh VERSION ../requirements-regular-bundle.txt   # release
```

## Official Release Builds

For signed, notarized release builds, the project uses:

- `prepare_dist_bundle.sh` – Builds from PyPI with universal2 binaries
- `sign_bundle_in_build.sh` – Code signing
- `notarize_all.sh` – Apple notarization
- `create_installer_from_build.sh` – Creates `.pkg` installer

See `readme_build.txt` for the full release workflow.

## Troubleshooting

**"Python 3.12 not found"** – Install Python 3.12 from python.org and ensure it goes to `/Library/Frameworks/Python.framework`.

**"execv failed" when launching** – The Python framework or symlinks inside the bundle may be broken. Try removing `~/thonny_template_build_312` and running the build again so the base bundle is recreated.

**Architecture mismatch** – The quick-start script builds for your current Mac (Intel or Apple Silicon). For a universal2 build, use `prepare_dist_bundle.sh` with the full toolchain.
