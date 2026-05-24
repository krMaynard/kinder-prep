/**
 * theme.js — Character theme system
 * Harker Prep Curriculum shared module.
 *
 * ES module. Import what you need:
 *   import { getTheme, setThemeId, applyTheme, THEMES } from '../_shared/theme.js';
 *
 * Theme is stored in localStorage as 'hpk_theme' (one of the THEMES keys).
 *
 * applyTheme(theme) sets CSS custom properties on :root so apps can reference
 * --theme-accent, --theme-accent-dark, --theme-header throughout their CSS.
 */

export const THEMES = {
  default: {
    id: 'default',
    name: 'Rainbow',
    icon: '🌈',
    character: '🌈',
    description: 'Colorful fun!',

    // CSS var values
    accentColor: '#FF6B6B',
    accentDark:  '#C94B4B',
    headerColor: '#FF6B6B',
    // glowColor: used for the active-theme ring in the picker
    // (separate from accentColor so dark themes can still have a visible ring)
    glowColor: '#FF6B6B',

    // Emoji pool for math/number counters (10 items)
    counterEmojis: ['🍎', '🌟', '🐸', '🦋', '🚀', '🎈', '🍩', '🐶', '🌈', '🎁'],

    // Background gradient for home screen card
    cardGradient: 'linear-gradient(145deg, #FF6B6B, #FF8E53)',

    // Praise prefix for speech (empty = use default phrases)
    praisePrefix: '',
  },

  batman: {
    id: 'batman',
    name: 'Batman',
    icon: '🦇',
    character: '🦇',
    description: 'I am Batman!',

    accentColor: '#1a1a2e',
    accentDark:  '#0d0d1a',
    headerColor: '#1a1a2e',
    glowColor: '#F5C518',   // bat-yellow — visible against the dark bubble

    counterEmojis: ['🦇', '⭐', '🌙', '🛡️', '💛', '🔦', '🌃', '🦸', '🌟', '🔑'],

    cardGradient: 'linear-gradient(145deg, #2d2d4e, #1a1a2e)',

    praisePrefix: 'Holy bat-math! ',
  },

  spiderman: {
    id: 'spiderman',
    name: 'Spider-Man',
    icon: '🕷️',
    character: '🕷️',
    description: 'With great power!',

    accentColor: '#E51E25',
    accentDark:  '#A81018',
    headerColor: '#E51E25',
    glowColor: '#E51E25',   // red ring matches Spider-Man red

    counterEmojis: ['🕷️', '🕸️', '❤️', '💙', '⭐', '🏙️', '🦸', '🌟', '🔵', '🔴'],

    cardGradient: 'linear-gradient(145deg, #E51E25, #003790)',

    praisePrefix: 'Spider-sense! ',
  },

  trex: {
    id: 'trex',
    name: 'T-Rex',
    icon: '🦖',
    character: '🦖',
    description: 'RAWR!',

    accentColor: '#2E7D32',   // deep forest green
    accentDark:  '#1B5E20',
    headerColor: '#2E7D32',
    glowColor: '#69F0AE',     // bright mint — pops against dark green bubble

    counterEmojis: ['🦖', '🦕', '🥚', '🌿', '🌋', '🦴', '🍖', '⚡', '🌴', '🪨'],

    cardGradient: 'linear-gradient(145deg, #4CAF50, #1B5E20)',

    praisePrefix: 'RAWR! ',
  },
};

// ── Storage ──────────────────────────────────────────────────────────────────

const THEME_KEY = 'hpk_theme';

/** Return the current theme ID from localStorage (defaults to 'default'). */
export function getThemeId() {
  try {
    const stored = localStorage.getItem(THEME_KEY);
    return (stored && THEMES[stored]) ? stored : 'default';
  } catch {
    return 'default';
  }
}

/** Persist a theme ID to localStorage. */
export function setThemeId(id) {
  try {
    if (THEMES[id]) localStorage.setItem(THEME_KEY, id);
  } catch {}
}

/** Return the full current theme object. */
export function getTheme() {
  return THEMES[getThemeId()];
}

// ── Application ───────────────────────────────────────────────────────────────

/**
 * Apply a theme by setting CSS custom properties on :root.
 * Call once per app on load; CSS can then reference the vars anywhere.
 *
 * Sets:
 *   --theme-accent        primary accent colour
 *   --theme-accent-dark   darker shade for shadows/borders
 *   --theme-header        colour for the app title
 *
 * @param {object} theme — one of the THEMES entries (or getTheme())
 */
export function applyTheme(theme) {
  if (typeof document === 'undefined') return;
  const root = document.documentElement;
  root.style.setProperty('--theme-accent',      theme.accentColor);
  root.style.setProperty('--theme-accent-dark',  theme.accentDark);
  root.style.setProperty('--theme-header',       theme.headerColor);
  // glowColor is used for visible ring/name on the active theme bubble;
  // kept separate so dark-accent themes (Batman) can still show a bright ring.
  root.style.setProperty('--theme-glow',         theme.glowColor ?? theme.accentColor);
}
