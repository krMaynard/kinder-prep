#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
APP_DIR="$REPO_ROOT/apps-native/story_generator_flutter"
APK_PATH="$APP_DIR/build/app/outputs/flutter-apk/app-release.apk"
IPA_DIR="$APP_DIR/build/ios/iphoneos"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
info()  { echo -e "${GREEN}▶${NC} $*"; }
warn()  { echo -e "${YELLOW}⚠${NC}  $*"; }
error() { echo -e "${RED}✗${NC}  $*" >&2; }
header(){ echo -e "\n${BOLD}$*${NC}"; }
step()  { echo -e "\n${BOLD}── $* ──${NC}"; }

header "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
header "  Story Generator — Flutter Setup"
header "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── 1. Flutter SDK ───────────────────────────────────────────────────────────
step "Checking Flutter"
if ! command -v flutter &>/dev/null; then
    error "flutter not found in PATH."
    error "Install Flutter from: https://docs.flutter.dev/get-started/install"
    exit 1
fi

FLUTTER_VER=$(flutter --version 2>&1 | grep -m1 "Flutter " || echo "Flutter (version unknown)")
info "$FLUTTER_VER"

# ── 2. Detect platform capabilities ─────────────────────────────────────────
step "Detecting available platforms"
ON_MAC=false
HAS_XCODE=false
HAS_ANDROID=false

if [[ "$(uname)" == "Darwin" ]]; then
    ON_MAC=true
    if xcode-select --print-path &>/dev/null && xcodebuild -version &>/dev/null 2>&1; then
        HAS_XCODE=true
        XCODE_VER=$(xcodebuild -version 2>/dev/null | head -1)
        info "macOS + $XCODE_VER detected — iPad/iOS builds available ✓"
    else
        warn "Xcode not found. iOS/iPad builds unavailable."
        warn "Install Xcode from the Mac App Store, then run: sudo xcode-select --install"
    fi
fi

if flutter doctor 2>/dev/null | grep -q "Android toolchain"; then
    # Android toolchain present — check if it's healthy
    if flutter doctor 2>/dev/null | grep -E "Android toolchain.*✓|Android toolchain - develop" | grep -q "✓"; then
        HAS_ANDROID=true
        info "Android toolchain detected ✓"
    else
        warn "Android toolchain has issues — run 'flutter doctor -v' for details."
        warn "Common fix: open Android Studio → SDK Manager → install SDK Platform 35 + NDK."
    fi
else
    warn "Android toolchain not detected. Install Android Studio to enable Android builds."
    warn "  https://developer.android.com/studio"
fi

# ── 3. Add iOS platform if on Mac with Xcode and not yet scaffolded ─────────
if $HAS_XCODE && [[ ! -d "$APP_DIR/ios" ]]; then
    step "Adding iOS platform support"
    info "Running flutter create --platforms ios (one-time setup)..."
    cd "$APP_DIR"
    flutter create --platforms ios .
    info "iOS platform added ✓"
fi

# ── 4. flutter pub get ───────────────────────────────────────────────────────
step "Fetching packages"
cd "$APP_DIR"
flutter pub get
info "Packages fetched ✓"

# ── 5. Choose target ─────────────────────────────────────────────────────────
step "Choose what to do next"

if ! $HAS_XCODE && ! $HAS_ANDROID; then
    warn "No build platform available. Install Xcode (Mac) or Android Studio to continue."
    exit 0
fi

echo ""
echo "  Targets available:"
[[ $HAS_XCODE == true ]]   && echo "    i  — run on iPad / iPhone (USB, hot-reload)"
[[ $HAS_XCODE == true ]]   && echo "    s  — run in iOS Simulator"
[[ $HAS_ANDROID == true ]] && echo "    a  — run on Android device (USB, hot-reload)"
[[ $HAS_ANDROID == true ]] && echo "    apk — build release APK for sideloading"
echo "    q  — quit (packages are ready, run manually later)"
echo ""
read -rp "  Choice: " CHOICE

run_ios() {
    info "Connecting to iPad/iPhone — unlock your device and tap Trust if prompted..."
    flutter run
}

run_sim() {
    info "Starting iOS Simulator..."
    open -a Simulator 2>/dev/null || true
    sleep 3
    flutter run
}

run_android() {
    info "Connecting to Android device..."
    flutter run
}

build_apk() {
    info "Building release APK..."
    flutter build apk --release
    echo ""
    echo -e "${GREEN}  APK ready:${NC}"
    echo "    $APK_PATH"
    echo ""
    echo "  Transfer to your device (USB, Google Drive, email) and tap to install."
    echo "  Enable 'Install unknown apps' in Android Settings if prompted."
}

case "${CHOICE:-q}" in
    i|I)   run_ios ;;
    s|S)   run_sim ;;
    a|A)   run_android ;;
    apk|APK) build_apk ;;
    *)     info "Done. Packages are ready — see commands below." ;;
esac

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Setup complete!${NC}"
echo ""
echo "  Run from apps-native/story_generator_flutter/:"
$HAS_XCODE   && echo -e "    ${BOLD}flutter run${NC}                       iPad/iPhone via USB"
$HAS_XCODE   && echo -e "    ${BOLD}flutter run -d 'iPhone 16'${NC}         iOS Simulator"
$HAS_ANDROID && echo -e "    ${BOLD}flutter run${NC}                       Android via USB"
$HAS_ANDROID && echo -e "    ${BOLD}flutter build apk --release${NC}       sideloadable APK"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
