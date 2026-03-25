# dotfiles

Ansible-based configuration management for a macOS development environment. Manages zsh, git, lazygit, Claude Code, Ghostty, and Micro via idempotent playbooks.

## Prerequisites

- macOS
- [Homebrew](https://brew.sh) installed
- Ansible installed (`brew install ansible`)

## Usage

```bash
make install              # apply all roles
make plan                 # dry-run, show what would change
make install-tag TAG=git  # apply a single role by tag
```

## Structure

Each tool is a top-level directory (no `roles/` nesting). Every role follows the same layout:

```
<role>/
  main.yml        # tasks
  templates/      # Jinja2 templates (when variables are injected)
  files/          # static files copied as-is
```

Roles are applied in sequence by `site.yml`. All share variables from `vars/main.yml`.

## Variables

`vars/main.yml` holds shared defaults:

| Variable | Default | Description |
|----------|---------|-------------|
| `git_name` | `Alexey Karetski` | Git commit author name |
| `git_email` | `karetski@gmail.com` | Git commit author email |
| `homebrew_formulae` | `[zsh-autocomplete, lazygit, terminal-notifier, micro]` | CLI tools to install |
| `homebrew_casks` | `[ghostty]` | GUI apps to install |
| `claude_sandbox_enabled` | `true` | Enables Claude Code sandbox |

## Roles

### homebrew

Verifies that Homebrew is installed (fails with instructions if not), then installs all formulae and casks declared in `vars/main.yml`.

Casks use the `adopt` option so existing installations are adopted rather than re-downloaded.

**Formulae**: `zsh-autocomplete`, `lazygit`, `terminal-notifier`, `micro`

**Casks**: `ghostty`

---

### zsh

Deploys `~/.zshrc` from a Jinja2 template.

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

Deploys Claude Code settings and a macOS notification hook.

**Installation**: Checks for `claude` in PATH; installs via the official install script if missing.

**`~/.claude/settings.json`** (templated):

- **System prompt**: Instructs Claude to be analytical, avoid filler, and — critically — never add AI metadata, signatures, or co-authorship markers to git commits, code, or documentation.
- **Attribution**: Disabled for both commits and PRs (empty strings) — prevents Co-Authored-By trailers and PR attribution at the settings level.
- **Sandbox**: Controlled by `claude_sandbox_enabled` (default: `true`).
- **Hooks**:
  - `Stop` — fires when Claude finishes a task; runs `notify.sh` with "Task completed"
  - `Notification` — fires on permission prompts or when Claude is waiting; runs `notify.sh` with "Action needed"
  - Both hooks time out after 5 seconds.

**`~/.claude/hooks/notify.sh`**:

Sends a macOS notification via `terminal-notifier`.

Smart skip: the script checks the currently focused application. If Terminal, iTerm2, Alacritty, Kitty, WezTerm, Hyper, Warp, or Ghostty is in the foreground, the notification is suppressed — the assumption being you're already watching Claude work.

Notification content priority:
1. Message passed directly in the hook JSON (if present)
2. Last assistant response extracted from the Claude session transcript (truncated to 80 characters)
3. Fallback: "Task completed"

---

### ghostty

Deploys the Ghostty terminal emulator config to `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`.

Ghostty itself is installed via the `homebrew_casks` list.

**Theme**: Separate light and dark variants using Apple System Colors (adapts to macOS appearance).

**Font**: SF Mono Terminal, Medium weight, 11pt.

**Cursor**: Block style.

**Shell integration**: Disabled for cursor, sudo, and title — minimal overhead, no unwanted prompt decoration.

**Splits**: Inactive splits are not dimmed (`unfocused-split-opacity = 1`).

---

### micro

Deploys [Micro](https://micro-editor.github.io) editor config to `~/.config/micro/`.

**Colorscheme**: `simple`.

