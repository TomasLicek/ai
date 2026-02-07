---
name: learn
description: What have you learned from this session? Apply Kaizen principles to improve the project, yourself, the user, or the user experience.
disable-model-invocation: false
argument-hint: [optional focus area]
---

# Learn — Session Retrospective

Kaizen: small improvements, compounded. Reflect on what happened, extract lessons, persist them where they'll matter.

## When to Use

- End of a work session
- After a painful debugging session or unexpected breakthrough
- When something felt off but you can't name it
- When a pattern keeps recurring across sessions

## Core Workflow

1. **Reflect on the session**
   - What actually happened? (not what was planned — what happened)
   - What worked well? What was surprisingly effective?
   - What was painful, slow, or wrong?
   - What mistakes were made? Root cause, not symptoms.
   - Any "aha" moments worth preserving?

2. **Extract actionable lessons**
   - For each insight, ask: where should this live so it's useful next time?
   - Categories:
     - **Project** — CLAUDE.md update, new doc, better conventions
     - **Workflow** — skill improvement, new skill idea, better tool usage
     - **Self** — memory update (what Claude should remember), pattern to watch for
     - **User** — suggestion for Tom (habit, tool, approach)

3. **Persist the learnings**
   - Update `MEMORY.md` or topic-specific memory files with durable insights
   - Propose CLAUDE.md changes if project conventions need updating
   - Update `handoff.md` if there's open work for next session
   - Suggest skill updates if a skill was clunky or missing
   - **Don't just report findings — actually write them down where they'll be found**

4. **Report**
   - Brief summary of key learnings
   - What was persisted and where
   - Any suggestions that need Tom's input

## Optional Arguments

If `$ARGUMENTS` provided, focus reflection on that area:
- "mistakes" — what went wrong and why
- "workflow" — how we worked, not what we built
- "project" — project-specific conventions and patterns
- "meta" — the tools, skills, and process itself

Without arguments, do a general retrospective.

## Important

- **Be honest, not diplomatic.** "We wasted 20 minutes because X" is useful. "The session was productive" is not.
- **Root causes over symptoms.** Don't say "the test failed." Say "we didn't read the existing test patterns before writing new ones."
- **Persist or it didn't happen.** A lesson that only lives in chat history is a lesson that will be relearned.
- **Small > grand.** One concrete memory update beats five vague observations.
- **This is NOT audit.** Use `/audit` for compliance checking. This is about growth.
