# ASSEMBLY LINE Pattern

Process work through sequential stages, each adding value.

## Flow

```
Input → Stage 1 Kimi (capture/extract)
     → Claude validates stage 1 output
     → Stage 2 Kimi (analyze/transform)
     → Claude validates stage 2 output
     → Stage N Kimi (generate/finalize)
     → Claude validates final output
```

## When to Use

- Tasks with natural sequential dependencies
- Capture → analyze → generate pipelines
- Multi-step transformations where each step builds on the previous
- When quality gates between stages prevent error propagation

## Claude's Role Between Stages

Claude acts as a quality gate between every stage:

1. **Validate output:** Is the stage output well-formed? Does it meet expectations?
2. **Transform format:** Convert stage N output into stage N+1's expected input format
3. **Add context:** Enrich with information from prior stages
4. **Decision gate:** Continue, retry (same stage with more context), or abort

## Stage Prompt Template

Each stage gets the standard 7-section skeleton, plus:

```markdown
<context>
## Previous Stage Output
{Output from stage N-1 pasted inline — this is your input to work with}

## Original Input
{The original task/input for reference — prevents context drift across stages}

## Stage Position
You are Stage {N} of {TOTAL}. Your output will be used by Stage {N+1} which will
{brief description of next stage's role}. Format your output accordingly.
</context>
```

## Retry Logic

If a stage produces bad output:
1. First retry: Re-dispatch same stage with additional context about what was wrong
2. Second retry: Re-dispatch with simplified expectations (partial output OK)
3. Third failure: Claude takes over that stage manually, then continues pipeline

## Key Principle

Each stage should be independently valuable — if the pipeline stops at any stage,
the output so far should still be useful. Don't defer all value to the final stage.
