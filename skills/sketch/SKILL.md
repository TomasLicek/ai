---
name: sketch
disable-model-invocation: true
description: Generate N divergent variants of something — layouts, architectures, approaches — then you pick and combine
argument-hint: <what to generate variants of>
---

# Sketch — Divergent Generation

Fan out N parallel variants of the same thing. Browse results, cherry-pick, combine.

## Input

`$ARGUMENTS` = what to generate variants of. Can be anything: a dashboard, an API design, a data pipeline, a component, an algorithm.

If `$ARGUMENTS` is empty, ask what to generate before proceeding.

## How It Works

### 1. Clarify and analyze

Before spawning anything:

- **Is the task clear enough to fan out?** If vague or too broad, ask first. Don't spawn 5 agents toward a fuzzy target.
- **What kind of task is this?** GUI/visual vs code/architecture vs mixed
- **What dimensions should vary?** (layout, style, data structure, algorithm, API shape...)
- **What stays constant?** (same data, same endpoints, same requirements)
- **How many variants?** Default 5. User can override with `N=3` in arguments.

### 2. Design the variants

Each variant needs a **clear angle** — not just "variant 1, variant 2." Name them by what makes them different:

<example>
Dashboard task → "dense-grid", "single-focus", "sidebar-nav", "card-mosaic", "terminal-aesthetic"
Auth system → "jwt-stateless", "session-based", "oauth-delegated", "passkey-first", "hybrid-jwt-session"
Data pipeline → "streaming", "batch-with-checkpoints", "event-sourced", "cqrs-split", "simple-cron"
</example>

State your variant strategy before spawning. Keep it brief.

### 3. Spawn parallel agents

Spawn `general-purpose` agents — **all in ONE message** for true parallelism.

Each agent gets:

```
Generate variant: [VARIANT_NAME]
Angle: [what makes this variant distinct]
Task: [original task description]
Constants: [what must stay the same across all variants]

Write output to: [output path]

Rules:
- This is a sketch, not production code. Functional but not polished.
- Commit fully to this variant's angle. Don't hedge toward "balanced."
- One variant = one coherent point of view.
- [GUI-specific or code-specific rules — see below]
```

### 4. Output location

Relative to the current working directory:
- Standalone files (HTML, scripts) → `variants/[variant-name]/`
- Files that belong in a project structure → original location with variant suffix: `dashboard_dense-grid.tsx`, `dashboard_sidebar-nav.tsx`, etc.

### 5. Present the lineup

After all agents complete:

- Create `variants/INDEX.md` — one-line summary per variant, what file(s) it produced
- **Assess divergence** — did variants actually differ, or did two agents converge on the same thing? Flag duplicates.
- **Present each variant** with its angle and what it does well — let Tom see the full spread
- Note any that failed or went off-brief
- Ask Tom: which to keep, combine, explore further, or kill?

Don't pick a winner. The point is giving Tom options to react to, not pre-digesting the decision.

## GUI Tasks

When the task is visual/frontend:

- **Read the `aesthetic` skill's SKILL.md** and extract the `<frontend_aesthetics>` block and font reference table. Inject both into each agent's prompt.
- Each variant MUST have a **different aesthetic** — different font pairing, different palette, different vibe
- Agents should state their aesthetic choices before building
- Self-contained HTML files unless project stack dictates otherwise
- Tailwind from CDN for vanilla HTML

## Non-GUI Tasks

When the task is code/architecture:

- Variants differ in **structural approach**, not cosmetics
- Each variant should be functional — runnable or at minimum compilable
- Include a brief comment block at top explaining the tradeoff this variant represents
- If tests exist and the variant's interface is compatible, run them. Otherwise note that tests assume a different structure.

## Rules

- Agents write files, they don't return walls of text
- Don't over-specify the variants — give each agent creative room within its angle
- If the task is too small for N variants (e.g., "a button"), reduce N and say why
- Variants that are too similar = wasted. Push for genuine divergence.
