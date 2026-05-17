# claude

Optional role. `make install` prompts before applying it unless `ENABLE_OPTIONAL_CLAUDE=1` is set in `vars/local.sh`.

Deploys Claude Code settings, hook scripts, and a status line script.

## Installation

Checks for `claude` in PATH and installs via the official install script if missing. Anthropic's current documented installs are npm or their native installer, so Claude stays separate from the Homebrew role.

## `~/.claude/settings.json`

- **System prompt** — instructs Claude to be analytical, avoid filler, and never add AI metadata, signatures, or co-authorship markers to git commits, code, or documentation.
- **Attribution** — disabled for both commits and PRs (empty strings) — prevents Co-Authored-By trailers and PR attribution at the settings level.
- **Sandbox** — enabled.
- **Effort level** — `"high"` — high reasoning effort on every request.
- **Hooks** — wires the scripts below into `PreToolUse` and `PostToolUse`.

## `~/.claude/CLAUDE.md`

Global Claude Code instruction file with project-agnostic rules (e.g. never use git worktrees unless explicitly asked; prefer `AskUserQuestion` for substantive decisions).

## Hooks

Deployed as executables under `~/.claude/hooks/`.

| Script | Event | Matcher | Purpose |
|--------|-------|---------|---------|
| `block-dangerous.sh` | `PreToolUse` | `Bash` | Block destructive shell commands: `rm -rf /` or `~`, `git reset --hard`, force-push, `git clean -fd`, `DROP TABLE/DATABASE`, disk wipe (`> /dev/sda`, `mkfs.`), fork bomb |
| `protect-files.sh` | `PreToolUse` | `Edit`/`Write` | Guard `vars/local.sh`, `.env`, and `.claude/settings.local.json` from edits and writes |
| `check-syntax.sh` | `PostToolUse` | `Edit`/`Write` | Run `bash -n` against edited `.sh` files; fail the tool call on syntax errors |

## Plugins

Installs `code-simplifier` from `claude-plugins-official` at user scope. `code-simplifier` refines recently modified code for clarity without changing behaviour.

## Status line

`~/.claude/statusline.sh` is the status line script for the Claude Code terminal UI. It receives JSON on stdin from the harness and outputs a pipe-separated status string, optionally followed by a second line listing enabled plugins.

| Segment | Source | Example |
|---------|--------|---------|
| Directory | `workspace.current_dir` | `dotfiles/neovim` |
| Model | `model.display_name` (stripped) | `Opus 4.6` |
| Context | `context_window.used_percentage` | `ctx:42%` |
| Rate limit | `rate_limits.five_hour` + countdown | `5h:15% \| 3h12m` |
| Plugins (2nd line) | `~/.claude/plugins/installed_plugins.json` + merged `enabledPlugins` | `code-simplifier` |

The plugins line is only emitted when installed plugins apply to the current `cwd` (user-scoped plugins always; project-scoped plugins only when `cwd` is under their `projectPath`). Only enabled plugins are listed, with effective state resolved in the order `.claude/settings.local.json` → `.claude/settings.json` → `~/.claude/settings.json`, matching Claude Code's own rule that a plugin counts as enabled only when `enabledPlugins[id]` is literal `true` (or a non-empty array of skill names) — everything else, including an absent key, is treated as disabled.
