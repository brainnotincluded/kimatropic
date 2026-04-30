---
description: Mega Debug — 5 parallel Kimi hypotheses for hard-to-find bugs
argument-hint: <bug description, e.g. "login fails intermittently after token refresh">
---

Run the **Mega Debug** swarm application from the kimatropic plugin.

Bug: $ARGUMENTS

Steps:
1. Read `${CLAUDE_PLUGIN_ROOT}/applications/mega-debug.md` for the workflow definition
2. Read `${CLAUDE_PLUGIN_ROOT}/orchestration/lens-array.md` for the dispatch pattern
3. Spawn 5 Kimi hypothesis agents in parallel (race condition, off-by-one, env/config, dependency version, recent commit regression) using the Agent tool with `subagent_type: kimatropic:kimi-researcher`
4. Collect each hypothesis with reasoning + evidence + reproduction steps
5. Synthesize: rank hypotheses by likelihood, flag the most likely root cause, propose a fix

If the bug description is empty, ask the user for: symptom, when it started, what changed recently, repro steps.
