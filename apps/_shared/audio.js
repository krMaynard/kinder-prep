/**
 * audio.js — Web Speech API wrapper
 * Harker Prep Curriculum shared module.
 *
 * ES module. Import what you need:
 *   import { speak, speakLetter, speakWord } from '../_shared/audio.js';
 *
 * All functions return Promises and resolve silently if the browser
 * does not support SpeechSynthesis (graceful degradation).
 */

// ---------------------------------------------------------------------------
// Phoneme map — isolated sounds, not letter names.
// These strings are tuned to produce natural phoneme sounds via SpeechSynthesis
// without relying on IPA or SSML (broad browser support).
// ---------------------------------------------------------------------------
const PHONEME_MAP = {
  a: 'aah',     // /æ/ as in "cat"
  b: 'buh',     // /b/
  c: 'kuh',     // hard-c as in "cat"
  d: 'duh',     // /d/
  e: 'eh',      // /ɛ/ as in "pet"
  f: 'ffff',    // /f/ — extra letters help TTS sustain the fricative
  g: 'guh',     // hard-g as in "go"
  h: 'huh',     // /h/
  i: 'ih',      // /ɪ/ as in "sit"
  j: 'juh',     // /dʒ/
  k: 'kuh',     // /k/
  l: 'lul',     // /l/ — sandwich helps isolation
  m: 'mmm',     // /m/ — nasal sustained
  n: 'nnn',     // /n/ — nasal sustained
  o: 'oh',      // /ɒ/ as in "hot"
  p: 'puh',     // /p/
  q: 'kwuh',    // /kw/ as in "queen"
  r: 'rrr',     // /r/
  s: 'sss',     // /s/ — sustained sibilant
  t: 'tuh',     // /t/
  u: 'uh',      // /ʌ/ as in "cup"
  v: 'vvv',     // /v/ — sustained
  w: 'wuh',     // /w/
  x: 'ksss',    // /ks/ as in "fox"
  y: 'yuh',     // /j/ as in "yes"
  z: 'zzz',     // /z/ — sustained
};

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

/** @returns {SpeechSynthesis | null} */
function getSynth() {
  if (typeof window === 'undefined') return null;
  return window.speechSynthesis ?? null;
}

/** @returns {boolean} */
function isSupported() {
  return getSynth() !== null && typeof SpeechSynthesisUtterance !== 'undefined';
}

/**
 * Cancel any in-progress speech.
 * Handles an iOS/Safari quirk where cancel() must be called
 * before a new utterance to avoid overlap.
 */
function cancelSpeech() {
  const synth = getSynth();
  if (synth) synth.cancel();
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Speak arbitrary text.
 *
 * @param {string} text  - The text to speak.
 * @param {number} [rate=0.85]  - Speed (0.1–10). 1 = normal. Lower = slower.
 * @param {number} [pitch=1.1] - Pitch (0–2). 1 = normal. Higher = more child-friendly.
 * @returns {Promise<void>} Resolves when speaking finishes (or immediately if unsupported).
 */
export function speak(text, rate = 0.85, pitch = 1.1) {
  return new Promise((resolve) => {
    if (!isSupported()) {
      resolve();
      return;
    }

    cancelSpeech();

    const synth = getSynth();
    const utt = new SpeechSynthesisUtterance(String(text));
    utt.rate   = Math.max(0.1, Math.min(10, rate));
    utt.pitch  = Math.max(0,   Math.min(2,  pitch));
    utt.volume = 1;
    utt.lang   = 'en-US';

    // Prefer a female voice when available (warmer for young children)
    const voices = synth.getVoices();
    if (voices.length > 0) {
      const preferred = voices.find(
        v => v.lang.startsWith('en') && /female|samantha|karen|victoria|fiona/i.test(v.name)
      ) || voices.find(v => v.lang.startsWith('en'));
      if (preferred) utt.voice = preferred;
    }

    synth.speak(utt);

    // iOS Safari sometimes stalls after a page becomes visible again.
    // Resume if the synth appears stuck after 200 ms.
    const resumeTimer = setTimeout(() => {
      if (synth.paused) synth.resume();
    }, 200);

    // Always clear the stall-recovery timer before resolving so it can't
    // fire synth.resume() on a subsequent utterance.
    function done() { clearTimeout(resumeTimer); resolve(); }
    utt.onend   = done;
    utt.onerror = done; // never reject — always degrade gracefully
  });
}

/**
 * Speak the isolated phoneme sound for a single letter.
 * Uses the phoneme map — e.g. "b" → "buh", not "bee".
 *
 * @param {string} letter - A single letter (case-insensitive).
 * @returns {Promise<void>}
 */
export function speakLetter(letter) {
  const key = String(letter).trim().toLowerCase().charAt(0);
  const phoneme = PHONEME_MAP[key] ?? key;
  return speak(phoneme, 0.80, 1.15);
}

/**
 * Speak a word in two passes:
 *   1. Slowly and clearly (blended read-aloud feel).
 *   2. After 800 ms pause, again at a natural conversational pace.
 *
 * @param {string} word
 * @returns {Promise<void>} Resolves after both passes complete.
 */
export async function speakWord(word) {
  const w = String(word).trim();
  // First pass — slow and deliberate
  await speak(w, 0.60, 1.05);
  // Brief pause so the child can process
  await delay(800);
  // Second pass — natural speed
  await speak(w, 0.95, 1.05);
}

/**
 * Speak a phrase at a friendly, clear pace.
 * Suitable for instructions and praise messages.
 *
 * @param {string} phrase
 * @returns {Promise<void>}
 */
export function speakPhrase(phrase) {
  return speak(String(phrase), 0.90, 1.10);
}

/**
 * Speak a praise/reward phrase with an upbeat tone.
 *
 * @param {string} [phrase='Great job!']
 * @returns {Promise<void>}
 */
export function speakPraise(phrase = 'Great job!') {
  return speak(String(phrase), 0.92, 1.20);
}

/**
 * Check whether Web Speech is available in this browser.
 * @returns {boolean}
 */
export function speechAvailable() {
  return isSupported();
}

/**
 * Cancel any currently-playing speech immediately.
 */
export function stopSpeaking() {
  cancelSpeech();
}

// ---------------------------------------------------------------------------
// Utility
// ---------------------------------------------------------------------------

/** @param {number} ms @returns {Promise<void>} */
function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// ---------------------------------------------------------------------------
// Voice preload — browsers load the voice list asynchronously.
// Call this once on page load so voices are ready before the first speak().
// ---------------------------------------------------------------------------
export function preloadVoices() {
  if (!isSupported()) return;
  const synth = getSynth();
  // Some browsers populate voices synchronously; others fire voiceschanged.
  // Trigger voice list population; the call itself caches voices in the browser.
  if (synth.getVoices().length === 0) {
    synth.addEventListener('voiceschanged', () => synth.getVoices(), { once: true });
  }
}

// Auto-preload when the module is imported in a browser context
if (typeof window !== 'undefined') {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', preloadVoices, { once: true });
  } else {
    preloadVoices();
  }
}
