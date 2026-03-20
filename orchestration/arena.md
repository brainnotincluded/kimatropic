# ARENA Pattern

Generate N independent solutions to the same problem. Evaluate and pick the best
or merge the strongest parts of each.

## Flow

```
Spec → Claude dispatches N kimi-implementer agents in parallel (isolated worktrees)
    → Each produces a complete solution independently
    → Claude evaluates all solutions against criteria
    → Picks best OR merges best parts from each
```

## When to Use

- Implementation tasks where diversity beats template
- Anti-vibe-code: 3 independent solutions are structurally different
- Prototyping where you want to compare approaches
- Any task where "there's more than one right way"

## Claude's Role

1. **Prepare identical prompts:** All N agents get the SAME spec. Diversity comes from
   model stochasticity. Add ONE line for differentiation:
   "Choose a novel approach — other agents are solving this simultaneously.
   The most unique, clean solution wins."

2. **Dispatch with isolation:** Each agent runs in a separate worktree (use --branch).
   This prevents file conflicts between parallel implementations.

3. **Evaluate all solutions:**
   - Spec compliance: does it actually do what was asked?
   - Code quality: readability, structure, naming, test coverage
   - Anti-vibe-code score: uniqueness of approach, no template patterns
   - Performance characteristics

4. **Merge or pick:**
   - If one solution is clearly best → use it directly
   - If solutions have complementary strengths → create a NEW implementation
     that takes the best architectural decisions from each
   - NEVER copy-paste code blocks from multiple solutions (creates Frankenstein code)

## Prompt Template

Same as kimi-implementer task prompt (7-section skeleton) with this addition
in the <approach> section:

```
You are one of N agents solving this independently. Another agent may build
something completely different — that's expected. Focus on writing the CLEANEST,
most ORIGINAL solution you can. Avoid default patterns from UI component libraries.
Make deliberate design choices, not template choices.
```

## Evaluation Criteria

Claude rates each solution 1-5 on:

| Criterion | 1 (worst) | 5 (best) |
|-----------|-----------|----------|
| Correctness | Missing features | All spec requirements met |
| Originality | Copy-paste template | Novel approach with clear reasoning |
| Code Quality | Messy, unclear | Clean, readable, well-structured |
| Completeness | Missing error/loading states | All states handled |
