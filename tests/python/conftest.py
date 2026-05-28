"""
Mock tkinter and other unavailable modules before story_generator is imported.
This file is loaded automatically by pytest before any test collection.
"""
import sys
from unittest.mock import MagicMock

# tkinter is not available on headless CI servers.
# Insert mocks for every tkinter submodule story_generator touches.
_TK_MODS = [
    'tkinter', 'tkinter.filedialog', 'tkinter.messagebox',
    'tkinter.scrolledtext', 'tkinter.ttk',
]
for _mod in _TK_MODS:
    if _mod not in sys.modules:
        sys.modules[_mod] = MagicMock()

# PIL is optional in story_generator (try/except) but mock it to keep import clean.
for _mod in ['PIL', 'PIL.Image', 'PIL.ImageTk']:
    if _mod not in sys.modules:
        sys.modules[_mod] = MagicMock()

# google.genai is also guarded, but mock for safety.
for _mod in ['google', 'google.genai', 'google.genai.types']:
    if _mod not in sys.modules:
        sys.modules[_mod] = MagicMock()
