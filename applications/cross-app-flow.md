# Cross-App Flow Tester

**Invoke:** `/kimi flow-test <flow-script>`
**Patterns:** ASSEMBLY LINE + LENS ARRAY
**Agents used:** kimi-vision (4 instances for analysis)
**Desktop control required:** Yes (essential — drives multiple apps)
**Browser tools required:** May be used for web apps in the flow

## Input

Flow script file defining a cross-application workflow.

## Stage 1: Execution (Claude via desktop control)

1. Read flow script (DSL format from screen-capture.sh)
2. Execute each step: open apps, click, type, copy, paste, switch windows
3. Record video of entire flow
4. Screenshot at each app transition point

## Stage 2: Parallel Analysis (LENS ARRAY — 4 kimi-vision instances)

| Lens | Evaluates |
|------|-----------|
| Data Integrity | Data preserved across app boundaries? Formatting maintained? |
| Timing | Transitions smooth? No lost focus? No race conditions? |
| Error Recovery | What if an app closes mid-flow? Clipboard overwritten? |
| Completeness | All expected outcomes visible in final state? |

## Output

Cross-app flow test report with pass/fail per step and issues found.
