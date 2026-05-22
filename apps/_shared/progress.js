/**
 * progress.js — localStorage progress tracker
 * Harker Prep Curriculum shared module.
 *
 * ES module. Import what you need:
 *   import { markDayComplete, getStars, addStars } from '../_shared/progress.js';
 *
 * Storage layout (all keys prefixed "hpk_"):
 *   hpk_day_{month}_{week}_{day}        → "1"  (day completed flag)
 *   hpk_stars                           → number (total star count)
 *   hpk_sightword_{word}                → "1"  (sight word learned flag)
 *
 * All functions are synchronous (localStorage is sync).
 * Functions never throw — they degrade gracefully if storage is unavailable.
 */

const PREFIX = 'hpk_';

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

function storageAvailable() {
  try {
    const test = '__hpk_test__';
    localStorage.setItem(test, '1');
    localStorage.removeItem(test);
    return true;
  } catch {
    return false;
  }
}

function getItem(key) {
  if (!storageAvailable()) return null;
  return localStorage.getItem(PREFIX + key);
}

function setItem(key, value) {
  if (!storageAvailable()) return;
  localStorage.setItem(PREFIX + key, String(value));
}

function removeItem(key) {
  if (!storageAvailable()) return;
  localStorage.removeItem(PREFIX + key);
}

/**
 * Build the storage key for a specific day slot.
 * @param {number|string} month - 1–6
 * @param {number|string} week  - 1–4
 * @param {number|string} day   - 1–5 (Mon–Fri)
 */
function dayKey(month, week, day) {
  return `day_${month}_${week}_${day}`;
}

// ---------------------------------------------------------------------------
// Day completion
// ---------------------------------------------------------------------------

/**
 * Mark a specific day as complete.
 *
 * @param {number|string} month - 1–6
 * @param {number|string} week  - 1–4
 * @param {number|string} day   - 1–5
 */
export function markDayComplete(month, week, day) {
  setItem(dayKey(month, week, day), '1');
}

/**
 * Check whether a specific day is complete.
 *
 * @param {number|string} month
 * @param {number|string} week
 * @param {number|string} day
 * @returns {boolean}
 */
export function isDayComplete(month, week, day) {
  return getItem(dayKey(month, week, day)) === '1';
}

/**
 * Get progress for an entire week.
 *
 * @param {number|string} month
 * @param {number|string} week
 * @returns {{ completed: number, total: 5 }}
 */
export function getWeekProgress(month, week) {
  let completed = 0;
  for (let d = 1; d <= 5; d++) {
    if (isDayComplete(month, week, d)) completed++;
  }
  return { completed, total: 5 };
}

/**
 * Get progress for an entire month.
 *
 * @param {number|string} month
 * @param {number} weeksInMonth - default 4
 * @returns {{ completed: number, total: number }}
 */
export function getMonthProgress(month, weeksInMonth = 4) {
  let completed = 0;
  const total = weeksInMonth * 5;
  for (let w = 1; w <= weeksInMonth; w++) {
    for (let d = 1; d <= 5; d++) {
      if (isDayComplete(month, w, d)) completed++;
    }
  }
  return { completed, total };
}

// ---------------------------------------------------------------------------
// Stars (reward currency)
// ---------------------------------------------------------------------------

/**
 * Add stars to the running total.
 *
 * @param {number} n - Number of stars to add (positive integer).
 */
export function addStars(n) {
  const current = getStars();
  setItem('stars', Math.max(0, current + Math.round(n)));
}

/**
 * Get the total number of stars earned.
 *
 * @returns {number}
 */
export function getStars() {
  return parseInt(getItem('stars') ?? '0', 10) || 0;
}

/**
 * Remove stars (e.g. for spending). Will not go below zero.
 *
 * @param {number} n - Number of stars to remove.
 * @returns {number} New star total.
 */
export function spendStars(n) {
  const newTotal = Math.max(0, getStars() - Math.round(n));
  setItem('stars', newTotal);
  return newTotal;
}

// ---------------------------------------------------------------------------
// Sight words
// ---------------------------------------------------------------------------

/**
 * Mark a sight word as learned.
 *
 * @param {string} word - The sight word (stored lowercase, trimmed).
 */
export function markSightWord(word) {
  const key = 'sightword_' + String(word).toLowerCase().trim();
  setItem(key, '1');
}

/**
 * Check whether a sight word has been learned.
 *
 * @param {string} word
 * @returns {boolean}
 */
export function isSightWordLearned(word) {
  const key = 'sightword_' + String(word).toLowerCase().trim();
  return getItem(key) === '1';
}

/**
 * Get all learned sight words.
 *
 * @returns {string[]} Array of learned words (lowercase).
 */
export function getSightWordsLearned() {
  if (!storageAvailable()) return [];
  const sightPrefix = PREFIX + 'sightword_';
  return Object.keys(localStorage)
    .filter(k => k.startsWith(sightPrefix) && localStorage.getItem(k) === '1')
    .map(k => k.slice(sightPrefix.length));
}

// ---------------------------------------------------------------------------
// Child name (personalisation)
// ---------------------------------------------------------------------------

/**
 * Set the child's name for personalised greetings.
 *
 * @param {string} name
 */
export function setChildName(name) {
  setItem('child_name', String(name).trim());
}

/**
 * Get the child's name. Returns "Friend" if not set.
 *
 * @returns {string}
 */
export function getChildName() {
  return getItem('child_name') || 'Friend';
}

// ---------------------------------------------------------------------------
// Reset
// ---------------------------------------------------------------------------

/**
 * Reset all progress data. Requires explicit confirmation to prevent accidents.
 *
 * @param {{ confirmed: true }} opts - Must pass { confirmed: true } to proceed.
 * @returns {boolean} true if reset was performed, false if not confirmed.
 */
export function resetAll(opts = {}) {
  if (opts.confirmed !== true) {
    console.warn('progress.resetAll(): pass { confirmed: true } to reset all data.');
    return false;
  }
  if (!storageAvailable()) return false;
  Object.keys(localStorage)
    .filter(k => k.startsWith(PREFIX))
    .forEach(k => localStorage.removeItem(k));
  return true;
}

/**
 * Reset progress for a single week only.
 *
 * @param {number|string} month
 * @param {number|string} week
 */
export function resetWeek(month, week) {
  for (let d = 1; d <= 5; d++) {
    removeItem(dayKey(month, week, d));
  }
}

// ---------------------------------------------------------------------------
// Summary helper (used by lesson-player home screen)
// ---------------------------------------------------------------------------

/**
 * Get a quick summary snapshot for the home screen.
 *
 * @param {number|string} currentMonth
 * @param {number|string} currentWeek
 * @returns {{
 *   childName: string,
 *   stars: number,
 *   weekProgress: { completed: number, total: 5 },
 *   sightWordsCount: number
 * }}
 */
export function getSummary(currentMonth, currentWeek) {
  return {
    childName: getChildName(),
    stars: getStars(),
    weekProgress: getWeekProgress(currentMonth, currentWeek),
    sightWordsCount: getSightWordsLearned().length,
  };
}

// ---------------------------------------------------------------------------
// Per-app word / counter tracking (used by activity apps)
// ---------------------------------------------------------------------------

/**
 * Return the list of words practiced so far for a given app.
 * @param {string} appId  - e.g. 'phonics_blender'
 * @returns {string[]}
 */
export function getPracticed(appId) {
  try {
    return JSON.parse(getItem(`app_${appId}_practiced`) ?? '[]');
  } catch {
    return [];
  }
}

/**
 * Mark a word as practiced for a given app (idempotent).
 * @param {string} appId
 * @param {string} word
 */
export function markPracticed(appId, word) {
  const list = getPracticed(appId);
  if (!list.includes(word)) {
    list.push(word);
    setItem(`app_${appId}_practiced`, JSON.stringify(list));
  }
}

/**
 * Increment a named counter for a given app and return the new value.
 * @param {string} appId
 * @param {string} key   - counter name, e.g. 'blends'
 * @returns {number}
 */
export function increment(appId, key) {
  const current = parseInt(getItem(`app_${appId}_${key}`) ?? '0', 10);
  const next = current + 1;
  setItem(`app_${appId}_${key}`, String(next));
  return next;
}
