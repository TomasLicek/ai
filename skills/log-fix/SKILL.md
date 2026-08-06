---
name: log-fix
description: >-
  Record a bug/task into the backlog EXPRESS lane (pm/backlog/0-inbox-express/) so
  the automated pipeline analyzes it and proceeds straight to implementation
  WITHOUT Tom's review stop. Use ONLY when Tom explicitly pre-blesses the
  item ("this is a clear bug, just do it", "log and fix", "fix it anyway",
  "skip my review", "/log-fix"). Never infer express intent - if Tom just
  wants something recorded, that is `log-analyze` (normal lane, waits for his
  review after triage). Requires a state-folder backlog (0-inbox-express/ exists);
  there is no express lane in legacy flat backlogs.
argument-hint: '[freeform bug/task description]'
---

<purpose>
The express twin of `log-analyze`. Same capture mechanics, different lane:
the file lands in `pm/backlog/0-inbox-express/`, which triage stamps with
`**Lane:** express` - after analysis and verification the issue moves directly
to `4-queue/` for agent pickup, skipping Tom's review parking lot
(`3-analyzed/`), and the deploy stage auto-merges it without Tom's tap.
Analysis, cross-model review, and browser testing are never skipped; only the
human stops are. The fast path applies only to Tom-authored items - anything
third-party gets demoted back through Tom's gate at verify-analysis.

Everything is delegated to the shared script with `--express`. Your job is
only good content: sharp title, one-line summary, clear problem, and done
criteria the pipeline can verify.
</purpose>

<the_script>
`~/.claude/skills/log-analyze/scripts/bug.sh` - shared with log-analyze, invoked
with `--express`. It errors out on legacy flat backlogs (no `0-inbox-express/`),
which is correct: no express lane there.
</the_script>

<usage>
You (Claude) write the fields yourself - you have the context. No `--polish`.

```
~/.claude/skills/log-analyze/scripts/bug.sh --express \
  --title "Filmstrip 404s on relisted cars" \
  --summary "Relisted cars render broken filmstrip thumbnails" \
  --problem "After relisting, old image URLs 404 but the filmstrip still references them." \
  --notes "Likely app/views/cars/_filmstrip.html.erb image_urls filter. Done when: relisted car detail shows placeholder, not broken image." \
  --json
```

Field guidance is identical to log-analyze (see its SKILL.md). One addition
that matters MORE here: because no human reviews this before an agent picks
it up, put checkable done criteria in `--notes` whenever you can - the
implementing agent gets no conversation context, only the file.
</usage>

<rules>
- Express is Tom's call, never yours. If he did not clearly pre-bless it,
  use `log-analyze` instead and tell him it went to the normal lane.
- Do NOT fix the bug in-session. Express means the PIPELINE fixes it; if
  Tom wants it fixed right now by you, that is normal work, not this skill.
- One item per invocation.
- Since this skips Tom's review AND his merge tap (express deploys to
  production autonomously): be extra conservative about scope. If the
  description is ambiguous or the fix could touch anything risky, say so
  and suggest the normal lane - a wrong express ticket ships wrong code.
- After writing, report the file path and remind that it will proceed
  all the way to production without Tom's review.
</rules>
