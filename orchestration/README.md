# Orchestration Patterns

Composable recipes for coordinating multiple Kimi instances. Claude reads these
documents and follows the instructions when executing swarm applications.

## Pattern Selection Guide

| I need to... | Use Pattern | Why |
|--------------|-------------|-----|
| Analyze something from multiple expert angles | LENS ARRAY | Each Kimi is a specialist, Claude synthesizes |
| Generate multiple solutions and pick the best | ARENA | Diversity beats template; pick or merge |
| Harden code through adversarial build/attack cycles | GAUNTLET | Each round makes code more robust |
| Process through sequential stages | ASSEMBLY LINE | Each stage transforms/enriches the output |
| Get high-confidence diagnosis through consensus | HIVEMIND | Agreement = confidence, disagreement = investigate |

## Combining Patterns

Patterns compose naturally. Common combinations:

- **LENS ARRAY + HIVEMIND:** Analyze from multiple angles, then check for consensus
- **ASSEMBLY LINE + LENS ARRAY:** Sequential stages where one stage fans out to parallel analysis
- **GAUNTLET + LENS ARRAY:** Red-team from multiple angles simultaneously
- **ARENA + GAUNTLET:** Multiple implementations, then harden the winner

## Common Elements

All patterns share:

- **Prompt template:** Every Kimi dispatch uses the 7-section skeleton from `prompt-engineering-principles.md`
- **JSON output:** All Kimi agents return structured JSON for Claude to synthesize
- **Status codes:** DONE / DONE_WITH_CONCERNS / BLOCKED / NEEDS_CONTEXT
- **Severity taxonomy:** Critical / Important / Suggestion (for analysis patterns)
- **Max instances:** 10 Kimis per orchestration (synthesis bottleneck beyond this)
