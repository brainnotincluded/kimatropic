---
name: kimi
description: >
  Delegate tasks to Kimi K2.5 swarm. Auto-trigger when: encountering bugs
  (debug), analyzing site design or URLs (design), architecture decisions
  (war-room), writing tests (test-storm), building user-facing features
  (gauntlet), large refactors/migrations (migrate), exploring unfamiliar
  codebases (reverse), checking visual regressions (visual-diff), responsive
  issues (responsive), animation problems (animation), cross-app testing
  (flow-test), accessibility concerns (a11y), UX evaluation (ux), or any
  batch implementation task. Use /kimi <subcommand> or auto-delegate.
---

# Kimi Delegation & Swarm Orchestration

Delegate tasks to Kimi K2.5 — from simple single-agent delegation to
multi-agent swarm orchestration with parallel analysis.

## Commands

### Simple Delegation (v1)
- `/kimi <task>` — delegate using kimi-implementer (default)
- `/kimi research <task>` — delegate using kimi-researcher
- `/kimi vision <task>` — delegate using kimi-vision
- `/kimi swarm <task>` — delegate using kimi-swarm

### Swarm Applications (v2)
- `/kimi design <url-or-app>` — Design Intelligence (6-lens analysis)
- `/kimi debug <description>` — Mega Debug (5 parallel hypotheses)
- `/kimi war-room <topic>` — War Room (structured expert debate)
- `/kimi test-storm <target>` — Test Storm (5-angle test generation)
- `/kimi gauntlet <task>` — Code Gauntlet (adversarial hardening)
- `/kimi migrate <spec>` — Migration Blitz (parallel migration)
- `/kimi reverse <target>` — Reverse Engineering (6-lens codebase analysis)
- `/kimi visual-diff` — Visual Regression Swarm
- `/kimi responsive <url>` — Responsive Gauntlet
- `/kimi animation <url>` — Animation Debugger
- `/kimi flow-test <script>` — Cross-App Flow Tester
- `/kimi a11y <url-or-app>` — Accessibility Auditor
- `/kimi ux <flow>` — UX Flow Recorder

## Behavior

### For simple delegation (v1):
1. Parse the user's input to determine the mode
2. Launch the selected subagent with the Agent tool
3. Present the summary JSON to the user
4. If failed, ask user: retry with Kimi, handle yourself, or abandon

### For swarm applications (v2):
1. Parse the subcommand to identify the application
2. Read the application definition from `applications/<name>.md`
3. Run `desktop-preflight.sh` if desktop control is needed
4. Follow the stages defined in the application file:
   - Execute capture stages (Claude uses browser tools + desktop-control.py)
   - Prepare prompt templates for each Kimi agent per the orchestration pattern
   - Dispatch agents in parallel using the Agent tool
   - Collect results and synthesize per the pattern instructions
5. Present the synthesized report to the user

### Reading application definitions:
Application files are at `PLUGIN_ROOT/applications/<name>.md`. Read the file
to understand the exact workflow, prompt templates, and output format.

### Reading orchestration patterns:
Pattern definitions are at `PLUGIN_ROOT/orchestration/<pattern>.md`. Read the
relevant pattern to understand how to dispatch, collect, and synthesize.

## Auto-Routing

When NOT explicitly invoked via /kimi, automatically use swarm applications when:
- User shares a URL for design review → `/kimi design`
- Bug is hard to find → `/kimi debug`
- Architecture decision → `/kimi war-room`
- Writing tests → `/kimi test-storm`
- Building user-facing feature → `/kimi gauntlet`
- Multi-file refactor/migration → `/kimi migrate`
- Unfamiliar codebase → `/kimi reverse`
- After UI code changes → `/kimi visual-diff`

**Never ask "should I use Kimi for this?"** If a swarm application matches, just use it.

## Opt-Out

- "do this yourself" / "don't use kimi" → Claude does the work directly
- "just use a single kimi" → falls back to v1 single-agent delegation
