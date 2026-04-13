---
name: handoff-update
description: Update handoff.xml after work session - review what changed, clean up done items, add new learnings
disable-model-invocation: true
argument-hint: [optional guidance]
---

<purpose>
Update the project's `handoff.xml` (always in project root) after a work session.
Primary consumer is a **fresh session** with zero prior context. Write for cold-start usefulness.
</purpose>

<rules>
- Done items get DELETED — handoff = what's OPEN. Not a changelog.
- Lasting learnings go to CLAUDE.md — handoff is for active work, not knowledge base
- Be specific, not terse — a fresh session should act without clarifying questions
- File paths are mandatory — every task item must reference relevant files/functions
- Be specific and detailed. Describe and hand over as much as possible so the next session does not have to rediscover what you already found out.
</rules>

<handoff_structure>
The handoff.xml file should follow this structure:

```markdown
> TL;DR: [3-5 sentences. What's the project doing right now? What's hot?]

<category_name>
- **Task title** — what and why, not just what
  [files]: `path/to/file.ts:42`, `other/file.py`
  [status]: what's done, what's left (concrete steps)
  [decided]: choices made and why — prevent re-litigation
  [landmine]: gotchas, things that look wrong but aren't, don't-touch zones
</category_name>

<context>
- stable facts about the project setup, structure, tooling
</context>
```

<example_bad>
`- Fix pagination bug`
</example_bad>

<example_good>
```
- **Pagination returns wrong total on filtered queries** — API returns unfiltered total_count
  [files]: `src/api/paginate.ts:45`, `src/hooks/useList.ts`
  [status]: root cause identified, need to add filtered count param to API call
  [decided]: offset correction over cursor-based (API doesn't support cursors)
  [landmine]: `paginate.ts` has a legacy code path (L80-95) that 3 views depend on — don't refactor
```
</example_good>

Not every marker is needed every time. Use what's relevant. `[files]` is always relevant.
</handoff_structure>

<git_context>
First check if the project is a git repo: !`git rev-parse --is-inside-work-tree 2>/dev/null`

If yes (output "true"):
- Recent commits: !`git log --oneline -10 2>/dev/null || echo "no commits yet"`
- Changed files: !`git diff --stat HEAD~5..HEAD 2>/dev/null || git diff --stat 2>/dev/null || echo "no diff available"`

If not a git repo: skip git context entirely and rely on conversation history + reading files.
</git_context>

<workflow>
1. We do work, discuss, fix things
2. User calls `/handoff-update` (maybe with freeform guidance in $ARGUMENTS)
3. Discover what changed: use the git context above, review conversation history, read current handoff.xml
4. Review:
   - What work was completed? → DELETE those items
   - What new items emerged? → ADD with full context (files, status, decisions)
   - What's blocked? → annotate with `[reason]:`
   - Lasting learnings? → update CLAUDE.md (project), ask first for global `~/.claude/CLAUDE.md`
5. Update the TL;DR to reflect current state
6. Show brief summary of changes
</workflow>

<doc_updates>
When we learn something lasting, **update CLAUDE.md directly** (project-level). Ask first for global.
Same for project docs — if we fixed something that docs cover, update them too. Be proactive.
Don't suggest "maybe we could update docs" — do it or ask to do it.
</doc_updates>

<arguments>
If the user provides $ARGUMENTS, treat as freeform guidance:
- "mark the pagination fix as done"
- "add a note about the API rate limit we discovered"

Without arguments, review the session yourself and figure out what changed.
</arguments>

<categories>
- `<delegate>` — Claude can handle autonomously
- `<backlog>` — lower priority
- `<decide>` — needs human choice
- `<manual>` — human must act externally
- `<blocked>` — cannot progress
- `<exploring>` — open-ended research
- `<context>` — reference info (not tasks)

Create new categories freely — `<urgent>`, `<waiting-on>`, `<ideas>`, whatever fits.
</categories>

<inline_markers>
- `[files]:` — relevant paths with line numbers **(always include)**
- `[status]:` — what's done, concrete next steps
- `[left-off]:` — breadcrumb for interrupted work (what line, what function, mid-what)
- `[decided]:` — choices made + reasoning
- `[landmine]:` — don't-touch zones, deceptive code, gotchas
- `[reason]:` — why blocked
- `[depends]:` — dependency on other task/person
- `[see]:` — reference URL or doc

Create new markers freely. The point is structured context, not rigid format.
</inline_markers>
