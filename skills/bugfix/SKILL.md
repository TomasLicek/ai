---
name: bugfix
description: Spawn sub-agents to fix bugs in parallel, then verify fixes
argument-hint: <bug list or "audit">
---

# Bug Fix Workflow

You are the **orchestrator**. Fix bugs via sub-agents, manage file collisions, verify results.

## Input

`$ARGUMENTS` can be:
- Path to file listing bugs
- Inline bugs separated by `|`

## Orchestration Logic

### 1. Analyze bugs for file overlap

Before spawning anything:
- Identify which file(s) each bug likely touches
- **Group bugs that touch the same file** - these go to ONE agent, sequentially
- **Separate files = parallel agents**

Example:
- Bug A: api.ts, Bug B: api.ts, Bug C: form.tsx, Bug D: CLAUDE.md
- → Agent 1: Bug A + B (same file, one agent)
- → Agent 2: Bug C (parallel)
- → Agent 3: Bug D (parallel)

### 2. Spawn fix agents

For each group, spawn `general-purpose` agent:
```
Fix: [bug description(s)]
Location: [file(s)]

1. Find root cause, don't patch symptoms
2. Minimal fix - no drive-by refactoring
3. Run tests if you touch tested code
4. Output: which files you modified and what you changed
```

**Parallel = multiple Task calls in ONE message** (for independent file groups)
**Serial = wait for previous** (if unsure about overlap)

### 3. Collision check

After all agents return:
- Compare which files each agent modified
- If same file modified by multiple agents → **PROBLEM** - check git diff, may need manual merge
- Log all modified files

### 4. Verification agent

Spawn ONE agent to review all fixes:
```
Verify these bug fixes landed correctly:
[list what was fixed]

For each: Does fix address root cause? Could it break anything? Edge cases?

Report: PASS / CONCERN [why] / FAIL [why]
Be brief.
```

### 5. Main thread summary

- Address any FAIL/CONCERN
- List what was fixed
- Note manual testing needed
- Update handoff.md if relevant

## Rules

- Max 5 parallel agents
- When in doubt about file overlap, serialize
- If bug is unclear, have agent investigate before fixing
- Write summaries to stdout so nothing lost
