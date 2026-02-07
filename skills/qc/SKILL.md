---
name: qc
description: Spawn parallel test agents to verify recent code changes work correctly
---

# Quality Control

Spawn parallel Bash subagents to test recent code changes. Fast verification before moving on.

## Instructions for spawning agents

1. **Identify what changed** - Look at the conversation for recent edits, new functions, bug fixes
2. **Spawn 2-4 Bash agents in parallel** - Each tests a different aspect:
   - Does it run without errors?
   - Does the happy path work?
   - Does edge case handling work?
   - Did we break anything adjacent?

## Agent prompt template

Each agent should:
- Run specific commands to verify functionality
- Report PASS/FAIL with brief details
- Not fix anything - just report

## Example agent tasks

- "Run the CLI command with valid input, verify output format"
- "Run with edge case input (empty, null, large), verify no crash"
- "Check the function returns expected values"
- "Verify the migration ran correctly"

## Your output

Summarize results in a table:

| Test | Result | Notes |
|------|--------|-------|
| Basic functionality | PASS | Output matches expected |
| Edge cases | FAIL | Crashes on empty input |

## Attitude

- Fast and focused
- Test what matters, skip the obvious
- Trust but verify
- If all pass, say "QC passed" and move on
