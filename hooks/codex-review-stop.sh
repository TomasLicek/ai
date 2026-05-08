#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:$HOME/.local/bin:$PATH"

source "$HOME/.claude/hooks/harness/gate.sh"

# Bail if this Stop was already triggered by a prior hook iteration.
INPUT=$(cat)
if command -v jq >/dev/null 2>&1; then
  [[ "$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)" == "true" ]] && exit 0
fi

hook_enabled codex-review || exit 0

git rev-parse --git-dir &>/dev/null || exit 0

# Mode selection:
#   - dirty tree (any modified/staged/untracked) → review the code (with conversation as context)
#   - clean tree                                 → review the conversation (no code in scope)
# The flag is the user-explicit trigger. Hash dedup below prevents re-running on identical input.
#
# `-uall`: list each untracked file individually instead of collapsing dirs to `?? dir/`.
# Filter excludes hook-owned state so enabling the hook doesn't itself flip mode to code.
RAW_STATUS=$(git status --porcelain -uall 2>/dev/null || true)
STATUS=$(printf '%s\n' "$RAW_STATUS" | grep -vE '^.. (\.claude/hooks/[^/]+\.enabled$|\.claude/codex-review/|\.claude/cursor-review/)' || true)
if [[ -n "$STATUS" ]]; then
  MODE="code"
else
  MODE="conversation"
fi

if [[ -e .claude/codex-review && ! -d .claude/codex-review ]]; then exit 0; fi
mkdir -p .claude/codex-review

# Clean up `.tmp.*` scratch files on any exit path (success, error, signal).
# Known success/failure branches handle their own tmp explicitly; this catches unexpected deaths
# (Ctrl-C, OOM, set -e firing on unrelated commands) so we don't orphan half-written files.
trap 'rm -f .claude/codex-review/*.tmp.* 2>/dev/null || true' EXIT

# Extract session conversation (used as context in code mode, as the review target in conversation mode).
# Prefer the exact transcript_path from the Stop hook payload — mtime-based discovery is racy when
# multiple Claude panes are open in the same project.
JSONL=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
if [[ -z "$JSONL" || ! -f "$JSONL" ]]; then
  PROJECT_KEY=$(pwd | tr '/_.' '-')
  TRANSCRIPT_DIR="$HOME/.claude/projects/$PROJECT_KEY"
  if [[ -d "$TRANSCRIPT_DIR" ]]; then
    JSONL=$(find "$TRANSCRIPT_DIR" -name "*.jsonl" -type f | xargs stat -f "%m %N" 2>/dev/null | sort -rn | head -1 | awk '{print $2}')
  fi
fi
if [[ -n "$JSONL" && -f "$JSONL" ]]; then
  TMP_CONV=".claude/codex-review/conversation.txt.tmp.$$"
  jq -r 'select(.type == "user" or .type == "assistant") |
    if .type == "user" and (.message.content | type == "string") then
      select(.message.content | test("<local-command-caveat>|<command-name>") | not) |
      "<user>\n" + .message.content + "\n</user>"
    elif .type == "assistant" then
      (.message.content[] | select(.type == "text") | "<agent>\n" + .text + "\n</agent>")
    else empty end' "$JSONL" > "$TMP_CONV" 2>/dev/null \
    && mv -f "$TMP_CONV" .claude/codex-review/conversation.txt \
    || rm -f "$TMP_CONV"
fi

# Compute dedup hash from whatever is actually being reviewed.
# Code mode: status + tracked diff + content-hashes of untracked files (so editing an untracked
#            file without `git add` still changes the hash).
# Conversation mode: full transcript content.
HASH_FILE=.claude/codex-review/last_hash
if [[ "$MODE" == "code" ]]; then
  UNTRACKED_HASHES=""
  while IFS= read -r -d '' f; do
    [[ -f "$f" ]] || continue
    case "$f" in
      .claude/hooks/*.enabled|.claude/codex-review/*|.claude/cursor-review/*) continue ;;
    esac
    h=$(shasum -a 1 "$f" 2>/dev/null | awk '{print $1}')
    UNTRACKED_HASHES+="${f}:${h}"$'\n'
  done < <(git ls-files --others --exclude-standard -z 2>/dev/null)
  HASH_INPUT="${STATUS}$(git diff HEAD 2>/dev/null || true)${UNTRACKED_HASHES}"
else
  HASH_INPUT=$(cat .claude/codex-review/conversation.txt 2>/dev/null || true)
fi
[[ -n "$HASH_INPUT" ]] || exit 0
HASH=$(printf '%s' "$HASH_INPUT" | shasum -a 1 | awk '{print $1}')
if [[ -f "$HASH_FILE" ]] && [[ "$(cat "$HASH_FILE")" == "$HASH" ]]; then
  exit 0
fi

# In code mode, write the changed-files manifest (porcelain format includes untracked as `??`).
if [[ "$MODE" == "code" ]]; then
  TMP_FILES=".claude/codex-review/changed_files.txt.tmp.$$"
  printf '%s\n' "$STATUS" > "$TMP_FILES" && mv -f "$TMP_FILES" .claude/codex-review/changed_files.txt
fi

# Codex CLI must be on PATH; silent no-op otherwise.
command -v codex >/dev/null 2>&1 || { echo "codex-review: 'codex' CLI not found, skipping" >&2; exit 0; }

if [[ "$MODE" == "code" ]]; then
  PROMPT=$(cat <<'PROMPT_EOF'
Run /double-check to review the work of other agents. Do not assume anything, except everything.

Inputs:
- `.claude/codex-review/conversation.txt` — transcript of session conversation in <user>/<agent> XML tags
- `.claude/codex-review/changed_files.txt` — changed files in `git status --porcelain` format. Untracked files appear as `??`.
- `git diff HEAD` — full diff of tracked changes (does NOT include untracked files; read those directly from disk)

Output your findings to stdout:
- First line: `STATUS: CLEAN` or `STATUS: ISSUES: N HIGH, M MEDIUM, K LOW`
- Each finding: severity (HIGH/MEDIUM/LOW), [file:line], description, proposed fix. Be very detailed here. Explain reasoning, angles, what leads you to that.
PROMPT_EOF
)
else
  PROMPT=$(cat <<'PROMPT_EOF'
Review this session's CONVERSATION for reasoning errors, skipped considerations, wrong assumptions, unverified claims, hallucinated facts, or anything the agent presented confidently but got wrong. There are NO code changes in this session — the working tree is clean. Old commits already in the branch are NOT in scope; only the conversation that just happened.

Input:
- `.claude/codex-review/conversation.txt` — full transcript in <user>/<agent> XML tags

Output your findings to stdout:
- First line: `STATUS: CLEAN` or `STATUS: ISSUES: N HIGH, M MEDIUM, K LOW`
- Each finding: severity (HIGH/MEDIUM/LOW), who said it (user/agent) and roughly when in the conversation, the claim or decision, why it's wrong or risky, what the right answer is. Be detailed — explain your reasoning.
PROMPT_EOF
)
fi

TMP_FINDINGS=".claude/codex-review/findings.md.tmp.$$"
if  codex exec --model gpt-5.5 -c 'model_reasoning_effort="high"' "$PROMPT" >"$TMP_FINDINGS" 2>/dev/null; then
  mv -f "$TMP_FINDINGS" .claude/codex-review/findings.md
else
  rm -f "$TMP_FINDINGS"
  echo "codex-review: codex invocation failed" >&2
  exit 0
fi

# Persist hash ONLY after the review actually succeeded — a failed codex run must not
# dedup-skip the next Stop with the same input.
TMP_HASH="${HASH_FILE}.tmp.$$"
printf '%s' "$HASH" > "$TMP_HASH" && mv -f "$TMP_HASH" "$HASH_FILE"

if [[ "$MODE" == "code" ]]; then
  KIND_TEXT="code changes"
else
  KIND_TEXT="conversation"
fi

cat >&2 <<EOF
<session-review>
Independent review of this session's ${KIND_TEXT} is in \`.claude/codex-review/findings.md\`.
First line is the sentinel (\`STATUS: CLEAN\` or \`STATUS: ISSUES: N HIGH, M MEDIUM, K LOW\`).

Read the findings and summarize. Do NOT auto-fix. Be critical of the findings — if a finding looks wrong or irrelevant, say so.
</session-review>
EOF

exit 2
