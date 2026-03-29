# dotfiles

Plain shell script configuration management for a macOS development environment. Manages zsh, git, lazygit, Claude Code, Codex, Ghostty, and Micro via idempotent install scripts.

## Prerequisites

- macOS
- [Homebrew](https://brew.sh) installed

## Usage

```bash
make install              # apply all roles; prompts to remove stale backups and unmanaged configs
make plan                 # dry-run: show what would change, including sanitize findings
make install-tag TAG=git  # apply a single role by tag
```

## Optional Components

Some roles and Homebrew packages can be marked optional. During `make install`, optional items prompt before they are applied. During `make plan`, they show as `would prompt to apply`.

This repo currently treats these items as optional:

- `claude` role
- `codex` Homebrew cask
- `codex` role

To auto-apply an optional item without an interactive prompt, set the matching variable in `vars/local.sh`:

```bash
export ENABLE_OPTIONAL_CLAUDE=1
export ENABLE_OPTIONAL_CODEX=1
```

Those variables are checked once per run and reused across related steps. For example, `ENABLE_OPTIONAL_CODEX=1` enables both the `codex` Homebrew install and the `codex` role.

To mark more items as optional:

- Add role names to `OPTIONAL_ROLES` in `vars/main.sh`
- Add formula names to `OPTIONAL_HOMEBREW_FORMULAE` in `vars/main.sh`
- Add cask names to `OPTIONAL_HOMEBREW_CASKS` in `vars/main.sh`

The corresponding override variable name is derived from the item name:

- `claude` -> `ENABLE_OPTIONAL_CLAUDE`
- `codex` -> `ENABLE_OPTIONAL_CODEX`
- `some-tool` -> `ENABLE_OPTIONAL_SOME_TOOL`

## Structure

Each tool is a top-level directory (no nesting). Every role follows the same layout:

```
<role>/
  install.sh      # tasks
  templates/      # envsubst templates (when variables are injected)
  files/          # static files copied as-is
```

Roles are applied in sequence by `install.sh`. All share variables from `vars/main.sh`, with optional per-machine overrides from `vars/local.sh`.

## Variables

`vars/main.sh` holds shared defaults. `vars/local.sh` is sourced after it if present — use it for machine-specific values. It is gitignored; see `vars/local.sh.example` for a template.

| Variable | Where | Description |
|----------|-------|-------------|
| `GIT_NAME` | `vars/local.sh` | Git commit author name |
| `GIT_EMAIL` | `vars/local.sh` | Git commit author email |
| `ENABLE_OPTIONAL_CLAUDE` | `vars/local.sh` | Auto-apply the optional Claude role instead of prompting |
| `ENABLE_OPTIONAL_CODEX` | `vars/local.sh` | Auto-apply the optional Codex cask and role instead of prompting |
| `OPTIONAL_ROLES` | `vars/main.sh` | Roles that should prompt before applying |
| `OPTIONAL_HOMEBREW_FORMULAE` | `vars/main.sh` | Formulae that should prompt before installing |
| `OPTIONAL_HOMEBREW_CASKS` | `vars/main.sh` | Casks that should prompt before installing |
| `HOMEBREW_FORMULAE` | `vars/main.sh` | CLI tools to install |
| `HOMEBREW_CASKS` | `vars/main.sh` | GUI apps to install |
| `CLAUDE_SANDBOX_ENABLED` | `vars/main.sh` | Enables Claude Code sandbox (default: `true`) |

## Roles

### homebrew

Verifies that Homebrew is installed (fails with instructions if not), then installs all formulae and casks declared in `vars/main.sh`.

Casks use the `adopt` option so existing installations are adopted rather than re-downloaded.

`codex` is an optional cask: `make install` will prompt before applying it unless `ENABLE_OPTIONAL_CODEX=1` is set in `vars/local.sh`.

**Formulae**: `zsh-autocomplete`, `lazygit`, `micro`, `jq`, `fzf`, `neovim`

**Casks**: `codex`, `ghostty`

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
- Sets `user.name` and `user.email` from `GIT_NAME` / `GIT_EMAIL` — both must be set in `vars/local.sh`

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

Optional role. `make install` prompts before applying it unless `ENABLE_OPTIONAL_CLAUDE=1` is set in `vars/local.sh`.

Deploys Claude Code settings and a status line script.

**Installation**: Checks for `claude` in PATH; installs via the official install script if missing. Anthropic’s current documented installs are npm or their native installer, so it remains separate from the Homebrew role.

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

---

### codex

Optional role. `make install` prompts before applying it unless `ENABLE_OPTIONAL_CODEX=1` is set in `vars/local.sh`.

Deploys a Codex instruction file and updates `~/.codex/config.toml` in place without removing existing project trust entries. Installation is handled by the `homebrew` role via the `codex` cask.

**`~/.codex/instructions.md`**:

- Mirrors the Claude guidance to stay analytical, concise, and implementation-focused.
- Explicitly forbids AI signatures, attribution lines, co-author tags, and similar metadata in commits, files, comments, or docs.

**`~/.codex/config.toml`**:

- Sets `commit_attribution = ""` to disable Codex co-author trailers.
- Pins `approval_policy = "untrusted"` and `sandbox_mode = "workspace-write"` to match the current workflow.
- Points `model_instructions_file` at the deployed instruction file.
- Adds the OpenAI developer docs MCP server at `https://developers.openai.com/mcp`.


---

### neovim

Deploys `~/.config/nvim/init.lua`.

**Plugin manager**: [lazy.nvim](https://github.com/folke/lazy.nvim) (auto-bootstrapped on first launch).

**Plugins**:

| Plugin | Purpose |
|--------|---------|
| `neo-tree.nvim` | File manager sidebar |
| `catppuccin` | Colorscheme (latte flavour) |

**Key bindings**:

| Key | Action |
|-----|--------|
| `<Space>e` | Toggle file manager (neo-tree) |
| `H` / `L` | Start / end of line |
| `J` / `K` | Bottom / top of file |
| `w` / `W` | Previous word (b / B) |
| `jk` (insert) | Escape to normal mode |

**neo-tree** follows the current file automatically and replaces netrw.

---

### micro

Deploys [Micro](https://micro-editor.github.io) editor config to `~/.config/micro/`.

**Colorscheme**: `simple`.
