# HIVEMIND Pattern

N Kimis solve the same problem independently. Agreements indicate high confidence.
Disagreements flag areas needing investigation.

## Flow

```
Problem → Claude dispatches N Kimis with identical prompts
       → Each returns their analysis/solution independently
       → Claude compares all N outputs
       → Agreements across ≥70% = high confidence
       → Unique findings from 1-2 = investigate further
       → Direct contradictions = flag for human review
```

## When to Use

- Diagnosis tasks where confidence matters
- Bug root cause analysis
- Architecture evaluation
- Risk assessment
- Any decision where "are we sure?" matters more than speed

## Claude's Role

1. **Prepare identical prompts:** All N Kimis get the EXACT same prompt.
   No hints about expected answers. No leading questions.
   The value comes from independent convergence.

2. **Dispatch in parallel:** 3-5 agents is the sweet spot. More than 5 has
   diminishing returns for consensus quality.

3. **Consensus algorithm:**
   - Parse all N outputs into comparable structures
   - Group similar findings (semantic similarity, not exact string match)
   - Score each finding: consensus_score = (agents_who_found_it / total_agents)
   - High confidence: consensus_score ≥ 0.7
   - Investigate: consensus_score 0.3-0.7
   - Outlier: consensus_score < 0.3 (might be noise OR a unique insight)
   - Contradiction: two findings that directly conflict → flag for human

4. **Report:**
   ```
   ## Consensus Report

   ### High Confidence (≥70% agreement)
   {Findings that most agents independently identified}

   ### Investigate (30-70% agreement)
   {Findings with partial agreement — worth deeper analysis}

   ### Outliers (<30%)
   {Single-agent findings — could be noise or unique insight}

   ### Contradictions
   {Direct conflicts between agents — requires human judgment}

   ### Raw Agent Outputs
   {For transparency — all N outputs preserved}
   ```

## Prompt Template

Standard 7-section skeleton with this addition:

```markdown
<approach>
Analyze this independently. Do NOT try to guess what answer is expected.
Do NOT hedge your findings with "it could be X or Y" — commit to your
best assessment and state your confidence level.

Your analysis will be compared with other independent analyses. The goal
is to find genuine agreement through independent work, not to produce
safe answers.
</approach>
```

## Anti-Pattern

Do NOT give agents any information about what other agents found. This defeats
the purpose of independent consensus. Each agent must work in complete isolation.
