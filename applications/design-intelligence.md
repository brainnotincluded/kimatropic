# Design Intelligence

**Invoke:** `/kimi design <url-or-app>`
**Patterns:** ASSEMBLY LINE + LENS ARRAY
**Agents used:** kimi-vision (6 instances for analysis)
**Desktop control required:** Yes (viewport screenshots, GIF recording)
**Browser tools required:** Yes (navigation, page text extraction)

## Input

User provides a URL or application name. Optionally specifies whether this is:
- Analysis of their OWN site (output: actionable fix list)
- Analysis of a REFERENCE site (output: reusable design system spec)

## Stage 1: Capture (Claude — no Kimi)

Claude performs all capture using browser tools + desktop control:

1. Navigate to URL (or focus app via desktop-control.py)
2. Run `screen-capture.sh screenshot-viewports <output-dir>` for 5 viewport sizes
3. Record GIF of hover states on all interactive elements (use browser tools)
4. Record 30-second video of typical navigation flow
5. Extract page text, CSS custom properties, meta tags (use browser tools / get_page_text)
6. Save everything to `$TMPDIR/kimatropic-design-<timestamp>/`

**Output of Stage 1:** A directory with:
- `desktop-1920x1080.png`, `laptop-1440x900.png`, `tablet-landscape-1024x768.png`,
  `tablet-portrait-768x1024.png`, `mobile-375x812.png`
- `interactions.gif` (hover states, clicks)
- `navigation.mp4` (30s flow)
- `page-text.txt` (extracted text content)
- `css-variables.json` (custom properties)

## Stage 2: Parallel Analysis (LENS ARRAY — 6 kimi-vision instances)

Dispatch 6 kimi-vision agents in parallel, each with a different lens.
All receive the same capture directory path.

### Lens 1: Typography

```markdown
<identity>
You are a typography specialist analyzing a website's type system. You evaluate
font choices, size scales, weight hierarchy, line heights, letter spacing, and
readability across viewport sizes. You think in terms of modular scales, type
pairing theory, and legibility research. Prioritize hierarchy clarity and
readability over aesthetic preference.
</identity>

<objective>
Produce a complete typography audit of this site with specific font values,
scale analysis, and readability assessment at each viewport size.
</objective>

<context>
Capture directory: {CAPTURE_DIR}
Screenshots at 5 viewports: desktop-1920x1080.png, laptop-1440x900.png,
tablet-landscape-1024x768.png, tablet-portrait-768x1024.png, mobile-375x812.png
CSS variables: {CSS_VARIABLES_JSON}
Page text: {PAGE_TEXT}
</context>

<approach>
Focus EXCLUSIVELY on typography. Other agents are handling: color system,
layout/spacing, component patterns, motion/interaction, vibe-code detection.
Do NOT analyze those aspects.

Analyze each viewport screenshot for:
- Font families used (identify specific typefaces)
- Size scale (is it modular? what ratio? how many steps?)
- Weight distribution across heading levels
- Line height patterns (comfortable reading? too tight? too loose?)
- Letter spacing on headings vs body text
- Maximum line length in characters (45-75 is optimal range)
- Text contrast against backgrounds

Spend ~70% on analysis, ~30% on recommendations.
</approach>

<output>
{
  "lens": "typography",
  "status": "DONE",
  "findings": [
    {
      "severity": "critical|important|suggestion",
      "title": "short description",
      "description": "detailed finding with measurements",
      "location": "viewport/section where observed",
      "evidence": "screenshot filename + region description",
      "recommendation": "specific CSS fix"
    }
  ],
  "type_system": {
    "primary_font": "font name",
    "secondary_font": "font name or null",
    "scale_ratio": 1.25,
    "scale_steps": ["12px", "14px", "16px", "20px", "24px", "32px", "48px"],
    "heading_weights": {"h1": 700, "h2": 600, "h3": 500},
    "body_line_height": 1.6,
    "max_line_length_chars": 72
  },
  "cross_cutting": [],
  "summary": "one paragraph overall typography assessment",
  "confidence": "high|medium|low"
}
</output>

<checklist>
- [ ] Identified all font families used
- [ ] Measured or estimated size scale
- [ ] Checked readability at mobile viewport
- [ ] Checked line length at desktop viewport
- [ ] Compared heading hierarchy across viewports
</checklist>

<escalation>
If screenshots are too low quality to read text, report BLOCKED.
</escalation>

<anti-patterns>
- Do NOT comment on colors, layout, or animations.
- Do NOT say "nice typography" without measurements to back it up.
- Do NOT ignore mobile viewport — it's where most type problems appear.
</anti-patterns>
```

### Lens 2: Color System

Same skeleton as Lens 1 with these substitutions:
- **Identity:** Color theorist analyzing palette, gradients, shadows, themes, contrast ratios
- **Focus:** Color palette extraction, dark/light mode analysis, contrast compliance, shadow system, gradient usage
- **Output.color_system:** `{primary, secondary, accent, neutral_scale, gradients[], shadows[], contrast_issues[]}`
- **Boundary:** "Other agents handle typography, layout, components, motion, vibe-code"

### Lens 3: Layout & Spacing

Same skeleton with:
- **Identity:** Grid architect analyzing spatial system, breakpoints, alignment
- **Focus:** Grid system identification, spacing scale, margin/padding patterns, breakpoint behavior, alignment consistency
- **Output.layout_system:** `{grid_type, columns, gutter, spacing_scale[], breakpoints[], alignment_issues[]}`
- **Boundary:** "Other agents handle typography, color, components, motion, vibe-code"

### Lens 4: Component Patterns

Same skeleton with:
- **Identity:** UI component cataloger identifying and classifying every distinct component type
- **Focus:** Button variants, card styles, form elements, navigation patterns, modal/dialog patterns, lists, media objects
- **Output.component_catalog:** `[{name, variants, props, usage_count, consistency_issues}]`
- **Boundary:** "Other agents handle typography, color, layout, motion, vibe-code"

### Lens 5: Motion & Interaction

Same skeleton with:
- **Identity:** Animation expert analyzing timing, transitions, scroll effects, hover behaviors
- **Focus:** Transition durations, easing curves, scroll-triggered animations, hover state quality, loading transitions, page transitions
- **Input:** GIF file + video file in addition to screenshots
- **Output.motion_system:** `{transitions[], animations[], scroll_effects[], hover_states[], easing_curves[]}`
- **Boundary:** "Other agents handle typography, color, layout, components, vibe-code"

### Lens 6: Vibe-Code Detector

Same skeleton with:
- **Identity:** Quality auditor specializing in detecting AI-generated, template-driven, superficially polished but functionally hollow websites
- **Focus:** Empty links/buttons, AI-generated copy, Shadcn/Tailwind defaults, excessive glassomorphism, broken responsive, div soup (from DOM if available)
- **Output.vibe_code_report:** `{score: 0-100, verdict, visual_smells[], functional_smells[], content_smells[], code_smells[]}`
- **Boundary:** "Other agents handle specific design system analysis. You assess overall authenticity and quality."

## Stage 3: Synthesis (Claude — no Kimi)

Claude collects all 6 JSON outputs and produces a **Design DNA** document:

1. Merge findings by severity (Critical → Important → Suggestion)
2. Mark high-confidence findings (identified by 2+ lenses)
3. Compile design tokens:
   - Typography tokens from Lens 1
   - Color tokens from Lens 2
   - Spacing tokens from Lens 3
4. Compile component catalog from Lens 4
5. Compile motion system from Lens 5
6. Calculate overall vibe-code score from Lens 6
7. If analyzing OWN site: prioritized fix list
8. If analyzing REFERENCE site: reusable design system specification

## Output

A Design DNA document with sections:
- Design Tokens (CSS custom properties ready to use)
- Component Catalog with variants
- Motion System description
- Vibe-Code Score (0-100) with specific smells
- Prioritized improvements list
