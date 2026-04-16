---
name: qc
effort: xhigh
description: Spawn parallel mixed-type agents to verify recent code changes work correctly. Use after any code change — bug fixes, new features, refactors, config changes. The "did we break anything?" check before moving on.
---

# Quality Control

Verify recent code changes by spawning parallel agents that each look at the change from a different angle. The goal is fast confidence — catch real problems, skip theater.

## Step 1: Understand the change

Before spawning anything, understand what changed and why. Run `git diff --name-only` and `git diff --cached --name-only`. Use conversation context for intent. You need to know:

- **What files changed** — this determines which agents to spawn
- **What the change is supposed to do** — this is what you tell the agents
- **What could go wrong** — this shapes the breaker prompt

If there's no git diff (e.g. change was just discussed, not committed), use conversation history.

## Step 2: Quick sanity check (if anything exists)

Glance for an existing test suite, linter, or type checker — `package.json` scripts, `Makefile`, `pytest`, `go test`, etc. If something relevant exists, run it before spawning agents. It's the cheapest signal and avoids wasting agents on problems a 10-second command would have caught.

Many projects won't have any of this. That's fine — skip straight to Step 3.

## Step 3: Spawn agents

Spawn 2-4 agents in parallel. Always include a breaker. Pick the rest based on what the change actually needs.

### Agent types

**Breaker** (`subagent_type: "breaker"`) — Always spawn one. This is the adversarial tester. It reads the code and actively tries to break it: malformed input, boundary values, missing fields, concurrent access, type coercion gotchas. It's not running a test suite — it's thinking like someone who wants to find the bug.

**General-purpose** (default) — The thoughtful tester. It reads the changed code, understands the logic, then verifies the happy path works and adjacent code wasn't broken. Good when the change involves business logic or when you need someone to reason about correctness, not just bash at it.

**Explore** (`subagent_type: "Explore"`) — The ripple detector. Doesn't test the change itself — instead scans the codebase for things that depend on what changed. Callers that pass old arguments, imports that reference renamed exports, config that references moved paths, tests that assert old behavior. Spawn this when the change touches interfaces, renames things, or modifies shared code.

### When to use what

Think about it this way: breaker asks "can I break it?", general-purpose asks "does it work?", Explore asks "did we miss something?"

- Most changes need breaker + general-purpose
- Multi-file or interface changes add Explore
- Config/infra changes: Explore is more valuable than breaker
- Don't spawn agents for work that existing tests already cover

## Step 4: Writing good agent prompts

The prompt is everything. A breaker agent with a vague prompt is just an expensive no-op. Every agent prompt must include:

1. **What changed** — specific files, specific lines, what was added/removed/modified
2. **What it's supposed to do** — the intent, not just the diff
3. **What to check** — concrete, specific verification targets
4. **Report format** — "Report PASS/FAIL with brief evidence. Don't fix anything."

### Example prompts

**Breaker for a new validation function:**
> File `src/validators/email.ts` was modified to add RFC 5322 email validation replacing the old regex. The function is `validateEmail(input: string): boolean`. Try to break it: empty string, null, undefined, strings with unicode, emails with plus addressing (user+tag@domain.com), IP-literal domains, extremely long local parts (>64 chars), missing @ symbol, multiple @ symbols, trailing dots. Report PASS/FAIL for each case. Don't fix anything.

**General-purpose for a refactored API handler:**
> The handler for POST /api/orders in `src/routes/orders.ts` was refactored from callback-style to async/await. The business logic should be identical — same validation, same DB calls, same response shape. Read the new code, verify the logic is preserved, and run the endpoint with a valid order payload to confirm it returns 201 with the expected shape. Check that error responses (400, 500) still match the old format. Report PASS/FAIL with details.

**Explore for a renamed export:**
> `calculateTotal` in `src/utils/pricing.ts` was renamed to `computeOrderTotal` and re-exported. Search the entire codebase for any remaining references to `calculateTotal` — imports, dynamic requires, string references in tests, documentation. Also check if any external package or config references this function name. Report what you find — files and line numbers.

## Output

Summarize results in a table:

| Agent | Type | Result | Details |
|---|---|---|---|
| Validation edge cases | breaker | FAIL | Crashes on null input, accepts `user@.com` |
| Happy path + error shape | general-purpose | PASS | 201 and 400 responses match expected format |
| Stale references | Explore | FAIL | 3 files still import `calculateTotal` |

Results are **PASS** or **FAIL**. No WARN — if something is wrong enough to mention, it's a FAIL. If it's fine, it's a PASS.

## After QC

- **All PASS** → say "QC passed" and move on
- **Any FAIL** → report the table, list the specific failures, and ask the user what they want to do about them. Don't auto-fix. Don't minimize. The point of QC is to surface problems, not to silently resolve them.
