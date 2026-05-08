#!/usr/bin/env bash
# Hooks-enabled indicator for a project path.
#
# Usage: indicator.sh [PATH] [--tmux|--ansi|--plain]
#
# Prints a one-line marker (no trailing newline) if PATH (default $PWD)
# contains any `.claude/hooks/<name>.enabled` flag files. Otherwise prints
# nothing and exits 0.
#
# Same convention as `gate.sh`: only `<path>/.claude/hooks/` is checked,
# matching where hooks actually fire (Claude Code invokes hooks with cwd
# at the project root). The sessionizer in ~/.tmux.conf opens every pane
# with `-c $project_root`, so `#{pane_current_path}` is the project root
# in normal use — no need to walk the tree. Trade-off: if you `cd` into a
# subdirectory in a terminal pane, the badge disappears. Acceptable; the
# badge is honest about "what the gate would see right here".
#
# Formats:
#   --tmux   tmux format string: `#[fg=red]H:foo,bar#[default]`
#   --ansi   literal ANSI escape sequences (caller pipes through `printf '%b'`)
#   --plain  no styling: `H:foo,bar`
#
# Defaults to --plain if no format flag is given.

set -eu

path="${1:-$PWD}"
fmt="${2:---plain}"

[[ -d "$path/.claude/hooks" ]] || exit 0

list=""
for f in "$path"/.claude/hooks/*.enabled; do
  [[ -f "$f" ]] || continue
  base="${f##*/}"
  base="${base%.enabled}"
  list="${list:+$list,}$base"
done

[[ -z "$list" ]] && exit 0

case "$fmt" in
  --tmux)  printf '#[fg=red]H:%s#[default]' "$list" ;;
  --ansi)  printf '\\e[31mH:%s\\e[0m' "$list" ;;
  --plain) printf 'H:%s' "$list" ;;
  *) echo "indicator.sh: unknown format: $fmt" >&2; exit 2 ;;
esac
