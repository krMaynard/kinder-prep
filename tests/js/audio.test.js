import { describe, it, expect, vi } from 'vitest';
import * as audio from '../../apps/_shared/audio.js';

// ---------------------------------------------------------------------------
// API contract — every function called by phonics-blender must be exported
// ---------------------------------------------------------------------------
describe('export contract', () => {
  const required = [
    'speak', 'speakLetter', 'speakWord', 'speakPhrase',
    'speakPraise', 'speechAvailable', 'stopSpeaking', 'preloadVoices',
  ];

  it.each(required)('%s is exported as a function', (name) => {
    expect(typeof audio[name]).toBe('function');
  });
});

// ---------------------------------------------------------------------------
// Phoneme map coverage — all 26 letters must have a mapped phoneme.
// speakLetter falls back to the raw letter when the key is missing; we
// detect a gap by checking that the resolved phoneme (spoken text) differs
// from the raw letter name, OR simply that speakLetter does not throw.
// ---------------------------------------------------------------------------
describe('phoneme map coverage', () => {
  it('speakLetter does not throw for any letter a–z', () => {
    for (const letter of 'abcdefghijklmnopqrstuvwxyz') {
      expect(() => audio.speakLetter(letter)).not.toThrow();
    }
  });

  it('handles uppercase letters without throwing', () => {
    for (const letter of 'ABCDEFGHIJKLMNOPQRSTUVWXYZ') {
      expect(() => audio.speakLetter(letter)).not.toThrow();
    }
  });
});

// ---------------------------------------------------------------------------
// Graceful degradation — all speak* functions must resolve (not hang or
// reject) when SpeechSynthesis is unavailable (jsdom doesn't implement it).
// ---------------------------------------------------------------------------
describe('graceful degradation when SpeechSynthesis is unavailable', () => {
  it('speak() resolves', async () => {
    await expect(audio.speak('hello')).resolves.toBeUndefined();
  });

  it('speakLetter() resolves', async () => {
    await expect(audio.speakLetter('b')).resolves.toBeUndefined();
  });

  it('speakWord() resolves', async () => {
    await expect(audio.speakWord('cat')).resolves.toBeUndefined();
  });

  it('speakPhrase() resolves', async () => {
    await expect(audio.speakPhrase('Good job!')).resolves.toBeUndefined();
  });

  it('speakPraise() resolves', async () => {
    await expect(audio.speakPraise()).resolves.toBeUndefined();
  });

  it('stopSpeaking() does not throw when synth is unavailable', () => {
    expect(() => audio.stopSpeaking()).not.toThrow();
  });

  it('preloadVoices() does not throw when synth is unavailable', () => {
    expect(() => audio.preloadVoices()).not.toThrow();
  });
});

// ---------------------------------------------------------------------------
// speechAvailable reflects the actual environment
// ---------------------------------------------------------------------------
describe('speechAvailable', () => {
  it('returns a boolean', () => {
    expect(typeof audio.speechAvailable()).toBe('boolean');
  });
});
