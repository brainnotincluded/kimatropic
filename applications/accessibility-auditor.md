# Accessibility Auditor

**Invoke:** `/kimi a11y <url-or-app>`
**Patterns:** LENS ARRAY + GAUNTLET
**Agents used:** kimi-vision (5 instances)
**Desktop control required:** Yes (keyboard navigation, zoom, high contrast)
**Browser tools required:** Yes (for web targets)

## Input

URL or application to audit.

## Stage 1: Multi-Mode Capture (Claude — 5 capture modes)

| Mode | How to Capture |
|------|---------------|
| Keyboard-only | Navigate using ONLY Tab/Enter/Escape/Arrow keys. Record video of entire session. |
| High contrast | Enable OS high-contrast mode. Screenshot all pages. |
| Zoom 200% | Set browser/app to 200% zoom. Screenshot all pages. |
| Reduced motion | Enable prefers-reduced-motion. Record video of all animations. |
| Extreme widths | Screenshot at 320px and 2560px widths. |

## Stage 2: Parallel Analysis (LENS ARRAY — 5 kimi-vision instances)

Each instance gets ONE capture mode's output and evaluates that specific aspect:
- Keyboard: reachability, focus visibility, tab order, keyboard traps
- Contrast: text readability, icon distinguishability, focus indicators
- Zoom: layout integrity, no horizontal scroll, text doesn't overflow
- Motion: animations disabled, no essential info in animations only
- Widths: usable at extremes, no hidden critical content

## Output

WCAG 2.1 AA compliance report with specific failures and CSS/HTML fixes.
