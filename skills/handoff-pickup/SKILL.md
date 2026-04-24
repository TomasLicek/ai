---
name: handoff-pickup
effort: xhigh
description: Session startup - read handoff.xml, resume active work first, choose approved next work, surface decisions, and respect board/backlog authority
disable-model-invocation: true
---

<purpose>
Read the project's `handoff.xml` (always in project root) and start a session from cold context.
Primary producer is `/handoff-update`; this skill is the consumer.

Goal: understand current project state, resume interrupted work safely, and choose the right next action without redoing work or treating planning notes as approved tasks.
</purpose>

<clarity_first>
If an active task, next task, backlog item, or user request is unclear, stop and ask for clarification before implementing.

This is mandatory even when the handoff contains detailed notes. Detailed does not always mean unambiguous. If there are unresolved choices, contradictory instructions, vague acceptance criteria, missing file ownership, unclear priority, or a decision that could materially change the implementation, ask the user.

Do not guess through ambiguity. Ask early, with the smallest concrete question that unblocks the work.
</clarity_first>

<source_of_truth>
`handoff.xml` is the canonical planning and pickup file.
Supporting markdown/design files may be referenced from it, but they are not competing sources of truth.
Read supporting files only when the handoff points to them or the user asks.
</source_of_truth>

<authority_order>
Read and act in this priority order:
1. `<active>` - interrupted work to resume, verify, or finish first
2. `<next>` - approved ready-to-start task packets
3. `<decide>` - questions that need the user
4. `<blocked>` - work that cannot proceed until a reason is cleared
5. `<backlog>` - lower-priority accepted ideas; execute only if mode permits or user asks
6. `<board>` - proposals and discussion; advisory only, not assigned work
7. `<context>` - stable facts and landmines

If `<active>` exists, do not skip to fresh work unless the user explicitly redirects.
</authority_order>

<section_semantics>
`<active>`:
- Treat as the highest priority recovery surface.
- Expect detailed recent-session notes: files touched, what changed, left-off point, failed attempts, verification, uncertainties, and intended next steps.
- First verify the current working tree and the described state. Do not blindly trust stale recovery notes.
- If the recovery path, intended result, or next action is unclear, ask the user before editing.
- Resume, complete, or ask if the recovery path is unsafe.

`<next>`:
- Treat as approved executable work.
- Prefer the highest-priority ready task unless the user names a different task.
- Read the full task packet: goal, files, constraints, implementation plan, acceptance checks, verification, landmines.
- If a task references supporting files, read only the relevant referenced files.
- If the task packet is not clear enough to execute safely, ask the user before editing.

`<decide>`:
- Surface crisp decisions to the user before doing work that depends on them.
- Include enough context and consequences that the user can answer quickly.
- If multiple decisions exist, group them, but keep the ask concise.

`<blocked>`:
- Display the reason and unblock condition.
- Ask whether the blocking condition changed only if it matters for this session.

`<backlog>`:
- Check the `mode` attribute.
- `mode="parking_lot"` means memory only. Do not execute from it unless the user explicitly asks or an item is promoted to `<next>`.
- `mode="agent_pool"` means agents may pick from it when `<active>`, `<next>`, and `<decide>` are empty, or when the user asks for autonomous work.
- When choosing from backlog, promote or restate the chosen item as an explicit current task before execution.
- If a backlog item is vague, ask before turning it into implementation work.

`<board>`:
- Planning, proposals, discussion, disagreement, architecture analysis, and options.
- Never treat board entries as assigned work.
- In pickup mode, do not touch or modify board content.
- Read board only when needed to understand context for an already selected task or when the user explicitly asks to discuss planning.
- Proposal IDs may be simple (`P1`, `P2`). Keep references intact when discussing them.

`<context>`:
- Load as background knowledge: setup facts, constraints, commands, landmines.
- Do not turn context bullets into tasks unless the user asks.
</section_semantics>

<startup_workflow>
1. Read project-root `handoff.xml`.
   - If missing, say so and ask whether to create one or continue without it.

2. Read `<context>` enough to understand constraints and landmines.

3. Inspect active project state when useful:
   - current git status
   - relevant files named by `<active>` or `<next>`
   - referenced supporting docs
   Git is a sanity check, not a substitute for reading the handoff.

4. Triage by authority order:
   - if `<active>` has tasks, summarize the interrupted work and resume/verify the most urgent one
   - else if `<next>` has ready tasks, select the highest-priority ready task
   - else if `<decide>` has items, ask the user for the needed choices
   - else if `<blocked>` matters, surface blockers
   - else if `<backlog mode="agent_pool">` is available and no higher-priority section blocks work, choose a backlog item
   - do not enter `<board>` from pickup unless the user explicitly asks for planning discussion

5. Before editing files:
   - state the selected task and why it is authoritative
   - mention key files and constraints
   - read the relevant files
   - if anything remains unclear after reading, ask the user before editing

6. After doing work:
   - verify with the task's listed checks where feasible
   - update `handoff.xml` via `/handoff-update` behavior if state changed
   - remove completed active recovery notes instead of leaving a work log
</startup_workflow>

<delegation_policy>
This skill should be aggressive about safe parallel delegation when the runtime and user instructions allow it.

Use parallel agents when:
- there are multiple independent `<active>` or `<next>` tasks
- a task naturally splits across disjoint files, features, or responsibilities
- the subtasks will not collide in the same files
- one subtask's decisions will not materially change another subtask
- the next local step is not blocked on the delegated result

Do not delegate when:
- the work is ambiguous and needs user clarification first
- tasks depend on each other's design decisions
- tasks are likely to create merge conflicts
- the task is urgent on the critical path and should be done locally first
- the only available work is `<board>` discussion or `<backlog mode="parking_lot">` memory

When delegating:
- give each agent a bounded task and relevant handoff excerpts
- include files, constraints, decisions, landmines, and verification expectations
- avoid duplicate work across agents
- do not let agents execute from `<board>`
- require agents to ask back if their delegated task is unclear
- verify returned work before treating it as done
</delegation_policy>

<decision_prompts>
When user input is needed:
- ask the minimum number of questions needed to unblock work
- include concrete options when the tradeoff is clear
- reference proposal/task IDs when present
- avoid asking about backlog or board items unless they affect the current session
</decision_prompts>

<inline_markers>
Inline markers may appear in old or mixed-format handoffs:
- `[files]:` - relevant paths with line numbers
- `[status]:` - current actionable state
- `[left-off]:` - exact recovery breadcrumb for interrupted work
- `[decided]:` - choices made and reasoning
- `[landmine]:` - gotchas and don't-touch zones
- `[reason]:` - why blocked
- `[depends]:` - dependency on task/person/system
- `[verify]:` - commands or checks to run
- `[see]:` - reference URL or doc

Treat markers as hints, not a full schema. Prefer explicit XML task packets when present.
</inline_markers>

<rules>
- Be concise in the user-facing startup summary, but do not skip important state.
- If anything is unclear, ask before implementing.
- Do not touch `<board>` in pickup mode unless the user explicitly asks for planning discussion.
- Do not execute from `<backlog mode="parking_lot">` without explicit user direction.
- Use safe parallel agents aggressively for independent active/next work when allowed.
- Do not leave completed work in handoff as a history log.
- Always respect constraints and landmines from `<context>`, `<active>`, and `<next>`.
- Verify delegated or local work before marking it done.
</rules>
