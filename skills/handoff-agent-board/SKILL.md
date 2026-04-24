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
The board is the shared artifact for semi-automated multi-agent, multi-lab discussion (Claude, Codex, Gemini, etc.). Tom dispatches turns between CLIs manually — no automation layer yet. Design the loop so it survives with a human in the middle.

Core rules:
- **Turn tracking.** Each open proposal carries a `next_turn` attribute naming who is expected to act next. Three distinct values:
  - `next_turn="<agent>"` — that agent (e.g. `"claude"`, `"codex"`, `"gemini"`) is expected to speak next
  - `next_turn="tom"` — thread is waiting on the human (answer a question, make a decision, or dispatch the next speaker)
  - unset / empty — open floor: no one is specifically expected; any agent may speak or Tom may dispatch
  These three are semantically distinct. Do not conflate "waiting on Tom" with "open floor."
- **One turn per invocation.** When invoked as an agent participant (not as chair), append exactly one attributed `<entry>` to the thread and stop. Do not also write turns for other agents. No ventriloquism — do not roleplay `by="codex"` from a Claude session or vice versa.
- **Same-agent consecutive turns are fine.** A proposal may have several consecutive turns by the same agent (e.g. Claude thinking aloud across sessions). The protocol does not require alternation — `next_turn` does.
- **Advance the turn on exit.** After appending an entry, update `next_turn`: name the agent whose input is actually needed next, set it to `tom` if the thread now needs the human, or clear it to `""` if the thread is open floor. Do not leave `next_turn` pointing at yourself after you just spoke unless you explicitly intend to take another turn without dispatch.
- **Chair role is separate.** When the user explicitly asks for synthesis, finalization, or cross-thread cleanup, the chair may do more than one thing per invocation (still no ventriloquism — chair synthesis is attributed `by="<current-agent>"` and labeled as synthesis, not as someone else's turn).
- **Stopping / convergence.** After ~3 substantive turns without new evidence, or when positions repeat, propose moving the thread to `needs_decision`, set `next_turn="tom"`, and add a `<decide>` item. Do not re-litigate.
- **Turn length.** Keep turns tight — aim for ≤ ~300 words. If analysis is longer, extract to a supporting markdown file via `details_ref` and keep the entry as a summary + pointer.

<turn_admission_rule>
Before appending a turn, check each open proposal's `next_turn`:

- **MAY speak** on a proposal when any of:
  - `next_turn` names the current agent (e.g. you are Claude and `next_turn="claude"`)
  - `next_turn` is unset or empty (open floor)
  - the user dispatched this session with an explicit instruction to speak (e.g. "take a turn on P2", "respond to codex on P1"). User dispatch wins over `next_turn` — including when `next_turn="tom"`, if Tom explicitly delegates his turn to you.
- **MUST decline** on a proposal when `next_turn` is set to any value other than the current agent (another lab, or `tom`) AND the user did not dispatch otherwise. Do not append. Output a short note naming the expected speaker (e.g. "P2 is awaiting codex; not speaking." or "P3 is waiting on Tom; not speaking.") so the dispatcher can route correctly. Silence is worse than a one-line status.
- **New proposals**: any agent may add a new proposal without dispatch — that is how cross-lab ideas enter the board. Set `next_turn` on the new proposal to whoever should respond (often `tom`, sometimes another lab, rarely open floor). Do not spam: one new proposal per invocation unless the user asks for more.
- **Consecutive same-agent turns**: allowed whenever `next_turn` still names the current agent after the previous turn, or when the user explicitly dispatches another turn. This covers "Claude thinking aloud across sessions" and does not require alternation.
- **After speaking**, always update `next_turn` on the proposal — name the agent whose input is actually needed next, set it to `tom` if the thread now needs the human (question, decision, dispatch), or clear it to `""` if open floor. Never leave `next_turn` silently pointing at yourself unless you intend to continue without dispatch.
</turn_admission_rule>
</cross_lab_mode>

<modes>
`participant` mode (default for agent-as-speaker):
- invoked by a dispatch like "take a turn on P1", "respond to codex on P2", or simply "you're up on the board"
- read the relevant proposal thread, check `next_turn`, apply the `<turn_admission_rule>`
- if admitted, append exactly one attributed `<entry>` with a required `turn="N"` and update `next_turn` on exit
- if declined, output a one-line status naming the expected speaker and stop — no other edits
- do NOT also add proposals, restructure threads, promote tasks, or synthesize other labs' views in this mode
- this is the mode that implements the cross-lab turn-taking loop; do not confuse with discussion/finalize

`discussion` mode:
- broader planning work beyond a single dispatched turn
- add proposals
- append detailed discussion (still one entry per invocation if acting as a participant)
- compare alternatives
- request multiple agent viewpoints (only when the user explicitly asks to spawn intra-lab subagents)
- identify risks, tradeoffs, and open questions
- add or update `<decide>` items

`finalize` mode:
- mark proposals approved, rejected, superseded, or promoted
- convert approved proposals into detailed `<next>` task packets
- move accepted but non-urgent ideas into `<backlog>`
- set backlog mode when the user wants autonomous agent work
- summarize what is ready for `/handoff-pickup`

Default assumption: if the user dispatched a specific turn ("take a turn on P1", "respond on P2"), you are in `participant` mode — do not ask whether to discuss/finalize. Only ask for clarification if the dispatch is genuinely ambiguous (e.g. "look at the board" with no target).
</modes>

<scope>
May touch:
- `<board>`
- `<board><proposals>`
- `<board><discussion>`
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
- `promoted` - already promoted into `<next>` or `<backlog>` (use `from_proposal` on the promoted item to close the loop)
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
- `next_turn` attribute naming the agent expected to speak next (or unset/empty for "open floor")

Avoid agent-owned proposal sections such as `<codex_proposals>` or `<claude_proposals>`.
The board is organized by proposal and discussion thread, not by agent territory.
</proposal_rules>

<discussion_rules>
Discussion entries should be detailed when the topic needs detail.
Agents and humans append entries to the same proposal thread and take turns.
Do not create per-agent discussion sections. Preserve chronology.

Use discussion for:
- why an approach is good or bad
- what assumptions need testing
- likely implementation risks
- architectural consequences
- disagreement between agents
- notes from code or design review
- references to supporting analysis files

Entries should be attributed:
- `proposal="P1"`
- `by="codex"`, `by="claude"`, `by="gemini"`, `by="tom"`, etc.
- `date="YYYY-MM-DD"`
- `turn="N"` — **required** when appending to an existing thread. Monotonic per proposal; read the last entry's `turn` and increment. For the first entry in a thread, use `turn="1"`. This is the only reliable chronology signal in a human-routed cross-lab loop.

Good discussion entries often do one of these:
- propose an approach
- challenge a prior entry
- answer a prior concern
- add evidence from file inspection
- identify a decision needed from the user
- summarize convergence or remaining disagreement

If analysis is too long for `handoff.xml`, create or reference a supporting markdown/design file. Keep the board entry as the canonical index: summary, status, decision needed, and file reference.
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
- leave the proposal marked `approved`, `superseded`, or `promoted`
- keep a short board note explaining where it went
</promotion_rules>

<next_task_quality>
When promoting to `<next>`, create a detailed executable task packet:
- title
- files or areas
- goal
- constraints
- implementation plan
- acceptance criteria
- verification commands/checks
- landmines
- dependencies
- owner/agent suggestions when useful
- parallelization notes when useful

If the task is unclear, do not promote it. Ask or leave it in `<decide>`.
</next_task_quality>

<backlog_quality>
Backlog items can be shorter than `<next>` packets, but they still need:
- title
- source proposal
- why it matters
- files or areas when known
- status
- constraints or landmines if important

If `mode="agent_pool"`, backlog items must be concrete enough for autonomous agents to choose safely.
</backlog_quality>

<context_rules>
Update `<context>` when planning resolves a durable fact that future agents should treat as background truth:
- architectural decisions
- project-wide constraints
- stable workflow policy
- tool or command landmines
- "do not do this" rules that should outlive the proposal

Do not put discussion, rejected alternatives, or temporary planning notes in `<context>`.
Keep those in `<board>`.

If the fact also belongs in project guidance, update `CLAUDE.md`, `AGENTS.md`, or the canonical symlink target when appropriate.

Do not update `<context>` or project guidance in `participant` mode. A participant turn appends one discussion entry, updates `next_turn`, and stops.
</context_rules>

<workflow>
1. Read project-root `handoff.xml`.
   - If missing, ask whether to create one.

2. Read current `<board>`, `<decide>`, `<next>`, and `<backlog>`.

3. Read `<context>`, `<active>`, and `<blocked>` only enough to avoid conflicts and respect constraints.

4. Determine mode:
   - participant: default for a dispatched turn; append one entry, update `next_turn`, and stop
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
   - mark proposal status
   - create detailed `<next>` packets for ready work
   - create `<backlog>` items for accepted later work
   - update `<context>` for durable decisions, constraints, or landmines
   - update or remove resolved `<decide>` items
   - leave board traceability without duplicating full task text

8. Report briefly:
   - proposals changed
   - decisions added/resolved
   - tasks promoted to `<next>`
   - items moved to backlog and backlog mode
   - context facts updated
   - what `/handoff-pickup` should do next
</workflow>

<parallel_planning_patterns>
Intra-lab only. Spawn subagents **only when the user explicitly asks** this skill to bring in multiple viewpoints from within the current lab (e.g. "have a risk reviewer and a UX reviewer weigh in"). Default behavior is one-agent-one-turn per invocation.

This is distinct from cross-lab turn-taking, which is always human-routed between CLIs — subagents of the current lab never speak as other labs.

When subagents are explicitly requested:
- possible roles: implementation complexity, UX/product consequences, performance/architecture risk, challenge / failure modes, task-packet drafter
- subagents return analysis; main agent edits `handoff.xml`
- merged output becomes a single `<entry>` attributed `by="<current-agent>"` summarizing the subagents' findings — not multiple entries faking cross-lab participation
- keep write ownership with the main agent
</parallel_planning_patterns>

<templates>
Proposal:

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
</proposal>
```

Discussion turn-taking examples:

```xml
<entry proposal="P1" by="codex" date="2026-04-24" turn="1">
  Prefer a CSS-only treatment first because current constraints forbid inline
  JS, inline styles, new build tooling, and image proxying. The main unresolved
  design choice is whether preserving the full dealer image matters more than
  filling the frame consistently on mobile.
</entry>

<entry proposal="P1" by="claude" date="2026-04-24" turn="2">
  I disagree with choosing cover by default. Dealer photos often include the
  whole car against a white background, and cropping can remove important
  visual information. I would use contain for the primary image, then improve
  the surrounding frame so whitespace looks intentional rather than broken.
</entry>

<entry proposal="P1" by="gemini" date="2026-04-24" turn="3">
  Implementation risk is low if this stays CSS-only. The main test risk is
  layout regression on narrow screens. Before promotion, the task packet should
  require checking at least one mobile viewport and one desktop viewport.
</entry>

<entry proposal="P1" by="codex" date="2026-04-24" turn="4">
  Convergence: contain-first is safer for dealer images, and the implementation
  can still make the frame feel deliberate. Remaining decision for Tom: accept
  contain-first now, or require screenshot review before promotion to next.
</entry>
```

Challenge / response example:

```xml
<entry proposal="P2" by="codex" date="2026-04-24" turn="1">
  Proposal: add a grid mode after detail-page polish. It would improve browsing
  for visual comparison but touches index layout, card density, and responsive
  behavior, so it should not be mixed into the detail-page task.
</entry>

<entry proposal="P2" by="claude" date="2026-04-24" turn="2">
  Challenge: grid mode may require pagination and filters to feel useful. If
  implemented first, it could create throwaway layout work. I recommend moving
  this to backlog parking_lot until index search priorities are decided.
</entry>

<entry proposal="P2" by="tom" date="2026-04-24" turn="3">
  Decision: accepted as future work only. Do not put it in next yet.
</entry>
```

External detail reference example:

```xml
<entry proposal="P3" by="codex" date="2026-04-24" turn="1">
  I wrote the long comparison in `docs/planning/search-ux-options.md`.
  Summary: filters should come before grid mode because they change the data
  contract and determine which layout states need support. Board status should
  track the decision here; the markdown file is supporting evidence only.
</entry>
```

Long-form multi-agent review example:

```xml
<entry proposal="P4" by="codex" date="2026-04-24" turn="1">
  I reviewed the proposed "rate limit car detail pages" idea against the
  current Rails surface. The relevant entry point is
  `app/controllers/cars_controller.rb`, especially the `show` action and the
  VIN extraction path in `app/models/car.rb`. The current route shape in
  `config/routes.rb` makes `/cars/:id` public and stable, so rate limiting
  needs to protect detail-page enumeration without breaking normal browsing or
  canonical redirects.

  My recommendation is not to add app-specific throttling code directly in
  `CarsController#show`. That would mix request policy into the controller and
  make redirects, 404s, and successful detail views diverge. Prefer one
  request-level mechanism, ideally Rack/Rails middleware or an existing
  framework hook if the app already has one. The important behavior is to count
  all `/cars/*` attempts, including malformed VINs and stale slugs, because
  enumeration pressure does not care whether the VIN exists.

  Arguments for doing it now:
  1. VIN-backed URLs are public and predictable.
  2. The show action deliberately distinguishes visible cars from missing cars,
     which is correct product behavior but still gives attackers a cheap route
     to hammer.
  3. The controller has focused tests already, so adding request-level behavior
     can be covered with a small integration test.

  Arguments against doing it now:
  1. There is no evidence yet of abusive traffic.
  2. Adding a dependency or cache-backed limiter may create deployment work
     larger than the current detail-page polish.
  3. If the project does not already have shared request throttling, this may
     deserve a broader policy decision rather than a one-route patch.

  Suggested decision: put this in backlog parking_lot unless Tom wants a
  security-hardening slice now. If promoted, the task packet should require
  checking existing middleware/config first and should forbid controller-local
  counters unless no better project pattern exists.
</entry>

<entry proposal="P4" by="claude" date="2026-04-24" turn="2">
  I mostly agree, but I want to sharpen the failure mode. The risky part is not
  just successful `/cars/:slug-vin` requests. It is the full set of cheap
  negative lookups: malformed IDs, valid-looking nonexistent VINs, stale slug
  redirects, and lowercase variants. If rate limiting is only applied after
  `Car.visible.find_by!`, attackers can still force database work before the
  limiter matters.

  Files I would inspect before implementation:
  - `config/application.rb` and environment configs for existing middleware.
  - `Gemfile` for Rack::Attack or similar dependencies.
  - `config/initializers/*` for request policy already in place.
  - `test/controllers/cars_controller_test.rb` for redirect and bad-route
    behavior that must keep passing.

  Best-practice angle: rate limiting should sit as close to the request edge as
  this app can reasonably support. If there is a reverse proxy in production,
  that may be the right layer. If not, Rack middleware is better than a
  controller before_action because it can count requests before route/controller
  work and keeps policy centralized.

  I would not promote this directly to next yet because we are missing an
  environment fact: where should throttling live in this deployment? That is a
  context/decision item, not just an implementation detail. I recommend adding
  a `<decide>` question: "Should `/cars/*` rate limiting be handled in app
  middleware, production proxy, or deferred?" Once answered, this becomes a
  precise task.
</entry>

<entry proposal="P4" by="gemini" date="2026-04-24" turn="3">
  Performance perspective: the detail-page path currently does a VIN parse,
  visible scope lookup, and eager loads brand/model for successful records.
  That is cheap under normal use, but negative traffic can still hit routing,
  controller, and database paths repeatedly. The strongest lightweight defense
  is to reject invalid shapes early and rate-limit valid-looking attempts by IP
  and path family.

  I would split the eventual implementation into two independent checks:
  1. Route/input hardening: make sure malformed paths are rejected before DB
     lookup wherever possible. This is partly already covered by route
     constraints and `Car.vin_from_param`.
  2. Request throttling: cap repeated `/cars/*` requests regardless of whether
     they return 200, 301, or 404.

  Testing recommendation:
  - Keep existing canonical redirect tests unchanged.
  - Add one limiter test for repeated canonical detail requests.
  - Add one limiter test for repeated malformed or nonexistent VIN attempts.
  - Do not assert exact response copy unless the project already standardizes
    rate-limit responses.

  My conclusion differs slightly from Claude's: if the deployment layer is
  unknown, an app-level backlog item can still be written, but it should be
  marked `blocked` or `needs_decision` on deployment policy. I would not put it
  in `agent_pool`, because autonomous agents cannot safely pick the right layer
  without that missing context.
</entry>

<entry proposal="P4" by="codex" date="2026-04-24" turn="4">
  Synthesis: all reviewers agree that controller-local throttling is the wrong
  default and that the missing deployment-layer decision blocks implementation.
  The useful output from this thread is a decision item, not a next task.

  Proposed board outcome:
  - Mark P4 as `needs_decision`.
  - Add a `<decide>` item asking where `/cars/*` throttling should live.
  - If Tom chooses app-level middleware, promote a focused next task that first
    inspects existing middleware/config and then implements a centralized
    limiter with request tests.
  - If Tom chooses proxy-level throttling, move the app code task to backlog or
    manual/deployment notes instead of changing Rails code.
</entry>
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
</rules>
