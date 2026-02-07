---
name: branch
description: Create a new git branch off current branch with standardized naming
model: haiku
argument-hint: [JIRA-123] description of branch
---

# Branch

Create a new git feature branch following naming convention.

## Context from caller

$ARGUMENTS

## Naming Convention

**Format:** `feature-tom-<[JIRA_TICKET] - briefDescription>`

Examples:
- `feature-tom-MED-123 - add meditation timer`
- `feature-tom-PROJ-456 - fix audio sync bug`
- `feature-tom-rails site landing pages` (no ticket)

## Steps

1. Parse arguments for optional JIRA ticket + description. No arguments → check git context, ask user.
2. Construct branch name: kebab-case-friendly, 3-5 word description max.
3. `git checkout -b "feature-tom-<name>"` off current branch.
4. Report new branch name and parent branch.

## Rules

- ALWAYS use `feature-tom-` prefix
- JIRA ticket is optional
- No arguments + no context → ASK the user
- Branch off current branch (don't switch to main first unless told)
- If branch exists, ask: switch to it or pick different name?
