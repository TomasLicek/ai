---
name: sketch
disable-model-invocation: true
description: Generate N divergent variants of something — layouts, architectures, approaches — then you pick and combine
argument-hint: <what to generate variants of>
---

# Sketch — Divergent Generation

Fan out N parallel variants of the same thing. Browse results, cherry-pick, combine.

`$ARGUMENTS` = what to generate variants of. Can be anything: a dashboard, an API design, a data pipeline, a component, an algorithm.

If `$ARGUMENTS` is empty, ask what to generate before proceeding.

<orchestrator_workflow>
<step name="clarify">
Before spawning anything:
- Is the task clear enough to fan out? If vague or too broad, ask first. Don't spawn 5 agents toward a fuzzy target.
- What kind of task is this? GUI/visual vs code/architecture vs mixed
- What dimensions should vary? (layout, style, data structure, algorithm, API shape...)
- What stays constant? (same data, same endpoints, same requirements)
- How many variants? Default 5. User can override with `N=3` in arguments.
</step>

<step name="design">
Each variant needs a clear angle — not just "variant 1, variant 2." Name them by what makes them different:

<example>
Dashboard task → "dense-grid", "single-focus", "sidebar-nav", "card-mosaic", "terminal-aesthetic"
Auth system → "jwt-stateless", "session-based", "oauth-delegated", "passkey-first", "hybrid-jwt-session"
Data pipeline → "streaming", "batch-with-checkpoints", "event-sourced", "cqrs-split", "simple-cron"
</example>

State your variant strategy before spawning. Keep it brief.
</step>

<step name="spawn">
Spawn `general-purpose` agents — all in ONE message for true parallelism.
Determine which instruction block applies (GUI or non-GUI or mixed) and include the relevant rules.
</step>

<step name="output">
Relative to the current working directory:
- Standalone files (HTML, scripts) → variants/[variant-name]/
- Files that belong in a project structure → original location with variant suffix: dashboard_dense-grid.tsx, dashboard_sidebar-nav.tsx, etc.
</step>

<step name="present">
After all agents complete:
- Create variants/INDEX.md — one-line summary per variant, what file(s) it produced
- Assess divergence — did variants actually differ, or did two agents converge on the same thing? Flag duplicates.
- Present each variant with its angle and what it does well — let Tom see the full spread
- Note any that failed or went off-brief
- Ask Tom: which to keep, combine, explore further, or kill?

Don't pick a winner. The point is giving Tom options to react to, not pre-digesting the decision.
</step>
</orchestrator_workflow>

<gui_rules>
When the task is visual/frontend:
- Read the `aesthetic` skill's SKILL.md and extract the frontend_aesthetics block and font reference table. Inject both into your approach before building.
- Each variant MUST have a different aesthetic — different font pairing, different palette, different vibe. Don't converge on "neutral."
- State your aesthetic choices before building: font pairing, dominant color(s), one animation idea
- Self-contained HTML files unless project stack dictates otherwise
- Tailwind from CDN for vanilla HTML
- Build to sketch quality: works and looks intentional, not polished
</gui_rules>

<code_rules>
When the task is code/architecture:
- Variants differ in structural approach, not cosmetics
- Each variant should be functional — runnable or at minimum compilable
- Include a brief comment block at top explaining the tradeoff this variant represents
- If tests exist and the variant's interface is compatible, run them. Otherwise note that tests assume a different structure.
- Commit fully to your variant's angle. Don't hedge or add "this could also work if we…"
</code_rules>

<universal_rules>
For all variants:
- This is a sketch, not production code. Functional but not overpolished.
- One variant = one coherent point of view. Full commitment to the angle.
- Don't return walls of text to stdout — write files. Orchestrator will present the lineup.
- If this is a small task and some variants feel too similar, say so. Genuine divergence > wasted variation.
</universal_rules>
