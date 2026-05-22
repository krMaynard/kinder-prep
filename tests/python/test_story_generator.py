"""
Tests for pure utility functions in tools/story_generator.py.
tkinter and google.generativeai are mocked via conftest.py.
"""
import ast
import json
import pathlib
import stat
import sys

import pytest

# Add tools/ to path so story_generator is importable.
sys.path.insert(0, str(pathlib.Path(__file__).parent.parent.parent / 'tools'))
import story_generator
from story_generator import check_vocabulary, ensure_config_dir, save_json_file


# ---------------------------------------------------------------------------
# check_vocabulary
# ---------------------------------------------------------------------------
class TestCheckVocabulary:
    def test_in_level_words_not_flagged(self):
        # "cat", "bat", "sat" are all in CVC short-a
        violations = check_vocabulary('cat bat sat', 'CVC short-a', [])
        assert violations == []

    def test_out_of_level_word_is_flagged(self):
        # "elephant" is not in any phonics set or sight words
        violations = check_vocabulary('the elephant ran', 'CVC short-a', [])
        assert any(v.lower() == 'elephant' for v in violations)

    def test_common_sight_words_never_flagged(self):
        # "the", "and", "is" are in COMMON_SIGHT_WORDS
        violations = check_vocabulary('the cat and dog is here', 'CVC short-a', [])
        sight = {'the', 'and', 'is', 'here'}
        flagged = {v.lower() for v in violations}
        assert flagged.isdisjoint(sight)

    def test_extra_sight_words_not_flagged(self):
        violations = check_vocabulary('Luca ran fast', 'CVC short-a', ['Luca', 'fast'])
        assert not any(v.lower() == 'luca' for v in violations)
        assert not any(v.lower() == 'fast' for v in violations)

    def test_child_name_not_flagged(self):
        # Regression: names were incorrectly flagged before the fix
        violations = check_vocabulary('Sebastian ran home', 'CVC short-a', ['Sebastian'])
        assert 'Sebastian' not in violations

    def test_character_name_not_flagged(self):
        violations = check_vocabulary('SpiderMan jumped up', 'CVC short-a', ['SpiderMan'])
        assert 'SpiderMan' not in violations

    def test_single_characters_ignored(self):
        # Single-char tokens should never be flagged
        violations = check_vocabulary('a I', 'CVC short-a', [])
        assert 'a' not in violations
        assert 'I' not in violations

    def test_case_insensitive_sight_words(self):
        # "The" (capital T) should still match "the" in COMMON_SIGHT_WORDS
        violations = check_vocabulary('The cat sat', 'CVC short-a', [])
        assert not any(v.lower() == 'the' for v in violations)

    def test_unknown_phonics_level_flags_everything_noncomon(self):
        # A level not in PHONICS_WORD_SETS returns empty set → non-sight words are flagged
        violations = check_vocabulary('elephant ran', 'nonexistent_level', [])
        assert any(v.lower() == 'elephant' for v in violations)

    def test_empty_text_returns_no_violations(self):
        assert check_vocabulary('', 'CVC short-a', []) == []


# ---------------------------------------------------------------------------
# Config file security
# ---------------------------------------------------------------------------
class TestConfigSecurity:
    def test_config_dir_mode(self, tmp_path, monkeypatch):
        test_dir = tmp_path / '.harker-prep-test'
        monkeypatch.setattr(story_generator, 'CONFIG_DIR', test_dir)
        ensure_config_dir()
        mode = test_dir.stat().st_mode
        # Owner rwx only (0o700); no group or other permissions
        assert stat.S_IMODE(mode) == 0o700

    def test_saved_file_mode(self, tmp_path, monkeypatch):
        test_dir = tmp_path / '.harker-prep-test'
        monkeypatch.setattr(story_generator, 'CONFIG_DIR', test_dir)
        config_file = test_dir / 'config.json'
        save_json_file(config_file, {'api_key': 'secret'})
        mode = config_file.stat().st_mode
        assert stat.S_IMODE(mode) == 0o600

    def test_saved_file_content_roundtrips(self, tmp_path, monkeypatch):
        test_dir = tmp_path / '.harker-prep-test'
        monkeypatch.setattr(story_generator, 'CONFIG_DIR', test_dir)
        data = {'key': 'value', 'count': 42, 'nested': {'x': True}}
        f = test_dir / 'data.json'
        save_json_file(f, data)
        assert json.loads(f.read_text()) == data


# ---------------------------------------------------------------------------
# Code structure: raw="" initialized before retry loop
# ---------------------------------------------------------------------------
class TestGenerateStoryTextStructure:
    """
    AST-based test: verifies that `raw` is assigned an empty string BEFORE
    the retry for-loop in generate_story_text, preventing UnboundLocalError
    when a network exception fires before response.text is assigned.
    """
    def test_raw_initialized_before_for_loop(self):
        src = (pathlib.Path(__file__).parent.parent.parent / 'tools' / 'story_generator.py').read_text()
        tree = ast.parse(src)

        fn = next(
            (n for n in ast.walk(tree)
             if isinstance(n, ast.FunctionDef) and n.name == 'generate_story_text'),
            None,
        )
        assert fn is not None, 'generate_story_text not found'

        for_loop_idx = next(
            (i for i, s in enumerate(fn.body) if isinstance(s, ast.For)),
            None,
        )
        assert for_loop_idx is not None, 'No for loop found in generate_story_text'

        raw_before = any(
            isinstance(s, ast.Assign)
            and any(isinstance(t, ast.Name) and t.id == 'raw' for t in s.targets)
            for s in fn.body[:for_loop_idx]
        )
        assert raw_before, '`raw` must be assigned before the retry for-loop'


# ---------------------------------------------------------------------------
# Code structure: _on_remember_key_changed does not persist key on toggle-on
# ---------------------------------------------------------------------------
class TestRememberKeyChanged:
    """
    AST-based test: verifies the fix that _on_remember_key_changed only saves
    the boolean flag, not the api_key value when the checkbox is turned on.
    Previously it did: if remember: self._config["api_key"] = self._api_key_var.get()
    which would write an empty/partial key to disk before the user finishes typing.
    """
    def _get_fn_source(self):
        src = (pathlib.Path(__file__).parent.parent.parent / 'tools' / 'story_generator.py').read_text()
        tree = ast.parse(src)
        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef) and node.name == '_on_remember_key_changed':
                return ast.get_source_segment(src, node)
        return None

    def test_function_exists(self):
        assert self._get_fn_source() is not None

    def test_does_not_write_api_key_on_remember_true(self):
        fn_src = self._get_fn_source()
        # The fixed version should NOT have: if remember: ... api_key = self._api_key_var.get()
        # It should only pop the key when remember is False.
        # We check that the string "api_key" only appears in a context that removes it,
        # not in a context that sets it from _api_key_var.
        assert '_api_key_var.get()' not in fn_src, (
            '_on_remember_key_changed must not write the key from the entry field; '
            'key is only persisted on first successful API use in _get_api_key()'
        )
