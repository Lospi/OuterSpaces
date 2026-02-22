#!/bin/bash
#
# generate_appcast.sh — Build, sign, and generate Sparkle appcast for Outer Spaces
#
# Usage:
#   ./generate_appcast.sh [--skip-build] [--dmg-path <path>]
#
# Prerequisites:
#   - Xcode with the Outer Spaces project
#   - Sparkle's generate_appcast and sign_update in DerivedData (via SPM)
#   - Sparkle EdDSA signing key (generate with: sign_update --generate)
#
# Environment variables (optional):
#   SPARKLE_KEY_FILE  — Path to Sparkle EdDSA private key file
#   DOWNLOAD_URL_BASE — Base URL for update downloads (default: GitHub releases)
#

set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────────────────

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
PROJECT_FILE="$REPO_ROOT/Outer Spaces.xcodeproj"
SCHEME="Outer Spaces"
CONFIGURATION="Release"
UPDATES_DIR="$REPO_ROOT/../Outer Spaces Updates"
APPCAST_FILE="$UPDATES_DIR/appcast.xml"
APP_NAME="Outer Spaces"
DMG_NAME="OuterSpaces.dmg"
GITHUB_REPO="Lospi/OuterSpaces"
DOWNLOAD_URL_BASE="${DOWNLOAD_URL_BASE:-https://github.com/$GITHUB_REPO/releases/download}"

# Sparkle tools from SPM DerivedData
DERIVED_DATA_BASE="$HOME/Library/Developer/Xcode/DerivedData"
SPARKLE_BIN=""

# ─── Helper functions ─────────────────────────────────────────────────────────

log() { echo "▸ $*"; }
error() { echo "✘ $*" >&2; exit 1; }

find_sparkle_tools() {
    # Search DerivedData for Sparkle tools from SPM
    local candidates
    candidates=$(find "$DERIVED_DATA_BASE" -path "*/artifacts/sparkle/Sparkle/bin/generate_appcast" 2>/dev/null | head -1)

    if [[ -n "$candidates" ]]; then
        SPARKLE_BIN="$(dirname "$candidates")"
        log "Found Sparkle tools at: $SPARKLE_BIN"
        return 0
    fi

    # Fallback: check if installed globally
    if command -v generate_appcast &>/dev/null; then
        SPARKLE_BIN="$(dirname "$(command -v generate_appcast)")"
        log "Using global Sparkle tools at: $SPARKLE_BIN"
        return 0
    fi

    error "Sparkle tools not found. Build the project in Xcode first to fetch SPM dependencies."
}

get_version_info() {
    MARKETING_VERSION=$(xcodebuild -project "$PROJECT_FILE" -scheme "$SCHEME" -showBuildSettings 2>/dev/null \
        | grep "MARKETING_VERSION" | head -1 | awk '{print $NF}')
    BUILD_NUMBER=$(xcodebuild -project "$PROJECT_FILE" -scheme "$SCHEME" -showBuildSettings 2>/dev/null \
        | grep "CURRENT_PROJECT_VERSION" | head -1 | awk '{print $NF}')

    if [[ -z "$MARKETING_VERSION" || -z "$BUILD_NUMBER" ]]; then
        error "Could not read version info from project. Is Xcode set up correctly?"
    fi

    log "Version: $MARKETING_VERSION (build $BUILD_NUMBER)"
}

# ─── Parse arguments ──────────────────────────────────────────────────────────

SKIP_BUILD=false
CUSTOM_DMG_PATH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --dmg-path)
            CUSTOM_DMG_PATH="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--skip-build] [--dmg-path <path>]"
            echo ""
            echo "Options:"
            echo "  --skip-build    Skip xcodebuild, use existing archive"
            echo "  --dmg-path      Path to pre-built DMG file"
            echo ""
            echo "Environment:"
            echo "  SPARKLE_KEY_FILE    Path to Sparkle EdDSA private key"
            echo "  DOWNLOAD_URL_BASE   Base URL for downloads (default: GitHub releases)"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# ─── Main ─────────────────────────────────────────────────────────────────────

log "=== Outer Spaces Release Script ==="

find_sparkle_tools
get_version_info

TAG="v$MARKETING_VERSION"
ARCHIVE_PATH="$REPO_ROOT/build/$APP_NAME.xcarchive"
APP_PATH="$ARCHIVE_PATH/Products/Applications/$APP_NAME.app"
DMG_OUTPUT="$UPDATES_DIR/$DMG_NAME"

# Step 1: Build (optional)
if [[ "$SKIP_BUILD" == false && -z "$CUSTOM_DMG_PATH" ]]; then
    log "Building $SCHEME ($CONFIGURATION)..."

    xcodebuild archive \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -archivePath "$ARCHIVE_PATH" \
        CODE_SIGN_IDENTITY="Apple Development" \
        CODE_SIGN_STYLE=Automatic \
        | tail -5

    if [[ ! -d "$APP_PATH" ]]; then
        error "Archive succeeded but app not found at: $APP_PATH"
    fi

    log "Archive complete: $APP_PATH"

    # Step 2: Create DMG
    log "Creating DMG..."

    STAGING_DIR=$(mktemp -d)
    cp -R "$APP_PATH" "$STAGING_DIR/"

    hdiutil create -volname "$APP_NAME" \
        -srcfolder "$STAGING_DIR" \
        -ov -format UDZO \
        "$DMG_OUTPUT"

    rm -rf "$STAGING_DIR"

    log "DMG created: $DMG_OUTPUT"

elif [[ -n "$CUSTOM_DMG_PATH" ]]; then
    log "Using provided DMG: $CUSTOM_DMG_PATH"
    cp "$CUSTOM_DMG_PATH" "$DMG_OUTPUT"
fi

# Step 3: Sign the DMG with Sparkle EdDSA
log "Signing DMG with Sparkle EdDSA..."

SIGN_ARGS=("$DMG_OUTPUT")
if [[ -n "${SPARKLE_KEY_FILE:-}" ]]; then
    SIGN_ARGS+=("-f" "$SPARKLE_KEY_FILE")
fi

SIGNATURE=$("$SPARKLE_BIN/sign_update" "${SIGN_ARGS[@]}" 2>&1)
log "Signature: $SIGNATURE"

# Step 4: Generate appcast with deltas
log "Generating appcast with deltas..."

mkdir -p "$UPDATES_DIR"

# generate_appcast processes the entire updates directory,
# generating deltas between consecutive versions and producing appcast.xml
"$SPARKLE_BIN/generate_appcast" \
    --download-url-prefix "$DOWNLOAD_URL_BASE/$TAG/" \
    "$UPDATES_DIR"

log "Appcast generated: $APPCAST_FILE"

# Step 5: Copy appcast to repo locations
REPO_APPCAST="$REPO_ROOT/appcast.xml"
if [[ -f "$APPCAST_FILE" ]]; then
    cp "$APPCAST_FILE" "$REPO_APPCAST"
    log "Appcast copied to repo: $REPO_APPCAST"
fi

# Step 6: Summary
echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Release $MARKETING_VERSION (build $BUILD_NUMBER) ready"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "  DMG:       $DMG_OUTPUT"
echo "  Appcast:   $APPCAST_FILE"
echo "  Tag:       $TAG"
echo ""
echo "  Deltas generated in: $UPDATES_DIR/"
ls -lh "$UPDATES_DIR"/*.delta 2>/dev/null || echo "  (no deltas — first release or single version)"
echo ""
echo "Next steps:"
echo "  1. Create GitHub release:  gh release create $TAG '$DMG_OUTPUT' --title '$TAG' --generate-notes"
echo "  2. Deploy appcast:         Copy $APPCAST_FILE to your GitHub Pages / hosting"
echo "  3. Verify:                 Open the app and check for updates"
echo ""
