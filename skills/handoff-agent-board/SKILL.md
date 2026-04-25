---
name: handoff-agent-board
effort: xhigh
description: Manage handoff.xml planning board - run multi-agent discussion, resolve proposals, and promote approved plans into next tasks or backlog without implementing code
disable-model-invocation: true
argument-hint: [optional planning guidance]
---

<purpose>
Manage planning in project-root `handoff.xml`.

This skill is the board chair / planning manager. Use it to run human/agent or multi-agent discussion, compare approaches, capture detailed planning, resolve proposals, and assign approved work into `<next>` or `<backlog>`.

This skill plans and assigns work. It does not implement code and does not resume interrupted implementation work.
</purpose>

<cross_lab_mode>
The board is the shared artifact for semi-automated multi-agent, multi-lab discussion (Claude, Codex, Gemini, etc.). Tom dispatches turns between CLIs manually — no automation layer yet.

Core rules:
- **Turn tracking.** Each open proposal carries a `next_turn` attribute naming who is expected to act next:
  - `next_turn="agent"` 
  - `next_turn="user"` - waiting on the user to answer a question or make a decision
- **One turn per proposal per invocation.** When invoked as an agent participant (not as chair), inspect the relevant open proposal threads. If multiple proposals are admitted for the current agent, handle each admitted proposal once in the same invocation. Append at most one attributed `<entry>` per proposal thread unless the user explicitly dispatches multiple turns on the same proposal. Do not write turns for other agents. No ventriloquism — do not roleplay `by="codex"` from a Claude session or vice versa.
- **Same-agent consecutive turns are fine.** A proposal may have several consecutive turns by the same agent (e.g. Claude thinking aloud across sessions). The protocol does not require alternation — `next_turn` does.
- **Advance the turn on exit.** After appending an entry, update `next_turn`: name the agent whose input is actually needed next, set it to `tom` if the thread now needs the human, or clear it to `""` if the thread is open floor. Do not leave `next_turn` pointing at yourself after you just spoke unless you explicitly intend to take another turn without dispatch.
- **Chair role is separate.** When the user explicitly asks for synthesis, finalization, or cross-thread cleanup, the chair may do more than one thing per invocation (still no ventriloquism — chair synthesis is attributed `by="<current-agent>"` and labeled as synthesis, not as someone else's turn).
- **Stopping / convergence.** Aim for at least 3 full back-and-forth rounds before setting `next_turn="tom"`. Do not escalate just because the current agent's view feels settled — the other lab may still have useful pushback or a different angle. Exception: if the issue is genuinely simple and both agents have explicitly converged (not just one feeling done), escalating after 2 rounds is fine. When in doubt, pass to the other lab first. After rounds produce no new evidence or positions repeat, propose `needs_decision`, set `next_turn="tom"`, and add a `<decide>` item. Do not re-litigate.
- **Turn length.** Keep turns tight — aim for ≤ ~300 words. If analysis is longer, extract to a supporting markdown file via `details_ref` and keep the entry as a summary + pointer.

<turn_admission_rule>
Before appending a turn, check each relevant open proposal's `next_turn`. If the user did not name a specific proposal, "relevant" means every open proposal whose `next_turn` names the current agent or is unset/empty:

- **MAY speak** on a proposal when any of:
  - `next_turn` names the current agent (e.g. you are Claude and `next_turn="claude"`)
  - `next_turn` is unset or empty (open floor)
  - the user dispatched this session with an explicit instruction to speak (e.g. "take a turn on P2", "respond to codex on P1"). User dispatch wins over `next_turn` — including when `next_turn="tom"`, if Tom explicitly delegates his turn to you.
- **MUST decline** on a proposal when `next_turn` is set to any value other than the current agent (another lab, or `tom`) AND the user did not dispatch otherwise AND none of the watchdog conditions below apply. Do not append to that proposal. If no proposals were admitted and no watchdog conditions apply, output a short note naming the expected speaker (e.g. "P2 is awaiting codex; not speaking." or "P3 is waiting on Tom; not speaking.") so the dispatcher can route correctly. Silence is worse than a one-line status.
- **Out-of-turn watchdog exception**: any agent MAY append a single flagging entry to any proposal — even when `next_turn` names another agent or `tom` — when it spots one of the following:
  - (a) **Constraint violation**: the discussion direction would break a known rule (CSP, Bulma-only, no inline styles/JS, CLAUDE.md policy, stack constraints from `<context>`).
  - (b) **Factual error**: a prior entry states something wrong about files, schema, routes, behavior, or project history in a way that would send the thread to a wrong conclusion.
  - (c) **Scope drift**: discussion is drifting toward implementation work the skill must not do, toward promoting something that isn't clearly approved, or away from the stated problem in the proposal.
  - (d) **Decision-altering missing insight**: something no prior entry addressed that materially changes which option is correct or safe — not "I have a preference," but "this changes the outcome."
  The threshold is "this will cause real harm if uncorrected now." Disagreement with style or framing is not a flag. Mark the entry with `type="flag"` so the thread stays navigable. After appending a watchdog entry, do NOT steal `next_turn` from whoever holds it — set it back to the prior holder, or escalate to `tom` if the flagged issue requires a human call.
- **New proposals**: any agent may add a new proposal without dispatch — that is how cross-lab ideas enter the board. Set `next_turn` on the new proposal to whoever should respond (often `tom`, sometimes another lab, rarely open floor). Do not spam: one new proposal per invocation unless the user asks for more.
- **Consecutive same-agent turns**: allowed whenever `next_turn` still names the current agent after the previous turn, or when the user explicitly dispatches another turn. This covers "Claude thinking aloud across sessions" and does not require alternation.
- **After speaking**, always update `next_turn` on the proposal — name the agent whose input is actually needed next, set it to `tom` if the thread now needs the human (question, decision, dispatch), or clear it to `""` if open floor. Never leave `next_turn` silently pointing at yourself unless you intend to continue without dispatch.
</turn_admission_rule>
</cross_lab_mode>

<modes>
`participant` mode (default for agent-as-speaker):
- invoked by a dispatch like "take a turn on P1", "respond to codex on P2", or simply "you're up on the board"
- read the relevant proposal thread(s), check `next_turn`, apply the `<turn_admission_rule>`
- if admitted, append exactly one attributed `<entry>` with a required `turn="N"` to each admitted proposal thread and update that proposal's `next_turn` on exit
- if a proposal is declined, skip that proposal; if all relevant proposals are declined, output a one-line status naming the expected speaker and stop — no other edits
- **watchdog exception**: even in participant mode, append a single `type="flag"` entry to any proposal where you spot a constraint violation, factual error, scope drift, or decision-altering missing insight — regardless of `next_turn`. After the flag, restore `next_turn` to its prior holder or escalate to `tom`. See the out-of-turn watchdog exception in `<turn_admission_rule>` for the exact threshold.
- do NOT also add proposals, restructure threads, promote tasks, or synthesize other labs' views in this mode
- this is the mode that implements the cross-lab turn-taking loop; do not confuse with discussion/finalize

`discussion` mode:
- broader planning work beyond a single dispatched turn
- add proposals
- append detailed discussion (still one entry per admitted proposal if acting as a participant)
- compare alternatives
- request multiple agent viewpoints (only when the user explicitly asks to spawn intra-lab subagents)
- identify risks, tradeoffs, and open questions
- add or update `<decide>` items

`finalize` mode:
- mark proposals approved, rejected, or superseded when they stay on the board
- convert approved proposals into detailed `<next>` task packets
- move accepted but non-urgent ideas into `<backlog>`
- set backlog mode when the user wants autonomous agent work
- remove proposals from `<board>` after promoting them into `<next>` or `<backlog>`
- summarize what is ready for `/handoff-pickup`

Default assumption: if the user dispatched a specific turn ("take a turn on P1", "respond on P2"), you are in `participant` mode — do not ask whether to discuss/finalize. Only ask for clarification if the dispatch is genuinely ambiguous (e.g. "look at the board" with no target).
</modes>

<scope>
May touch:
- `<board>`
- `<board><proposals>`
- `<board><proposal><discussion>`
- `<decide>`
- `<next>` when promoting approved executable work
- `<backlog>` when parking accepted ideas or creating an autonomous task pool
- `<context>` when planning produces durable project facts, decisions, constraints, or landmines

May read:
- `<context>` for constraints and landmines
- `<active>` to avoid conflicting with interrupted work
- `<next>` and `<backlog>` to avoid duplicates
- `<blocked>` to avoid proposing blocked work as ready
- supporting markdown/design files referenced by board entries

Must not touch:
- `<active>`
- `<blocked>`

Do not edit implementation files. If implementation should start, leave clear `<next>` tasks for `/handoff-pickup` or the next agent.
</scope>

<clarity_first>
If the planning goal, proposal meaning, approval state, target section, or assignment is unclear, stop and ask before modifying `handoff.xml`.

Do not guess at user intent. Ask the smallest concrete question that unblocks the board or promotion update.
</clarity_first>

<board_semantics>
`<board>` is planning state, not assigned work.

Use it for:
- proposals that are not executable work yet
- detailed discussion between agents and humans
- architecture and design analysis
- competing approaches and tradeoffs
- risks, constraints, and "do not do this" reasoning
- references to larger supporting files

Do not use it for:
- active recovery notes
- approved executable task packets
- completed work history
- backlog memory that is not being discussed
</board_semantics>

<proposal_rules>
Use simple proposal IDs: `P1`, `P2`, `P3`.

Proposal statuses:
- `proposed` - idea is open for discussion
- `needs_decision` - blocked on a human choice
- `approved` - user accepted the direction; ready to promote into `<next>` or `<backlog>`
- `rejected` - user rejected it; keep briefly only if useful
- `superseded` - replaced by another proposal

Each proposal should include enough context to discuss it without rediscovery:
- title
- proposed_by
- files or areas affected
- problem
- suggestion
- risks
- open questions
- details_ref when deeper analysis lives in a supporting file
- `<discussion>` child containing that proposal's chronological entries
- `next_turn` attribute naming the agent expected to speak next (or unset/empty for "open floor")

Avoid agent-owned proposal sections such as `<codex_proposals>` or `<claude_proposals>`.
The board is organized by proposal and discussion thread, not by agent territory.
</proposal_rules>

<discussion_rules>
Discussion entries should be detailed when the topic needs detail.
Agents and humans append entries inside the owning proposal's `<discussion>`
child and take turns there. Do not put all proposal discussion in one
board-level `<discussion>` section. Do not create per-agent discussion
sections. Preserve chronology within each proposal.

Use discussion for:
- why an approach is good or bad
- what assumptions need testing
- likely implementation risks
- architectural consequences
- disagreement between agents
- notes from code or design review
- references to supporting analysis files

Entries should be attributed:
- `by="codex"`, `by="claude"`, `by="gemini"`, `by="tom"`, etc.
- `turn="N"` — **required** when appending to an existing thread. Monotonic per proposal; read the last entry's `turn` and increment. For the first entry in a thread, use `turn="1"`. This is the only reliable chronology signal in a human-routed cross-lab loop.

**Critical but honest engagement.** When reading a prior entry from another agent:
- Assume the other agent's reasoning may be incomplete, biased toward its own framing, or missing a constraint you know. Start from mild suspicion, not deference.
- If after scrutiny the point is genuinely sound, say so explicitly and move on. Hollow agreement ("I agree with everything above") is useless. Real agreement names what you checked and why it held up.
- Pushback for its own sake is equally useless. Only challenge when you have a concrete reason: a missing constraint, a different reading of the spec, a failure mode the other agent didn't model. No reflexive contrarianism.
- The goal is a better decision, not winning the exchange.

Good discussion entries often do one of these:
- propose an approach
- challenge a prior entry with a specific reason
- concede a prior point after checking it, and explain what you verified
- add evidence from file inspection
- identify a decision needed from the user
- summarize convergence or remaining disagreement

If analysis is too long for `handoff.xml`, create or reference a supporting markdown/design file. Keep the proposal-local discussion entry as the canonical index: summary, status, decision needed, and file reference.
</discussion_rules>

<decide_rules>
Add or update `<decide>` when planning needs a human decision.

A good decision item includes:
- proposal ID
- the question
- concrete options
- consequences or tradeoffs
- what becomes possible after the decision

Do not bury required user choices inside long discussion entries.
</decide_rules>

<promotion_rules>
Promote only when approval is clear from the user or the current session context.
If approval is not clear, keep the proposal in `<board>` and add/update `<decide>`.

Promote to `<next>` when:
- the work is approved
- the work is ready to execute
- dependencies and constraints are clear
- acceptance checks can be stated
- it should be picked up before lower-priority backlog work

Promote to `<backlog mode="parking_lot">` when:
- the idea is accepted but not current
- it is useful project memory
- agents should not execute it unless the user asks or it is later promoted to `<next>`

Promote to `<backlog mode="agent_pool">` when:
- the user wants autonomous agents to have a task pool
- tasks are safe to pick independently after `<active>`, `<next>`, and `<decide>` are clear
- each item is specific enough that an agent can start or ask a bounded clarification

Promotion should preserve traceability:
- include `from_proposal="P1"` on promoted tasks/items when useful
- ensure the promoted task/item is self-sufficient before deleting board discussion: either include the implementation details directly, or include a `details_ref`/supporting-file reference to the canonical plan
- remove the proposal, including its nested `<discussion>`, from `<board>` after the promoted task/item exists
- do not keep a shortened duplicate proposal in `<board>` just to say where it went
- put any durable outcome in `<context>` only if it is a lasting project fact, constraint, or landmine
- keep rejected/superseded proposals only when their reasoning prevents future re-litigation
</promotion_rules>

<task_quality>
When promoting to `<next>` or `<backlog>`, create a very detailed executable task packet. We do not want to reinvent the wheel again when start implementing. Add `details_reference_files` to a supporting plan/design file when the scope or implementation plan is too large/long to fit into handoff.xml

If the task is unclear or would depend on deleted board discussion to execute, do not promote it. Ask or leave it in `<decide>`.
</task_quality>

<context_rules>
Update `<context>` to store context that is not a long term (such context belongs to CLAUDE.md or documentation).

Do not put discussion, rejected alternatives, or temporary planning notes in `<context>`. Keep those in `<board>`.

If the fact also belongs in project guidance, update `CLAUDE.md` and relevant`documentation`.
</context_rules>

<workflow>

1. Read project-root `handoff.xml`.
   - If missing, ask whether to create one.

2. Read current `<board>`, `<decide>`, `<next>`, and `<backlog>`.

3. Read `<context>`, `<active>`, and `<blocked>` only enough to avoid conflicts and respect constraints.

4. Determine mode:
   - participant: default for a dispatched turn; append one entry per admitted proposal, update each touched `next_turn`, and stop
   - discussion: gather, compare, debate, and document
   - finalize: approve/reject/supersede, promote to `<next>` or `<backlog>`, and clean decision state
   - mixed: do both, but keep discussion and promotion steps explicit

5. If the user explicitly asks this skill to spawn subagents for parallel viewpoints (e.g. "have a risk reviewer and a UX reviewer weigh in on P3"):
   - spawn subagents only on explicit request — do not fan out by default
   - this is an intra-lab helper, not the cross-lab mechanism; cross-lab turns are routed by Tom between CLIs (see `<cross_lab_mode>`)
   - assign each subagent a distinct planning viewpoint or proposal
   - ask for findings, risks, recommendations, and suggested task breakdowns
   - do not assign implementation work
   - main agent merges subagent results into a single attributed entry under its own `by=` — no ventriloquism for other labs

6. For discussion mode:
   - add/update proposals
   - append detailed attributed discussion
   - add `<decide>` items for unresolved human choices
   - keep dissent when it prevents future re-litigation

7. For finalize mode:
   - confirm approval is clear
   - create detailed `<next>` packets for ready work
   - create `<backlog>` items for accepted later work
   - remove promoted proposals, including nested discussion, from `<board>` after traceability is captured with `from_proposal`
   - mark only unpromoted proposals as approved, rejected, superseded, or needs_decision
   - update `<context>` for durable decisions, constraints, or landmines
   - update or remove resolved `<decide>` items

8. Report briefly:
   - proposals changed or removed
   - decisions added/resolved
   - tasks promoted to `<next>`
   - items moved to backlog and backlog mode
   - context facts updated
   - what `/handoff-pickup` should do next
   </workflow>

<parallel_planning_patterns>
Intra-lab only. Spawn subagents **only when the user explicitly asks** this skill to bring in multiple viewpoints from within the current lab (e.g. "have a risk reviewer and a UX reviewer weigh in"). Default behavior is one agent speaking once per admitted proposal in an invocation.

This is distinct from cross-lab turn-taking, which is always human-routed between CLIs — subagents of the current lab never speak as other labs.

When subagents are explicitly requested:
- possible roles: implementation complexity, UX/product consequences, performance/architecture risk, challenge / failure modes, task-packet drafter
- subagents return analysis; main agent edits `handoff.xml`
- merged output becomes a single proposal-local `<entry>` attributed `by="<current-agent>"` summarizing the subagents' findings — not multiple entries faking cross-lab participation
- keep write ownership with the main agent
</parallel_planning_patterns>

<templates>
Proposal with local discussion:

```xml
<proposal id="P1" status="proposed" next_turn="claude">
  <title>Polish detail page image treatment</title>
  <proposed_by>codex</proposed_by>
  <files>`app/views/cars/_details.html.erb`</files>
  <problem>Images can appear white, stretched, or visually weak.</problem>
  <suggestion>Use a constrained gallery treatment with existing CSS.</suggestion>
  <risks>Must preserve hotlinked images and strict CSP.</risks>
  <open_questions>
    Should dealer images use object-fit contain or cover on mobile?
  </open_questions>
  <details_ref>`docs/planning/detail-page-images.md`</details_ref>
  <discussion>
    <entry by="codex" date="2026-04-24" turn="1">
      Prefer a CSS-only treatment first because current constraints forbid
      inline JS, inline styles, new build tooling, and image proxying. The main
      unresolved design choice is whether preserving the full dealer image
      matters more than filling the frame consistently on mobile.
    </entry>
  </discussion>
</proposal>
```

Discussion turn-taking examples:

```xml
<proposal id="P1" status="needs_decision" next_turn="tom">
  ...
  <discussion>
    <entry by="codex" date="2026-04-24" turn="1">
      Prefer a CSS-only treatment first because current constraints forbid
      inline JS, inline styles, new build tooling, and image proxying.
    </entry>

    <entry by="claude" date="2026-04-24" turn="2">
      I disagree with choosing cover by default. Dealer photos often include
      the whole car against a white background, and cropping can remove
      important visual information.
    </entry>

    <entry by="gemini" date="2026-04-24" turn="3">
      Implementation risk is low if this stays CSS-only. The main test risk is
      layout regression on narrow screens.
    </entry>

    <entry by="codex" date="2026-04-24" turn="4">
      Convergence: contain-first is safer for dealer images. Remaining decision
      for Tom: accept contain-first now, or require screenshot review before
      promotion to next.
    </entry>
  </discussion>
</proposal>
```

Challenge / response example:

```xml
<proposal id="P2" status="proposed" next_turn="tom">
  ...
  <discussion>
    <entry by="codex" date="2026-04-24" turn="1">
      Proposal: add a grid mode after detail-page polish. It would improve
      browsing for visual comparison but touches index layout, card density,
      and responsive behavior.
    </entry>

    <entry by="claude" date="2026-04-24" turn="2">
      Challenge: grid mode may require pagination and filters to feel useful.
      If implemented first, it could create throwaway layout work.
    </entry>

    <entry by="tom" date="2026-04-24" turn="3">
      Decision: accepted as future work only. Do not put it in next yet.
    </entry>
  </discussion>
</proposal>
```

External detail reference example:

```xml
<proposal id="P3" status="proposed" next_turn="tom">
  ...
  <details_ref>`docs/planning/search-ux-options.md`</details_ref>
  <discussion>
    <entry by="codex" date="2026-04-24" turn="1">
      I wrote the long comparison in `docs/planning/search-ux-options.md`.
      Summary: filters should come before grid mode because they change the
      data contract and determine which layout states need support.
    </entry>
  </discussion>
</proposal>
```

Long-form multi-agent review example:

```xml
<proposal id="P4" status="needs_decision" next_turn="tom">
  ...
  <discussion>
    <entry by="codex" date="2026-04-24" turn="1">
      I reviewed the proposed "rate limit car detail pages" idea against the
      current Rails surface. My recommendation is not to add app-specific
      throttling code directly in `CarsController#show`; prefer one
      request-level mechanism.
    </entry>

    <entry by="claude" date="2026-04-24" turn="2">
      I mostly agree, but I want to sharpen the failure mode. The risky part is
      the full set of cheap negative lookups: malformed IDs, valid-looking
      nonexistent VINs, stale slug redirects, and lowercase variants.
    </entry>

    <entry by="gemini" date="2026-04-24" turn="3">
      Performance perspective: split the eventual implementation into
      route/input hardening and request throttling. I would not put this in
      `agent_pool` while the deployment layer is unknown.
    </entry>

    <entry by="codex" date="2026-04-24" turn="4">
      Synthesis: all reviewers agree that controller-local throttling is the
      wrong default and that the missing deployment-layer decision blocks
      implementation. The useful output from this thread is a decision item,
      not a next task.
    </entry>
  </discussion>
</proposal>
```

Promoted next task:

```xml
<task id="N1" from_proposal="P1" priority="high" status="ready">
  <title>Polish car detail page image presentation</title>
  <files>`app/views/cars/_details.html.erb`</files>
  <goal>Make listing images stable and deliberate without proxying remote images.</goal>
  <constraints>Keep CSP strict. No inline styles or JavaScript.</constraints>
  <implementation_plan>
    1. Replace loose image rendering with a fixed-ratio image area.
    2. Choose object-fit behavior from the approved board decision.
    3. Add fallback state for missing or unsafe image URLs.
  </implementation_plan>
  <acceptance>Mobile and desktop layout do not stretch or overflow.</acceptance>
  <verify>`bin/lint-views`; `bin/rails test`; `git diff --check`</verify>
</task>
```

Backlog item:

```xml
<item id="B1" from_proposal="P2" status="accepted">
  <title>Add grid mode for car listings</title>
  <why>Useful future UX improvement, but not part of current detail-page polish.</why>
  <files>`app/views/cars/index.html.erb`</files>
</item>
```
</templates>

<rules>
- Do not implement code.
- Do not touch `<active>` or `<blocked>`.
- Promote only when approval is clear.
- Ask if anything is unclear.
- Keep proposal IDs simple.
- Discussion may be long and detailed when needed.
- Use supporting files for very large analysis, but keep board status canonical.
- Update `<context>` only for durable facts, not temporary discussion.
- Preserve dissent and rejected reasoning when it prevents future re-litigation.
- Make promoted `<next>` tasks detailed enough for `/handoff-pickup` to execute.
- **Aim for 3 agent rounds before escalating to Tom.** One agent feeling done is not convergence — pass to the other lab first. Exception: escalate earlier only if the issue is simple and both agents have explicitly agreed. When in doubt, keep the ball in play between labs.
- **Speak up when you spot a real problem, even out of turn.** Constraint violations, factual errors, scope drift, and decision-altering missing insights are interruption-worthy regardless of `next_turn`. Use `type="flag"` on the entry and give the turn back to its prior holder. Reflexive contrarianism or stylistic preference is not a flag — the threshold is "this will cause real harm if uncorrected now."
</rules>
