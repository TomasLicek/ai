---
name: autoresearch-init
description: Set up an autonomous experiment session — discuss optimization goals, define metrics and decision rules, write session files (autoresearch.md, autoresearch.sh, autoresearch.ideas.md), run baseline. Use when asked to "set up autoresearch", "init autoresearch", "prepare an optimization loop", or before running /autoresearch for the first time on a new target. Also use when the user wants to change what autoresearch is optimizing.
argument-hint: <goal or topic to optimize>
---

# Autoresearch Init

Collaborative setup for an autonomous experiment loop. The goal is to produce session files that a loop agent (via `/autoresearch`) can pick up and run indefinitely without further guidance.

## Before You Start

Check if `autoresearch.md` already exists in the repo root. If it does, ask the user: are we starting fresh (overwrite) or modifying the existing session? If modifying, read the existing files first and adjust rather than rewriting from scratch.

## Step 1: Understand the Goal

Have a conversation. Don't rush to write files. Gather these through discussion (or infer from `$ARGUMENTS` and context):

- **What are we optimizing?** (perf, bundle size, accuracy, Sharpe ratio, val_bpb, test speed, etc.)
- **How do we measure it?** (benchmark script, test suite, backtest, build command, etc.)
- **What files can the agent modify?** Ideally 1-3 files. More = harder to reason about.
- **What must NOT change?** (tests, API contracts, data formats, date ranges, etc.)
- **How long does one run take?** This determines how many experiments fit in a session.

## Step 2: Design the Evaluation Strategy

This is the most important part. Get it right here and the loop runs itself. Get it wrong and the loop thrashes.

### Think about metrics carefully

The obvious metric isn't always the right one. Push the user:

- "You say you want to optimize speed — but speed of what exactly? Cold start? P99? Average?"
- "Is there a metric that captures what you actually care about better than the one you named?"
- "What would make a 'better' result that you'd throw away? That reveals your real constraints."

### Single metric vs multi-metric

Discuss this explicitly. The decision framework:

**Single metric works when:**
- There's one clear thing to optimize (val_bpb, test duration, bundle size)
- Other concerns are either irrelevant or naturally correlated
- The domain is well-understood and the metric captures what matters

**Multi-metric with constraints works when:**
- Improving the primary metric can degrade something important (speed vs accuracy, return vs risk, size vs features)
- There are hard limits that must not be violated (memory budget, max latency, max drawdown)
- The user cares about tradeoffs, not just one number

**When multi-metric is needed, structure it as:**

```
Primary metric: <name> (<direction>)  — this is what we hill-climb on
Hard constraints:                      — violate any = auto-discard regardless of primary
  - <metric> <operator> <threshold>    (e.g., "drawdown < 40%", "memory < 8GB")
Soft preferences:                      — used as tiebreakers when primary is equal
  - <metric> (<direction>)             (e.g., "fewer trades is better", "simpler code")
```

This avoids weighted scoring (which is arbitrary and hard to tune) while still handling real tradeoffs. Hard constraints are gates. Primary metric is the hill. Soft preferences break ties.

### Write it down

Whatever the user decides, capture the full decision logic so the loop agent doesn't have to guess. The loop agent should be able to make keep/discard decisions mechanically from the rules.

## Step 3: Read the Source

Before writing anything, read every file that's in scope deeply. Understand:
- What the code does today
- Where the obvious optimization opportunities are
- What's complex enough that random changes will break it
- What a reasonable first set of experiment ideas would be

## Step 4: Write Session Files

### `autoresearch.md`

The heart of the session. A fresh agent with zero context should be able to read this file and run the loop effectively. Invest time making it excellent.

```markdown
# Autoresearch: <goal>

## Branch
Trunk: `autoresearch/<goal>-<date>`

## Objective
<Specific description of what we're optimizing and the workload.
Include enough context that a fresh agent understands the domain.>

## Metrics
- **Primary**: <name> (<unit>, lower/higher is better)
- **Secondary**: <name>, <name>, ...

## Decision Rules
<How to decide keep vs discard. Include:
- Primary metric comparison (the hill to climb)
- Hard constraints with thresholds (auto-discard if violated)
- Soft preferences (tiebreakers)
Example: "Keep if Sharpe improved AND drawdown < 40%. Discard if drawdown > 40% even if Sharpe improved.">

## How to Run
`./autoresearch.sh` — outputs `METRIC name=number` lines to stdout.
<Include expected runtime, what to check if all metrics are 0, etc.>

## Files in Scope
<Every file the agent may modify, with a brief note on what it does.>

## Off Limits
<What must NOT be touched and why.>

## Constraints
<Hard rules: tests must pass, no new deps, etc.>

## Available Tools
<What's available to the agent — libraries, APIs, indicators, etc.
This section helps the agent generate better ideas.>

## Strategy Seed Ideas
<5-10 initial ideas to try, ranging from obvious to creative.
The agent will generate more as it goes, but good seeds accelerate the start.>

## What's Been Tried
<Nothing yet — baseline pending>
```

### `autoresearch.sh`

Bash script (`chmod +x`, `set -euo pipefail`) that:
1. Pre-checks fast (syntax errors, lint — fail in <1s, don't waste time on broken code)
2. Runs the actual benchmark/test/evaluation
3. Outputs metrics as `METRIC name=number` lines to stdout

The script handles its own logging — verbose output goes to `run.log`, only METRIC lines go to stdout. This keeps the loop agent's context clean (the loop agent should NOT add its own `> run.log 2>&1` redirect on top).

```bash
#!/usr/bin/env bash
set -euo pipefail

# Pre-check: fast syntax validation
python -c "import ast; ast.parse(open('src/engine.py').read())" || {
    echo "METRIC time_ms=0"
    exit 1
}

# Run benchmark, capture verbose output to log
python bench.py > run.log 2>&1

# Parse and emit metrics from log
time_ms=$(grep "elapsed" run.log | awk '{print $2}')
echo "METRIC time_ms=${time_ms:-0}"
```

Design principles:
- **Fast pre-checks first.** Every wasted second is multiplied by hundreds of runs.
- **Verbose output goes to `run.log` inside the script.** The loop agent reads METRIC lines from stdout and can `tail run.log` if something goes wrong. The script owns the redirect — the loop agent just runs `./autoresearch.sh` without redirecting.
- **Default to 0 on failure.** The loop agent treats 0 as "crash" and handles it.

### `autoresearch.ideas.md`

Separate file for the ideas backlog. Starts with the seed ideas from the discussion, grows as the loop agent discovers new angles.

```markdown
# Autoresearch Ideas: <goal>

Ideas to try, roughly ordered by promise. The loop agent adds to this as it works.
Remove ideas once tried (see autoresearch.md "What's Been Tried" for history).

## High Priority
- <idea 1>
- <idea 2>

## Worth Exploring
- <idea 3>
- <idea 4>

## Wild Cards
- <idea 5>
```

## Step 5: Create Branch and Commit

The main session branch is the "clean trunk" — only successful experiments get merged here. Each experiment will be developed on its own branch off this trunk (handled by `/autoresearch`).

```bash
git checkout -b autoresearch/<goal>-<date>
chmod +x autoresearch.sh
echo "results.jsonl" >> .gitignore
echo "run.log" >> .gitignore
git add autoresearch.md autoresearch.sh autoresearch.ideas.md .gitignore
git commit -m "autoresearch: init session for <goal>"
```

## Step 6: Run Baseline

Execute `./autoresearch.sh` and record the baseline metrics. This is run #1 — the starting point everything is compared against. Log it to `results.jsonl`:

```json
{"run": 1, "commit": "<hash>", "branch": "autoresearch/<goal>-<date>", "metrics": {"primary_name": value, ...}, "status": "keep", "description": "baseline"}
```

**IMPORTANT: NEVER commit or stage `results.jsonl`.** It is a working-tree log file only. Untracked files persist across branch switches, so it's always available regardless of which experiment branch you're on.

## Step 7: Hand Off

Tell the user the setup is complete and they can start the loop:

> Setup complete. Baseline: <metric> = <value>.
> Run `/autoresearch` to start the experiment loop.

Show them the key files created and the baseline result. If there were interesting insights from reading the source code, share those too — they might inform the first few experiments.
