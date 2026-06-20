---
name: sp
effort: xhigh
description: Read status.md (pm/status.md) and get working on what's next
disable-model-invocation: true
---

<purpose>
Read the project's `status.md` (pm/status.md inside the pm [project management] folder in project root) and orchestrate session startup from cold context.
Producer is `su` (status update); this skill is the consumer.

Goal: understand current state, resume open work, and act on what's next without redoing work or asking questions the file already answers.
</purpose>

<rules>
- Doubt = stop. If a task is unclear, contradictory, or a real decision is buried in it, ask before implementing
- `status.md` = what's OPEN. Treat every item as live work, not history
- `[files]` is your entry point, read the referenced files before editing
- Respect `[decided]` (don't re-litigate)
- Verify delegated or local work before marking it done.
- Be concise in the startup summary, but don't skip important state.
</rules>

<inline_markers>
- `[files]:`  relevant paths, with line numbers when present
- `[status]:`  what's done, concrete next steps
- `[decided]:`  choices already made + why (don't re-open)
- `[landmine]:`  gotchas, deceptive code, don't-touch zones

Markers are optional. Other markers may exist, interpret sensibly.
</inline_markers>

<workflow>
1. **Read `pm/status.md`.** If missing, say so and ask whether to create one (via `su`) or continue without it.
2. **Triage each item by judgment** (no category tags, decide from content):
   - Autonomous work Claude can own? Spawn subagent(s) aggressively, parallel when independent and non-colliding. Pass full context: `[files]`, `[status]`, `[decided]`, `[landmine]`.
   - Needs a human choice?  AskUserQuestion.
   - Blocked or needs external/manual action? Surface as a short checklist with the reason; ask if the situation changed.
   - Open-ended research? Offer to spawn an Explore agent.
   - Reference-only / background? Load silently.
   - Use AskUserQuestion any time clarification unblocks the work.
3. **Before editing:** state the selected task and why, name key files and constraints, read the files. If anything is still unclear, ask.
4. **Verify and wrap up:**
   - Verify spawned-agent work before marking it done.
   - Update `pm/status.md` (via `su` behavior) when items complete or state changes; delete done items, don't leave a work log.
   - End with a clear picture: what's running, what needs input, what's blocked.
</workflow>

<arguments>
If the user provides $ARGUMENTS, treat as freeform guidance.
Without arguments, read `status.md` and act on the highest-value open work.
</arguments>
