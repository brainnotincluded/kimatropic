#!/usr/bin/env node
/**
 * session-start — Inject auto-routing table into Claude's context
 * Cross-platform: Windows, macOS, Linux
 * Replaces the bash version for portability
 */

const CONTEXT = `## Kimatropic: Automatic Swarm Routing

You have access to Kimi K2.5 swarm orchestration. Use these AUTOMATICALLY when the situation matches — do NOT wait for the user to ask.

| When you notice... | Automatically use | Why |
|---------------------|-------------------|-----|
| User shares a URL and asks about design/look/UI | \`/kimi design <url>\` | Multi-lens design analysis beats single-perspective review |
| A bug is hard to find or reproduce | \`/kimi debug <description>\` | 5 parallel hypotheses find root cause faster |
| Architecture decision with trade-offs | \`/kimi war-room <topic>\` | Structured expert debate produces better decisions |
| Need to write tests for a module | \`/kimi test-storm <target>\` | 5 test perspectives = dramatically better coverage |
| Building user-facing feature | \`/kimi gauntlet <task>\` | Adversarial hardening catches vibe-code and bugs |
| Large refactor/migration across many files | \`/kimi migrate <spec>\` | Parallel migration in worktrees, minutes not hours |
| Entering an unfamiliar codebase | \`/kimi reverse <target>\` | 6 parallel analysts map the architecture fast |
| After code changes to UI | \`/kimi visual-diff\` | Semantic visual regression catches what pixel-diff misses |
| Responsive/mobile issues suspected | \`/kimi responsive <url>\` | Continuous resize analysis finds every breakpoint failure |
| Animation feels wrong/janky | \`/kimi animation <url>\` | Frame-level analysis by motion specialist Kimis |
| Testing cross-application workflow | \`/kimi flow-test <script>\` | No other tool can test workflows spanning multiple apps |
| Accessibility is a concern | \`/kimi a11y <url>\` | 5 parallel a11y modes (keyboard, contrast, zoom, motion, extremes) |
| Evaluating UX quality of a flow | \`/kimi ux <flow>\` | Simulated user journey with cognitive load analysis |
| Batch implementation with clear spec | auto-delegate to kimi-implementer | Cost optimization |
| Deep codebase exploration | auto-delegate to kimi-researcher | Preserves Opus context |

When in doubt, USE the swarm application. The cost of 5 cheap Kimi instances is less than Opus deliberating alone, and the result is better.`;

const response = {
  hook_response: {
    additional_context: CONTEXT
  }
};

console.log(JSON.stringify(response));
