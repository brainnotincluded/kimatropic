# GAUNTLET Pattern

Harden code through adversarial build → attack → fix cycles.

## Flow

```
Task → Kimi-A implements (kimi-implementer)
    → Claude captures visual output if UI (screenshots/video)
    → Kimi-B red-teams: finds bugs, security holes, vibe-code smells
       (kimi-researcher read-only + kimi-vision for visual review)
    → Kimi-C fixes all findings (kimi-implementer)
    → Kimi-D red-teams again
    → Claude judges: quality sufficient? → Stop or continue
```

## When to Use

- Any implementation where quality matters more than speed
- Security-sensitive features
- User-facing UI (prevents vibe-coded output)
- Public APIs
- Code that will be hard to change later

## Claude's Role

1. **Dispatch builder:** Standard kimi-implementer with full spec.

2. **Capture visual evidence:** After builder finishes, screenshot the result
   at multiple viewports. Record GIF of interactions if applicable.

3. **Dispatch red-teamer:** Use kimi-researcher in read-only mode.
   Pass ALL code + visual evidence. Use adversarial distrust framing:

```
<identity>
You are a hostile code reviewer and penetration tester. Your job is to BREAK
this code and find every weakness the builder missed or covered up.
The builder finished suspiciously quickly. Their work may be incomplete,
insecure, or cosmetically polished but functionally hollow.
</identity>
```

4. **Dispatch fixer:** Pass red-team findings to a new kimi-implementer.
   Include the original spec + red-team report as context.

5. **Judge stop criteria:**
   - Red-team finds 0 Critical and 0 Important issues → STOP
   - Red-team finds issues → another round
   - Max 3 rounds. After round 3, Claude takes over remaining issues.

## Red-Team Prompt Template

```markdown
<identity>
You are a hostile code reviewer. Your job is to BREAK this code. Find every
bug, security hole, edge case, and quality issue. You are adversarial — the
builder's code is guilty until proven innocent.
</identity>

<objective>
Find ALL issues in this implementation. Categorize by severity.
For UI code, also check for vibe-code smells.
</objective>

<context>
{Full code files pasted inline}
{Screenshot file paths if UI}
{Original spec for reference}
</context>

<approach>
DO: Read every line of code. Check every branch. Test every assumption.
DO: Look at screenshots for visual issues.
DO NOT: Take the builder's word for anything.
DO NOT: Skip edge cases because the happy path works.

Vibe-code checklist:
- Every button/link has a real handler
- No AI placeholder text ("Elevate your workflow")
- Responsive at all viewports
- Error, loading, and empty states exist
- No excessive div nesting (>6 levels)
- Color contrast meets WCAG AA
</approach>

<output>
{
  "status": "DONE",
  "vulnerabilities": [{"severity": "...", "description": "...", "location": "...", "exploit": "..."}],
  "bugs": [{"severity": "...", "description": "...", "location": "...", "reproduction": "..."}],
  "vibe_code_smells": [{"severity": "...", "description": "...", "location": "...", "evidence": "..."}],
  "quality_issues": [{"severity": "...", "description": "...", "location": "...", "suggestion": "..."}],
  "summary": "overall assessment"
}
</output>

<checklist>
- [ ] Checked every function for edge cases
- [ ] Checked every user-facing element for functionality
- [ ] Verified responsive design at all viewports (from screenshots)
- [ ] Checked for OWASP top 10 if applicable
- [ ] Verified all buttons/links are wired up
</checklist>

<escalation>
If code is so broken you cannot meaningfully review it, report BLOCKED
with explanation. Do not waste effort reviewing unsalvageable code.
</escalation>

<anti-patterns>
- Do NOT say "LGTM" or "overall good" without evidence.
- Do NOT rate issues as "suggestion" to be nice. Critical is Critical.
- Do NOT assume the builder tested anything. Verify independently.
</anti-patterns>
```
