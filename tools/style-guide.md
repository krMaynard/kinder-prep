# Image Generation Style Guide
## Social Stories for Early Readers (Ages 3–5)

---

## Visual Style

**Core aesthetic:** Soft watercolor illustration — gently blended washes, no harsh lines or heavy outlines. Warm, inviting color palette (creams, soft blues, gentle yellows, warm oranges). Friendly, rounded character shapes. Every image must be child-safe: no scary elements, no violence, no frightening expressions, no dark or ominous environments.

**Background:** Simple white or very light neutral background (pale cream or sky blue wash). Avoid busy or detailed backgrounds that compete with the central subject.

**Color temperature:** Warm. Avoid cold, clinical, or saturated colors. Preferred palette centers around soft peach, warm yellow, sky blue, mint green, and gentle coral.

---

## Character Consistency

- Characters should appear the same across all pages of a story (same colors, proportions, clothing/markings).
- Human child characters: round face, large expressive eyes, simple clothing in consistent colors. Always appear joyful or curious — never scared or upset.
- Animal characters: clearly friendly, with soft rounded bodies, no sharp teeth visible, and gentle eyes.
- When specifying a recurring character in a prompt, always re-describe their key visual traits (e.g. "a friendly red dog with floppy ears and a wagging tail") to maintain consistency across API calls.
- Characters should be shown at roughly the same scale relative to the frame across pages.

---

## Composition

- **Large central subject:** The main character(s) should fill 50–70% of the frame. Do not place them small in a wide landscape.
- **Minimal detail:** Avoid intricate backgrounds, crowds, or complex scenes. One or two supporting elements (a tree, a bench, a toy) are sufficient.
- **Clear, readable image:** The action or subject should be immediately obvious even at thumbnail size (200×200 px).
- **No text in image:** Never include words, letters, signs, or labels within the illustration itself. Text lives in the app UI only.
- **Safe framing:** Leave a small margin of light background around characters — do not crop figures at the edges.
- **Single moment:** Each image captures one clear action or emotion, not a sequence of events.

---

## Prompt Template

Use this structure when building image generation prompts:

```
Soft watercolor illustration for a children's book. {page_text}
Characters: {child_name} (a friendly 4-year-old child) and {favorite_character}.
Style: warm colors, simple white background, child-safe, no text in image, large clear central subject.
Page {page_num} of {page_count}.
```

Always append: `No text, no letters, no signs in the image.`
