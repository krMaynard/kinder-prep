#!/usr/bin/env python3
"""
Social Story Generator
A Tkinter desktop application for generating personalized decodable books
for early readers, powered by Google Gemini.
"""

from __future__ import annotations

import io
import json
import os
import pathlib
import re
import shutil
import threading
import tkinter as tk
from tkinter import filedialog, messagebox, scrolledtext, ttk
from typing import Optional

try:
    from PIL import Image, ImageTk
    PIL_AVAILABLE = True
except ImportError:
    PIL_AVAILABLE = False

try:
    from google import genai
    from google.genai import types as genai_types
    GENAI_AVAILABLE = True
except ImportError:
    GENAI_AVAILABLE = False

try:
    import keyring
    KEYRING_AVAILABLE = True
except ImportError:
    KEYRING_AVAILABLE = False

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

APP_NAME = "Social Story Generator"
APP_VERSION = "1.0.0"
CONFIG_DIR = pathlib.Path.home() / ".harker-prep"
PROFILE_FILE = CONFIG_DIR / "profile.json"
CONFIG_FILE = CONFIG_DIR / "config.json"
STYLE_TEMPLATES_FILE = CONFIG_DIR / "style_templates.json"

KEYCHAIN_SERVICE = "harker-prep"
KEYCHAIN_ACCOUNT = "gemini-api-key"

BUILTIN_TEMPLATES: dict[str, str] = {
    "Watercolor": (
        "Soft watercolor illustration, warm colors, friendly child-safe characters, "
        "simple white or light background, no scary or violent elements, suitable for children 3-5."
    ),
    "Cartoon": (
        "Bold cartoon illustration, bright primary colors, thick outlines, expressive characters, "
        "simple white background, child-friendly, suitable for ages 3-5."
    ),
    "Colored Pencil": (
        "Colored pencil illustration, soft textures, pastel tones, hand-drawn feel, "
        "white background, gentle and warm, suitable for children 3-5."
    ),
    "Pixel Art": (
        "Retro pixel art illustration, 16-bit style, bright colors, simple pixel characters, "
        "no scary elements, charming and playful, suitable for children 3-5."
    ),
}

PHONICS_LEVELS = [
    "CVC short-a",
    "CVC short-i",
    "CVC short-o",
    "CVC short-u",
    "CVC short-e",
    "CVCC",
    "Long vowel (silent-e)",
    "Digraphs",
]

# Words decodable at each phonics level (simplified reference sets)
PHONICS_WORD_SETS: dict[str, set[str]] = {
    "CVC short-a": {
        "can", "cat", "bat", "hat", "mat", "rat", "sat", "fat", "pat",
        "man", "pan", "ran", "tan", "van", "ban", "fan", "jan", "nan",
        "bad", "dad", "had", "mad", "sad", "lad", "add",
        "bag", "rag", "tag", "wag", "nag", "jag", "lag",
        "cap", "map", "nap", "rap", "tap", "zap", "gap",
        "car", "bar", "far", "jar", "tar", "war",
        "has", "was", "as", "at", "am", "an",
        "and", "ask",
    },
    "CVC short-i": {
        "bit", "fit", "hit", "kit", "lit", "pit", "sit", "wit",
        "big", "dig", "fig", "gig", "jig", "pig", "rig", "wig",
        "bid", "did", "hid", "kid", "lid", "rid",
        "bin", "fin", "gin", "kin", "pin", "sin", "tin", "win",
        "dip", "hip", "lip", "nip", "rip", "sip", "tip", "zip",
        "his", "is", "in", "if", "it", "its",
        "him", "six", "mix", "fix",
    },
    "CVC short-o": {
        "bob", "cob", "fob", "gob", "job", "lob", "mob", "rob", "sob",
        "cod", "god", "mod", "nod", "pod", "rod", "tod",
        "bog", "cog", "dog", "fog", "hog", "jog", "log",
        "cop", "hop", "mop", "pop", "sop", "top",
        "cot", "dot", "got", "hot", "jot", "lot", "not", "pot", "rot",
        "on", "of", "or", "off", "odd",
        "box", "fox", "pox",
    },
    "CVC short-u": {
        "bud", "dud", "mud", "stud",
        "bug", "dug", "hug", "jug", "lug", "mug", "pug", "rug", "tug",
        "bun", "fun", "gun", "nun", "pun", "run", "sun",
        "bus", "gus", "pus",
        "but", "cut", "gut", "hut", "jut", "nut", "put", "rut",
        "cub", "hub", "pub", "rub", "sub", "tub",
        "cup", "pup", "sup",
        "up", "us", "um",
    },
    "CVC short-e": {
        "bed", "fed", "led", "red", "wed",
        "beg", "keg", "leg", "peg",
        "ben", "den", "hen", "men", "pen", "ten", "yen",
        "jet", "let", "met", "net", "pet", "set", "vet", "wet", "yet",
        "yes", "get",
        "belt", "felt", "melt", "held", "help", "self",
    },
    "CVCC": {
        "band", "hand", "land", "sand", "best", "nest", "rest", "test",
        "bold", "cold", "fold", "gold", "hold", "told",
        "bump", "dump", "hump", "jump", "pump",
        "back", "jack", "lack", "pack", "rack", "sack", "tack",
        "beck", "deck", "neck", "peck",
        "lick", "kick", "pick", "sick", "tick", "wick",
        "dock", "lock", "rock", "sock", "mock",
        "duck", "luck", "muck", "suck", "tuck",
        "fill", "hill", "mill", "will", "pill", "till",
        "bell", "cell", "fell", "sell", "tell", "well", "yell",
        "full", "pull", "bull",
        "fast", "last", "mast", "past", "vast",
        "fist", "list", "mist", "wrist",
    },
    "Long vowel (silent-e)": {
        "bake", "cake", "fake", "lake", "make", "rake", "sake", "take",
        "bike", "hike", "like", "pike",
        "bone", "cone", "tone", "zone", "lone", "gone",
        "cute", "mule", "rule", "tune",
        "came", "game", "name", "same", "tame", "fame",
        "time", "dime", "lime", "mime", "rhyme",
        "home", "dome", "nome",
        "use", "fuse", "muse",
        "ace", "ice", "once",
        "side", "hide", "ride", "wide",
        "safe", "wave", "cave", "gave",
        "life", "wife",
    },
    "Digraphs": {
        "ship", "shop", "shed", "shot", "shut", "shin", "shag",
        "chip", "chap", "chin", "chop", "chat", "check",
        "that", "this", "them", "then", "than", "with",
        "when", "whip", "whiz",
        "path", "math", "bath", "both",
        "much", "such", "rich", "inch",
        "wish", "fish", "dish",
        "rang", "sing", "ring", "king", "wing", "song", "long", "hang",
        "phone", "graph",
    },
}

# Common sight words acceptable at any level
COMMON_SIGHT_WORDS = {
    "the", "a", "an", "is", "are", "was", "were",
    "I", "me", "my", "we", "us", "our",
    "he", "she", "it", "they", "his", "her", "its",
    "you", "your",
    "to", "do", "go", "so", "no",
    "and", "or", "but", "for", "of", "in", "on", "at", "by",
    "up", "out", "off", "all", "one", "two", "too", "has",
    "have", "had", "not", "be", "been", "can", "will", "said",
    "see", "look", "come", "like", "play", "went", "what",
    "here", "there", "where", "who", "how",
    "with", "from", "into", "over", "down", "now",
    "then", "when", "that", "this",
    "big", "little", "old", "new", "good",
    "some", "day", "way", "time",
}

TEXT_MODEL = "gemini-3.1-pro-preview"
IMAGE_MODEL = "gemini-3.1-flash-image"  # Nano Banana 2 — native image generation

# ---------------------------------------------------------------------------
# Color scheme
# ---------------------------------------------------------------------------

COLORS = {
    "bg": "#F7F4EF",
    "sidebar_bg": "#EDE8E0",
    "accent": "#5B7FA6",
    "accent_dark": "#3D5C82",
    "accent_light": "#A8C4E0",
    "warning": "#C0392B",
    "warning_bg": "#FDECEA",
    "success": "#27AE60",
    "text": "#2C2C2C",
    "text_muted": "#6B6B6B",
    "border": "#C8C0B4",
    "button_bg": "#5B7FA6",
    "button_fg": "#FFFFFF",
    "button_disabled": "#A0A0A0",
}


# ---------------------------------------------------------------------------
# Utility helpers
# ---------------------------------------------------------------------------

def ensure_config_dir() -> None:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    try:
        CONFIG_DIR.chmod(0o700)
    except OSError:
        pass


def load_json_file(path: pathlib.Path) -> dict:
    if path.exists():
        try:
            with open(path, "r", encoding="utf-8") as f:
                return json.load(f)
        except (json.JSONDecodeError, OSError):
            return {}
    return {}


def save_json_file(path: pathlib.Path, data: dict) -> None:
    ensure_config_dir()
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
    try:
        path.chmod(0o600)
    except OSError:
        pass


def slugify(text: str) -> str:
    """Convert a title string to a URL-safe slug."""
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[\s_-]+", "-", text)
    text = re.sub(r"^-+|-+$", "", text)
    return text or "story"


def keychain_get() -> Optional[str]:
    if not KEYRING_AVAILABLE:
        return None
    try:
        return keyring.get_password(KEYCHAIN_SERVICE, KEYCHAIN_ACCOUNT) or None
    except Exception:
        return None


def keychain_set(key: str) -> None:
    if not KEYRING_AVAILABLE:
        return
    try:
        keyring.set_password(KEYCHAIN_SERVICE, KEYCHAIN_ACCOUNT, key)
    except Exception:
        pass


def keychain_delete() -> None:
    if not KEYRING_AVAILABLE:
        return
    try:
        keyring.delete_password(KEYCHAIN_SERVICE, KEYCHAIN_ACCOUNT)
    except Exception:
        pass


def check_vocabulary(text: str, phonics_level: str, extra_sight_words: list[str]) -> list[str]:
    """Return list of words in text that violate the phonics constraints."""
    allowed = set(COMMON_SIGHT_WORDS)
    allowed |= PHONICS_WORD_SETS.get(phonics_level, set())
    allowed |= {w.lower().strip() for w in extra_sight_words if w.strip()}

    tokens = re.findall(r"[a-zA-Z']+", text)
    violations = []
    for token in tokens:
        word = token.lower().strip("'")
        if len(word) <= 1:
            continue
        if word not in allowed:
            violations.append(token)
    return violations


# ---------------------------------------------------------------------------
# Gemini API helpers
# ---------------------------------------------------------------------------

def init_genai(api_key: str) -> "genai.Client":
    if not GENAI_AVAILABLE:
        raise RuntimeError(
            "google-genai is not installed. Run: pip install google-genai"
        )
    return genai.Client(api_key=api_key)


def generate_story_text(
    api_key: str,
    child_name: str,
    favorite_character: str,
    theme: str,
    phonics_level: str,
    sight_words: list[str],
    page_count: int,
) -> dict:
    """Call Gemini text model and return parsed story JSON."""
    client = init_genai(api_key)

    sight_words_str = ", ".join(sight_words) if sight_words else "the, a, is, can, I, see, go"

    prompt = f"""You are writing a decodable book for a 4-year-old learning to read.

Child: {child_name}
Hero of the story: {child_name} and {favorite_character}
Theme: {theme}
Pages: {page_count} (one sentence per page, 6-8 words max per sentence)

STRICT vocabulary rules:
- Phonics level: {phonics_level} — only use words decodable at this level
- Allowed sight words: {sight_words_str}
- Every other word must follow the phonics pattern exactly
- NO multi-syllable words except the character name

Output format — return ONLY valid JSON, no markdown, no code fences:
{{
  "title": "...",
  "pages": [
    {{"page": 1, "text": "..."}},
    ...
  ]
}}"""

    raw = ""
    last_error: Exception | None = None
    for attempt in range(2):
        try:
            response = client.models.generate_content(
                model=TEXT_MODEL,
                contents=prompt,
            )
            if not response.candidates or not response.candidates[0].content:
                raise RuntimeError("No candidates or content returned in response")
            raw = (response.text or "").strip()
            # Strip markdown code fences if present
            raw = re.sub(r"^```[a-z]*\n?", "", raw)
            raw = re.sub(r"\n?```$", "", raw)
            return json.loads(raw)
        except json.JSONDecodeError as exc:
            last_error = exc
            # Try to extract JSON from the response
            match = re.search(r"\{.*\}", raw, re.DOTALL)
            if match:
                try:
                    return json.loads(match.group())
                except json.JSONDecodeError:
                    pass
        except Exception as exc:
            last_error = exc
            if attempt == 0:
                continue
            break

    raise RuntimeError(f"Story text generation failed: {last_error}")


_DEFAULT_STYLE_GUIDE = (
    "Soft watercolor illustration, warm colors, friendly child-safe characters, "
    "simple white or light background, no scary or violent elements, suitable for children 3-5."
)


def generate_page_image(
    api_key: str,
    page_text: str,
    child_name: str,
    favorite_character: str,
    page_num: int,
    page_count: int,
    style_guide: str = _DEFAULT_STYLE_GUIDE,
) -> bytes:
    """Generate an image for a single page, return raw PNG bytes."""
    client = init_genai(api_key)

    prompt = (
        f"Children's book illustration. {page_text} "
        f"Characters: {child_name} (a friendly 4-year-old child) and {favorite_character}. "
        f"Style: {style_guide} "
        f"No text, no letters, no signs in the image. "
        f"Page {page_num} of {page_count}."
    )

    last_error: Exception | None = None
    for attempt in range(2):
        try:
            response = client.models.generate_content(
                model=IMAGE_MODEL,
                contents=prompt,
                config=genai_types.GenerateContentConfig(
                    response_modalities=["IMAGE", "TEXT"],
                ),
            )
            if (
                not response.candidates
                or not response.candidates[0].content
                or not response.candidates[0].content.parts
            ):
                raise RuntimeError("No content parts returned in response")
            for part in response.candidates[0].content.parts:
                if part.inline_data and part.inline_data.mime_type.startswith("image/"):
                    return part.inline_data.data
            raise RuntimeError("No image data in response")
        except Exception as exc:
            last_error = exc
            if attempt == 0:
                continue
            break

    raise RuntimeError(f"Image generation failed for page {page_num}: {last_error}")


# ---------------------------------------------------------------------------
# CollapsibleFrame widget
# ---------------------------------------------------------------------------

class CollapsibleFrame(ttk.Frame):
    """A LabelFrame that can be toggled open/closed."""

    def __init__(self, parent: tk.Widget, text: str, **kwargs):
        super().__init__(parent, **kwargs)
        self._open = True

        self._header = ttk.Frame(self)
        self._header.pack(fill=tk.X)

        self._toggle_btn = ttk.Button(
            self._header,
            text="▼  " + text,
            command=self._toggle,
            style="Collapse.TButton",
        )
        self._toggle_btn.pack(fill=tk.X)

        self._body = ttk.Frame(self, padding=(6, 2, 6, 6))
        self._body.pack(fill=tk.X)

    def _toggle(self) -> None:
        label = self._toggle_btn.cget("text")[3:]  # strip "▼  " or "▶  "
        if self._open:
            self._body.pack_forget()
            self._toggle_btn.configure(text="▶  " + label)
        else:
            self._body.pack(fill=tk.X)
            self._toggle_btn.configure(text="▼  " + label)
        self._open = not self._open

    @property
    def body(self) -> ttk.Frame:
        return self._body


# ---------------------------------------------------------------------------
# ScrollableFrame widget
# ---------------------------------------------------------------------------

class ScrollableFrame(ttk.Frame):
    """A vertically scrollable container."""

    def __init__(self, parent: tk.Widget, **kwargs):
        super().__init__(parent, **kwargs)

        self._canvas = tk.Canvas(self, bg=COLORS["bg"], highlightthickness=0)
        self._scrollbar = ttk.Scrollbar(self, orient=tk.VERTICAL, command=self._canvas.yview)
        self._canvas.configure(yscrollcommand=self._scrollbar.set)

        self._scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        self._canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

        self.inner = ttk.Frame(self._canvas)
        self._window_id = self._canvas.create_window((0, 0), window=self.inner, anchor=tk.NW)

        self.inner.bind("<Configure>", self._on_inner_configure)
        self._canvas.bind("<Configure>", self._on_canvas_configure)
        self._canvas.bind_all("<MouseWheel>", self._on_mousewheel)
        self._canvas.bind_all("<Button-4>", self._on_mousewheel)
        self._canvas.bind_all("<Button-5>", self._on_mousewheel)

    def _on_inner_configure(self, _event: tk.Event) -> None:
        self._canvas.configure(scrollregion=self._canvas.bbox("all"))

    def _on_canvas_configure(self, event: tk.Event) -> None:
        self._canvas.itemconfig(self._window_id, width=event.width)

    def _on_mousewheel(self, event: tk.Event) -> None:
        if event.num == 4:
            self._canvas.yview_scroll(-1, "units")
        elif event.num == 5:
            self._canvas.yview_scroll(1, "units")
        else:
            self._canvas.yview_scroll(int(-1 * (event.delta / 120)), "units")


# ---------------------------------------------------------------------------
# Main Application
# ---------------------------------------------------------------------------

class StoryGeneratorApp(tk.Tk):
    def __init__(self):
        super().__init__()

        self.title(APP_NAME)
        self.geometry("900x700")
        self.minsize(800, 600)
        self.configure(bg=COLORS["bg"])

        # Application state
        self._story_data: Optional[dict] = None          # parsed JSON from Gemini
        self._page_images: dict[int, bytes] = {}         # page_num -> raw PNG bytes
        self._photo_refs: list[ImageTk.PhotoImage] = []  # keep refs alive
        self._generating = False
        self._last_spec_path: Optional[str] = None

        self._load_config()
        self._setup_styles()
        self._build_menu()
        self._build_ui()
        self._load_profile()

        self.protocol("WM_DELETE_WINDOW", self._on_quit)

    # ------------------------------------------------------------------
    # Config / Profile persistence
    # ------------------------------------------------------------------

    def _load_config(self) -> None:
        self._config = load_json_file(CONFIG_FILE)
        self._profile = load_json_file(PROFILE_FILE)
        self._style_templates = self._load_style_templates()
        self._migrate_key_to_keychain()

    def _migrate_key_to_keychain(self) -> None:
        """One-time migration: move api_key from config.json into Keychain."""
        old_key = self._config.pop("api_key", None)
        if old_key and KEYRING_AVAILABLE and not keychain_get():
            keychain_set(old_key)
            self._save_config()  # persist the removal of api_key from config

    def _save_config(self) -> None:
        save_json_file(CONFIG_FILE, self._config)

    def _save_profile(self) -> None:
        save_json_file(PROFILE_FILE, self._profile)

    # ------------------------------------------------------------------
    # Styles
    # ------------------------------------------------------------------

    def _setup_styles(self) -> None:
        style = ttk.Style(self)
        # Use aqua on macOS, clam elsewhere for best native look
        available = style.theme_names()
        if "aqua" in available:
            style.theme_use("aqua")
        elif "clam" in available:
            style.theme_use("clam")

        style.configure("TFrame", background=COLORS["bg"])
        style.configure("Sidebar.TFrame", background=COLORS["sidebar_bg"])
        style.configure("TLabel", background=COLORS["bg"], foreground=COLORS["text"])
        style.configure("Sidebar.TLabel", background=COLORS["sidebar_bg"], foreground=COLORS["text"])
        style.configure(
            "TLabelframe",
            background=COLORS["sidebar_bg"],
            foreground=COLORS["accent_dark"],
        )
        style.configure(
            "TLabelframe.Label",
            background=COLORS["sidebar_bg"],
            foreground=COLORS["accent_dark"],
            font=("Helvetica", 11, "bold"),
        )
        style.configure(
            "Accent.TButton",
            font=("Helvetica", 12, "bold"),
        )
        style.configure(
            "Small.TButton",
            font=("Helvetica", 10),
        )
        style.configure(
            "Collapse.TButton",
            font=("Helvetica", 11, "bold"),
            anchor=tk.W,
        )
        style.configure("TNotebook", background=COLORS["bg"])
        style.configure("TNotebook.Tab", font=("Helvetica", 11))

    # ------------------------------------------------------------------
    # Menu bar
    # ------------------------------------------------------------------

    def _build_menu(self) -> None:
        menubar = tk.Menu(self)
        self.configure(menu=menubar)

        # File menu
        file_menu = tk.Menu(menubar, tearoff=False)
        file_menu.add_command(label="New Story", command=self._new_story, accelerator="Cmd+N")
        file_menu.add_command(label="Open Story Spec…", command=self._open_story_spec, accelerator="Cmd+O")
        file_menu.add_command(label="Save Story Spec…", command=self._save_story_spec, accelerator="Cmd+S")
        file_menu.add_separator()
        file_menu.add_command(label="Quit", command=self._on_quit, accelerator="Cmd+Q")
        menubar.add_cascade(label="File", menu=file_menu)
        self.bind_all("<Command-n>", lambda _e: self._new_story())
        self.bind_all("<Command-o>", lambda _e: self._open_story_spec())
        self.bind_all("<Command-s>", lambda _e: self._save_story_spec())
        self.bind_all("<Command-q>", lambda _e: self._on_quit())

        # Help menu
        help_menu = tk.Menu(menubar, tearoff=False)
        help_menu.add_command(label="About", command=self._show_about)
        menubar.add_cascade(label="Help", menu=help_menu)

    # ------------------------------------------------------------------
    # UI construction
    # ------------------------------------------------------------------

    def _build_ui(self) -> None:
        # Main horizontal paned window
        self._paned = ttk.PanedWindow(self, orient=tk.HORIZONTAL)
        self._paned.pack(fill=tk.BOTH, expand=True)

        # Left sidebar
        self._sidebar = ttk.Frame(self._paned, style="Sidebar.TFrame", width=290)
        self._sidebar.pack_propagate(False)
        self._paned.add(self._sidebar, weight=0)

        # Right content area
        self._content = ttk.Frame(self._paned)
        self._paned.add(self._content, weight=1)

        self._build_sidebar()
        self._build_content()
        self._build_bottom_bar()

    def _build_sidebar(self) -> None:
        sidebar_scroll = ScrollableFrame(self._sidebar, style="Sidebar.TFrame")
        sidebar_scroll.pack(fill=tk.BOTH, expand=True)
        sidebar_scroll._canvas.configure(bg=COLORS["sidebar_bg"])
        sidebar_scroll.inner.configure(style="Sidebar.TFrame")

        pad = {"padx": 8, "pady": 4}

        # ---- Profile section ----
        self._profile_frame = CollapsibleFrame(sidebar_scroll.inner, "Profile")
        self._profile_frame.pack(fill=tk.X, **pad)
        pf = self._profile_frame.body

        ttk.Label(pf, text="Child's name", style="Sidebar.TLabel").pack(anchor=tk.W)
        self._child_name_var = tk.StringVar()
        ttk.Entry(pf, textvariable=self._child_name_var).pack(fill=tk.X, pady=(0, 4))

        ttk.Label(pf, text="Favorite characters", style="Sidebar.TLabel").pack(anchor=tk.W)
        self._fav_chars_var = tk.StringVar()
        ttk.Entry(pf, textvariable=self._fav_chars_var).pack(fill=tk.X, pady=(0, 4))

        ttk.Label(pf, text="Phonics level", style="Sidebar.TLabel").pack(anchor=tk.W)
        self._phonics_var = tk.StringVar(value=PHONICS_LEVELS[0])
        phonics_menu = ttk.OptionMenu(pf, self._phonics_var, PHONICS_LEVELS[0], *PHONICS_LEVELS)
        phonics_menu.pack(fill=tk.X, pady=(0, 4))

        ttk.Label(pf, text="Reading level description", style="Sidebar.TLabel").pack(anchor=tk.W)
        self._reading_level_var = tk.StringVar()
        ttk.Entry(pf, textvariable=self._reading_level_var).pack(fill=tk.X, pady=(0, 4))

        ttk.Button(
            pf,
            text="Save Profile",
            command=self._save_profile_ui,
            style="Small.TButton",
        ).pack(anchor=tk.E, pady=(2, 0))

        # ---- Story Spec section ----
        spec_lf = ttk.LabelFrame(sidebar_scroll.inner, text="Story Spec", padding=8)
        spec_lf.pack(fill=tk.X, **pad)

        ttk.Label(spec_lf, text="Title").pack(anchor=tk.W)
        self._title_var = tk.StringVar()
        ttk.Entry(spec_lf, textvariable=self._title_var).pack(fill=tk.X, pady=(0, 4))

        ttk.Label(spec_lf, text="Theme / topic").pack(anchor=tk.W)
        self._theme_var = tk.StringVar()
        ttk.Entry(spec_lf, textvariable=self._theme_var).pack(fill=tk.X, pady=(0, 4))

        ttk.Label(spec_lf, text="Favorite character in story").pack(anchor=tk.W)
        self._story_char_var = tk.StringVar()
        ttk.Entry(spec_lf, textvariable=self._story_char_var).pack(fill=tk.X, pady=(0, 4))

        ttk.Label(spec_lf, text="Sight words (comma-separated)").pack(anchor=tk.W)
        self._sight_words_var = tk.StringVar()
        ttk.Entry(spec_lf, textvariable=self._sight_words_var).pack(fill=tk.X, pady=(0, 4))

        ttk.Label(spec_lf, text="Page count").pack(anchor=tk.W)
        self._page_count_var = tk.IntVar(value=6)
        ttk.Spinbox(
            spec_lf,
            from_=4,
            to=8,
            textvariable=self._page_count_var,
            width=6,
        ).pack(anchor=tk.W, pady=(0, 6))

        ttk.Button(
            spec_lf,
            text="Load from file…",
            command=self._open_story_spec,
            style="Small.TButton",
        ).pack(anchor=tk.W)

        # ---- API Key section ----
        api_lf = ttk.LabelFrame(sidebar_scroll.inner, text="API Key", padding=8)
        api_lf.pack(fill=tk.X, **pad)

        ttk.Label(api_lf, text="Gemini API Key").pack(anchor=tk.W)
        self._api_key_var = tk.StringVar()
        self._api_key_entry = ttk.Entry(api_lf, textvariable=self._api_key_var, show="•")
        self._api_key_entry.pack(fill=tk.X, pady=(0, 4))

        self._remember_key_var = tk.BooleanVar(value=bool(self._config.get("remember_key", False)))
        ttk.Checkbutton(
            api_lf,
            text="Remember key (Keychain)",
            variable=self._remember_key_var,
            command=self._on_remember_key_changed,
        ).pack(anchor=tk.W)

        # Restore saved key from Keychain if "Remember key" is on
        if self._remember_key_var.get():
            saved_key = keychain_get()
            if saved_key:
                self._api_key_var.set(saved_key)

        # ---- Style Guide section ----
        sg_lf = ttk.LabelFrame(sidebar_scroll.inner, text="Image Style Guide", padding=8)
        sg_lf.pack(fill=tk.X, **pad)

        # Template selector row
        ttk.Label(sg_lf, text="Template").pack(anchor=tk.W)
        template_row = ttk.Frame(sg_lf)
        template_row.pack(fill=tk.X, pady=(0, 6))

        self._template_var = tk.StringVar(value="Watercolor")
        template_names = list(self._style_templates.keys())
        self._template_menu = ttk.OptionMenu(
            template_row, self._template_var,
            template_names[0] if template_names else "",
            *template_names[1:],
        )
        self._template_menu.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(0, 4))
        ttk.Button(
            template_row,
            text="Load",
            command=self._apply_style_template,
            style="Small.TButton",
        ).pack(side=tk.LEFT)

        ttk.Separator(sg_lf, orient=tk.HORIZONTAL).pack(fill=tk.X, pady=4)

        # Style guide text area
        ttk.Label(
            sg_lf,
            text="Edit to customise the art style:",
            wraplength=230,
            justify=tk.LEFT,
        ).pack(anchor=tk.W, pady=(0, 4))

        self._style_guide_text = tk.Text(
            sg_lf,
            height=5,
            wrap=tk.WORD,
            font=("TkDefaultFont", 11),
            relief=tk.SOLID,
            borderwidth=1,
        )
        self._style_guide_text.pack(fill=tk.X, pady=(0, 4))
        self._style_guide_text.insert(
            "1.0",
            self._config.get("style_guide", _DEFAULT_STYLE_GUIDE),
        )

        # Save current text as a named template
        ttk.Separator(sg_lf, orient=tk.HORIZONTAL).pack(fill=tk.X, pady=4)
        ttk.Label(sg_lf, text="Save as template").pack(anchor=tk.W)
        save_row = ttk.Frame(sg_lf)
        save_row.pack(fill=tk.X, pady=(0, 4))

        self._template_name_var = tk.StringVar()
        ttk.Entry(save_row, textvariable=self._template_name_var).pack(
            side=tk.LEFT, fill=tk.X, expand=True, padx=(0, 4)
        )
        ttk.Button(
            save_row,
            text="Save",
            command=self._save_style_template,
            style="Small.TButton",
        ).pack(side=tk.LEFT, padx=(0, 4))
        ttk.Button(
            save_row,
            text="Delete",
            command=self._delete_style_template,
            style="Small.TButton",
        ).pack(side=tk.LEFT)

    def _save_style_guide(self) -> None:
        guide = self._style_guide_text.get("1.0", tk.END).strip()
        self._config["style_guide"] = guide
        self._save_config()
        self._set_status("Style guide saved.")

    def _get_style_guide(self) -> str:
        return self._style_guide_text.get("1.0", tk.END).strip() or _DEFAULT_STYLE_GUIDE

    # ------------------------------------------------------------------
    # Style templates
    # ------------------------------------------------------------------

    def _load_style_templates(self) -> dict[str, str]:
        """Merge built-in templates with user-saved ones (user overrides win)."""
        user = load_json_file(STYLE_TEMPLATES_FILE)
        return {**BUILTIN_TEMPLATES, **user}

    def _refresh_template_menu(self) -> None:
        self._style_templates = self._load_style_templates()
        menu = self._template_menu["menu"]
        menu.delete(0, tk.END)
        for name in self._style_templates:
            menu.add_command(
                label=name,
                command=lambda n=name: self._template_var.set(n),
            )
        if self._template_var.get() not in self._style_templates:
            first = next(iter(self._style_templates), "")
            self._template_var.set(first)

    def _apply_style_template(self) -> None:
        name = self._template_var.get()
        text = self._style_templates.get(name, "")
        if not text:
            return
        self._style_guide_text.delete("1.0", tk.END)
        self._style_guide_text.insert("1.0", text)
        self._template_name_var.set(name)
        self._set_status(f"Loaded template: {name}")

    def _save_style_template(self) -> None:
        name = self._template_name_var.get().strip()
        if not name:
            messagebox.showwarning("Name Required", "Enter a template name.")
            return
        if name in BUILTIN_TEMPLATES:
            if not messagebox.askyesno(
                "Override Built-in",
                f'"{name}" is a built-in template. Override it?',
            ):
                return
        text = self._style_guide_text.get("1.0", tk.END).strip()
        user = load_json_file(STYLE_TEMPLATES_FILE)
        user[name] = text
        save_json_file(STYLE_TEMPLATES_FILE, user)
        self._refresh_template_menu()
        self._template_var.set(name)
        self._set_status(f"Template saved: {name}")

    def _delete_style_template(self) -> None:
        name = self._template_var.get()
        if name in BUILTIN_TEMPLATES:
            messagebox.showwarning(
                "Cannot Delete Built-in",
                f'"{name}" is a built-in template and cannot be deleted.',
            )
            return
        user = load_json_file(STYLE_TEMPLATES_FILE)
        if name not in user:
            messagebox.showwarning("Not Found", f'"{name}" is not a saved template.')
            return
        if not messagebox.askyesno("Delete Template", f'Delete template "{name}"?'):
            return
        del user[name]
        save_json_file(STYLE_TEMPLATES_FILE, user)
        self._refresh_template_menu()
        self._set_status(f"Template deleted: {name}")

    def _build_content(self) -> None:
        self._notebook = ttk.Notebook(self._content)
        self._notebook.pack(fill=tk.BOTH, expand=True, padx=8, pady=8)

        # -- Story Text Tab --
        self._text_tab = ttk.Frame(self._notebook)
        self._notebook.add(self._text_tab, text="  Story Text  ")

        # Vocab warning panel
        self._vocab_warning_frame = ttk.Frame(self._text_tab)
        self._vocab_warning_frame.pack(fill=tk.X, padx=8, pady=(6, 0))
        self._vocab_warning_label = tk.Label(
            self._vocab_warning_frame,
            text="",
            bg=COLORS["warning_bg"],
            fg=COLORS["warning"],
            font=("Helvetica", 11),
            wraplength=540,
            justify=tk.LEFT,
            padx=8,
            pady=6,
        )

        # Scrollable text area for story pages
        self._text_scroll_frame = ScrollableFrame(self._text_tab)
        self._text_scroll_frame.pack(fill=tk.BOTH, expand=True, padx=8, pady=8)
        self._page_text_frames: list[dict] = []

        # -- Images Tab --
        self._images_tab = ttk.Frame(self._notebook)
        self._notebook.add(self._images_tab, text="  Images  ")

        self._images_scroll_frame = ScrollableFrame(self._images_tab)
        self._images_scroll_frame.pack(fill=tk.BOTH, expand=True, padx=8, pady=8)
        self._page_image_widgets: list[dict] = []

    def _build_bottom_bar(self) -> None:
        bottom = ttk.Frame(self, style="Sidebar.TFrame")
        bottom.pack(fill=tk.X, side=tk.BOTTOM)

        sep = ttk.Separator(bottom, orient=tk.HORIZONTAL)
        sep.pack(fill=tk.X)

        btn_frame = ttk.Frame(bottom, style="Sidebar.TFrame")
        btn_frame.pack(side=tk.LEFT, padx=12, pady=8)

        self._gen_text_btn = ttk.Button(
            btn_frame,
            text="Generate Story Text",
            command=self._on_generate_text,
            style="Accent.TButton",
        )
        self._gen_text_btn.pack(side=tk.LEFT, padx=(0, 8))

        self._gen_images_btn = ttk.Button(
            btn_frame,
            text="Generate Images",
            command=self._on_generate_images,
            style="Accent.TButton",
            state=tk.DISABLED,
        )
        self._gen_images_btn.pack(side=tk.LEFT, padx=(0, 8))

        self._save_btn = ttk.Button(
            btn_frame,
            text="Save to Repo",
            command=self._on_save_to_repo,
            style="Accent.TButton",
            state=tk.DISABLED,
        )
        self._save_btn.pack(side=tk.LEFT)

        self._status_var = tk.StringVar(value="Ready.")
        status_label = ttk.Label(
            bottom,
            textvariable=self._status_var,
            font=("Helvetica", 11),
            foreground=COLORS["text_muted"],
            style="Sidebar.TLabel",
        )
        status_label.pack(side=tk.RIGHT, padx=12, pady=8)

    # ------------------------------------------------------------------
    # Profile load/save
    # ------------------------------------------------------------------

    def _load_profile(self) -> None:
        if not self._profile:
            return
        self._child_name_var.set(self._profile.get("child_name", ""))
        self._fav_chars_var.set(self._profile.get("favorite_characters", ""))
        self._phonics_var.set(self._profile.get("phonics_level", PHONICS_LEVELS[0]))
        self._reading_level_var.set(self._profile.get("reading_level", ""))
        # Pre-fill story character from profile favorites
        self._story_char_var.set(self._profile.get("favorite_characters", ""))

    def _save_profile_ui(self) -> None:
        self._profile = {
            "child_name": self._child_name_var.get().strip(),
            "favorite_characters": self._fav_chars_var.get().strip(),
            "phonics_level": self._phonics_var.get(),
            "reading_level": self._reading_level_var.get().strip(),
        }
        self._save_profile()
        self._set_status("Profile saved.")
        messagebox.showinfo("Profile Saved", "Profile saved to ~/.harker-prep/profile.json")

    # ------------------------------------------------------------------
    # API key persistence
    # ------------------------------------------------------------------

    def _on_remember_key_changed(self) -> None:
        remember = self._remember_key_var.get()
        self._config["remember_key"] = remember
        if not remember:
            keychain_delete()
        self._save_config()

    def _get_api_key(self) -> Optional[str]:
        key = self._api_key_var.get().strip()
        if not key:
            messagebox.showwarning(
                "API Key Required",
                "Please enter your Gemini API Key in the 'API Key' section on the left.\n\n"
                "You can get a key at: https://aistudio.google.com/app/apikey",
            )
            return None
        if self._remember_key_var.get():
            self._config["remember_key"] = True
            self._save_config()
            if KEYRING_AVAILABLE:
                keychain_set(key)
            else:
                messagebox.showwarning(
                    "Keychain Unavailable",
                    "keyring is not installed — API key was not saved.\n"
                    "Run: pip install keyring",
                )
        return key

    # ------------------------------------------------------------------
    # Story Spec: load / save / new
    # ------------------------------------------------------------------

    def _new_story(self) -> None:
        if not messagebox.askyesno("New Story", "Clear current story and start fresh?"):
            return
        self._story_data = None
        self._page_images.clear()
        self._title_var.set("")
        self._theme_var.set("")
        self._sight_words_var.set("")
        self._page_count_var.set(6)
        self._clear_text_tab()
        self._clear_images_tab()
        self._gen_images_btn.configure(state=tk.DISABLED)
        self._save_btn.configure(state=tk.DISABLED)
        self._set_status("Ready.")

    def _open_story_spec(self) -> None:
        spec_dir = pathlib.Path(__file__).parent / "story-specs"
        initial_dir = str(spec_dir) if spec_dir.exists() else str(pathlib.Path.home())
        path = filedialog.askopenfilename(
            title="Open Story Spec",
            initialdir=initial_dir,
            filetypes=[("JSON files", "*.json"), ("All files", "*.*")],
        )
        if not path:
            return
        try:
            with open(path, "r", encoding="utf-8") as f:
                spec = json.load(f)
            self._populate_from_spec(spec)
            self._last_spec_path = path
            self._config["last_spec_path"] = path
            self._save_config()
            self._set_status(f"Loaded spec: {pathlib.Path(path).name}")
        except (json.JSONDecodeError, OSError) as exc:
            messagebox.showerror("Error Loading Spec", str(exc))

    def _populate_from_spec(self, spec: dict) -> None:
        self._title_var.set(spec.get("title", ""))
        self._theme_var.set(spec.get("theme", ""))
        self._story_char_var.set(spec.get("favorite_character", ""))
        sight = spec.get("target_sight_words", [])
        if isinstance(sight, list):
            self._sight_words_var.set(", ".join(sight))
        else:
            self._sight_words_var.set(str(sight))
        count = spec.get("page_count", 6)
        self._page_count_var.set(max(4, min(8, int(count))))
        level = spec.get("phonics_level", "")
        if level in PHONICS_LEVELS:
            self._phonics_var.set(level)

    def _save_story_spec(self) -> None:
        title = self._title_var.get().strip() or "story"
        slug = slugify(title)
        path = filedialog.asksaveasfilename(
            title="Save Story Spec",
            initialfile=f"{slug}.json",
            defaultextension=".json",
            filetypes=[("JSON files", "*.json")],
        )
        if not path:
            return
        sight_raw = self._sight_words_var.get()
        sight_list = [w.strip() for w in sight_raw.split(",") if w.strip()]
        spec = {
            "slug": slug,
            "title": title,
            "theme": self._theme_var.get().strip(),
            "phonics_level": self._phonics_var.get(),
            "target_sight_words": sight_list,
            "page_count": self._page_count_var.get(),
            "favorite_character": self._story_char_var.get().strip(),
        }
        try:
            with open(path, "w", encoding="utf-8") as f:
                json.dump(spec, f, indent=2)
            self._set_status(f"Spec saved to {pathlib.Path(path).name}")
        except OSError as exc:
            messagebox.showerror("Error Saving Spec", str(exc))

    # ------------------------------------------------------------------
    # Story Text Tab rendering
    # ------------------------------------------------------------------

    def _clear_text_tab(self) -> None:
        for widget in self._text_scroll_frame.inner.winfo_children():
            widget.destroy()
        self._page_text_frames.clear()
        self._vocab_warning_label.pack_forget()

    def _render_story_text(self, story: dict) -> None:
        self._clear_text_tab()
        pages = story.get("pages", [])
        sight_raw = self._sight_words_var.get()
        sight_list = [w.strip() for w in sight_raw.split(",") if w.strip()]
        phonics_level = self._phonics_var.get()

        all_violations: list[str] = []

        # Child name and character name are explicitly allowed by the prompt
        # regardless of phonics level — extract individual words from each.
        extra_names: list[str] = []
        for name_field in (self._child_name_var.get(), self._story_char_var.get()):
            extra_names.extend(w.strip() for w in name_field.split() if w.strip())

        for page_data in pages:
            page_num = page_data.get("page", 0)
            text = page_data.get("text", "")

            container = ttk.Frame(
                self._text_scroll_frame.inner,
                padding=10,
                relief=tk.GROOVE,
            )
            container.pack(fill=tk.X, padx=8, pady=6)

            header_row = ttk.Frame(container)
            header_row.pack(fill=tk.X)

            ttk.Label(
                header_row,
                text=f"Page {page_num}",
                font=("Helvetica", 13, "bold"),
                foreground=COLORS["accent_dark"],
            ).pack(side=tk.LEFT)

            edit_btn = ttk.Button(
                header_row,
                text="Edit",
                style="Small.TButton",
                command=lambda c=container, n=page_num, t=text: self._edit_page_text(c, n, t),
            )
            edit_btn.pack(side=tk.RIGHT)

            violations = check_vocabulary(text, phonics_level, sight_list + extra_names)
            all_violations.extend(violations)

            text_widget = tk.Text(
                container,
                height=3,
                wrap=tk.WORD,
                font=("Georgia", 14),
                relief=tk.FLAT,
                bg=COLORS["bg"],
                fg=COLORS["text"],
                borderwidth=0,
                padx=4,
                pady=4,
            )
            text_widget.pack(fill=tk.X, pady=(4, 0))
            text_widget.insert(tk.END, text)
            text_widget.tag_configure("violation", foreground=COLORS["warning"], underline=True)

            # Highlight violations
            for viol in violations:
                start = "1.0"
                while True:
                    pos = text_widget.search(viol, start, tk.END, nocase=False)
                    if not pos:
                        break
                    end_pos = f"{pos}+{len(viol)}c"
                    text_widget.tag_add("violation", pos, end_pos)
                    start = end_pos

            text_widget.configure(state=tk.DISABLED)

            self._page_text_frames.append({
                "page": page_num,
                "text_widget": text_widget,
                "container": container,
            })

        # Show/hide vocab warning
        if all_violations:
            unique = list(dict.fromkeys(all_violations))[:10]
            warning_text = (
                f"Vocabulary warning: {len(all_violations)} word(s) may exceed the phonics level. "
                f"Flagged words: {', '.join(unique)}"
                + (" …and more." if len(all_violations) > 10 else ".")
            )
            self._vocab_warning_label.configure(text=warning_text)
            self._vocab_warning_label.pack(fill=tk.X)
        else:
            self._vocab_warning_label.pack_forget()

    def _edit_page_text(self, container: ttk.Frame, page_num: int, current_text: str) -> None:
        """Open a small edit dialog for a page's text."""
        dialog = tk.Toplevel(self)
        dialog.title(f"Edit Page {page_num}")
        dialog.geometry("480x180")
        dialog.resizable(True, False)
        dialog.transient(self)
        dialog.grab_set()

        ttk.Label(dialog, text=f"Page {page_num} text:", font=("Helvetica", 12, "bold")).pack(
            anchor=tk.W, padx=12, pady=(12, 4)
        )
        text_var = tk.StringVar(value=current_text)
        entry = ttk.Entry(dialog, textvariable=text_var, font=("Georgia", 13))
        entry.pack(fill=tk.X, padx=12, pady=(0, 8))
        entry.focus_set()
        entry.select_range(0, tk.END)

        def _apply() -> None:
            new_text = text_var.get().strip()
            if not new_text:
                return
            # Update story data
            if self._story_data:
                for pg in self._story_data.get("pages", []):
                    if pg.get("page") == page_num:
                        pg["text"] = new_text
                        break
            # Re-render the text tab
            self._render_story_text(self._story_data)
            dialog.destroy()

        btn_row = ttk.Frame(dialog)
        btn_row.pack(anchor=tk.E, padx=12, pady=4)
        ttk.Button(btn_row, text="Cancel", command=dialog.destroy, style="Small.TButton").pack(
            side=tk.LEFT, padx=(0, 6)
        )
        ttk.Button(btn_row, text="Apply", command=_apply, style="Accent.TButton").pack(side=tk.LEFT)
        entry.bind("<Return>", lambda _e: _apply())

    # ------------------------------------------------------------------
    # Images Tab rendering
    # ------------------------------------------------------------------

    def _clear_images_tab(self) -> None:
        for widget in self._images_scroll_frame.inner.winfo_children():
            widget.destroy()
        self._page_image_widgets.clear()
        self._photo_refs.clear()

    def _render_images_tab(self) -> None:
        self._clear_images_tab()
        if not self._story_data:
            return

        pages = self._story_data.get("pages", [])
        # Arrange in rows of 3
        row_frame: Optional[ttk.Frame] = None

        for idx, page_data in enumerate(pages):
            page_num = page_data.get("page", idx + 1)
            text = page_data.get("text", "")

            if idx % 3 == 0:
                row_frame = ttk.Frame(self._images_scroll_frame.inner)
                row_frame.pack(fill=tk.X, padx=4, pady=4)

            cell = ttk.Frame(row_frame, padding=6, relief=tk.GROOVE)
            cell.pack(side=tk.LEFT, padx=4, pady=4, anchor=tk.N)

            # Image placeholder or actual image
            img_label = tk.Label(
                cell,
                width=200,
                height=200,
                bg=COLORS["accent_light"],
                text=f"Page {page_num}\n(no image yet)",
                font=("Helvetica", 11),
                fg=COLORS["text_muted"],
            )
            img_label.pack()

            # If we have bytes for this page, render it
            if page_num in self._page_images:
                self._set_page_thumbnail(img_label, page_num)

            # Caption
            caption = tk.Label(
                cell,
                text=text,
                font=("Helvetica", 10),
                wraplength=196,
                justify=tk.LEFT,
                bg=COLORS["bg"],
                fg=COLORS["text_muted"],
            )
            caption.pack(fill=tk.X, pady=(4, 2))

            # Regenerate button
            regen_btn = ttk.Button(
                cell,
                text=f"Regenerate Page {page_num}",
                style="Small.TButton",
                command=lambda n=page_num, t=text, lbl=img_label: self._regenerate_page_image(n, t, lbl),
            )
            regen_btn.pack()

            self._page_image_widgets.append({
                "page": page_num,
                "img_label": img_label,
                "regen_btn": regen_btn,
            })

    def _set_page_thumbnail(self, label: tk.Label, page_num: int) -> None:
        if not PIL_AVAILABLE:
            label.configure(text=f"Page {page_num}\n(Pillow not installed)")
            return
        raw = self._page_images.get(page_num)
        if not raw:
            return
        try:
            img = Image.open(io.BytesIO(raw))
            img.thumbnail((200, 200), Image.LANCZOS)
            photo = ImageTk.PhotoImage(img)
            label.configure(image=photo, text="", width=200, height=200)
            label.image = photo  # prevent GC
            self._photo_refs.append(photo)
        except Exception as exc:
            label.configure(text=f"Page {page_num}\n(error: {exc})")

    # ------------------------------------------------------------------
    # Generation: Story Text
    # ------------------------------------------------------------------

    def _on_generate_text(self) -> None:
        if self._generating:
            return
        api_key = self._get_api_key()
        if not api_key:
            return

        child_name = self._child_name_var.get().strip()
        if not child_name:
            messagebox.showwarning("Missing Name", "Please enter the child's name in the Profile section.")
            return

        title = self._title_var.get().strip()
        theme = self._theme_var.get().strip()
        if not theme:
            messagebox.showwarning("Missing Theme", "Please enter a story theme.")
            return

        favorite_character = self._story_char_var.get().strip() or "a friendly animal"
        phonics_level = self._phonics_var.get()
        sight_raw = self._sight_words_var.get()
        sight_list = [w.strip() for w in sight_raw.split(",") if w.strip()]
        page_count = self._page_count_var.get()

        self._set_generating(True)
        self._set_status("Generating story text…")
        self._notebook.select(self._text_tab)

        def _worker():
            try:
                story = generate_story_text(
                    api_key=api_key,
                    child_name=child_name,
                    favorite_character=favorite_character,
                    theme=theme,
                    phonics_level=phonics_level,
                    sight_words=sight_list,
                    page_count=page_count,
                )
                self.after(0, lambda: self._on_text_generated(story))
            except Exception as exc:
                self.after(0, lambda e=exc: self._on_generation_error("Text generation failed", e))

        threading.Thread(target=_worker, daemon=True).start()

    def _on_text_generated(self, story: dict) -> None:
        self._story_data = story
        # Update title from generated story if blank
        if not self._title_var.get().strip() and story.get("title"):
            self._title_var.set(story["title"])
        self._render_story_text(story)
        self._gen_images_btn.configure(state=tk.NORMAL)
        self._save_btn.configure(state=tk.NORMAL)
        self._set_generating(False)
        self._set_status(f"Story generated — {len(story.get('pages', []))} pages.")

    # ------------------------------------------------------------------
    # Generation: Images (all pages)
    # ------------------------------------------------------------------

    def _on_generate_images(self) -> None:
        if self._generating or not self._story_data:
            return
        api_key = self._get_api_key()
        if not api_key:
            return

        self._set_generating(True)
        self._notebook.select(self._images_tab)
        self._render_images_tab()

        child_name = self._child_name_var.get().strip() or "the child"
        favorite_character = self._story_char_var.get().strip() or "a friendly animal"
        style_guide = self._get_style_guide()
        pages = list(self._story_data.get("pages", []))  # snapshot before dispatch
        page_count = len(pages)

        self._set_status(f"Generating images for {page_count} pages…")

        def _worker():
            errors = []
            for page_data in pages:
                page_num = page_data.get("page", 0)
                text = page_data.get("text", "")
                self.after(0, lambda n=page_num, t=page_count: self._set_status(
                    f"Generating image for page {n} of {t}…"
                ))
                try:
                    img_bytes = generate_page_image(
                        api_key=api_key,
                        page_text=text,
                        child_name=child_name,
                        favorite_character=favorite_character,
                        page_num=page_num,
                        page_count=page_count,
                        style_guide=style_guide,
                    )
                    self._page_images[page_num] = img_bytes
                    self.after(0, lambda n=page_num: self._update_page_thumbnail(n))
                except Exception as exc:
                    errors.append(f"Page {page_num}: {exc}")

            self.after(0, lambda e=errors: self._on_images_done(e))

        threading.Thread(target=_worker, daemon=True).start()

    def _update_page_thumbnail(self, page_num: int) -> None:
        for widget_info in self._page_image_widgets:
            if widget_info["page"] == page_num:
                self._set_page_thumbnail(widget_info["img_label"], page_num)
                break

    def _on_images_done(self, errors: list[str]) -> None:
        self._set_generating(False)
        if errors:
            messagebox.showwarning(
                "Some Images Failed",
                "The following pages failed to generate images:\n\n" + "\n".join(errors),
            )
            self._set_status(f"Images done with {len(errors)} error(s).")
        else:
            self._set_status("All images generated successfully.")

    # ------------------------------------------------------------------
    # Generation: Single page regeneration
    # ------------------------------------------------------------------

    def _regenerate_page_image(self, page_num: int, text: str, img_label: tk.Label) -> None:
        if self._generating:
            return
        api_key = self._get_api_key()
        if not api_key:
            return

        child_name = self._child_name_var.get().strip() or "the child"
        favorite_character = self._story_char_var.get().strip() or "a friendly animal"
        style_guide = self._get_style_guide()
        page_count = len(self._story_data.get("pages", [])) if self._story_data else 1

        self._set_generating(True)
        self._set_status(f"Regenerating image for page {page_num}…")

        def _worker():
            try:
                img_bytes = generate_page_image(
                    api_key=api_key,
                    page_text=text,
                    child_name=child_name,
                    favorite_character=favorite_character,
                    page_num=page_num,
                    page_count=page_count,
                    style_guide=style_guide,
                )
                self._page_images[page_num] = img_bytes
                self.after(0, lambda: self._set_page_thumbnail(img_label, page_num))
                self.after(0, lambda: self._set_status(f"Page {page_num} image updated."))
                self.after(0, lambda: self._set_generating(False))
            except Exception as exc:
                self.after(0, lambda e=exc: self._on_generation_error(
                    f"Image regeneration failed (page {page_num})", e
                ))

        threading.Thread(target=_worker, daemon=True).start()

    # ------------------------------------------------------------------
    # Save to Repo
    # ------------------------------------------------------------------

    def _on_save_to_repo(self) -> None:
        if not self._story_data:
            messagebox.showwarning("Nothing to Save", "Generate a story first.")
            return

        repo_root = filedialog.askdirectory(
            title="Select the homework repo root folder",
        )
        if not repo_root:
            return

        title = self._title_var.get().strip() or self._story_data.get("title", "story")
        slug = slugify(title)

        out_dir = pathlib.Path(repo_root) / "apps" / "social-stories" / "stories" / slug
        out_dir.mkdir(parents=True, exist_ok=True)

        pages_out = []
        for page_data in self._story_data.get("pages", []):
            page_num = page_data.get("page", 0)
            img_filename = f"page-{page_num:02d}.png"
            entry = {
                "page": page_num,
                "text": page_data.get("text", ""),
                "image": img_filename,
            }
            pages_out.append(entry)

            # Write image file if we have it
            img_bytes = self._page_images.get(page_num)
            if img_bytes:
                img_path = out_dir / img_filename
                with open(img_path, "wb") as f:
                    f.write(img_bytes)

        story_json = {
            "title": title,
            "slug": slug,
            "pages": pages_out,
        }
        story_json_path = out_dir / "story.json"
        with open(story_json_path, "w", encoding="utf-8") as f:
            json.dump(story_json, f, indent=2)

        missing_images = [
            p["page"] for p in pages_out if p["page"] not in self._page_images
        ]
        if missing_images:
            messagebox.showinfo(
                "Saved (partial)",
                f"Story saved to:\n{out_dir}\n\n"
                f"Note: Images for page(s) {missing_images} were not generated yet "
                f"and placeholder filenames were written to story.json.",
            )
        else:
            messagebox.showinfo(
                "Saved",
                f"Story saved to:\n{out_dir}",
            )
        self._set_status(f"Story saved to {out_dir.name}.")

    # ------------------------------------------------------------------
    # Error handling
    # ------------------------------------------------------------------

    def _on_generation_error(self, title: str, exc: Exception) -> None:
        self._set_generating(False)
        self._set_status(f"Error: {exc}")
        messagebox.showerror(title, str(exc))

    # ------------------------------------------------------------------
    # UI state helpers
    # ------------------------------------------------------------------

    def _set_generating(self, generating: bool) -> None:
        self._generating = generating
        state = tk.DISABLED if generating else tk.NORMAL
        self._gen_text_btn.configure(state=state)
        if self._story_data:
            self._gen_images_btn.configure(state=state)
            self._save_btn.configure(state=state)

    def _set_status(self, message: str) -> None:
        self._status_var.set(message)
        self.update_idletasks()

    # ------------------------------------------------------------------
    # Menu actions
    # ------------------------------------------------------------------

    def _show_about(self) -> None:
        messagebox.showinfo(
            f"About {APP_NAME}",
            f"{APP_NAME} v{APP_VERSION}\n\n"
            "Generate personalized decodable books for early readers\n"
            "powered by Google Gemini.\n\n"
            "Profile and config saved to ~/.harker-prep/",
        )

    def _on_quit(self) -> None:
        self.destroy()


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    if not PIL_AVAILABLE:
        print(
            "WARNING: Pillow is not installed. Images will not be displayed.\n"
            "Install with: pip install Pillow"
        )
    if not GENAI_AVAILABLE:
        print(
            "WARNING: google-genai is not installed.\n"
            "Install with: pip install google-genai"
        )

    app = StoryGeneratorApp()
    app.mainloop()


if __name__ == "__main__":
    main()
