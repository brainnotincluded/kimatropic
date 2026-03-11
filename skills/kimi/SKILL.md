---
name: kimi
description: Manually delegate any task to Kimi K2.5. Use as /kimi <task description> to force-delegate a task regardless of auto-routing rules. Supports optional mode flags.
---

# Kimi Manual Delegation

Force-delegate a task to Kimi K2.5 regardless of auto-routing rules.

## Usage

- `/kimi <task>` — delegate using kimi-implementer (default)
- `/kimi research <task>` — delegate using kimi-researcher
- `/kimi vision <task>` — delegate using kimi-vision
- `/kimi swarm <task>` — delegate using kimi-swarm

## Behavior

When invoked, dispatch the task to the appropriate Kimi subagent:

1. Parse the user's input to determine the mode:
   - If starts with "research" → use `kimi-researcher` agent
   - If starts with "vision" → use `kimi-vision` agent
   - If starts with "swarm" → use `kimi-swarm` agent
   - Otherwise → use `kimi-implementer` agent

2. Launch the selected subagent with the task description using the Agent tool

3. When the subagent returns, present the summary JSON to the user in a readable format:
   - Status (success/failed/partial)
   - Files changed (modified, created, deleted)
   - Summary text
   - Any warnings or errors
   - Wall time

4. If status is "failed", ask the user whether to:
   - Retry with Kimi (more context)
   - Handle it yourself (Opus takes over)
   - Abandon the task

## Auto-routing Reminder

When NOT using /kimi (normal conversation), auto-delegate to Kimi when:
- Batch file operations (refactor N files, rename patterns)
- Implementation with clear spec and acceptance criteria
- Image/video analysis
- Test generation or boilerplate
- Task decomposes into 3+ independent parallel chunks
- Deep codebase exploration/research

Keep on Opus when:
- Architecture decisions, system design
- Ambiguous requirements needing user clarification
- Security-sensitive code review
- Cross-cutting architectural concerns
- Coordinating the overall plan
- Tasks with tight sequential dependencies
