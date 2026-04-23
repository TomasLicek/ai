---
name: autoresearch
effort: xhigh
description: Resume and run an autonomous experiment loop. Reads autoresearch.md for context, then loops forever — try ideas, keep what works, discard what doesn't. Use when asked to "run autoresearch", "start experiments", "continue autoresearch", or "optimize in a loop". Requires autoresearch.md to exist (run /autoresearch-init first if it doesn't).
argument-hint: '<optional: specific idea or direction to try first>'
---

# Autoresearch

Autonomous experiment loop: try ideas, measure, keep what works, discard what doesn't, never stop.

## Startup

1. **Check for session files.** Look for `autoresearch.md` in the repo root.
   - If missing: tell the user to run `/autoresearch-init` first. Stop.
   - If present: read it along with `autoresearch.sh`, `autoresearch.ideas.md` (if exists), and `results.jsonl` (if exists).

2. **Identify the trunk branch.** Read the `## Branch` section of `autoresearch.md` — it contains the trunk branch name (e.g., `autoresearch/sharpe-2026-03-14`). Switch to it: `git checkout <trunk>`.

3. **Understand the state.** Check `git log --oneline -20` and `results.jsonl` to see where things left off. How many runs? What was tried? What's the current best? What branches exist under `autoresearch/exp/*`?

4. **Read the source files in scope.** Every file listed in autoresearch.md's "Files in Scope." Read them fully — deep understanding beats random mutations.

5. **If `$ARGUMENTS` contains a specific idea**, try that first. Otherwise, check `autoresearch.ideas.md` for the highest-priority untried idea. If nothing there either, form your own hypothesis from the results history and source code.

6. **Start looping immediately.** Do not ask permission.

## The Loop

**LOOP FOREVER.** Never ask "should I continue?" — the user expects autonomous work.
**NEVER STOP ON YOUR OWN. The user may be sleeping. Keep going until interrupted.**

```
REPEAT:
  1. Think: review results.jsonl + autoresearch.md + source → form hypothesis
     - Look at discarded experiments too. Can two near-misses combine?
       Browse discarded branches: git branch --list "autoresearch/exp/*"
       View a discard's diff: git diff <trunk>...autoresearch/exp/NNN-name
  2. Ensure you're on trunk, then create experiment branch:
       git checkout <trunk>
       git checkout -b autoresearch/exp/NNN-short-name
  3. Edit: modify files in scope only
  4. Commit: git add <in-scope files only> && git commit -m "autoresearch: <description>"
  5. Run: ./autoresearch.sh
     The script logs verbose output to run.log and emits METRIC lines to stdout.
     Capture stdout to read metrics. On crash: tail -50 run.log for diagnosis.
  6. Decide: apply the decision rules from autoresearch.md
     - KEEP: merge to clean trunk
         git checkout <trunk>
         git merge autoresearch/exp/NNN-short-name
     - DISCARD: branch stays (code preserved for future combination)
         git checkout <trunk>
     - CRASH: same as discard
  7. Append to results.jsonl (you're on trunk now)
  8. Every ~5 runs (on trunk): update autoresearch.md "What's Been Tried" and commit
  9. Periodically (on trunk): update autoresearch.ideas.md — remove tried ideas, add new ones
```

Where `<trunk>` is the branch name from the `## Branch` section of `autoresearch.md`.

### Branch Structure

```
autoresearch/sharpe-2026-03-14    ← clean trunk, only keeps (created by /autoresearch-init)
autoresearch/exp/001-increase-lr  ← merged to trunk
autoresearch/exp/002-rsi-filter   ← abandoned (discard — code preserved)
autoresearch/exp/003-ema-cross    ← abandoned (discard — code preserved)
autoresearch/exp/004-momentum     ← merged to trunk
```

The clean trunk always has the best known code. Experiment branches are always created from the trunk tip, so merges are fast-forwards. Discarded branches stay — they're the raw material for combining ideas later.

### Combining Discarded Experiments

When stuck, this is your secret weapon. Two experiments that each failed alone might work together:

```bash
# Browse what was tried and discarded
git branch --list "autoresearch/exp/*"
git log --oneline autoresearch/exp/003-rsi-filter

# See exactly what a discard changed
git diff <trunk>...autoresearch/exp/003-rsi-filter

# Try combining: create new experiment, cherry-pick from discards
git checkout -b autoresearch/exp/NNN-combine-rsi-momentum
git cherry-pick <commit-from-003>  # may need conflict resolution
# ...add more changes, run, evaluate
```

## Results Format

Append one JSON line per run to `results.jsonl`:

```json
{"run": 1, "commit": "a1b2c3d", "branch": "autoresearch/sharpe-2026-03-14", "metrics": {"val_bpb": 0.997, "memory_gb": 44.0}, "status": "keep", "description": "baseline"}
{"run": 2, "commit": "b2c3d4e", "branch": "autoresearch/exp/001-increase-lr", "metrics": {"val_bpb": 0.993, "memory_gb": 44.2}, "status": "keep", "description": "increase LR to 0.04"}
{"run": 3, "commit": "c3d4e5f", "branch": "autoresearch/exp/002-rsi-filter", "metrics": {"val_bpb": 1.005, "memory_gb": 44.0}, "status": "discard", "description": "RSI(14) filter: buy <30, sell >70. Too few signals, only 12 trades in 10yr"}
```

Write meaningful descriptions — especially for discards. A future agent (or you after a context reset) needs to understand what was tried AND why it failed to decide whether to combine or revisit it.

**NEVER commit or stage `results.jsonl`.** It is a working-tree log file only.

## Decision Rules

Follow the rules defined in `autoresearch.md`. The typical structure is:

- **Primary metric is the hill to climb.** Improved → `keep`. Worse or equal → `discard`.
- **Hard constraints are gates.** If autoresearch.md defines thresholds (e.g., "drawdown < 40%"), violating any = auto-discard even if the primary metric improved.
- **Soft preferences break ties.** When the primary metric is roughly equal, prefer simpler code, fewer parameters, less resource usage — whatever autoresearch.md specifies.
- **Simpler is better.** Removing code for equal performance is a `keep`. Ugly complexity for a tiny gain is a `discard`.

## Context Management

Your context window is finite and you're running potentially hundreds of iterations. Protect it:

- **Don't flood your context with benchmark output.** The benchmark script (`autoresearch.sh`) handles its own logging to `run.log` and emits only METRIC lines to stdout. On crash, use `tail -50 run.log` for diagnosis.
- **Keep commit messages short.** `autoresearch: <10 words max>`.
- **Don't re-read source files every iteration.** Re-read when you're stuck or trying something structurally different, not on every loop.
- **If context is getting full:** stop the loop gracefully. Update `autoresearch.md` with current state (what's been tried, current best, promising next ideas), commit it, then tell the user to run `/autoresearch` again to resume in a fresh context.

## When You're Stuck

If 5+ experiments in a row are discarded, stop and think differently:

1. **Re-read the source files.** All of them, fully. The best ideas come from deep understanding, not random variations.
2. **Review what worked.** Look at the `keep` entries in results.jsonl. What do they have in common? Can you push further in that direction?
3. **Combine near-misses.** Browse discarded branches. Two failures might complement each other — one improved metric A but hurt B, another did the reverse. Cherry-pick and combine.
4. **Check autoresearch.ideas.md.** Is there something in "Wild Cards" you haven't tried?
5. **Try the opposite.** If you've been making things more complex, try simplifying. If you've been tuning parameters, try changing the algorithm.
6. **Challenge your assumptions.** Is the benchmark measuring what you think? Is there a ceiling on this approach? Read the off-limits files for clues.

**Don't thrash.** If you've tried the same idea three times with minor variations and it keeps getting discarded, it's dead. Move on.

## Crashes

Use judgment:
- **Typo, missing import, syntax error:** fix and re-run. Don't waste a slot.
- **Fundamental problem (OOM, algorithm broken):** log as `crash`, switch back to trunk, move on.
- **Flaky (passes sometimes, fails sometimes):** investigate once. If it's environmental, note it in autoresearch.md and move on.

## User Messages During the Loop

If the user sends a message while you're looping, finish the current run cycle first (run → log → keep/discard), then incorporate their feedback in the next iteration. Don't abandon a running experiment.

## When Done (only if user stops you)

Summarize:
- Total runs, keeps, discards, crashes
- Best metric achieved vs baseline
- Top 3 most impactful changes
- Any promising untried ideas from autoresearch.ideas.md
- Notable discarded branches worth revisiting

**NEVER STOP ON YOUR OWN. The user may be sleeping. Keep going until interrupted.**
