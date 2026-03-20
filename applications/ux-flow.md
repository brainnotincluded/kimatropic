# UX Flow Recorder & Analyzer

**Invoke:** `/kimi ux <flow-description-or-script>`
**Patterns:** ASSEMBLY LINE
**Agents used:** kimi-vision (5 instances for analysis)
**Desktop control required:** Yes
**Browser tools required:** Yes (for web targets)

## Input

User journey description or flow script file.

## Stage 1: Flow Execution (Claude)

Execute user journey via browser/desktop control with realistic timing:
1. Follow each step: navigate, click, type, scroll
2. Record full session as video
3. Take timed screenshots (every 3 seconds + at each major action)
4. Measure: time between actions, clicks per task, scroll distance

## Stage 2: Parallel UX Analysis (LENS ARRAY — 5 kimi-vision instances)

| Lens | Evaluates |
|------|-----------|
| Cognitive Load | Choices per screen, information hierarchy, next action obviousness |
| Perceived Speed | Loading states, progress feedback, optimistic UI |
| Error Recovery | Back button behavior, refresh handling, wrong input recovery |
| Learnability | First-time user experience, label clarity, icon comprehension |
| Emotional Design | Satisfaction of interactions, feedback at success/failure |

## Output

UX quality scorecard (0-100 per dimension) with specific improvements.
