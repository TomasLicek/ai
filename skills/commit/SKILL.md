---
name: commit
description: Commit changes using haiku for speed
model: haiku
---

# Commit

Create a git commit for staged/unstaged changes.

## Context from caller

$ARGUMENTS

## Steps

1. Run in parallel:
   - `git status` (no -uall flag)
   - `git diff` + `git diff --staged`
   - `git log --oneline -5` (match commit style)

2. Analyze changes, draft commit message:
   - Use the context above to understand what was done
   - Focus on WHY not WHAT
   - 1-2 sentences max
   - Match repo's commit style

3. Stage and commit:
   - Stage specific files relevant to the change (NOT `git add -A` or `git add .`)
   - Skip .env, credentials, secrets, large binaries
   - Commit with HEREDOC:
   ```bash
   git add file1 file2 && git commit -m "$(cat <<'EOF'
   Your message here
   EOF
   )"
   ```

4. Report: commit hash, files changed

## Rules

- NEVER amend, force push, or skip hooks
- NEVER commit .env, credentials, secrets
- If nothing to commit, just say "Nothing to commit"
- If pre-commit hook fails, report the error (don't fix)
