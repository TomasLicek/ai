---
name: double-check
description: Four-eyes principle — verify we didn't screw up this session
effort: xhigh
allowed-tools: Read, Grep, Glob, Bash, Task
---

# Double-Check

Spawn a subagent to verify the session. Not a summary — a verification. Senior independent checking we didn't go off the rails, did not misjudge, or forget to clean after ourselves.

## Instructions for subagent

You're the second pair of eyes. Review the entire session — not just code, but thinking, process, decisions, and artifacts. Your job is to catch what they missed while deep in implementation, conversation and reasoning.

**Verify:**

1. **Did we solve the actual problem?** Or did we drift and solve something adjacent?
2. **Reasoning integrity** — did the logic hold up, or did we talk ourselves into something shaky?
3. **Stayed on track?** Identify where we got derailed. Was the detour justified or did we lose the thread?
4. **Unfinished threads** — things said "we'll come back to" and never did
5. **Session hygiene** — temp files, debug logs, console.logs, hardcoded test values, scratch comments left from debugging
6. **Subagent drift** — did spawned agents go off-topic or produce results that were blindly accepted?
7. **Code changes** — the classic four-eyes: bugs, edge cases, error handling, broken ripple effects, things any reviewer would flag
8. **Scope** — did more than asked? Did less than needed?
9. **Omission audit** — what's NOT there that should be? Check against the original ask:
   - Requirements mentioned but never implemented
   - Edge cases discussed but not handled
   - Config/docs that should have been updated but weren't
   - Validation, error paths, or cleanup that the change implies but nobody wrote
   - If we hedged or punted ("we can do that later") — flag it, was it justified or lazy?

**Output:**

- Findings by severity (blocking → minor)
- Be specific: file, line, what's wrong, or decision, why it's suspect
- If everything checks out, say so in one line and shut up

**Attitude:**

- You're a senior who has to put their name on this
- Direct, not diplomatic — flag what's wrong
- Catch the "oh shit" before it ships

---

Spawn **parallel** subagents — as many as needed based on what happened in the session. Examples:

- **Session reasoning** — conversation review: decisions, logic, detours, unfinished threads, scope drift
- **Artifact hygiene** — scan changed files, working dir, scratchpad for debug leftovers, temp files, hardcoded test values
- **Code review** — four-eyes on actual code changes: bugs, edge cases, ripple effects
- **Omission audit** — read the original ask, list what was promised/implied, check each against what was delivered. Report: hit/miss/punted. This catches the "sounds done but isn't" failure mode.
- **Test coverage** — did we test what we changed? Gaps?
- **Dependency/config check** — did we touch configs, package files, env vars that need attention?

Only spawn agents relevant to the session. Small session = fewer agents. Big session touching multiple areas = more agents.

Merge all findings into a single report, deduplicated, sorted by severity.

This is a verification gate, not a book report.
