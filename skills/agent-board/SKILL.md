---
name: agent-board
effort: medium
description: Run planning and discussion on the handoff.xml board - add proposals, debate options, capture decisions, and promote approved work into next tasks or backlog. No implementation. Use for planning sessions, architecture discussions, and resolving open questions.
argument-hint: [optional planning topic or proposal ID to focus on]
---

<purpose>
Run planning and discussion on the project's `handoff.xml` `<board>`.

Use this skill to open new proposals, debate approaches, compare tradeoffs, record decisions, and promote approved work into `<next>` or `<backlog>`. It does not implement code, does not touch `<active>` or `<blocked>`, and does not resume interrupted work.

Two modes:
- `discussion` — add proposals, explore approaches, debate tradeoffs, capture risks, record open questions, add `<decide>` items
- `finalize` — approve or reject proposals, promote to `<next>` or `<backlog>`, clean up resolved state

Default to `discussion` unless the user explicitly asks to finalize or promote.
</purpose>

<clarity_first>
If the planning goal, proposal meaning, approval state, or target section is unclear, stop and ask before modifying `handoff.xml`.

The smallest concrete question that unblocks the session is always better than guessing.
</clarity_first>

<scope>
May touch:
- `<board>` and its `<proposal>` children
- `<decide>`
- `<next>` when promoting approved executable work
- `<backlog>` when parking accepted ideas
- `<context>` when planning produces durable project facts, decisions, constraints, or landmines

May read:
- `<context>` for constraints and landmines
- `<active>` to avoid conflicting with interrupted work
- `<next>` and `<backlog>` to avoid duplicates
- `<blocked>` to avoid proposing blocked work as ready
- supporting markdown/design files referenced by proposals

Must not touch:
- `<active>`
- `<blocked>`

Do not edit implementation files.
</scope>

<board_semantics>
`<board>` is planning state, not assigned work.

Use it for:
- proposals not yet executable
- detailed discussion of approaches and tradeoffs
- architecture and design analysis
- risks, constraints, and "do not do this" reasoning
- references to supporting analysis files

Do not use it for:
- active recovery notes
- approved executable task packets
- completed work history
- backlog memory that is not being discussed
</board_semantics>

<proposal_rules>
Use simple proposal IDs: `P1`, `P2`, `P3`.

Statuses:
- `proposed` — idea is open for discussion
- `needs_decision` — blocked on a human choice
- `approved` — direction accepted; ready to promote
- `rejected` — user rejected it; keep only when reasoning prevents future re-litigation
- `superseded` — replaced by another proposal

Each proposal should include enough context to discuss without rediscovery:
- title
- proposed_by
- files or areas affected
- problem
- suggestion
- risks
- open_questions
- `details_ref` when deeper analysis lives in a supporting file
- `<discussion>` child with chronological entries

Do not create agent-owned sections (`<claude_proposals>`, etc.). Board is organized by proposal, not by contributor territory.
</proposal_rules>

<discussion_rules>
Discussion entries live inside the owning proposal's `<discussion>` child. Do not create a shared board-level discussion section.

Attribute every entry:
- `by="tom"`, `by="claude"`, etc.
- `date="YYYY-MM-DD"`
- `turn="N"` — monotonic per proposal; read the last entry's number and increment

Good discussion entries do one of:
- propose an approach
- challenge a prior entry with a specific reason
- concede a prior point after checking it (name what you verified)
- add evidence from file inspection
- identify a decision needed from the user
- summarize convergence or remaining disagreement

**Critical engagement, not deference.** Assume prior entries may be incomplete or framing-biased. Check them. If they hold up, say so and name what you verified. If they do not, say why with a concrete reason — not just a preference. Hollow agreement and reflexive contrarianism are equally useless.

If analysis is too long for `handoff.xml`, write a supporting markdown file and keep the discussion entry as a summary + `details_ref`.
</discussion_rules>

<decide_rules>
Add a `<decide>` item when planning needs a human decision before work can be promoted.

A good decide item includes:
- proposal ID
- the question
- concrete options
- consequences or tradeoffs
- what becomes possible after the decision

Do not bury required human choices inside long discussion entries.
</decide_rules>

<promotion_rules>
Promote only when approval is clearly stated by the user or unambiguous from session context. If unclear, keep in `<board>` and add/update `<decide>`.

Promote to `<next>` when:
- work is approved and ready to execute
- dependencies and constraints are clear
- acceptance checks can be stated
- it should be picked up before lower-priority backlog

Promote to `<backlog mode="parking_lot">` when:
- idea is accepted but not current
- agents must not auto-execute it

Promote to `<backlog mode="agent_pool">` when:
- user wants agents to have an autonomous task pool
- each item is specific enough to start or ask a bounded clarification

Traceability: include `from_proposal="P1"` on promoted items. Make the promoted item self-sufficient — either inline the implementation details or include a `details_ref`. Remove the proposal and its `<discussion>` from `<board>` after promotion. Do not leave a shortened duplicate behind. Put durable outcomes in `<context>` only if they are lasting project facts, constraints, or landmines.

Keep rejected/superseded proposals only when their reasoning prevents future re-litigation.
</promotion_rules>

<task_quality>
When promoting to `<next>`, create a detailed executable task packet. The goal is that `/handoff-pickup` can execute it without rediscovering context.

Include: goal, files, constraints, implementation plan (ordered steps), acceptance checks, verify commands.

Add a `details_ref` to a supporting file when the scope is too large for `handoff.xml`.

If the task is unclear or would depend on deleted board discussion, do not promote it — ask or leave in `<decide>`.
</task_quality>

<context_rules>
Update `<context>` for session-durable but not permanent facts (session-scoped decisions, temporary constraints).

Permanent project facts belong in `CLAUDE.md` or documentation — put them there AND in `<context>` if needed mid-session.

Do not put discussion, rejected alternatives, or temporary planning notes in `<context>`.
</context_rules>

<workflow>
1. Read project-root `handoff.xml`. If missing, ask whether to create one.

2. Read `<board>`, `<decide>`, `<next>`, `<backlog>`.

3. Read `<context>`, `<active>`, `<blocked>` enough to avoid conflicts.

4. Determine mode from user intent:
   - `discussion` — add/update proposals, debate, document tradeoffs, add `<decide>` items
   - `finalize` — approve/reject, promote to `<next>` or `<backlog>`, clean up
   - default to `discussion` when unclear

5. For discussion:
   - add or update proposals with full context
   - append attributed discussion entries
   - add `<decide>` items for unresolved human choices
   - keep dissent when it prevents re-litigation

6. For finalize:
   - confirm approval is clear
   - create detailed `<next>` packets for ready work
   - create `<backlog>` items for accepted later work
   - remove promoted proposals (including nested discussion) from `<board>`
   - mark remaining unpromoted proposals with final status
   - update `<context>` for durable decisions or landmines
   - update or remove resolved `<decide>` items

7. Report briefly:
   - proposals added or changed
   - decisions added or resolved
   - tasks promoted to `<next>`
   - items moved to backlog
   - context updated
   - what `/handoff-pickup` should do next
</workflow>

<templates>
New proposal:

```xml
<proposal id="P1" status="proposed">
  <title>Short decision title</title>
  <proposed_by>tom</proposed_by>
  <files>`app/controllers/cars_controller.rb`</files>
  <problem>What is wrong or unclear.</problem>
  <suggestion>What direction to explore.</suggestion>
  <risks>What could go wrong. Stack constraints to respect.</risks>
  <open_questions>
    What needs a human decision before this can be promoted?
  </open_questions>
  <discussion>
    <entry by="tom" date="2026-05-11" turn="1">
      Opening framing.
    </entry>
  </discussion>
</proposal>
```

Discussion entry:

```xml
<entry by="claude" date="2026-05-11" turn="2">
  Concrete response. What I checked. What I agree with and why.
  What I challenge and the specific reason. What decision is still needed.
</entry>
```

Promoted next task:

```xml
<task id="N1" from_proposal="P1" priority="high" status="ready">
  <title>Do the thing</title>
  <files>`app/views/cars/index.html.erb`</files>
  <goal>Outcome in one sentence.</goal>
  <constraints>CSP strict. No inline styles. No inline JS.</constraints>
  <implementation_plan>
    1. Step one.
    2. Step two.
    3. Step three.
  </implementation_plan>
  <acceptance>Measurable done condition.</acceptance>
  <verify>`bin/lint-views`; `bin/rails test`; `git diff --check`</verify>
</task>
```

Backlog item:

```xml
<item id="B10" from_proposal="P2" status="accepted">
  <title>Future idea title</title>
  <why>Why accepted but not now.</why>
  <files>`app/views/cars/index.html.erb`</files>
</item>
```
</templates>

<rules>
- Do not implement code.
- Do not touch `<active>` or `<blocked>`.
- Promote only when approval is clear.
- Ask if anything is unclear before modifying `handoff.xml`.
- Keep proposal IDs simple.
- Discussion may be long and detailed when the topic warrants it.
- Use supporting files for large analysis; keep board status canonical.
- Update `<context>` only for durable facts — not temporary discussion.
- Preserve dissent and rejected reasoning when it prevents future re-litigation.
- Make promoted `<next>` tasks detailed enough for `/handoff-pickup` to execute cold.
</rules>
