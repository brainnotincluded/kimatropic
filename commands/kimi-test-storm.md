---
description: Test Storm — 5-angle parallel test generation for a module
argument-hint: <file path or module name>
---

Run the **Test Storm** swarm application from the kimatropic plugin.

Target: $ARGUMENTS

Steps:
1. Read `${CLAUDE_PLUGIN_ROOT}/applications/test-storm.md`
2. Read `${CLAUDE_PLUGIN_ROOT}/orchestration/lens-array.md`
3. Read the target module so you can pass its source as context
4. Dispatch 5 Kimi agents in parallel with `subagent_type: kimatropic:kimi-implementer`, one per angle:
   - Happy path
   - Edge cases (empty, null, max, min)
   - Error paths and exceptions
   - Concurrency / race conditions
   - Property-based / fuzz
5. Collect generated tests, dedupe overlapping cases, integrate into the existing test file or a new one

If target is empty, ask for the file path.
