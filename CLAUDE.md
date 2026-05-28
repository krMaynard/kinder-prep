# Harker Prep Curriculum — Claude Instructions

## Project Goal

This repository supports a 6-month curriculum to prepare a gifted 4-year-old for admission to The Harker School. The two primary learning domains are:

1. **Reading** — letter recognition → phonics → decoding → sight words → simple sentence reading
2. **Math** — number sense → counting → basic addition and subtraction within 10

## Repository Layout

- `/curriculum` — lesson plans (weekly, broken into daily activities)
- `/apps` — interactive browser-based tools and games for the child to use
- `/assessments` — milestone checklists and progress logs
- `/resources` — printable worksheets, reference lists, and parent/tutor guides

## When Working in This Repo

- All learning content must be age-appropriate for a 4-year-old: short sessions (10–15 min), bright visuals, positive reinforcement, game-like interactions.
- Interactive apps should run in the browser with no install required — prefer vanilla HTML/CSS/JS or lightweight frameworks.
- Curriculum pacing should be flexible — build in review cycles and assume some days will be skipped.
- Always keep the Harker School admission standard as the success benchmark: the child should demonstrate clear school readiness in literacy and numeracy by month 6.
- When generating lesson plans, follow evidence-based early literacy practices (systematic phonics, phonemic awareness) and early numeracy research (number sense before computation).

## Key Constraints

- Learner age: 4 years old (gifted)
- Timeline: 6 months
- Sessions: ~15 minutes/day, 5 days/week
- Goal: Harker School Kindergarten admission readiness

## PR Self-Review

After pushing a branch and creating a PR, always run `/code-review --comment` against it before considering the work done. Read each changed file as if seeing it for the first time — not as the author who just wrote it. Post findings as inline comments, then fix every actionable one in a follow-up commit before merging.

## LLM API Model Names

Before hardcoding any Gemini (or other LLM) model name, **always confirm the exact model ID with a web search** — do not rely on training-data knowledge. Model names change frequently (preview → stable, version bumps, deprecations) and AI code review tools (e.g. Gemini Code Assist) may themselves have stale knowledge of valid model IDs.

Current models in use (verify before changing):
- Text generation: `gemini-3.1-pro-preview` (fallback: `gemini-3.5-flash`) — check [ai.google.dev/gemini-api/docs/models](https://ai.google.dev/gemini-api/docs/models)
- Image generation: `gemini-3.1-flash-image` (Nano Banana 2, stable) — check [ai.google.dev/gemini-api/docs/image-generation](https://ai.google.dev/gemini-api/docs/image-generation)
