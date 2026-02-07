---
name: handoff-update
description: Update handoff.md after work session - review what changed, clean up done items, add new learnings
disable-model-invocation: true
argument-hint: [optional guidance]
---

# Handoff Update

Review and update the project's `handoff.md` (always in project root) after a work session.

## Core Rules

1. **Done items get DELETED, not strikethrough** - handoff = what's OPEN
2. **Keep it lean** - move lasting learnings to CLAUDE.md, not handoff
3. **Handoff is not a changelog** - no history, just current state

## Typical Workflow

Usually you won't receive explicit commands. The flow is:

1. We do work, discuss, fix things
2. User calls `/handoff-update` (maybe with freeform guidance in $ARGUMENTS)
3. You review:
   - What work was completed this session?
   - What items in handoff.md are now done? → DELETE them
   - What new items emerged? → ADD them to appropriate category
   - What's now blocked that wasn't before? → MOVE or annotate
   - Did we learn something lasting? → Update CLAUDE.md (see below)

4. Make the updates
5. Show brief summary of changes

## CLAUDE.md Updates - Be proactive

When we fix something or learn something important, **proactively update CLAUDE.md**:

- How to use a tool correctly
- What to avoid (discovered a bug, bad pattern, etc.)
- Better way of doing things we discovered
- API quirks or limitations learned

**For project CLAUDE.md:** Just do it, then inform the user what you added and why.

**For global `~/.claude/CLAUDE.md`:** Ask first before modifying.

Don't suggest "maybe we could update CLAUDE.md" - either do it or ask to do it.

## Documentation updates
Same as CLAUDE.md - be proactive and update it.

## Optional Arguments

If the user provides $ARGUMENTS, treat as freeform guidance:
- "mark the pagination fix as done"
- "add a note about the API rate limit we discovered"
- "move caching decision to blocked, waiting on infra team"

Without arguments, review the session yourself and figure out what changed.

## Common Categories

- `<delegate>` - Claude can handle autonomously
- `<backlog>` - Lower priority, often delegatable
- `<decide>` - Needs human choice
- `<manual>` - Human must act externally
- `<blocked>` - Cannot progress
- `<exploring>` - Open-ended research
- `<context>` - Reference info (not tasks)

**Create new categories as needed** - `<urgent>`, `<waiting-on>`, `<ideas>`, whatever fits.

## Common Inline Markers

Examples (not exhaustive):
- `[why]:` - motivation, impact
- `[left-off]:` / `[progress]:` - breadcrumb
- `[constraint]:` - rules, gotchas
- `[reason]:` - why blocked
- `[next]:` - suggested next step
- `[see]:` - reference file/url
- `[depends]:` - dependency

**Create new markers as needed** - `[owner]:`, `[deadline]:`, whatever fits the context.

## Important

- Be concise in communication but don't skip important topics
- Never add timestamps or "completed on" markers
- Preserve formatting in `<context>` sections
- Categories and markers are guidance - create new ones freely
