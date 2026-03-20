# Mega Debug

**Invoke:** `/kimi debug <bug-description>`
**Patterns:** LENS ARRAY + HIVEMIND
**Agents used:** kimi-researcher (5 instances, read-only)
**Desktop control required:** Only if UI bug (screenshot broken state)
**Browser tools required:** Only if web UI bug

## Input

Bug description from user. Optionally: error messages, stack traces, reproduction steps.

## Stage 1: Evidence Capture (Claude — no Kimi)

1. If UI bug: screenshot the broken state, record video of reproduction steps
2. If DevTools visible: screenshot Console, Network, Performance tabs
3. Gather: error logs, recent git changes (`git log --oneline -20`), relevant code files
4. Package all evidence into a capture directory

## Stage 2: Parallel Hypothesis Investigation (LENS ARRAY — 5 kimi-researcher instances)

All 5 agents get the SAME evidence. Each is constrained to read-only analysis.
Each investigates a different hypothesis:

| Lens | Hypothesis | Key Instruction |
|------|-----------|-----------------|
| Data Flow Tracer | Data gets corrupted/transformed wrong | "Trace data from input source to broken output. Find the exact transformation where it goes wrong." |
| Git Archaeologist | Recent change broke it | "Run git log and git bisect on relevant files. Identify the most likely breaking commit and explain why." |
| Edge Case Hunter | Untested input combination | "Identify boundary conditions, null/empty/overflow cases, and character encoding issues that could trigger this bug." |
| Dependency Detective | External dependency issue | "Check package versions, API changes, environment differences, and configuration that could cause this." |
| Visual Forensics | UI rendering issue | "Analyze screenshots for CSS specificity conflicts, z-index issues, overflow problems, layout thrashing." |

Each lens uses the standard LENS ARRAY prompt template with the lens-specific identity and approach.

## Stage 3: Consensus (HIVEMIND)

Claude compares all 5 findings:
- ≥3 agents point to same root cause → HIGH CONFIDENCE diagnosis
- 2 agents agree → MEDIUM CONFIDENCE — investigate further
- All different → present all hypotheses ranked by evidence strength
- Direct contradictions → flag for human review

## Output

Diagnosis report:
- Root cause (with confidence level)
- Evidence supporting the diagnosis
- Proposed fix with specific code changes
- Alternative hypotheses (if confidence < high)
