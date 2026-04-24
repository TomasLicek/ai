---
name: handoff-update
effort: xhigh
description: Update handoff.xml after a work session - preserve open state, detailed active recovery context, approved next work, planning state, and lasting project learnings
disable-model-invocation: true
argument-hint: [optional guidance]
---

<purpose>
Update the project's `handoff.xml` (always in project root) at the end of a session or before stopping mid-task.
Primary consumer is a **fresh session with zero prior context**. Write so the next agent can safely resume, choose the right next action, and avoid redoing work.
</purpose>

<core_policy>
`handoff.xml` is not a work log, changelog, diary, or proof-of-work document.

Keep only what is useful for future action:
- unfinished active work that must be resumed or checked
- approved next tasks that are ready to execute
- human decisions needed before work can proceed
- unresolved proposal/discussion state when planning is still active
- blocked work and why it is blocked
- accepted backlog items, when the project wants them in this file
- stable project facts, constraints, and landmines

Delete completed items unless the fact is needed to prevent a future agent from redoing or misunderstanding open work.
</core_policy>

<active_exception>
`<active>` is the intentional exception to "not a work log".

When work is interrupted, compacted, or left half-finished, `<active>` MUST contain detailed recent-session recovery notes. Be as detailed as possible while staying relevant: what was attempted, what changed, what was touched, what was verified, what is suspected, what remains, and where the next agent should resume.

This is the only place where "I did X, touched Y, was about to do Z" belongs.
Once that task is completed, abandoned, or converted into a clean future task, remove the recovery notes.
</active_exception>

<authority_order>
Agents should treat sections in this priority order:
1. `<active>` - interrupted work to resume, verify, or finish first
2. `<next>` - approved ready-to-start task packets
3. `<decide>` - questions that need the user
4. `<blocked>` - work that cannot proceed until a reason is cleared
5. `<backlog>` - lower-priority accepted ideas; execute only if mode permits or user asks
6. `<board>` - proposals and discussion; advisory only, not assigned work
7. `<context>` - stable facts and landmines
</authority_order>

<handoff_structure>
Prefer this structure:

```xml
<handoff>
  <tldr>
    3-5 sentences. Current project state, active work, next approved action,
    and what not to redo.
  </tldr>

  <active>
    Interrupted or in-progress work. Detailed recovery notes are required here.
  </active>

  <next>
    Approved executable task packets. These replace separate next-steps files
    as the canonical source of what to do next.
  </next>

  <decide>
    Specific human decisions needed before work can move forward.
  </decide>

  <blocked>
    Tasks that cannot proceed, with concrete reasons and unblock conditions.
  </blocked>

  <board>
    <proposals>
      Agent or human suggestions that are not approved work yet.
    </proposals>
    <discussion>
      Detailed planning discussion, architecture analysis, disagreement,
      tradeoffs, and references tied to proposal IDs.
    </discussion>
  </board>

  <backlog mode="parking_lot">
    Accepted but lower-priority ideas. Do not execute unless promoted to next
    or explicitly requested. For autonomous runs this may be changed to
    mode="agent_pool".
  </backlog>

  <context>
    Stable setup facts, constraints, tooling notes, and landmines.
  </context>
</handoff>
```

Do not force empty sections into the file. Keep the structure readable, but preserve the section semantics.
</handoff_structure>

<section_semantics>
`<active>`:
- Use for interrupted work, compaction recovery, or half-finished implementation.
- Must be detailed. Include files touched, current state, exact left-off point, intended next steps, hypotheses, partial decisions, verification already run, failed attempts, and risks.
- Include enough context that the next agent can resume without asking what happened or rediscovering the same facts.
- Remove after the work is finished or converted to a clean `<next>` task.

`<next>`:
- Use for approved, ready-to-execute work.
- Each task should be a detailed task packet when implementation risk is nontrivial.
- Include goal, files, constraints, implementation plan, acceptance checks, verification commands, and landmines.
- `<next>` is authoritative; agents may execute from here.
- If a plan is too large to fit cleanly, reference a supporting file, but keep the canonical task summary and decision state here.

`<decide>`:
- Use for crisp user choices. Include options and consequences when useful.
- Do not bury decisions in discussion paragraphs.

`<blocked>`:
- Use when work cannot proceed. Include `[reason]`, `[depends]`, and unblock criteria.

`<board>`:
- Use for proposals, agent discussion, alternatives, detailed planning, architecture analysis, and unresolved planning.
- Advisory only. Never treat board proposals as assigned work unless the user explicitly approves/promotes them.
- Discussion can be long and detailed. This is where agents and humans can argue through what to do, what not to do, risks, implementation options, and open questions.
- If the detail is too large, reference a supporting markdown/design file from the relevant proposal or discussion entry. The handoff remains the canonical index and summary.
- Prefer simple proposal IDs (`P1`, `P2`) over elaborate numbering.
- Attribute entries (`by="codex"`, `by="claude"`, `by="gemini"`, `by="tom"`, etc.).

`<backlog>`:
- Use for accepted ideas that are not current.
- `mode="parking_lot"` means backlog is memory for the user/project. Agents must not execute from it unless the user explicitly asks or an item is promoted to `<next>`.
- `mode="agent_pool"` means autonomous agents may pick from it, but only when `<active>`, `<next>`, and `<decide>` are empty or the user explicitly asks for autonomous work.
- Keep backlog items shorter than `<next>` task packets. Expand them only when promoting to `<next>`.

`<context>`:
- Use for durable facts: project setup, commands, architectural constraints, known landmines.
- Lasting knowledge that belongs in project docs, `CLAUDE.md`, or `AGENTS.md` should be written there too. If one is a symlink to the other, update the project's canonical file.
</section_semantics>

<task_packet_templates>
Use an active recovery packet for interrupted work:

```xml
<active>
  <task id="A1" status="interrupted">
    <title>Polish detail page image layout</title>
    <files_touched>
      `app/views/cars/_details.html.erb`
      `app/assets/stylesheets/application.css`
    </files_touched>
    <current_state>
      Started replacing the loose image block with a fixed-ratio gallery area.
      CSS is half-written. Desktop looked plausible; mobile was not checked.
      The image fallback branch still needs review.
    </current_state>
    <what_changed>
      Added wrapper markup around the primary image and started CSS classes for
      image containment. No database or routing changes.
    </what_changed>
    <left_off>
      Inspect the image block, verify the CSS intent, then check mobile width
      before continuing.
    </left_off>
    <intended_next_steps>
      1. Finish empty image state.
      2. Verify HTTP(S) hotlinked images still render.
      3. Check mobile and desktop layout.
      4. Run lint/tests/diff checks listed below.
    </intended_next_steps>
    <verified>
      `bin/lint-views` passed before the CSS change; rerun after editing.
    </verified>
    <failed_or_uncertain>
      Mobile layout not checked. Unsure whether object-fit should be contain
      or cover for dealer images with white backgrounds.
    </failed_or_uncertain>
    <risks>
      Do not loosen CSP broadly. Do not add inline styles or proxy images.
    </risks>
  </task>
</active>
```

Use a next task packet for approved future work:

```xml
<next>
  <task id="N1" priority="high" status="ready">
    <title>Polish car detail page image presentation</title>
    <files>
      `app/views/cars/_details.html.erb`
      `app/assets/stylesheets/application.css`
    </files>
    <goal>
      Make listing images look deliberate and stable without storing, proxying,
      or transforming remote images.
    </goal>
    <constraints>
      No new gems. No React, Node, CSS build step, inline JavaScript,
      inline event handlers, inline styles, or view script blocks.
      Keep CSP strict and images hotlinked.
    </constraints>
    <implementation_plan>
      1. Replace the current loose image rendering with a fixed-ratio image area.
      2. Choose object-fit behavior deliberately.
      3. Add an empty/fallback state for missing or unsafe image URLs.
      4. Check mobile and desktop layout.
    </implementation_plan>
    <acceptance>
      Detail page renders. Invalid image URLs do not render. Layout does not
      stretch or overflow on mobile. Required lint/tests pass.
    </acceptance>
    <verify>
      `bin/lint-views`
      `bin/rails test`
      `git diff --check`
    </verify>
    <landmines>
      Do not proxy images. Do not loosen CSP with broad hosts.
    </landmines>
  </task>
</next>
```

Use board entries for unapproved planning:

```xml
<board>
  <proposals>
    <proposal id="P1" status="proposed">
      <title>Polish detail page image treatment</title>
      <proposed_by>codex</proposed_by>
      <files>`app/views/cars/_details.html.erb`</files>
      <problem>Images can appear white, stretched, or visually weak.</problem>
      <suggestion>Use a constrained gallery treatment with existing CSS.</suggestion>
      <risks>Must preserve hotlinked images and strict CSP.</risks>
      <details_ref>`docs/planning/detail-page-images.md` if deeper analysis is needed</details_ref>
    </proposal>
  </proposals>
  <discussion>
    <entry proposal="P1" by="codex" date="2026-04-24">
      Prefer a CSS-only treatment first because the current constraints forbid
      inline JS, inline styles, new build tooling, and image proxying. Main
      unresolved issue is whether dealer images with white backgrounds should
      use contain, cover, or a hybrid treatment.
    </entry>
    <entry proposal="P1" by="claude" date="2026-04-24">
      Before implementation, inspect several real image URLs and decide the
      desired mobile crop behavior. If the analysis is long, add a referenced
      markdown note and summarize the conclusion here.
    </entry>
  </discussion>
</board>
```
</task_packet_templates>

<workflow>
1. Discover state:
   - read current `handoff.xml`
   - review this session's work and user guidance
   - if useful, inspect git status and recent commits; this is a hint, not a substitute for knowing what happened in the session
   - inspect external planning/design files only when the user references them or the handoff points to them
2. Remove stale/completed work:
   - delete done items from `<active>`, `<next>`, `<blocked>`, and old task categories
   - do not preserve completed-work history unless it protects open work
3. Capture unfinished work:
   - if work is mid-task or context is being compacted, write/update `<active>` with detailed recovery context
   - include files touched, current state, left-off point, intended next steps, verification, uncertainties, failed attempts, and risks
4. Maintain approved next work:
   - convert user-approved plans into detailed `<next>` task packets
   - keep `<next>` focused; do not dump every idea there
5. Maintain planning state:
   - keep unresolved suggestions and detailed planning in `<board>`
   - put human choices in `<decide>`
   - put accepted lower-priority ideas in `<backlog>`
6. Update durable context:
   - update `<context>` for stable facts and landmines
   - update project `CLAUDE.md`, `AGENTS.md`, or the canonical symlink target for lasting learnings when appropriate
7. Update `<tldr>`:
   - summarize current state, active work, next approved action, and important warnings
8. Report briefly:
   - mention what sections changed and any decisions still needed
</workflow>

<git_context>
Git commands are useful context, but they are not the source of truth for what the agent just did.
Use them as a sanity check when helpful:

- Is this a git repo? !`git rev-parse --is-inside-work-tree 2>/dev/null`
- Recent commits: !`git log --oneline -10 2>/dev/null || echo "no commits yet"`
- Changed files: !`git status --short 2>/dev/null || echo "no status available"`
- Recent diff summary: !`git diff --stat HEAD~5..HEAD 2>/dev/null || git diff --stat 2>/dev/null || echo "no diff available"`

Do not blindly infer session state from git alone. Prefer conversation history, actual file inspection, and known work performed in this session.
</git_context>

<planning_file_policy>
Prefer one canonical file: project-root `handoff.xml`.

Supporting markdown/design files are allowed when a proposal, discussion, or task packet is too large to fit cleanly in `handoff.xml`.
When using a supporting file:
- reference it from the relevant `<proposal>`, `<entry>`, `<task>`, or `<context>` item
- keep the canonical status, decision, and next action in `handoff.xml`
- do not let the supporting file become a competing source of truth

Detailed next-step plans normally belong in `<next><task>...</task></next>`.
</planning_file_policy>

<doc_updates>
When we learn something lasting, update the project-level guidance file directly.
Use `CLAUDE.md`, `AGENTS.md`, or the project's canonical symlink target, depending on what the repo uses.
Ask first before editing global guidance such as `~/.claude/CLAUDE.md`.
For project docs, update them when the session changed behavior that docs cover.
</doc_updates>

<arguments>
If the user provides arguments, treat them as freeform guidance:
- "mark image polish active, mobile unchecked"
- "promote P1 to next"
- "move pagination ideas to backlog parking lot"
- "summarize the architecture discussion in board"

Without arguments, infer the update from conversation, known session work, current handoff contents, and file inspection.
</arguments>

<inline_markers>
Use XML child tags for larger structured packets. Inline markers are still acceptable inside list-style sections:
- `[files]:` - relevant paths with line numbers when possible
- `[status]:` - current actionable state
- `[left-off]:` - exact recovery breadcrumb for interrupted work
- `[decided]:` - choices made and reasoning
- `[landmine]:` - gotchas and don't-touch zones
- `[reason]:` - why blocked
- `[depends]:` - dependency on task/person/system
- `[verify]:` - commands or checks to run
- `[see]:` - reference URL or doc

Every actionable item needs relevant files/functions unless the task is purely external.
</inline_markers>
