# LENS ARRAY Pattern

Analyze the same input from N different expert perspectives simultaneously.

## Flow

```
Input → Claude prepares N prompts (one per lens)
     → Dispatches N kimi-vision or kimi-researcher agents in parallel
     → Each returns structured findings from their expert perspective
     → Claude synthesizes into holistic analysis
```

## When to Use

- Analysis tasks where multiple perspectives add value
- Design review, code review, debugging, reverse engineering
- Any task where you'd want 5 different experts looking at the same thing

## Claude's Role

1. **Prepare lens prompts:** For each lens, create a prompt using the 7-section skeleton.
   CRITICAL: Include explicit boundary telling each agent what OTHER lenses cover
   so it doesn't duplicate work.

2. **Dispatch in parallel:** Use the Agent tool to launch N kimi-vision or kimi-researcher
   agents simultaneously. Each gets a different lens prompt but the SAME input data.

3. **Collect results:** Wait for all N agents to return.

4. **Synthesize:**
   - Group findings by severity (Critical → Important → Suggestion)
   - Identify agreements (finding appears in 2+ lenses) → high confidence
   - Identify unique insights (single-lens findings) → worth investigating
   - Produce merged report with attribution (which lens found what)

## Lens Prompt Template

```markdown
<identity>
You are a {LENS_ROLE} analyzing {INPUT_TYPE}.
{DETAILED_BEHAVIORAL_DESCRIPTION — what to prioritize, how to approach,
what makes this lens different from others}
</identity>

<objective>
Analyze the provided {INPUT_TYPE} exclusively through the lens of {FOCUS_AREA}.
Produce structured findings with severity ratings and actionable recommendations.
</objective>

<context>
{ALL input data pasted inline — file contents, screenshot paths, code snippets.
Never reference external files the agent cannot access.}
</context>

<approach>
Focus EXCLUSIVELY on {FOCUS_AREA}. Other agents are handling: {LIST_OTHER_LENSES}.
Do NOT analyze those aspects. If you notice something outside your lens that seems
critical, note it briefly in the "cross_cutting" field but do not investigate.

Spend ~70% of effort on identifying issues, ~30% on recommending fixes.
</approach>

<output>
Return this exact JSON structure:
{
  "lens": "{LENS_NAME}",
  "status": "DONE|DONE_WITH_CONCERNS|BLOCKED|NEEDS_CONTEXT",
  "findings": [
    {
      "severity": "critical|important|suggestion",
      "title": "short description",
      "description": "detailed finding with evidence",
      "location": "file path, line number, or visual region",
      "evidence": "screenshot filename or code snippet",
      "recommendation": "specific fix suggestion"
    }
  ],
  "cross_cutting": ["brief notes about other lens areas if critical"],
  "summary": "one paragraph overall assessment",
  "confidence": "high|medium|low"
}
</output>

<checklist>
Before submitting:
- [ ] Did I focus exclusively on my lens area?
- [ ] Does every finding have evidence and a recommendation?
- [ ] Did I assign appropriate severity levels?
- [ ] Is my output valid JSON matching the schema?
</checklist>

<escalation>
If you cannot analyze the input (corrupted file, missing context, task too ambiguous):
set status to BLOCKED and explain what's needed. Bad analysis is worse than no analysis.
</escalation>

<anti-patterns>
- Do NOT produce generic praise ("overall good design"). Every statement must be specific.
- Do NOT duplicate work of other lenses. Stay in your lane.
- Do NOT claim "everything looks fine" without evidence of thorough checking.
- Do NOT rate everything as "suggestion" to avoid conflict. Use Critical when warranted.
</anti-patterns>
```

## Synthesis Template

Claude uses this to merge N lens outputs:

```markdown
## {APPLICATION_NAME} Report

### Critical Issues (must address)
{Grouped by topic, attributed to lens that found them.
Issues found by 2+ lenses get a ⚡ high-confidence marker.}

### Important Issues (should address)
{Same grouping and attribution.}

### Suggestions
{Brief list, no deep analysis.}

### Cross-Cutting Observations
{Items flagged by agents outside their lens — may need separate investigation.}

### Lens Coverage
| Lens | Findings | Confidence |
|------|----------|------------|
{Table of all lenses with count and confidence level}
```
