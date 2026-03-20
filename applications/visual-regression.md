# Visual Regression Swarm

**Invoke:** `/kimi visual-diff [--before <commit>] [--after <commit>]`
**Patterns:** LENS ARRAY
**Agents used:** kimi-vision (N instances, one per page/state)
**Desktop control required:** Yes (screenshots)
**Browser tools required:** Yes (for web)

## Input

Optional before/after commit references. Default: before=HEAD~1, after=HEAD.

## Workflow

1. Claude creates worktree at `before` commit, starts dev server, screenshots every page
2. Claude screenshots every page from current (`after`) working tree
3. Fans out to N kimi-vision instances, each comparing one page pair (before vs after)
4. Each Kimi reports: layout shifts, color changes, typography changes, missing/new elements

## Key Differentiator

Kimi understands SEMANTIC changes, not just pixel diffs:
- "Button moved 2px right" → IGNORE (insignificant)
- "Button now overlaps footer" → CRITICAL (layout break)
- "Color changed from #333 to #334" → IGNORE (imperceptible)
- "Primary CTA invisible on dark background" → CRITICAL (usability break)

## Output

Visual regression report with severity ratings per page/component.
