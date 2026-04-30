---
description: Reverse Engineering — 6-lens parallel codebase mapping
argument-hint: <repo path or module>
---

Run the **Reverse Engineering** swarm application from the kimatropic plugin.

Target: $ARGUMENTS

Steps:
1. Read `${CLAUDE_PLUGIN_ROOT}/applications/reverse-engineering.md`
2. Read `${CLAUDE_PLUGIN_ROOT}/orchestration/lens-array.md`
3. Dispatch 6 Kimi agents in parallel via `subagent_type: kimatropic:kimi-researcher`, each with a different lens prompt:
   - Entry points & request flow
   - Data model & persistence
   - Dependency graph & boundaries
   - Build/deploy/runtime
   - Test coverage & gaps
   - Hidden coupling & dead code
4. Each Kimi must run with read-only constraint (prepend "analyze only, do not modify files" to prompts since Kimi runs --yolo)
5. Synthesize: architecture map, coupling diagram (text), risk hotspots, recommended onboarding reading order

If target is empty, default to the current working directory.
