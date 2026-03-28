# dotfiles

Plain shell script configuration management for a macOS development environment. Manages zsh, git, lazygit, Claude Code, Ghostty, and Micro via idempotent install scripts.

## Prerequisites

- macOS
- [Homebrew](https://brew.sh) installed

## Usage

```bash
make install              # apply all roles
make plan                 # dry-run, show what would change
make install-tag TAG=git  # apply a single role by tag
```

## Structure

Each tool is a top-level directory (no nesting). Every role follows the same layout:

```
<role>/
  install.sh      # tasks
  templates/      # envsubst templates (when variables are injected)
  files/          # static files copied as-is
```

Roles are applied in sequence by `install.sh`. All share variables from `vars/main.sh`.

## Variables

`vars/main.sh` holds shared defaults:

| Variable | Default | Description |
|----------|---------|-------------|
| `GIT_NAME` | `Alexey Karetski` | Git commit author name |
| `GIT_EMAIL` | `karetski@gmail.com` | Git commit author email |
| `HOMEBREW_FORMULAE` | `(zsh-autocomplete lazygit terminal-notifier micro jq)` | CLI tools to install |
| `HOMEBREW_CASKS` | `(ghostty)` | GUI apps to install |
| `CLAUDE_SANDBOX_ENABLED` | `true` | Enables Claude Code sandbox |

## Roles

### homebrew

Verifies that Homebrew is installed (fails with instructions if not), then installs all formulae and casks declared in `vars/main.sh`.

Casks use the `adopt` option so existing installations are adopted rather than re-downloaded.

**Formulae**: `zsh-autocomplete`, `lazygit`, `terminal-notifier`, `micro`

**Casks**: `ghostty`

---

### zsh

Deploys `~/.zshrc` as a static file.

**PATH**: Prepends `~/.local/bin` (where role-deployed scripts live).

**Plugin**: Sources `zsh-autocomplete` from its Homebrew location for real-time completion.

**Aliases**:

| Alias | Expands to | Description |
|-------|-----------|-------------|
| `ll` | `lssplit` | Lists directory contents split into Directories, Files, and Symlinks sections with colored headers |
| `caff` | `caffeinate` | Prevent system sleep |
| `caffd` | `caffeinate -d` | Prevent display sleep only |

**Key bindings**:

| Key | Action |
|-----|--------|
| Cmd+Left | Beginning of line |
| Cmd+Right | End of line |
| Option+Delete | Backward kill word |

**Prompt**: Two-line prompt using zsh's `vcs_info` hook.
- Line 1: Git branch/status (shown only inside a git repo)
- Line 2: Success/failure indicator (`%` / `#` for root), current path, username
- Right prompt: Current time

Git status symbols in the prompt: `⎇` (branch name), `□` (unstaged changes), `■` (staged changes).

**Local overrides**: Sources `~/.zshrc.local` at the end if the file exists. Use this for machine-specific aliases and config that doesn't belong in the shared repo.

---

### git

Deploys git configuration across two files.

**`~/.gitconfig`** (templated):
- Sets `user.name` and `user.email` from variables

**`~/.config/git/ignore`**:

Globally ignores `.claude/settings.local.json` so per-machine Claude overrides are never accidentally committed.

---

### lazygit

Deploys `~/Library/Application Support/lazygit/config.yml`.

**Theme**: White selected-line background.

**Custom commands**:

| Key | Context | Action |
|-----|---------|--------|
| `p` | files | Quick Look the selected file |
| `p` | commitFiles | Quick Look the selected commit file |

---

### claude

Deploys Claude Code settings and a status line script.

**Installation**: Checks for `claude` in PATH; installs via the official install script if missing.

**`~/.claude/settings.json`** (templated via `envsubst`):

- **System prompt**: Instructs Claude to be analytical, avoid filler, and — critically — never add AI metadata, signatures, or co-authorship markers to git commits, code, or documentation.
- **Attribution**: Disabled for both commits and PRs (empty strings) — prevents Co-Authored-By trailers and PR attribution at the settings level.
- **Sandbox**: Controlled by `CLAUDE_SANDBOX_ENABLED` (default: `true`).

**`~/.claude/statusline.sh`**: Status line script for the Claude Code terminal UI.

---

### ghostty

Deploys the Ghostty terminal emulator config to `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`.

Ghostty itself is installed via the `HOMEBREW_CASKS` list.

**Theme**: Separate light and dark variants using Apple System Colors (adapts to macOS appearance).

**Font**: SF Mono Terminal, Medium weight, 11pt.

**Cursor**: Block style.

**Shell integration**: Disabled for cursor, sudo, and title — minimal overhead, no unwanted prompt decoration.

**Splits**: Inactive splits are not dimmed (`unfocused-split-opacity = 1`).

---

### micro

Deploys [Micro](https://micro-editor.github.io) editor config to `~/.config/micro/`.

**Colorscheme**: `simple`.

