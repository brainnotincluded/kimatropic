---
description: War Room — structured expert debate for architecture decisions
argument-hint: <decision topic, e.g. "Postgres vs DynamoDB for event store">
---

Run the **War Room** swarm application from the kimatropic plugin.

Topic: $ARGUMENTS

Steps:
1. Read `${CLAUDE_PLUGIN_ROOT}/applications/war-room.md`
2. Read `${CLAUDE_PLUGIN_ROOT}/orchestration/arena.md` for the debate pattern
3. Dispatch via `subagent_type: kimatropic:kimi-council` (which itself spawns N=5 sub-Kimi voices: pragmatist, architect, skeptic, optimizer, user-advocate). Claude is the 6th voice + moderator.
4. Run R rounds (default 3) with Claude synthesizing between rounds
5. Output: ranked options, dissent log, recommended path with reasoning

If topic is empty, ask for the decision and constraints.
