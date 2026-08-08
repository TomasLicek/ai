---
name: log-analyze
description: >-
  Record/file a bug into the current project's pm/backlog — writes a standalone
  bug-<slug>.md into the backlog. In a state-folder backlog (maildir style, e.g.
  VinRaptor) it lands in 0-inbox/ and backlog.md is regenerated; in a legacy flat
  backlog it also indexes a one-line bullet under the `## Bugs` section of
  backlog.md. Use whenever the user wants to log, file, capture, jot, note, or
  track a bug / defect / issue / regression for later, even phrased casually
  ("add this to the backlog", "make a note that X is broken", "remember to fix
  Y"). ALSO use proactively when you spot a real bug mid-session that is out of
  scope to fix right now — write it down here instead of losing it. This is for
  RECORDING bugs, not fixing them (use `bugfix` for fixing).
argument-hint: '[freeform bug description]'
---

<purpose>
Capture a bug in the project's `pm/backlog/` with zero ceremony. The script
auto-detects which of two backlog layouts the project uses and does the right
thing for each. Your job is only to produce good content (a sharp title, a
one-line summary, a clear problem).

**State-folder backlog (maildir style, e.g. VinRaptor).** Detected when
`pm/backlog/0-inbox/` exists. Raw drops live in state folders and `backlog.md`
is GENERATED, never hand-edited. The script:

1. Writes a standalone `bug-<slug>.md` into `0-inbox/` (the only raw-drop
   path — the express lane was retired 2026-08-08; urgency is a
   `**Priority:**` header line now, see `--priority` in usage).
2. Runs the repo's `bin/backlog-index` to regenerate `backlog.md`. No bullet is
   inserted by hand. Index regen is best-effort - a failure warns but the bug
   file still lands and the run still succeeds.

**Legacy flat backlog.** The historical two-part convention, so the entry is
indistinguishable from a hand-written one:

1. A standalone `bug-<slug>.md` file (Title + Type/Status/Source line +
   `## Problem` + optional `## Repro`).
2. A linked one-line bullet under `## Bugs` in `backlog.md`, placed before the
   `## Decisions` section.

A pure bash + awk script does the deterministic file plumbing.
</purpose>

<the_script>
`~/.claude/skills/log-analyze/scripts/bug.sh`

Pure bash + awk (no Python). It finds `pm/backlog/` by walking up from the
current directory, then picks a mode by whether `0-inbox/` exists there:

- **State-folder mode:** writes the bug file into `0-inbox/` and runs
  `bin/backlog-index` to regenerate `backlog.md`. It
  never edits `backlog.md` directly. Slug-collision scanning covers every state
  folder (`0-inbox` … `9-shipped`, the full maildir set) as both `bug-<slug>.md`
  files and `bug-<slug>/` folders, because slugs are immutable once assigned.
- **Legacy mode:** slugifies the title, writes the bug file at the backlog root,
  and inserts the index bullet (creating the `## Bugs` section before
  `## Decisions` if it does not exist).

Slug collisions auto-suffix (`-2`, `-3`). `jq` is needed only for `--json` and
`--polish`. On write failure it fails loud with a non-zero exit (never a false
"✓"). Note: legacy mode does not lock `backlog.md`, so two simultaneous runs in
the same repo can race — a non-issue for normal solo/sequential use.
</the_script>

<usage>
There are two paths. Pick by who is driving.

**1. You (Claude) filing a bug mid-session — the primary path.**
You already have the context, so write the fields yourself. Do NOT use
`--polish` (you are the model; polishing would waste a Haiku call to redo work
you can do better). Pass explicit flags and `--json` so you get a clean result:

```
~/.claude/skills/log-analyze/scripts/bug.sh \
  --title "Filmstrip 404s on relisted cars" \
  --summary "Relisted cars render broken filmstrip thumbnails" \
  --problem "After relisting, old image URLs 404 but the filmstrip still references them; the gallery shows broken-image icons." \
  --repro $'Relist a car\nOpen its detail page\nThumbnails are broken' \
  --notes "Likely app/views/cars/_filmstrip.html.erb image_urls filter." \
  --status open \
  --json
```

- `--title`: names the defect, no trailing period.
- `--summary`: ONE line for the index bullet (what a human scanning the backlog
  reads). Keep it specific and short.
- `--problem`: 1-3 plain sentences. Include the file/line if you know it.
- `--repro`: optional, newline-separated steps (omit if there are none).
- `--notes`: optional. Use it when you have context the user didn't give —
  the likely culprit file/line, a related backlog item, or "distinct from X".
  This is the single most valuable thing you can add over a hand-written entry,
  because you have the codebase in front of you. Don't pad it; only add a note
  if you actually know something useful.
- `--status`: defaults to `open`. Use `monitoring` for "watching, no action yet".
- `--slug`: rarely needed — the auto-slug is usually good. Override only if it
  comes out awkward.
- `--priority`: state-folder backlogs only. Stamps a `**Priority:** A1|A2|C`
  line into the drop's header; triage copies it into `ticket.md`. Priority only
  reorders the pipeline (A1 > A2 > B > C) — every ticket still stops at Tom's
  gate, so there is no lane to skip. Pass it ONLY when Tom explicitly states an
  urgency; NEVER infer it from tone. No flag = no line = B, the default (and
  `--priority B` is an error for exactly that reason). In a legacy flat backlog
  `--priority` is an error.

**2. Tom from the terminal — the lazy fallback.**
He brain-dumps one rough sentence. Let a cheap model clean it up with `--polish`:

```
~/.claude/skills/log-analyze/scripts/bug.sh --polish \
  "currency toggle flickers stale price for a sec after switching eur->czk"
```

`--polish` shells to `claude -p --model haiku` to distill a clean title +
summary + problem. If `claude` is unavailable or fails, it silently falls back
to deterministic derivation (first sentence → title, raw text → problem), so it
never breaks. Without `--polish` the raw text is used verbatim — still valid,
just less tidy.
</usage>

<rules>
- Do NOT fix the bug. This skill records it. If the user actually wants it
  fixed now, that is `bugfix` / normal work, not this.
- One bug per invocation. Multiple distinct bugs → call the script once each.
- The summary is the index one-liner — make it scannable, not a paragraph.
- Don't invent repro steps or specifics the user didn't give. An empty Repro is
  fine; a wrong one is worse than none.
- Prefer running from inside the project so the script auto-locates the backlog.
  If cwd is elsewhere, pass `--backlog-dir /path/to/pm/backlog`.
- Use `--dry-run` first only if you're unsure where it will land; normally just
  write it and report back to the user.
- Never hand-edit a generated `backlog.md`. In a state-folder backlog the script
  regenerates it via `bin/backlog-index`; do not touch it yourself.
- After writing, tell the user the file path so they can see exactly what landed.
  In legacy mode also report the index bullet; in state-folder mode report that
  it dropped into `0-inbox/` (and the stamped priority, if any).
</rules>
