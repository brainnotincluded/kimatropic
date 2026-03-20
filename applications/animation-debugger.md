# Animation Debugger

**Invoke:** `/kimi animation <url-or-element>`
**Patterns:** LENS ARRAY
**Agents used:** kimi-vision (4 instances)
**Desktop control required:** Yes (GIF/video recording)
**Browser tools required:** Yes (for web targets)

## Input

URL or specific element/component with animation issues.

## Stage 1: Capture (Claude)

Record GIF/video of all animations: hover states, scroll triggers, page transitions,
loading spinners, skeleton screens. Record at highest framerate available.

## Stage 2: Parallel Analysis (LENS ARRAY — 4 kimi-vision instances)

| Lens | Evaluates |
|------|-----------|
| Timing & Easing | Duration appropriate? Easing curves natural? Start/end states clean? |
| Performance | Layout thrashing? Paint flashing? Compositor-only animations used? |
| Accessibility | prefers-reduced-motion respected? No seizure-risk flashing? Pauseable? |
| Purpose | Does animation serve UX purpose or is it gratuitous vibe-code? |

## Output

Animation quality report with specific CSS/JS fixes per animation.
