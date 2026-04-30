---
description: Design Intelligence — 6-lens design analysis of a URL or app
argument-hint: <url or path to local app>
---

Run the **Design Intelligence** swarm application from the kimatropic plugin.

Target: $ARGUMENTS

Steps:
1. Read `${CLAUDE_PLUGIN_ROOT}/applications/design-intelligence.md` for the workflow
2. Read `${CLAUDE_PLUGIN_ROOT}/orchestration/lens-array.md` for the dispatch pattern
3. Run `${CLAUDE_PLUGIN_ROOT}/scripts/desktop-preflight.sh` (or `desktop-preflight.js` on Windows) to ensure desktop control works if needed
4. Capture screenshots (browser tools or `desktop-control.py`)
5. Dispatch 6 Kimi vision agents in parallel via the Agent tool with `subagent_type: kimatropic:kimi-vision`, one per lens:
   - Hierarchy & layout
   - Typography & rhythm
   - Color & contrast
   - Interaction & affordance
   - Branding & emotion
   - Accessibility (basic pass — for full a11y use `/kimi-a11y`)
6. Synthesize per the application file: top issues, top wins, ranked recommendations

If target is empty, ask for the URL or app path.
