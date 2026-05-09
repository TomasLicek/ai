#!/usr/bin/env bash
# Hooks toggle popup. Launched from tmux (Prefix+H) in project cwd.
# Select hooks to flip their state. Enter = apply, Esc = cancel.

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
  sleep 1
  exit 0
fi

project=$(basename "$PWD")

# Build display: ON/off prefix makes current state immediately visible.
build_list() {
  for i in "${!NAMES[@]}"; do
    name="${NAMES[$i]}"
    desc="${DESCS[$i]}"
    if [[ -f "$HOOKS_DIR/${name}.enabled" ]]; then
      printf 'ON   %-14s  %s\n' "$name" "$desc"
    else
      printf 'off  %-14s  %s\n' "$name" "$desc"
    fi
  done
}

# Toggle model: selected items get their state FLIPPED on Enter.
# Avoids fzf --multi Enter quirk (outputs cursor item when nothing is marked).
SELECTED=$(build_list | fzf \
  --multi \
  --height=100% \
  --reverse \
  --no-sort \
  --marker='▶' \
  --prompt="$project  " \
  --header="Space: mark  Enter: toggle marked  Esc: cancel" \
  --bind "space:toggle" \
  --color="marker:green,pointer:green" \
) || exit 0

[[ -z "$SELECTED" ]] && exit 0

changed=0
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  rest="${line#?????}"          # strip 5-char "ON   " or "off  " prefix
  name="${rest%%[[:space:]]*}"  # first whitespace-delimited token = hook name

  # Validate against registry.
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
  changed=1
done <<< "$SELECTED"

# Brief flash so the confirmation lines are readable before popup closes.
if [[ $changed -eq 1 ]]; then
  sleep 0.4
fi
