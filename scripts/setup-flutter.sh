#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
APP_DIR="$REPO_ROOT/apps-native/story_generator_flutter"
APK_PATH="$APP_DIR/build/app/outputs/flutter-apk/app-release.apk"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
info()  { echo -e "${GREEN}▶${NC} $*"; }
warn()  { echo -e "${YELLOW}⚠${NC}  $*"; }
error() { echo -e "${RED}✗${NC}  $*" >&2; }
header(){ echo -e "\n${BOLD}$*${NC}"; }

header "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
header "  Story Generator — Flutter Setup"
header "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── 1. Flutter SDK ───────────────────────────────────────────────────────────
if ! command -v flutter &>/dev/null; then
    error "flutter not found in PATH."
    error "Install Flutter from: https://docs.flutter.dev/get-started/install"
    exit 1
fi

FLUTTER_VER=$(flutter --version 2>&1 | grep -m1 "Flutter " || echo "Flutter (version unknown)")
info "$FLUTTER_VER"

# ── 2. flutter pub get ───────────────────────────────────────────────────────
info "Fetching packages (flutter pub get) ..."
cd "$APP_DIR"
flutter pub get
info "Packages fetched ✓"

# ── 3. Detect connected device ───────────────────────────────────────────────
echo ""
DEVICES=$(flutter devices 2>/dev/null | grep -E "•|android" | grep -v "No devices" || true)
DEVICE_COUNT=$(echo "$DEVICES" | grep -c "•" 2>/dev/null || echo 0)

build_apk() {
    info "Building release APK ..."
    flutter build apk --release
    echo ""
    echo -e "${GREEN}  APK ready:${NC}"
    echo "    $APK_PATH"
    echo ""
    echo "  Transfer to your device (USB, Google Drive, email) and tap to install."
    echo "  Enable 'Install unknown apps' in Android Settings if prompted."
}

install_apk() {
    if ! command -v adb &>/dev/null; then
        warn "adb not found — cannot install automatically."
        warn "Transfer the APK manually instead."
        return
    fi
    info "Installing APK via adb ..."
    adb install -r "$APK_PATH"
    info "Installed! Launch 'Story Generator' on your device."
}

if [[ "$DEVICE_COUNT" -gt 0 ]]; then
    info "Connected device(s) detected:"
    echo "$DEVICES"
    echo ""
    echo "  What would you like to do?"
    echo "    r  — run in dev mode (hot-reload)"
    echo "    b  — build release APK"
    echo "    i  — build release APK + install via adb"
    echo "    s  — skip (just fetch packages)"
    echo ""
    read -rp "  Choice [r/b/i/s]: " CHOICE
    case "${CHOICE:-s}" in
        r|R) info "Starting dev run ..."; flutter run ;;
        b|B) build_apk ;;
        i|I) build_apk; install_apk ;;
        *)   info "Skipping — run 'flutter run' or 'flutter build apk --release' manually." ;;
    esac
else
    warn "No Android device detected."
    echo ""
    echo "  Options:"
    echo "    1. Connect a device with USB debugging enabled and re-run this script."
    echo "    2. Start an Android emulator in Android Studio, then re-run."
    echo "    3. Build the APK now and sideload it later."
    echo ""
    read -rp "  Build the APK now? [y/N]: " BUILD_NOW
    if [[ "${BUILD_NOW:-n}" =~ ^[Yy]$ ]]; then
        build_apk
    else
        info "Setup done. Run './scripts/setup-flutter.sh' again when a device is connected."
    fi
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Flutter setup complete!${NC}"
echo ""
echo "  Useful commands (run from apps-native/story_generator_flutter/):"
echo -e "    ${BOLD}flutter run${NC}                   — dev mode with hot-reload"
echo -e "    ${BOLD}flutter build apk --release${NC}   — build sideloadable APK"
echo -e "    ${BOLD}flutter test${NC}                  — run widget tests"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
