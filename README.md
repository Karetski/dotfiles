# dotfiles

Ansible-based configuration management for a macOS development environment. Manages zsh, git, lazygit, Claude Code, Ghostty, Fresh, and tmux via idempotent playbooks.

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
| `git_email` | `alexey@karetski.com` | Git commit author email |
| `homebrew_formulae` | see below | CLI tools to install |
| `homebrew_casks` | `[ghostty]` | GUI apps to install |
| `claude_sandbox_enabled` | `true` | Enables Claude Code sandbox |
| `lazygit_image_preview` | `false` | Enables chafa-based image diffs in lazygit |

Default formulae: `zsh-autocomplete`, `lazygit`, `terminal-notifier`, `chafa`, `tmux`.

## Roles

### homebrew

Verifies that Homebrew is installed (fails with instructions if not), then installs all formulae and casks declared in `vars/main.yml`.

Casks use the `adopt` option so existing installations are adopted rather than re-downloaded.

---

### zsh

Deploys `~/.zshrc` from a Jinja2 template.

**PATH**: Prepends `~/.local/bin` (where role-deployed scripts live).

**tmux auto-attach**: On shell startup, if not already inside tmux, creates a new tmux session. Sessions are not reused — each terminal tab gets its own session and it is destroyed when the tab closes.

**Plugin**: Sources `zsh-autocomplete` from its Homebrew location for real-time completion.

**Aliases**:

| Alias | Expands to | Description |
|-------|-----------|-------------|
| `ll` | `lssplit` | Lists directory contents split into Directories, Files, and Symlinks sections with colored headers |
| `caff` | `caffeinate` | Prevent system sleep |
| `caffd` | `caffeinate -d` | Prevent display sleep only |

**Key bindings** (iTerm2 Natural Text Editing style):

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

Deploys git configuration across three files.

**`~/.gitconfig`** (templated):
- Sets `user.name` and `user.email` from variables
- Registers an image diff handler: `diff.image.command = git-image-diff` (used by lazygit's external diff)

**`~/.config/git/attributes`**:

Maps common image extensions to the `diff=image` handler:

```
*.png  diff=image
*.jpg  diff=image
*.jpeg diff=image
*.gif  diff=image
*.webp diff=image
*.svg  diff=image
```

**`~/.config/git/ignore`**:

Globally ignores `.claude/settings.local.json` so per-machine Claude overrides are never accidentally committed.

---

### lazygit

Deploys lazygit's config and an optional image diff script.

**`~/.config/lazygit/config.yml`** (templated):

When `lazygit_image_preview: true`, sets `git.paging.externalDiffCommand: git-image-diff`. Otherwise the config is empty (lazygit uses its own defaults).

**`~/.local/bin/git-image-diff`** (deployed only when `lazygit_image_preview: true`):

A shell script that acts as git's external diff driver for image files.

- For image files (`.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.bmp`, `.tiff`, `.ico`, `.svg`): renders each side using `chafa` as ANSI art in the terminal. Rendered output is cached in `/tmp/gid-*.cache` by MD5 hash to avoid re-rendering the same image repeatedly.
- For deleted files: prints `(deleted)`.
- For all other files: falls back to standard `diff -u`.

Requires `chafa` and `terminal-notifier` installed (both included in `homebrew_formulae`).

To enable image preview on a machine, set in `host_vars/<hostname>.yml`:

```yaml
lazygit_image_preview: true
```

---

### claude

Deploys Claude Code settings and a macOS notification hook.

**`~/.claude/settings.json`** (templated):

- **System prompt**: Instructs Claude to be analytical, avoid filler, and — critically — never add AI metadata, signatures, or co-authorship markers to git commits, code, or documentation.
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

---

### fresh

Deploys the [Fresh](https://www.freshcode.app) editor config to `~/.config/fresh/config.json`.

**Keymap**: macOS.

**Editor settings**: Enables keyboard disambiguation of escape codes and alternate key reporting for accurate key detection in the terminal.

**Custom keybindings**:

| Key | Context | Action |
|-----|---------|--------|
| Alt+F | global | Move word right |
| Alt+B | global | Move word left |
| Ctrl+B | global | Disabled (noop) |
| Ctrl+E | file_explorer, normal | Disabled (noop) |
| Alt+] | file_explorer | Disabled (noop) |
| Alt+J | global | Focus editor |
| Ctrl+Alt+J | global | Focus file explorer |

**Theme**: Light.

**File explorer**: Shows hidden files.

---

### tmux

Deploys `~/.tmux.conf`.

**Prefix**: Changed from the default `Ctrl+B` to `Ctrl+Space`.

**Mouse**: Enabled.

**Sessions**: Each terminal tab creates a fresh session (`destroy-unattached on`). Sessions are destroyed when the tab closes.

**True color**: Enabled via `default-terminal tmux-256color` and `Tc` terminal override so 24-bit color works inside tmux.

**Pane splitting**: New windows and panes always open in the current pane's working directory.

| Key | Action |
|-----|--------|
| `prefix` + `c` | New window (inherits current path) |
| `prefix` + `\|` | Split horizontally (inherits current path) |
| `prefix` + `-` | Split vertically (inherits current path) |
