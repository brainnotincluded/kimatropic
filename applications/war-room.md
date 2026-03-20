# War Room

**Invoke:** `/kimi war-room <topic>`
**Patterns:** HIVEMIND
**Agents used:** kimi-researcher (5 instances, read-only)
**Desktop control required:** No
**Browser tools required:** No

## Input

Architecture question or technical decision with trade-offs.

## Workflow

### Setup: Role Assignment
Dispatch 5 kimi-researcher agents (read-only), each with a distinct expert role:

| Role | Priority Bias | Key Question |
|------|--------------|--------------|
| Security Engineer | Safety, attack surface | "How can this be exploited?" |
| Performance Engineer | Speed, scalability | "What happens at 10x load?" |
| UX Advocate | User experience, accessibility | "Will a real human understand this?" |
| Maintenance Engineer | Long-term maintainability | "Will we regret this in 6 months?" |
| Domain Expert | Business logic correctness | "Does this actually solve the problem?" |

### Round 1: Position Statements
Each expert states their view with reasoning. All dispatched in parallel.

### Round 2: Steel-Manning
Each expert must make the STRONGEST case for their LEAST preferred option.
Claude passes Round 1 outputs to each expert with the instruction:
"Now argue FOR the option you liked LEAST. Make the strongest possible case."

### Round 3: Final Recommendations
Each expert gives final recommendation with explicit trade-offs acknowledged.
Claude passes Rounds 1+2 to each expert.

## Synthesis (Claude)

Produce an Architecture Decision Record (ADR):
- Decision
- Context
- Options considered (with genuine pros/cons from each expert)
- Decision rationale
- Consequences and trade-offs accepted
- Dissenting opinions (preserved, not hidden)

## Output

ADR document ready to commit to project docs.
