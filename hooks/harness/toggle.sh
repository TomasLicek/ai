#!/usr/bin/env bash
# Hooks toggle popup. Launched from tmux (Prefix+H) in project cwd.
# Reads the hook registry, shows current state, toggles selected hooks.

set -euo pipefail

export PATH="/opt/homebrew/bin:$PATH"

REGISTRY="$HOME/.claude/hooks/harness/registry"
HOOKS_DIR=".claude/hooks"

if ! command -v fzf >/dev/null 2>&1; then
  echo "fzf not found — install: brew install fzf"
  sleep 3
  exit 1
fi

if [[ ! -f "$REGISTRY" ]]; then
  echo "registry missing: $REGISTRY"
  sleep 3
  exit 1
fi

trap 'sleep 1.8' EXIT

mkdir -p "$HOOKS_DIR"

# Load registry into parallel arrays (bash 3.2 compatible).
NAMES=()
DESCS=()
while IFS='|' read -r name desc; do
  [[ -z "$name" || "$name" =~ ^[[:space:]]*# ]] && continue
  NAMES+=("$name")
  DESCS+=("$desc")
done < "$REGISTRY"

if (( ${#NAMES[@]} == 0 )); then
  echo "no hooks in registry"
  exit 0
fi

build_list() {
  for i in "${!NAMES[@]}"; do
    name="${NAMES[$i]}"
    desc="${DESCS[$i]}"
    if [[ -f "$HOOKS_DIR/${name}.enabled" ]]; then
      printf '[x] %-14s  %s\n' "$name" "$desc"
    else
      printf '[ ] %-14s  %s\n' "$name" "$desc"
    fi
  done
}

project=$(basename "$PWD")

SELECTED=$(build_list | fzf \
  --multi \
  --height=100% \
  --reverse \
  --prompt="Toggle > " \
  --header="Hooks in $project — Tab: select, Enter: toggle, Esc: cancel" \
) || exit 0

[[ -z "$SELECTED" ]] && exit 0

while IFS= read -r line; do
  rest="${line#???\ }"
  name="${rest%%[[:space:]]*}"
  valid=0
  for known in "${NAMES[@]}"; do
    [[ "$known" == "$name" ]] && { valid=1; break; }
  done
  [[ $valid -eq 1 ]] || continue

  flag="$HOOKS_DIR/${name}.enabled"
  if [[ -f "$flag" ]]; then
    rm -f "$flag"
    printf '  disabled: %s\n' "$name"
  else
    : > "$flag"
    printf '  enabled:  %s\n' "$name"
  fi
done <<< "$SELECTED"
