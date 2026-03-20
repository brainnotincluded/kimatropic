# Migration Blitz

**Invoke:** `/kimi migrate <migration-spec>`
**Patterns:** LENS ARRAY + ASSEMBLY LINE
**Agents used:** kimi-researcher (1 for analysis), kimi-implementer (N for parallel migration), kimi-vision (for visual comparison)
**Desktop control required:** Only for visual verification of UI
**Browser tools required:** Only for visual verification of web UI

## Input

Migration specification: what to migrate (e.g., "JS to TS", "React class to hooks",
"API v1 to v2"), scope (which files/directories).

## Stage 1: Analysis (kimi-researcher)

1. Identify all files needing migration
2. Group into independent batches (files without mutual dependencies)
3. If UI: screenshot all pages before migration

## Stage 2: Parallel Migration (N kimi-implementer instances in worktrees)

Each agent gets one batch of files. All run in isolated worktrees.
Each receives: migration spec + batch file list + shared type definitions/interfaces.

## Stage 3: Visual Verification (if UI — LENS ARRAY with kimi-vision)

Screenshot all pages after migration. Fan out to kimi-vision instances
to compare before/after for each page.

## Stage 4: Merge (Claude)

Merge worktrees in dependency order. Resolve conflicts. Run full test suite.

## Output

Fully migrated codebase + visual regression report.
