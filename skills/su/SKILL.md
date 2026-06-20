---
name: su
effort: xhigh
description: Update status.md (pm/status.md)
disable-model-invocation: false
argument-hint: [optional guidance]
---

<purpose>
Update the project's `status.md` (pm/status.md inside pm [project management] folder living in project root) to handoff the work.
Primary consumer is a next **fresh session** with zero prior context. Write for cold-start usefulness.
</purpose>

<rules>
- Done items get DELETED.  status.md = what's OPEN. Not a changelog
- Lasting learnings go to CLAUDE.md or documentation (pm/documentation) folder. status.md is for active work, not knowledge base
- Be specific, not terse. Fresh session should act without clarifying questions unless decisions needed.
- File paths are mandatory. Every task item must reference relevant files/functions
- Be specific and detailed. Describe and hand over as much as possible so the next session does not have to rediscover what you already found out.

</rules>

<status_structure>

```markdown
> TL;DR: [3-5 sentences. What's the project doing right now? What's hot?]

**Task title** what and why, not just what
  [files]: `path/to/file.ts:42`, `other/file.py`
  [status]: what's done, what's left (concrete steps)
  [decided]: choices made and why — prevent re-litigation
  [landmine]: gotchas, things that look wrong but aren't, don't-touch zones
```

<example_bad>
`- Fix pagination bug`
</example_bad>

<example_good>
```
**Pagination returns wrong total on filtered queries** API returns unfiltered total_count
  [files]: `src/api/paginate.ts:45`, `src/hooks/useList.ts`
  [status]: root cause identified, need to add filtered count param to API call
  [decided]: offset correction over cursor-based (API doesn't support cursors)
  [landmine]: `paginate.ts` has a legacy code path (L80-95) that 3 views depend on - don't refactor
```
</example_good>

Not every marker is needed every time. Use what's relevant. `[files]` is always relevant.

</status_structure>

<arguments>
If the user provides $ARGUMENTS, treat as freeform guidance:

- "mark the pagination fix as done"
- "add a note about the API rate limit we discovered"

Without arguments, review the session yourself and figure out what changed.
</arguments>
