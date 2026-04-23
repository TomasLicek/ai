#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:$PATH"

source "$HOME/.claude/hooks/harness/gate.sh"

# Bail if this Stop was already triggered by a prior hook iteration.
INPUT=$(cat)
if command -v jq >/dev/null 2>&1; then
  [[ "$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)" == "true" ]] && exit 0
fi

hook_enabled double-check || exit 0

cat >&2 <<'EOF'
<double-check-trigger>
Invoke the `/double-check` skill before stopping the session.
After it completes, provide summary, then stop. Do NOT auto-fix any findings.
</double-check-trigger>
EOF

exit 2
