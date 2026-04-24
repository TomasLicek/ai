# bin

Global helper commands that are meant to be symlinked into a directory on
`PATH`, usually `~/.local/bin`.

## handoff

`handoff` is a global viewer for project-local `handoff.xml` files.

From any project directory, run:

```sh
handoff
```

It walks upward from the current directory until it finds the nearest
`handoff.xml`, parses the open planning items, and opens an `fzf` interface with
a preview pane.

The installed command is:

```sh
/Users/tom/code/ai/bin/handoff
```

The global entrypoint is a symlink:

```sh
~/.local/bin/handoff -> /Users/tom/code/ai/bin/handoff
```

### Commands

```sh
handoff                 # open the fzf browser
handoff list            # print all open handoff items
handoff decide          # print only decisions / items needing attention
handoff next            # print ready next tasks
handoff backlog         # print backlog items
handoff show P8         # print one item by id
handoff --file PATH     # use a specific handoff.xml
```

### Parsed Sections

The viewer currently understands these `handoff.xml` sections:

- `handoff/decide/item`
- `handoff/next/task`
- `handoff/blocked/task`
- `handoff/blocked/item`
- `handoff/board/proposal`
- `handoff/backlog/item`

Decision items are shown first, then next tasks, blocked work, proposals that
need attention, and backlog entries.

### Dependencies

- Ruby with `rexml`
- `fzf` for the interactive view

If `fzf` is missing, `handoff` falls back to a plain printed list.

### Notes

The parser is intentionally tolerant. It can read strict `<handoff>...</handoff>`
files, and it also handles older handoff fragments that contain XML-like
sections without a root `<handoff>` element.
