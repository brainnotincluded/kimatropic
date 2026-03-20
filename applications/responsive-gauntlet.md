# Responsive Gauntlet

**Invoke:** `/kimi responsive <url-or-app>`
**Patterns:** ASSEMBLY LINE + LENS ARRAY
**Agents used:** kimi-vision (1 for breakpoint detection + 5 per breakpoint for analysis)
**Desktop control required:** Yes (window resize + screenshots)
**Browser tools required:** Yes (for web targets)

## Input

URL or application to test responsively.

## Stage 1: Continuous Resize (Claude + desktop control)

1. Open URL or focus app
2. Record video while resizing window from 1920px → 320px width
   (use desktop-control.py window-resize in steps of ~50px with 0.5s delay)
3. Send resize video to kimi-vision to identify breakpoints where layout shifts

## Stage 2: Breakpoint Screenshots (Claude)

Screenshot at each identified breakpoint width.

## Stage 3: Per-Breakpoint Analysis (LENS ARRAY — 5 kimi-vision per breakpoint)

| Lens | Checks |
|------|--------|
| Text Readability | Font sizes, line lengths (45-75 chars optimal), truncation, overflow |
| Touch Targets | Button/link sizes ≥44px on mobile, spacing between tap targets |
| Image Scaling | Images resize properly, no overflow, appropriate resolution |
| Navigation | Menu transforms correctly, hamburger works, all links reachable |
| Content Priority | Important content visible without scroll, no hidden critical info |

## Output

Responsive audit with specific pixel values where things break + CSS fixes.
