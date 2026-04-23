#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:$HOME/.local/bin:$PATH"

source "$HOME/.claude/hooks/harness/gate.sh"

# Bail if this Stop was already triggered by a prior hook iteration.
INPUT=$(cat)
if command -v jq >/dev/null 2>&1; then
  [[ "$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)" == "true" ]] && exit 0
fi

hook_enabled cursor-review || exit 0

git rev-parse --git-dir &>/dev/null || exit 0

DIFF=$(git diff HEAD 2>/dev/null || true)
[[ -n "$DIFF" ]] || exit 0

# Skip binary-only diffs (unstable hash, useless patch).
if ! git diff HEAD --numstat 2>/dev/null | awk '$1 ~ /^[0-9]+$/ && $2 ~ /^[0-9]+$/ {found=1} END {exit !found}'; then
  exit 0
fi

DIFF_HASH=$(printf '%s' "$DIFF" | shasum -a 1 | awk '{print $1}')
HASH_FILE=.claude/cursor-review/last_hash
if [[ -f "$HASH_FILE" ]] && [[ "$(cat "$HASH_FILE")" == "$DIFF_HASH" ]]; then
  exit 0
fi

if [[ -e .claude/cursor-review && ! -d .claude/cursor-review ]]; then exit 0; fi
mkdir -p .claude/cursor-review

FILES=$(git diff --name-status HEAD 2>/dev/null || true)
[[ -n "$FILES" ]] || exit 0

# Atomic writes: survive concurrent sessions in the same repo.
TMP_FILES=".claude/cursor-review/changed_files.txt.tmp.$$"
TMP_HASH="${HASH_FILE}.tmp.$$"
printf '%s\n' "$FILES" > "$TMP_FILES" && mv -f "$TMP_FILES" .claude/cursor-review/changed_files.txt
printf '%s' "$DIFF_HASH" > "$TMP_HASH" && mv -f "$TMP_HASH" "$HASH_FILE"

# Cursor CLI must be on PATH; silent no-op otherwise.
command -v agent >/dev/null 2>&1 || { echo "cursor-review: 'agent' CLI not found, skipping" >&2; exit 0; }

PROMPT=$(cat <<'PROMPT_EOF'
Scope: `.claude/cursor-review/changed_files.txt` in the current working directory lists the files changed vs `HEAD` in `git diff --name-status` format (A=added, M=modified, D=deleted, R=renamed, etc.). These are the files to review.

Method:
- Read each listed file in full (skip deletions).
- Roam freely — read callers, callees, imports, tests, configs, whatever you need to judge the change in context. Narrow views mis-judge.
- Run `git diff -- <path>` yourself if you want to pinpoint what changed in a specific file.
- Ignore prior conversation and any inferred author intent. Review the code as it stands.

Classify each finding:
- HIGH: logic bugs, security issues, data loss, breakage
- MEDIUM: correctness edge cases, concurrency, error handling
- LOW: style, naming, minor nits

Output format — emit your review as plain text to stdout ONLY. Do not write any files. Do not emit preambles, code fences, or commentary.
- First line sentinel: `STATUS: CLEAN` (no issues) OR `STATUS: ISSUES: N HIGH, M MEDIUM, K LOW`.
- Remaining lines: detailed break-down what's wrong, prefixed with severity, `file:line` where possible. 
- Propose fixes.
PROMPT_EOF
)

TMP_FINDINGS=".claude/cursor-review/findings.md.tmp.$$"
if agent -p --output-format text --model "gpt-5.4" "$PROMPT" >"$TMP_FINDINGS" 2>/dev/null; then
  mv -f "$TMP_FINDINGS" .claude/cursor-review/findings.md
else
  rm -f "$TMP_FINDINGS"
  echo "cursor-review: agent invocation failed" >&2
  exit 0
fi

cat >&2 <<'EOF'
<cursor-review>
Cross-agent review ran on the changed files with full file context. Findings are in `.claude/cursor-review/findings.md`. 
First line is the sentinel (`STATUS: CLEAN` or `STATUS: ISSUES: N HIGH, M MEDIUM, K LOW`).

Output summary + file path, then stop. Do NOT auto-fix. And please be very vare of the findings - think whether the findings 
are appropriate and relevant. If you think the review is not right, say so.
</cursor-review>
EOF

exit 2
