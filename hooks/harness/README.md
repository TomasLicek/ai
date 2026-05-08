# Harness — internals

This folder holds everything that is **not itself a hook** but supports hooks:
the gating library, the interactive toggle, and the registry that powers the
toggle's UI.

The parent folder (`~/.claude/hooks/`) holds *actual hook scripts* (the
things Claude Code invokes) and the user-facing `README.md`. If you're
trying to *use* or *add* a hook, read that one first. This file is for
people — or agents — touching the framework itself.

---

## Files

```
harness/
├── gate.sh       # sourced by hook scripts; `hook_enabled NAME` predicate
├── toggle.sh     # launched by tmux (prefix + H); interactive flag flipper
├── indicator.sh  # prints "H:foo,bar" badge for tmux / Claude Code statusLine
├── registry      # plain-text list of hooks the toggle should offer
└── README.md     # this file
```

Nothing in this folder is invoked by Claude Code directly. Claude Code calls
hook scripts (`~/.claude/hooks/<name>-<event>.sh`); those scripts in turn
source `gate.sh`. The toggle is a user-driven sidecar for flipping per-project
flags without opening an editor or burning an agent turn.

---

## `gate.sh`

**Purpose.** Single-function library providing `hook_enabled NAME`.

**Contract.**
- **Input:** one argument, the hook's short name (the same string used as the
  first column of the registry).
- **Output:** exit status. `0` if the flag file exists, non-zero otherwise.
  No stdout or stderr.
- **Side effects:** none. Does not create, move, or touch anything.
- **cwd assumption:** called with cwd at the project root. The flag path is
  relative: `.claude/hooks/<NAME>.enabled`. This is intentional — Claude Code
  invokes hooks with cwd set to the project root, so relative paths resolve
  correctly and the gate is automatically per-project.

**Typical use inside a hook script:**

```bash
source "$HOME/.claude/hooks/harness/gate.sh"
hook_enabled double-check || exit 0
```

**Why a file and not an inline check?** Centralising the flag path means that
if we ever change the convention (e.g. move flags under
`.claude/state/hooks/`), only `gate.sh` needs editing. Every hook picks up
the change.

**Why `[[ -f ... ]]` and not `[[ -e ... ]]`?** `-f` requires a regular file.
Rejects directories, symlinks to directories, device nodes, etc. Prevents a
user accidentally creating a directory with the flag name from half-enabling
a hook.

---

## `registry`

**Purpose.** Declarative list of hooks that the toggle popup should surface.
Adding a line here makes a hook visible in the UI; removing a line hides it.

**Format.** One hook per line. Fields separated by `|`:

```
name|description
```

- `name` — the hook's short name. Must match the gate flag
  (`.claude/hooks/<name>.enabled`) and the registry entry used by any tooling.
  ASCII, no spaces (the parse assumes whitespace terminates the name).
- `description` — free-form human text shown next to the `[x]`/`[ ]` marker
  in the popup. Keep it under ~60 chars so it fits the popup width.

**Comments.** A line starting with `#` (optionally preceded by whitespace) is
skipped. Empty lines are skipped.

**Presence in the registry is decoupled from installation.** A hook can be
registered in `~/.claude/settings.json` (so Claude Code invokes it) without
being in this registry — the toggle will simply not show it, but it will
still fire based on its flag file. The inverse also holds: listing a hook
here without installing it lets you toggle the flag but nothing will actually
fire. Both are usually mistakes; keep the two in sync.

**Why a separate file rather than an array inside `toggle.sh`?** Adding a
hook shouldn't require editing shell code. A flat text file is easy to diff,
easy to back up, and safe to edit from any tool.

---

## `toggle.sh`

**Purpose.** Interactive popup launched from tmux (`prefix + H`). Shows each
registered hook with its current enabled/disabled state in the current
project, lets you multi-select, and flips the flag files for every selection.

**Invocation.** Bound in `~/.tmux.conf`:

```tmux
bind-key H display-popup -E -w 60% -h 40% -d "#{pane_current_path}" \
  "~/.claude/hooks/harness/toggle.sh"
```

The `-d "#{pane_current_path}"` is critical: it sets the popup's cwd to the
current tmux pane's directory, which is how the script knows which project
it's operating on. `toggle.sh` itself does no project discovery — it trusts
cwd.

**Flow.**

1. `set -euo pipefail` — fail fast on unset vars, failed commands, pipeline
   errors.
2. `export PATH="/opt/homebrew/bin:$PATH"` — tmux popups inherit a minimal
   PATH on macOS. Without this, `fzf` and other Homebrew binaries aren't
   found.
3. Check `fzf` is installed; if not, print a hint and exit. The `sleep 3`
   before exit keeps the popup open long enough to read the message
   (popups close as soon as the process exits).
4. Check the registry file exists. Same sleep-before-exit pattern.
5. Install an `EXIT` trap that sleeps 1.8s. Every subsequent exit path
   (success, cancel, error) gets a brief pause so the terminal output is
   readable before the popup closes.
6. `mkdir -p .claude/hooks` — ensure the flag dir exists in the project.
   Safe if it already exists.
7. Read the registry into two parallel arrays (`NAMES`, `DESCS`). Parallel
   arrays instead of an associative array because macOS ships with bash
   3.2, which lacks `declare -A`.
8. Build the display list: `[x] name  description` for enabled hooks,
   `[ ] name  description` for disabled. Pipe into `fzf --multi`.
9. If the user cancels (`Esc`, or no selection), exit 0.
10. Parse each selected line. Strip the 4-char prefix (`[x] ` or `[ ] `),
    take the first whitespace-delimited token as the name, cross-check
    against the registry (reject anything not known — defence against a
    corrupted fzf output or a selection line we didn't generate).
11. For each valid selection: if the flag exists, remove it; otherwise
    create it. Echo the result so the user sees confirmation before the
    popup closes.

**Flag operations.** Created with `: > "$flag"` (empty file), removed with
`rm -f "$flag"`. Never writes non-empty content — the presence of the file
*is* the signal. Size and contents are ignored by `gate.sh`.

**Atomicity.** The flag flip is a single `rm` or single redirection, each
atomic from the kernel's perspective. Multiple panes flipping the same flag
in the same project is theoretically racy but in practice harmless — the
last write wins, and the gate check is a cheap `[[ -f ]]` that tolerates
either outcome. No lockfile needed.

**Parse hardening.** The `rest="${line#???\ }"` expansion strips exactly 4
characters (`[`, `x`/space, `]`, space) from the start of each line. This is
deliberately coupled to `build_list`'s format string — if you change the
prefix width in `printf '[x] %-14s  %s\n'`, update the parse too.
`${rest%%[[:space:]]*}` then grabs everything up to the first whitespace as
the name.

**Registry cross-check.** Even though the UI only ever shows lines we
generated, the selected-line parse falls back to a registry lookup before
creating/removing files. This defends against two classes of bug: user
pasting text into the fzf buffer, and future changes to `build_list` that
might shift column positions.

**Why `sleep 3` on error exits but `sleep 1.8` on success?** Errors need
longer to read. Successes just need a glance at the confirmation line.

---

## `indicator.sh`

**Purpose.** Render the "this project has hooks enabled" badge for any
status bar. One source of truth, two consumers: tmux's `status-right` and
Claude Code's `statusLine`. Adding a new consumer (zsh prompt, neovim
statusline, etc.) is a one-line shell-out.

**Contract.**
- **Input:** optional `PATH` (default `$PWD`) and optional format flag
  (`--tmux` | `--ansi` | `--plain`, default `--plain`).
- **Output:** a single line on stdout with no trailing newline, or nothing.
- **Exit:** `0` on success (with or without output), `2` on bad format flag.
- **Side effects:** none.

**Same convention as `gate.sh`.** The indicator checks
`<path>/.claude/hooks/` literally — no walking the directory tree. This
matches where hooks actually fire (Claude Code invokes hooks with cwd at
the project root) and keeps the indicator honest about "what the gate
would see right here". The sessionizer in `~/.tmux.conf` opens every pane
with `-c $project_root`, so `#{pane_current_path}` is the project root in
normal use. Trade-off: if you `cd` into a subdirectory in a terminal pane,
the badge disappears. Acceptable; symmetric with the gate's behavior.

**Format modes.**
- `--tmux` — emits `#[fg=red]H:foo,bar#[default]`. tmux's `#()`
  interpolation re-parses output, so the format directives apply.
- `--ansi` — emits `\e[31mH:foo,bar\e[0m` *as literal backslash-e text*,
  not actual ESC bytes. Designed to be captured into a shell variable and
  rendered later via `printf '%b'`. Matches Claude Code's statusLine
  rendering, which assembles a string with literal escapes and prints it
  with `printf '%b'` at the end.
- `--plain` — emits `H:foo,bar`. For consumers that handle styling
  separately or don't want any.

**Why three formats and not just one?** Each consumer has different
rendering pipelines. A unified format (e.g. only ANSI) would force every
consumer to either re-parse and re-emit, or accept the wrong escapes.
Three modes keeps each call site a one-liner.

**Why no caching?** The script does at most a few stat calls and a glob.
Running it once per `status-interval` (2s in tmux, 3s in Claude Code) is
microseconds. Caching would add complexity for no gain.

**Output discipline.** No trailing newline. Important for tmux: a newline
in `#()` output corrupts the format string. Test before changing.

---

## End-to-end data flow

A toggle-then-hook cycle:

```
tmux prefix+H
  └── popup: ~/.claude/hooks/harness/toggle.sh
       └── reads:  ~/.claude/hooks/harness/registry
       └── writes: <project>/.claude/hooks/<name>.enabled
                        │
                        ▼
Claude Code end-of-turn fires registered Stop hook
  └── ~/.claude/hooks/<name>-stop.sh
       └── sources: ~/.claude/hooks/harness/gate.sh
       └── calls:   hook_enabled <name>
                      └── checks <project>/.claude/hooks/<name>.enabled
       └── if enabled: does its work, exits 2 with stderr for Claude
```

Every box only touches things in the box below it. The harness has no
knowledge of specific hooks; specific hooks have no knowledge of the
registry or the popup. Adding, removing, or renaming a hook affects at most
its own script, a single registry line, and a single `settings.json` entry.

---

## Extension points

- **New hook** — see `~/.claude/hooks/README.md`. Three edits: script file,
  `settings.json` entry, registry line.
- **New gate predicate** — e.g. `hook_disabled_globally`, `hook_paused_until
  TIMESTAMP`. Add to `gate.sh`, source as usual, combine with
  `hook_enabled`.
- **Different UI** — any tool can write/remove `.claude/hooks/<name>.enabled`
  files. CLI wrapper, shell alias, script hotkey — all valid. `toggle.sh` is
  just one implementation.
- **New status-bar consumer** — call `indicator.sh <path> --plain` (or
  `--ansi`/`--tmux`) and embed the output. Don't reimplement the scan;
  every new consumer is a one-liner shell-out.
- **Indicator format** — edit the `case "$fmt"` block in `indicator.sh`.
  Both tmux's `status-right` (in `~/.tmux.conf`) and Claude Code's
  `statusLine.command` (in `~/.claude/settings.json`) call it, so format
  changes propagate to both.

## Invariants (don't break these)

1. `gate.sh` stays side-effect free. No mkdir, no writes, no network.
   Hook scripts rely on cheap, safe predicate semantics.
2. Flag files stay empty. If we ever need metadata (expiry, scope), add a
   sibling file — don't start parsing the flag's contents.
3. Registry name column stays ASCII-no-spaces. The current parser assumes
   whitespace terminates the name field.
4. `toggle.sh` only touches `.claude/hooks/*.enabled`. No other filesystem
   writes. No agent invocation. No network.
5. Relative paths are resolved from cwd — never `cd` inside scripts, never
   assume a specific project layout beyond `.claude/`.
6. `indicator.sh` is read-only and side-effect free. Status bars run it
   every 2-3 seconds; never add writes, network, or anything that could
   block. No trailing newline in its output.

## Testing the harness manually

Smoke test from any scratch directory:

```bash
# gate predicate
cd /tmp && rm -rf gatetest && mkdir gatetest && cd gatetest
source ~/.claude/hooks/harness/gate.sh
hook_enabled double-check; echo "off: $?"             # expect: off: 1
mkdir -p .claude/hooks && touch .claude/hooks/double-check.enabled
hook_enabled double-check; echo "on:  $?"             # expect: on:  0

# registry parse (no UI)
while IFS='|' read -r n d; do
  [[ -z "$n" || "$n" =~ ^[[:space:]]*# ]] && continue
  echo "name=[$n] desc=[$d]"
done < ~/.claude/hooks/harness/registry

# toggle end-to-end (opens fzf — run in a real terminal, not here)
~/.claude/hooks/harness/toggle.sh

# indicator (all three formats, against a synthetic project)
TMP=$(mktemp -d); mkdir -p "$TMP/proj/.claude/hooks"
: > "$TMP/proj/.claude/hooks/double-check.enabled"
~/.claude/hooks/harness/indicator.sh "$TMP/proj"          --plain   # H:double-check
~/.claude/hooks/harness/indicator.sh "$TMP/proj"          --ansi    # \e[31m...
~/.claude/hooks/harness/indicator.sh "$TMP/proj"          --tmux    # #[fg=red]...
~/.claude/hooks/harness/indicator.sh "$TMP/proj/sub/dir"  --plain   # empty (no walk-up)
~/.claude/hooks/harness/indicator.sh "$TMP"               --plain   # empty (no .claude/hooks)
rm -rf "$TMP"
```

## Known quirks

- **macOS bash 3.2.** No associative arrays, no `mapfile`, no `${var@Q}`.
  If you edit these scripts, test with `/bin/bash` not `brew install`'s
  newer bash. The `#!/usr/bin/env bash` shebang picks whichever is first in
  PATH; tmux popups typically land on `/bin/bash`.
- **fzf output ordering.** Multi-selection returns lines in the order the
  user selected them, not registry order. Not a correctness issue; just
  don't assume ordering in any downstream logic.
- **tmux popup PATH.** Minimal by default. Always `export PATH` at the top
  of scripts run from popups.
- **`set -e` and pipelines.** `set -o pipefail` is on, so a failure in any
  pipe stage fails the whole pipeline. If you add a pipeline that's
  allowed to have a failing early stage (`grep -c`, etc.), handle it
  explicitly.
