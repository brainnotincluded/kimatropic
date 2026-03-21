# Contributing to Kimatropic

Thanks for your interest in contributing. This guide covers how to add new orchestration patterns, swarm applications, and agents.

## Project Structure

```
kimatropic/
  .claude-plugin/plugin.json   # Plugin metadata
  agents/                      # Agent definitions (delegation bridges to Kimi)
  applications/                # Swarm application definitions (workflows)
  hooks/                       # Claude Code hooks (session-start auto-routing)
  orchestration/               # Orchestration pattern definitions
  scripts/                     # Shell/Python tooling (kimi-run, desktop-control, etc.)
  skills/kimi/SKILL.md         # Skill definition (command dispatch)
  tests/                       # Test scripts
```

## Adding a New Orchestration Pattern

Orchestration patterns define how multiple Kimi instances coordinate. They live in `orchestration/`.

1. Create `orchestration/<pattern-name>.md`.
2. Include these sections:
   - **Flow:** ASCII diagram showing the coordination topology.
   - **When to Use:** Clear criteria for when this pattern applies.
   - **Claude's Role:** Step-by-step instructions Claude follows to execute the pattern.
   - **Prompt Template:** The 7-section skeleton (`<identity>`, `<objective>`, `<context>`, `<approach>`, `<output>`, `<checklist>`, `<escalation>`, `<anti-patterns>`) adapted for the pattern.
   - **Synthesis Template:** How Claude merges/evaluates the outputs.
3. Add the pattern to the selection guide in `orchestration/README.md`.
4. Ensure the pattern composes with existing patterns -- document natural combinations.

## Adding a New Swarm Application

Swarm applications combine patterns into complete workflows. They live in `applications/`.

1. Create `applications/<app-name>.md`.
2. Start with the metadata block:
   ```markdown
   # Application Name

   **Invoke:** `/kimi <subcommand> <args>`
   **Patterns:** Which orchestration patterns this application uses
   **Agents used:** Which agent types and how many instances
   **Desktop control required:** Yes/No
   **Browser tools required:** Yes/No
   ```
3. Define the workflow as numbered stages. Each stage should specify:
   - Who executes it (Claude or Kimi agents)
   - What input it receives
   - What output it produces
   - How failures are handled
4. Include full prompt templates for each Kimi agent role, using the 7-section skeleton.
5. Define the synthesis step where Claude merges agent outputs.
6. Add the command to `skills/kimi/SKILL.md` under the appropriate section.
7. Add an auto-routing entry to `hooks/session-start` if the application should trigger automatically.

## Adding a New Agent

Agents are delegation bridges between Claude and Kimi. They live in `agents/`.

1. Create `agents/<agent-name>.md` with YAML frontmatter:
   ```yaml
   ---
   name: <agent-name>
   description: |
     When to use this agent, what it does, what it does NOT do.
   model: inherit
   ---
   ```
2. The agent body should be minimal -- agents are bridges, not thinkers. They:
   - Receive a task from Claude
   - Run `kimi-run.sh` with appropriate flags
   - Return the JSON output unmodified
3. Document any special flags (e.g., `--mode swarm`, read-only prefixes).

## Code Style

- **Shell scripts:** Use `set -euo pipefail`. Quote all variables. Use `readonly` for constants. Prefer `$(command)` over backticks. Target bash 4+ but handle macOS defaults (e.g., GNU coreutils with `g` prefix).
- **Python scripts:** Follow PEP 8. Use type hints where practical. All CLI output as JSON for machine consumption. Keep dependencies minimal (pyautogui is the only required package).
- **Markdown definitions:** Use the established section structure. Be explicit about what Claude should do vs. what Kimi agents should do. Include anti-pattern sections to prevent common mistakes.
- **Prompt templates:** Always use the 7-section skeleton. Include boundary instructions (what other agents cover) to prevent duplicate work. Require JSON output for machine synthesis.

## Testing

Test scripts live in `tests/`. Run them from the repository root:

```bash
# Preflight checks (no Kimi session required)
./tests/test-preflight.sh

# Kimi integration (requires Kimi CLI and credentials)
./tests/test-kimi-run.sh

# Desktop control (requires pyautogui and screen access)
./tests/test-desktop-control.sh
./tests/test-desktop-preflight.sh

# Live Kimi session (requires active Kimi account, costs credits)
./tests/test-kimi-run-live.sh

# Screen capture (requires pyautogui + ffmpeg)
./tests/test-screen-capture.sh
```

When adding a new script or modifying existing ones, add corresponding test cases. Tests use a simple `expect_exit` / `expect_contains` pattern -- see `tests/test-preflight.sh` for the template.

## Pull Requests

- One feature per PR.
- Include a clear description of what the new pattern/application/agent does and why it is useful.
- If adding a swarm application, include an example invocation and expected output shape.
- Ensure all existing tests still pass.
