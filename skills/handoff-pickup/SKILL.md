---
name: handoff-pickup
description: Session startup - read handoff.xml, triage items, spawn agents for delegatable work, surface decisions needed
disable-model-invocation: true
---

<purpose>
Read the project's `handoff.xml` (always in project root) and orchestrate session startup.
Primary producer is the `/handoff-update` skill. This skill is the consumer.
</purpose>

<categories>
- `<delegate>` — work Claude can handle autonomously → spawn subagents
- `<backlog>` — lower priority, often delegatable → spawn when appropriate
- `<decide>` — needs human choice → surface via AskUserQuestion
- `<manual>` — human must act externally → display as checklist
- `<blocked>` — cannot progress → display with reason, ask if situation changed
- `<exploring>` — open-ended research → offer to spawn Explore agent
- `<context>` — reference info, not actionable → load silently

Unknown categories may exist — interpret based on name and act sensibly.
</categories>

<inline_markers>
- `[files]:` — relevant paths with line numbers
- `[status]:` — what's done, concrete next steps
- `[left-off]:` — breadcrumb for interrupted work
- `[decided]:` — choices made + reasoning (don't re-litigate)
- `[landmine]:` — don't-touch zones, deceptive code, gotchas
- `[reason]:` — why blocked
- `[depends]:` — dependency on other task/person
- `[see]:` — reference URL or doc

Markers are optional, not mandatory. Other markers may exist — interpret sensibly.
</inline_markers>

<model_selection>
- **Haiku** — simple: delete files, create files, cleanup, rename
- **Sonnet** — medium: refactoring, research, multi-file edits
- **Opus** — complex: new features, hard bugs, architectural changes
</model_selection>

<workflow>
1. **Read `handoff.xml`** from project root

2. **Parse** — identify items by XML category tags and inline markers

3. **Triage and act:**

   `<delegate>` and `<backlog>`:
   - Spawn subagents (parallel when independent)
   - Select model based on complexity
   - Pass full context: file paths, decisions made, landmines, left-off breadcrumbs
   - For backlog: use judgment on what's worth starting

   `<decide>`:
   - Batch into AskUserQuestion (up to 4 questions)
   - Include `[decided]` context so user sees what was already resolved

   `<manual>`:
   - Display as checklist, note `[depends]` if present

   `<blocked>`:
   - Display with `[reason]` prominently
   - Ask if situation has changed

   `<exploring>`:
   - Briefly mention what's being explored
   - Offer to spawn Explore agent

   `<context>`:
   - Load silently as background knowledge

   Unknown categories: interpret and act sensibly.

   Use AskUserQuestion with ANY category when clarification would help.

4. **Verify and wrap up:**
   - If agents were spawned, verify their work before marking done
   - Update `handoff.xml` if items completed or state changed
   - End with clear picture: what's running, what needs input, what's blocked
</workflow>

<rules>
- Be concise but don't skip important topics
- Not all sections required — handoff can have any subset
- Categories and markers are guidance — new ones may exist
- Always verify delegated work before marking done
</rules>
