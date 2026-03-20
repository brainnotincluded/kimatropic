# Test Storm

**Invoke:** `/kimi test-storm <target-file-or-module>`
**Patterns:** ARENA + LENS ARRAY
**Agents used:** kimi-implementer (5 instances in worktrees)
**Desktop control required:** Only for visual regression tests
**Browser tools required:** Only for visual regression tests

## Input

Target file or module to generate tests for. Claude reads the source code.

## Workflow

Dispatch 5 kimi-implementer agents in parallel, each in an isolated worktree.
Each generates tests from a different angle:

| Agent | Focus | Instruction |
|-------|-------|-------------|
| 1 | Happy paths | "Write comprehensive tests covering all expected/standard use cases" |
| 2 | Edge cases | "Write tests for boundary values, empty inputs, max values, unicode, special characters, off-by-one" |
| 3 | Error paths | "Write tests for invalid inputs, network failures, timeouts, permission errors, corrupted data" |
| 4 | Integration | "Write tests for cross-module interactions, API contracts, database queries, external service calls" |
| 5 | Visual regression | "If UI component: generate screenshot comparison tests. If not UI: write property-based tests." |

## Synthesis (Claude)

1. Collect all 5 test files
2. Deduplicate: remove tests that cover the same case (keep the more thorough version)
3. Merge into single comprehensive test file
4. Run merged test suite to verify all tests pass
5. Report coverage if coverage tool available

## Output

Comprehensive test suite + coverage report.
