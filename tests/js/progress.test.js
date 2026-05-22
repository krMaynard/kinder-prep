import { describe, it, expect, beforeEach } from 'vitest';
import {
  markDayComplete, isDayComplete, getWeekProgress,
  addStars, getStars,
  markSightWord, isSightWordLearned, getSightWordsLearned,
  setChildName, getChildName,
  resetAll,
  getPracticed, markPracticed, increment,
} from '../../apps/_shared/progress.js';

// Clear storage before each test so tests are fully isolated.
beforeEach(() => {
  resetAll({ confirmed: true });
});

// ---------------------------------------------------------------------------
// API contract — every function an app calls must actually be exported
// ---------------------------------------------------------------------------
describe('export contract', () => {
  const required = [
    // called by phonics-blender
    'getPracticed', 'markPracticed', 'increment',
    // called by lesson-player
    'getStars', 'getWeekProgress', 'getChildName', 'setChildName',
    // core API
    'markDayComplete', 'isDayComplete', 'addStars',
    'markSightWord', 'isSightWordLearned', 'getSightWordsLearned', 'resetAll',
  ];

  it.each(required)('%s is exported as a function', (name) => {
    const exports = {
      markDayComplete, isDayComplete, getWeekProgress,
      addStars, getStars,
      markSightWord, isSightWordLearned, getSightWordsLearned,
      setChildName, getChildName, resetAll,
      getPracticed, markPracticed, increment,
    };
    expect(typeof exports[name]).toBe('function');
  });
});

// ---------------------------------------------------------------------------
// getPracticed / markPracticed
// ---------------------------------------------------------------------------
describe('getPracticed', () => {
  it('returns [] for a fresh app', () => {
    expect(getPracticed('phonics_blender')).toEqual([]);
  });

  it('reflects words added with markPracticed', () => {
    markPracticed('phonics_blender', 'cat');
    markPracticed('phonics_blender', 'dog');
    const list = getPracticed('phonics_blender');
    expect(list).toContain('cat');
    expect(list).toContain('dog');
  });

  it('is idempotent — no duplicate entries', () => {
    markPracticed('phonics_blender', 'cat');
    markPracticed('phonics_blender', 'cat');
    expect(getPracticed('phonics_blender').filter(w => w === 'cat')).toHaveLength(1);
  });

  it('isolates words per appId', () => {
    markPracticed('app_a', 'cat');
    expect(getPracticed('app_b')).not.toContain('cat');
  });
});

// ---------------------------------------------------------------------------
// increment
// ---------------------------------------------------------------------------
describe('increment', () => {
  it('starts at 1 on first call', () => {
    expect(increment('phonics_blender', 'blends')).toBe(1);
  });

  it('returns successive integers on repeated calls', () => {
    increment('phonics_blender', 'blends');
    increment('phonics_blender', 'blends');
    expect(increment('phonics_blender', 'blends')).toBe(3);
  });

  it('isolates counters per key', () => {
    increment('phonics_blender', 'blends');
    expect(increment('phonics_blender', 'words')).toBe(1);
  });

  it('isolates counters per appId', () => {
    increment('app_a', 'blends');
    expect(increment('app_b', 'blends')).toBe(1);
  });
});

// ---------------------------------------------------------------------------
// Stars
// ---------------------------------------------------------------------------
describe('stars', () => {
  it('starts at 0', () => {
    expect(getStars()).toBe(0);
  });

  it('accumulates across multiple addStars calls', () => {
    addStars(3);
    addStars(2);
    expect(getStars()).toBe(5);
  });
});

// ---------------------------------------------------------------------------
// Day completion
// ---------------------------------------------------------------------------
describe('day completion', () => {
  it('is false before being marked', () => {
    expect(isDayComplete(1, 1, 1)).toBe(false);
  });

  it('is true after markDayComplete', () => {
    markDayComplete(1, 1, 1);
    expect(isDayComplete(1, 1, 1)).toBe(true);
  });

  it('getWeekProgress counts completed days', () => {
    markDayComplete(1, 1, 1);
    markDayComplete(1, 1, 3);
    const { completed, total } = getWeekProgress(1, 1);
    expect(completed).toBe(2);
    expect(total).toBe(5);
  });

  it('isolates days across weeks', () => {
    markDayComplete(1, 1, 1);
    expect(isDayComplete(1, 2, 1)).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// Sight words
// ---------------------------------------------------------------------------
describe('sight words', () => {
  it('isSightWordLearned returns false initially', () => {
    expect(isSightWordLearned('the')).toBe(false);
  });

  it('isSightWordLearned returns true after markSightWord', () => {
    markSightWord('the');
    expect(isSightWordLearned('the')).toBe(true);
  });

  it('getSightWordsLearned reflects all marked words', () => {
    markSightWord('the');
    markSightWord('and');
    expect(getSightWordsLearned()).toContain('the');
    expect(getSightWordsLearned()).toContain('and');
  });
});

// ---------------------------------------------------------------------------
// Child name
// ---------------------------------------------------------------------------
describe('child name', () => {
  it("returns 'Friend' as the default when no name has been set", () => {
    expect(getChildName()).toBe('Friend');
  });

  it('returns the set name', () => {
    setChildName('Luca');
    expect(getChildName()).toBe('Luca');
  });
});

// ---------------------------------------------------------------------------
// resetAll
// ---------------------------------------------------------------------------
describe('resetAll', () => {
  it('is a no-op without confirmed:true', () => {
    addStars(5);
    resetAll({});
    expect(getStars()).toBe(5);
  });

  it('is a no-op when called with no argument', () => {
    addStars(5);
    resetAll();
    expect(getStars()).toBe(5);
  });

  it('clears stars when confirmed', () => {
    addStars(5);
    resetAll({ confirmed: true });
    expect(getStars()).toBe(0);
  });

  it('clears practiced words when confirmed', () => {
    markPracticed('phonics_blender', 'cat');
    resetAll({ confirmed: true });
    expect(getPracticed('phonics_blender')).toEqual([]);
  });
});
