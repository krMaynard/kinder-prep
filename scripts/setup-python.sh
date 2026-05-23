#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TOOLS_DIR="$REPO_ROOT/tools"
VENV="$TOOLS_DIR/.venv"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
info()  { echo -e "${GREEN}▶${NC} $*"; }
warn()  { echo -e "${YELLOW}⚠${NC}  $*"; }
error() { echo -e "${RED}✗${NC}  $*" >&2; }
header(){ echo -e "\n${BOLD}$*${NC}"; }

header "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
header "  Story Generator — Python Setup (macOS)"
header "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── 1. Python version ────────────────────────────────────────────────────────
if ! command -v python3 &>/dev/null; then
    error "python3 not found. Install Python 3.10+ from https://python.org/downloads/"
    exit 1
fi

PY_FULL=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}")')
PY_MAJOR=$(python3 -c 'import sys; print(sys.version_info.major)')
PY_MINOR=$(python3 -c 'import sys; print(sys.version_info.minor)')

if [[ $PY_MAJOR -lt 3 || ($PY_MAJOR -eq 3 && $PY_MINOR -lt 10) ]]; then
    error "Python 3.10+ required, found $PY_FULL."
    error "Download a newer version from https://python.org/downloads/"
    exit 1
fi
info "Python $PY_FULL ✓"

# ── 2. Tkinter ───────────────────────────────────────────────────────────────
if ! python3 -c "import tkinter" 2>/dev/null; then
    error "Tkinter is not available in this Python installation."
    warn  "On macOS, Homebrew Python often lacks Tkinter. Use the python.org installer instead:"
    warn  "  https://python.org/downloads/macos/"
    exit 1
fi
info "Tkinter ✓"

# ── 3. Virtual environment ───────────────────────────────────────────────────
if [[ ! -d "$VENV" ]]; then
    info "Creating virtual environment at tools/.venv ..."
    python3 -m venv "$VENV"
else
    info "Virtual environment already exists — reusing"
fi

# ── 4. Install / upgrade packages ───────────────────────────────────────────
info "Installing packages from tools/requirements.txt ..."
"$VENV/bin/pip" install --quiet --upgrade pip
"$VENV/bin/pip" install --quiet -r "$TOOLS_DIR/requirements.txt"
info "Packages installed ✓"

# ── 5. Write launcher ────────────────────────────────────────────────────────
LAUNCHER="$TOOLS_DIR/run.sh"
cat > "$LAUNCHER" <<'LAUNCHER'
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/.venv/bin/python" "$SCRIPT_DIR/story_generator.py" "$@"
LAUNCHER
chmod +x "$LAUNCHER"
info "Launcher written to tools/run.sh"

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Setup complete!${NC}"
echo ""
echo "  Launch the app any time with:"
echo -e "    ${BOLD}./tools/run.sh${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Auto-launch unless --no-launch is passed
if [[ "${1:-}" != "--no-launch" ]]; then
    info "Launching Story Generator..."
    exec "$VENV/bin/python" "$TOOLS_DIR/story_generator.py"
fi
