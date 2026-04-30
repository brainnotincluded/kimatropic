---
description: Code Gauntlet — adversarial hardening of user-facing features
argument-hint: <task or PR description>
---

Run the **Code Gauntlet** swarm application from the kimatropic plugin.

Task: $ARGUMENTS

Steps:
1. Read `${CLAUDE_PLUGIN_ROOT}/applications/code-gauntlet.md`
2. Read `${CLAUDE_PLUGIN_ROOT}/orchestration/gauntlet.md` for the adversarial pattern
3. Run a builder Kimi (`kimatropic:kimi-implementer`) to implement the feature
4. Dispatch in parallel: security adversary, perf adversary, UX adversary, edge-case adversary (each via `kimatropic:kimi-researcher` with role-specific prompts)
5. Collect attacks, fix them, repeat until each adversary signs off OR escalate to user
6. Output: hardened code + audit log of attacks/fixes

If task is empty, ask what feature to harden.
