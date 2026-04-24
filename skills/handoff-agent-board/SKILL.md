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

<modes>
`discussion` mode:
- add proposals
- append detailed discussion
- compare alternatives
- request multiple agent viewpoints
- identify risks, tradeoffs, and open questions
- add or update `<decide>` items

`finalize` mode:
- mark proposals approved, rejected, or superseded
- convert approved proposals into detailed `<next>` task packets
- move accepted but non-urgent ideas into `<backlog>`
- set backlog mode when the user wants autonomous agent work
- summarize what is ready for `/handoff-pickup`

If the user intent is unclear, ask whether they want discussion mode or finalize mode.
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
- `approved` - user accepted the direction; it can be promoted into `<next>` or `<backlog>`
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
- optional `turn="1"`, `turn="2"` when order needs to be explicit

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
</context_rules>

<workflow>
1. Read project-root `handoff.xml`.
   - If missing, ask whether to create one.

2. Read current `<board>`, `<decide>`, `<next>`, and `<backlog>`.

3. Read `<context>`, `<active>`, and `<blocked>` only enough to avoid conflicts and respect constraints.

4. Determine mode:
   - discussion: gather, compare, debate, and document
   - finalize: approve/reject/supersede, promote to `<next>` or `<backlog>`, and clean decision state
   - mixed: do both, but keep discussion and promotion steps explicit

5. If multiple agents or viewpoints are requested or useful:
   - use parallel agents when the runtime and user instructions allow it
   - assign each agent a distinct planning viewpoint or proposal
   - ask for findings, risks, recommendations, and suggested task breakdowns
   - do not assign implementation work
   - main agent merges results into attributed board discussion and task packets

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
Use parallel planning agents when useful and allowed:
- one agent reviews implementation complexity
- one agent reviews UX/product consequences
- one agent reviews performance or architecture risk
- one agent challenges the proposal and lists failure modes
- one agent converts approved proposal details into candidate task packets

Keep write ownership with the main agent. Subagents return analysis; the main agent edits `handoff.xml`.
</parallel_planning_patterns>

<templates>
Proposal:

```xml
<proposal id="P1" status="proposed">
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
