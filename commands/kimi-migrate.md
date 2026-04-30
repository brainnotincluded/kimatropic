---
description: Migration Blitz — parallel migration across many files
argument-hint: <migration spec, e.g. "rename Logger → AppLogger and update imports">
---

Run the **Migration Blitz** swarm application from the kimatropic plugin.

Spec: $ARGUMENTS

Steps:
1. Read `${CLAUDE_PLUGIN_ROOT}/applications/migration-blitz.md`
2. Read `${CLAUDE_PLUGIN_ROOT}/orchestration/assembly-line.md`
3. Identify shards (N file groups) — usually by directory or feature boundary
4. Dispatch one Kimi per shard via `subagent_type: kimatropic:kimi-implementer` with a worktree branch (`--branch shard-N`) so they don't collide
5. Wait for all shards to complete
6. Run tests, integrate branches, resolve conflicts
7. Output: list of shards, status per shard, final diff summary

If spec is empty, ask for the migration definition (what changes, scope, acceptance criteria).
