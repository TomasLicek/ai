---
name: handoff-pickup
description: Session startup - read handoff.md, triage items, spawn agents for delegatable work, surface decisions needed
disable-model-invocation: true
---

# Handoff Pickup

Read the project's `handoff.md` (always in project root) and orchestrate session startup.

## Handoff Structure

The handoff file uses XML category tags with optional inline markers.

**Common categories:**
- `<delegate>` - Work that can be handled autonomously → spawn subagents
- `<backlog>` - Lower priority but often delegatable → spawn subagents when appropriate
- `<decide>` - Needs human choice → surface via AskUserQuestion
- `<manual>` - Human must act (external systems, physical actions) → display
- `<blocked>` - Cannot progress → display with reasons
- `<exploring>` - Open-ended research, no clear deliverable → offer to continue
- `<context>` - Reference info, not actionable → load silently

**Other categories may exist** - if you encounter unlisted categories, interpret them sensibly based on their name and contents.

**Common inline markers (examples, not exhaustive):**
- `[why]:` - motivation, impact
- `[left-off]:` / `[progress]:` - where we stopped
- `[constraint]:` - rules, gotchas
- `[reason]:` - why blocked
- `[next]:` - suggested next step
- `[see]:` - reference file/url
- `[depends]:` - dependency on another item

**Inline markers are optional, not mandatory.** Create new markers as needed - if `[deadline]:` or `[owner]:` or `[risk]:` makes sense for an item, use it.

## Model Selection for Subagents

- **Haiku** - simple tasks: delete files, create files, cleanup, rename
- **Sonnet** - medium work: refactoring, research, multi-file edits
- **Opus** - coding: new features, complex bugs, architectural changes

## Workflow

1. **Read `handoff.md`** from project root

2. **Parse categories** - identify items by their XML tags

3. **Triage and act:**

   **`<delegate>` and `<backlog>` items:**
   - Spawn subagents (parallel when independent)
   - Select model based on complexity (haiku/sonnet/opus)
   - Pass any inline marker context to the agent
   - For backlog: most items are delegatable but use judgment

   **`<decide>` items:**
   - Batch into AskUserQuestion (up to 4 questions)
   - Present options clearly with context

   **`<manual>` items:**
   - Display as a checklist for the human
   - Note any dependencies

   **`<blocked>` items:**
   - Display with reason prominently
   - Ask if situation has changed

   **`<exploring>` items:**
   - Briefly mention what's being explored
   - Offer to spawn Explore agent to continue

   **`<context>` items:**
   - Load silently as background knowledge
   - Don't display or act

   **Unknown categories:** Interpret based on name and act sensibly.

   **Note:** Use AskUserQuestion with ANY category when clarification would help - not just `<decide>` items.

4. **Verify and wrap up:**
   - If agents were spawned, verify their work before marking done
   - Update `handoff.md` if items completed or state changed
   - End with clear picture: what's running, what needs human input, what's blocked

## Important

- Keep asking until you fully understand what needs to be done
- Be concise in communication but don't skip important topics
- Not all sections required - handoff can have any subset
- Inline markers are optional - add your own when useful
- Categories are guidance - create new ones if needed
- Always verify delegated work before marking done
