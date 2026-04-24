# Tom's lazyguide to AI

Opinionated Claude Code workspace for reusable AI tooling: skills, hooks, subagents, and the session state used to hand work between them.

## What's here

- **`skills/`** - custom slash commands and workflows for debugging, review, simplification, research, quality control, handoffs, and experimentation. Recent additions focus on the `handoff` loop: pickup, update, and board management for multi-agent work.
- **`hooks/`** - Stop and PreToolUse hooks, including a cross-agent review hook that asks another model for a second look during a turn.
- **`agents/`** - subagents for parallel work, such as a breaker agent that tries to find problems in recent changes.
- **`handoff.xml`** - the repo-level planning and recovery file that keeps active work, next tasks, and durable context in one place.
- **`snippets.md`** and **`ideas.md`** - reusable prompt fragments and a parking lot for future experiments.

## How it fits together

- Use the skills when you want a repeatable workflow instead of a one-off prompt.
- Use the hooks when you want Claude Code to intervene automatically at tool boundaries.
- Use the agents when a task can be split and checked in parallel.
- Use `handoff.xml` when a session needs to survive context loss or move cleanly between planning, pickup, and execution.

## Use

Symlink into `~/.claude/` so Claude Code picks everything up:

```sh
ln -s "$PWD/skills" ~/.claude/skills
ln -s "$PWD/hooks" ~/.claude/hooks
ln -s "$PWD/agents" ~/.claude/agents
```

Personal `CLAUDE.md` and project-specific `.claude/` live elsewhere - this repo is the reusable layer.

## License

MIT - see [LICENSE](LICENSE).
