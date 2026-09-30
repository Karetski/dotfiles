# claude

Optional role. `make install` prompts before applying it unless `ENABLE_OPTIONAL_CLAUDE=1` is set in `vars/local.sh`.

Deploys Claude Code settings, hook scripts, and a status line script.

## Installation

Checks for `claude` in PATH and installs via the official install script if missing. Anthropic's current documented installs are npm or their native installer, so Claude stays separate from the Homebrew role.

## `~/.claude/settings.json`

- **Attribution** — disabled for commits and PRs (empty strings) and `sessionUrl: false` — prevents Co-Authored-By trailers, "Generated with Claude Code" lines, and session links at the settings level.
- **TUI** — `"tui": "default"` plus `env.CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1`, which forces the classic renderer even if fullscreen gets toggled on or auto-enabled.
- **Sandbox** — enabled.
- **Effort level** — `modelSettings["claude-opus-5-5"].effortLevel = "high"`. Claude Code ignores a top-level user `effortLevel` for newer models (Opus 5.5+), so effort must be set per model; add an entry when the default model changes.
- **Hooks** — wires the scripts below into `PreToolUse` and `PostToolUse`.

## `~/.claude/CLAUDE.md`

Global Claude Code instruction file with project-agnostic rules (e.g. a one-line style/no-attribution note; never use git worktrees unless explicitly asked; prefer `AskUserQuestion` for substantive decisions).

## Hooks

Deployed as executables under `~/.claude/hooks/`.

| Script | Event | Matcher | Purpose |
|--------|-------|---------|---------|
| `block-dangerous.sh` | `PreToolUse` | `Bash` | Block destructive shell commands: recursive `rm` of `/`, `~`, or `$HOME`, `git reset --hard`, force-push (`-f`, `--force*`, `+refspec`), `git clean -f*`, `DROP TABLE/DATABASE`, disk wipe (`> /dev/sda`, `mkfs.`), fork bomb; `git commit` / `gh pr` / `gh issue` commands carrying AI attribution (Claude Co-Authored-By, "Generated with Claude", `noreply@anthropic.com`) |
| `protect-files.sh` | `PreToolUse` | `Edit`/`Write` | Guard `vars/local.sh`, `.env`, and `.claude/settings.local.json` from edits and writes |
| `check-syntax.sh` | `PostToolUse` | `Edit`/`Write` | Run `bash -n` against edited `.sh` files; exit 2 on syntax errors so the error is fed back to Claude |

## Plugins

Installs the following plugins from `claude-plugins-official` at user scope:

- `code-simplifier` — refines recently modified code for clarity without changing behaviour.
- `code-review` — reviews a pull request or pending changes.

## Status line

`~/.claude/statusline.sh` is the status line script for the Claude Code terminal UI. It receives JSON on stdin from the harness and outputs a pipe-separated status string, optionally followed by a second line listing enabled plugins.

| Segment | Source | Example |
|---------|--------|---------|
| Directory | `workspace.current_dir` (parent/basename) | `Developer/dotfiles` |
| Model | `model.display_name` (stripped of `Claude ` prefix and version/date suffix) | `Opus` |
| Context | `context_window.used_percentage` | `ctx:8%` |
| Rate limit | `rate_limits.five_hour` + countdown | `5h:44% \| 3h27m` |
| Plugins (2nd line) | `~/.claude/plugins/installed_plugins.json` + merged `enabledPlugins` | `code-simplifier` |

Segments are joined with ` │ ` (U+2502 box-drawing vertical), e.g. `Developer/dotfiles │ Opus │ ctx:8% │ 5h:44% | 3h27m`.

The plugins line is only emitted when installed plugins apply to the current `cwd` (user-scoped plugins always; project-scoped plugins only when `cwd` is under their `projectPath`). Only enabled plugins are listed, with effective state resolved in the order `.claude/settings.local.json` → `.claude/settings.json` → `~/.claude/settings.json`, matching Claude Code's own rule that a plugin counts as enabled only when `enabledPlugins[id]` is literal `true` (or a non-empty array of skill names) — everything else, including an absent key, is treated as disabled.
