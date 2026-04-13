# CLAUDE.md

The canonical contributor and agent instructions now live in [AGENTS.md](/Users/karetski/Developer/dotfiles/AGENTS.md). Use that file for repository structure, commands, coding style, testing expectations, and PR guidance.

## Claude-Specific Note
The `claude/` role in this repository still manages local Claude Code configuration, including:

- `~/.claude/settings.json`
- `~/.claude/statusline.sh`
- `~/.claude/hooks/block-dangerous.sh`
- `~/.claude/hooks/protect-files.sh`
- `~/.claude/hooks/check-syntax.sh`

Repository changes to that role should follow the same standards documented in [AGENTS.md](/Users/karetski/Developer/dotfiles/AGENTS.md).
