# Code Gauntlet

**Invoke:** `/kimi gauntlet <task-description>`
**Patterns:** GAUNTLET
**Agents used:** kimi-implementer (build/fix), kimi-researcher (red-team, read-only), kimi-vision (visual red-team)
**Desktop control required:** Yes if UI (screenshot after each round)
**Browser tools required:** Yes if web UI

## Input

Implementation task description with acceptance criteria.

## Workflow

Follow the GAUNTLET pattern from `orchestration/gauntlet.md`:

### Round 1
1. Dispatch kimi-implementer with the task spec
2. Claude captures screenshots/video of result (if UI)
3. Dispatch kimi-researcher (read-only) + kimi-vision with code + visuals
4. Red-team produces findings JSON

### Round 2
5. Dispatch kimi-implementer with original spec + Round 1 red-team findings
6. Claude re-captures visuals
7. Dispatch new kimi-researcher + kimi-vision for second red-team

### Round 3 (if needed)
8. Same as Round 2 with Round 2 findings
9. Claude judges: 0 critical/important issues? → Done

### Stop Criteria
- Red-team finds 0 Critical and 0 Important issues → STOP, report success
- Max 3 rounds. After round 3, Claude takes over remaining issues.

## Output

Battle-hardened implementation with:
- Final code (all issues from all rounds fixed)
- Red-team report history (all rounds preserved)
- Vibe-code score (from visual red-team)
- Remaining suggestions (non-blocking)
