# Tom's lazyguide to AI

My Claude Code setup — opinionated skills, hooks, and agents, plus field notes on coding with AI.

## What's here

- **`skills/`** — custom slash-commands: `/casey-wtf`, `/autoresearch`, `/double-check`, `/learn`, `/qc`, `/debug-hypothesis`, and ~20 more.
- **`hooks/`** — Stop/PreToolUse hooks. Includes a cross-agent `cursor-review` that pings another model for a second opinion on each turn.
- **`agents/`** — subagents for parallel work (e.g. `breaker` — tries to break what you just built).
- **`snippets.md`** · **`ideas.md`** · **`handoff.xml`** — prompt fragments, parking lot, open-work tracker.

## Use

Symlink into `~/.claude/` so Claude Code picks everything up:

```sh
ln -s "$PWD/skills" ~/.claude/skills
ln -s "$PWD/hooks"  ~/.claude/hooks
ln -s "$PWD/agents" ~/.claude/agents
```

Personal CLAUDE.md and project-specific `.claude/` live elsewhere — this repo is just the reusable bits.

## License

MIT — see [LICENSE](LICENSE).
