---
name: update-docs
description: "USER-INVOKABLE ONLY. Do NOT trigger automatically. Only invoke when the user explicitly types /update-docs or asks to update documentation. Audits and updates all relevant project documentation — CLAUDE.md, README, docs/, handoff.xml, MEMORY.md — based on what happened in this session."
argument-hint: [optional: specific doc to update]
---

# Update Docs

Sync project documentation with reality after a session.

## Workflow

1. **Scan for doc files** — find all candidates in the current project:

   ```
   find . -maxdepth 4 \( -name "CLAUDE.md" -o -name "README*" -o -name "MEMORY.md" -o -name "handoff.xml" -o -path "*/docs/*.md" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null
   ```

2. **Reflect on the session** — before touching anything, consider:
   - What changed in the codebase?
   - What commands / patterns are new or deprecated?
   - What decisions were made and why?
   - What tripped us up that future-us should know?

3. **Update all relevant files immediately** — no asking, just do it:
   - Surgical edits only — add/update stale or missing sections, remove falsehoods
   - Preserve existing structure, tone, and XML tags
   - Skip a file only if truly nothing changed for it

4. **Report at the end** — one line per file: what changed (or "skipped — nothing new").

## Principles

- Less is more. Don't pad. If nothing meaningful changed for a file, skip it.
- Preserve XML tags in markdown files (e.g., `<example>`, `</example_file>`) — do not strip them.
- Updates should survive the next session — write for future-Claude, not current-Claude.
- If unsure what to add, ask rather than guess.
