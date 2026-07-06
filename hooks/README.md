# Claude Code Hooks Harness

Per-project, opt-in hooks for Claude Code with a tmux-native toggle and
statusline indicator. No slash commands, no agent turns to flip state.

## Layout

```
~/.claude/hooks/
├── README.md                 # this file
├── double-check-stop.sh      # Stop hook: invokes /double-check skill
├── cursor-review-stop.sh     # Stop hook: cross-agent review via `agent -p`
├── codex-review-stop.sh      # Stop hook: cross-agent review via `codex exec`
└── harness/                  # all framework tooling — back this up as one unit
    ├── gate.sh               # hook_enabled() helper, sourced by every hook
    ├── toggle.sh             # tmux popup (prefix + H) — reads registry, flips flags
    ├── indicator.sh          # statusline badge (red H:<names> when hooks enabled)
    ├── registry              # one line per hook: `name|description`
    └── README.md             # internals docs (framework-maintainer facing)
```

Per-project state lives under `<project>/.claude/`:

```
<project>/.claude/
├── hooks/<name>.enabled   # opt-in flag per hook (touch to enable, rm to disable)
├── cursor-review/         # output of cursor-review (gitignored globally)
│   ├── findings.md        # reviewer output; first line: STATUS: CLEAN|ISSUES: …
│   ├── diff.patch         # input snapshot the reviewer read
│   └── last_hash          # dedup state (skips identical consecutive diffs)
└── codex-review/          # output of codex-review (gitignored globally)
    ├── findings.md        # same STATUS: sentinel convention
    ├── conversation.txt   # extracted session transcript (input)
    ├── changed_files.txt  # code-mode input listing
    └── last_hash          # dedup state
```

`double-check` keeps no state — it just tells Claude to invoke the skill.

## Daily use

- **Toggle in current project** — `prefix + H` in tmux → fzf popup. `Tab` to
  multi-select, `Enter` to flip, `Esc` to cancel. Popup closes after a brief
  pause so you can read the confirmation.
- **See what's enabled** — statusline shows a red `H:<names>` segment when any
  hook is enabled in the current project. Silent when none.
- **Review findings** — `.claude/cursor-review/findings.md` or
  `.claude/codex-review/findings.md`. First line is the sentinel; details
  follow. Open it however you want (`bat`, editor, popup).

## How a hook works

1. Claude Code triggers the registered script at the configured event
   (`Stop`, `PostToolUse`, etc.) with a JSON payload on stdin.
2. The script sources `harness/gate.sh` and bails early unless the project
   opted in via `.claude/hooks/<name>.enabled`.
3. It does its thing. To inject feedback into the current Claude turn, write
   to stderr and `exit 2`. Silent work uses `exit 0`. Anything else is noise.

### Required discipline

- **Stop hooks must honor `stop_hook_active`**. The payload's
  `stop_hook_active=true` means Claude is already re-entering from a prior
  hook iteration. Exit 0 immediately or you'll loop.
- **Atomic writes**. Tom runs multiple Claude panes per project (sessionizer).
  Write to `path.tmp.$$` then `mv -f` to the final name.
- **Dedup when sensible**. Hash the input you'd act on; skip if unchanged from
  the last run.
- **Silent by default**. If the hook has nothing to say, say nothing.

## Adding a new hook

Example: a `lint-stop` hook that runs a linter and flags issues to Claude.

1. **Write the script** — `~/.claude/hooks/lint-stop.sh`:

   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   export PATH="/opt/homebrew/bin:$PATH"
   source "$HOME/.claude/hooks/harness/gate.sh"

   INPUT=$(cat)
   if command -v jq >/dev/null 2>&1; then
     [[ "$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')" == "true" ]] && exit 0
   fi

   hook_enabled lint || exit 0

   # ... do the lint, write findings, exit 2 with message on stderr if issues ...
   ```

   `chmod +x ~/.claude/hooks/lint-stop.sh`.

2. **Register it in `~/.claude/settings.json`** under `hooks`. All Stop hooks
   go as sibling `command` entries inside a single Stop matcher block:

   ```json
   "Stop": [
     {
       "hooks": [
         { "type": "command", "command": "bash ~/.claude/hooks/double-check-stop.sh" },
         { "type": "command", "command": "bash ~/.claude/hooks/cursor-review-stop.sh" },
         { "type": "command", "command": "bash ~/.claude/hooks/lint-stop.sh" }
       ]
     }
   ]
   ```

   Restart Claude Code once after editing settings.json.

3. **Add to the registry** — append to `~/.claude/hooks/harness/registry`:

   ```
   lint|Run linter on Stop, surface issues to Claude
   ```

   The toggle popup and statusline pick it up automatically. No restart needed.

4. **Opt in per project** — `prefix + H` → toggle `lint` on.

### New hook checklist

Every new hook touches five places. Miss one and it fails silently later:

1. Register the script in `~/.claude/settings.json`.
2. Add its gate name to `harness/registry`.
3. Gitignore its output dir globally (`~/.config/git/ignore`) if it writes
   transcripts or findings.
4. Document it in this README (layout + Current hooks).
5. Run the smoke test in `harness/README.md`.

Why this list exists: three past drift bugs (a missing codex-review gitignore
rule, this README missing codex-review entirely, and registry/settings drift)
all came from adding a hook without a checklist.

### Naming conventions

- Hook filename: `<name>-<event>.sh` (e.g. `review-stop.sh`, `lint-posttool.sh`).
- Flag file name (first column in registry) is just `<name>`. The gate flag
  lives at `.claude/hooks/<name>.enabled` regardless of event.
- Keep the registry description short — it's shown in the popup row.

## Troubleshooting

- **Hook not firing** — check in order: `settings.json` has the entry, you
  restarted Claude Code after editing it, the flag file exists in the project,
  the script is executable, `bash -n` on the script passes.
- **Popup does nothing** — `fzf` missing? `brew install fzf`. Registry path
  exists? `cat ~/.claude/hooks/harness/registry`.
- **Statusline stale** — it refreshes on Claude Code's statusline interval.
  Starting a new turn forces an update.
- **Infinite loop** — you forgot the `stop_hook_active` guard. Add it.

## Current hooks

- `double-check` - minimal. Asks Claude to invoke the `/double-check` skill
  before stopping, then summarize in one line. No findings file, no dedup, no
  state. Works because `/double-check` is a skill Claude already knows how to
  run. Use this as the default; it's the cheap, debuggable version.
- `cursor-review` - cross-agent clean-context review on Stop. Writes the diff
  to `.claude/cursor-review/diff.patch`, then shells out to `agent -p`
  (Cursor CLI) with a locked-down prompt. Review comes back on stdout,
  captured atomically into `.claude/cursor-review/findings.md` (first line
  sentinel: `STATUS: CLEAN` or `STATUS: ISSUES: N HIGH, M MEDIUM, K LOW`).
  The `agent` binary must be on PATH; otherwise the hook silently no-ops.
  No auto-fix - Tom decides what to act on.
- `codex-review` - cross-agent clean-context review on Stop, like
  `cursor-review` but shelling out to `codex exec` (Codex CLI) instead of
  `agent`. Two modes, picked from the working tree: a dirty tree reviews the
  code changes with the session transcript as context, a clean tree reviews
  the conversation itself. Writes its inputs and output under
  `.claude/codex-review/` (`conversation.txt`, `changed_files.txt` in code
  mode, `findings.md` with the same `STATUS:` sentinel). Requires a git repo;
  silently no-ops if the `codex` binary isn't on PATH. No auto-fix.

All three hooks share:
- `stop_hook_active` re-entry guard.
- Silent no-op when their gate flag isn't set.

The review hooks (`cursor-review`, `codex-review`) additionally require a git
repo, maintain dedup state (input hash), and write a findings file.
`double-check` is intentionally stateless and git-agnostic — the skill
reviews what happened in the session, not the diff, so it fires anywhere.

## Deferred

- Tmux popup for peeking `findings.md` (prefix + R?).
