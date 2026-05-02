# dotfiles

Plain shell script configuration management for a macOS development environment. Manages shell, CLI tools, Claude Code, terminal and editor configs, and language toolchains via idempotent install scripts organised as 23 roles.

## Prerequisites

- macOS
- [Homebrew](https://brew.sh) installed

## Usage

```bash
make install              # apply all roles; prompts to remove stale backups and unmanaged configs
make plan                 # dry-run: show what would change, including sanitize findings
make install-tag TAG=git  # apply a single role by tag
make install-confirm      # confirm each role and each brew package before applying
```

## Optional Components

Some roles can be marked optional. During `make install`, optional roles prompt before they are applied. During `make plan`, they show as `would prompt to apply`.

This repo currently treats these roles as optional:

- `claude`
- `stats`
- `zed`
- `docker-desktop`
- `linearmouse`
- `bun`

To auto-apply an optional role without an interactive prompt, set the matching variable in `vars/local.sh`:

```bash
export ENABLE_OPTIONAL_CLAUDE=1
export ENABLE_OPTIONAL_STATS=1
export ENABLE_OPTIONAL_ZED=1
export ENABLE_OPTIONAL_DOCKER_DESKTOP=1
export ENABLE_OPTIONAL_LINEARMOUSE=1
export ENABLE_OPTIONAL_BUN=1
```

Because each role now declares its own brew dependencies, a single override gates both the role's config and the Homebrew package that ships with it. For example, `ENABLE_OPTIONAL_STATS=1` covers both installing Stats.app and importing its preferences.

### Confirm mode

`make install-confirm` (or `CONFIRM_MODE=1 make install`) temporarily treats every role and every Homebrew package as optional, prompting `[y/N]` before each one. Use it on a fresh or unfamiliar machine to walk through the install one step at a time and cherry-pick what runs — without permanently editing `OPTIONAL_ROLES`.

- Each of the 23 roles prompts before its install script runs.
- Each Homebrew formula and cask that is not yet installed prompts before `brew install`. Already-installed packages are skipped silently (nothing would change anyway).
- `ENABLE_OPTIONAL_*` overrides are **ignored** in confirm mode — if you want to confirm everything, existing always-on preferences shouldn't short-circuit the prompt.
- `_role_is_configured` auto-skip is bypassed — already-configured optional roles still prompt.
- `CONFIRM_MODE=1 DRY_RUN=1` combines with `make plan`: no interactive prompts, `would prompt to apply` lines for every role and package instead.
- `CONFIRM_MODE=1 TAG=git` still runs a single tagged role without prompting (TAG wins).

To mark more roles as optional, add their names to `OPTIONAL_ROLES` in `vars/main.sh`.

The corresponding override variable name is derived from the role name:

- `claude` -> `ENABLE_OPTIONAL_CLAUDE`
- `stats` -> `ENABLE_OPTIONAL_STATS`
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

## Scripts

### Makefile

Entry point for all operations. Wraps `install.sh` with convenience targets.

| Target | Command | Description |
|--------|---------|-------------|
| `install` | `./install.sh` | Apply all roles in sequence |
| `plan` | `DRY_RUN=1 ./install.sh` | Dry run — show intended changes without modifying files |
| `install-tag` | `TAG=$(TAG) ./install.sh` | Apply a single role by name |
| `install-confirm` | `CONFIRM_MODE=1 ./install.sh` | Prompt `[y/N]` before every role and every brew package |

### install.sh

Main orchestrator. Sources `lib/utils.sh` for helpers, `vars/main.sh` for defaults, and `vars/local.sh` for machine-specific overrides if present. Iterates through the role list in this order, grouped by purpose:

- **preflight** — `xcode-select`, `homebrew`
- **shell** — `zsh`, `zsh-autocomplete`, `fzf`
- **cli tools** — `git`, `lazygit`, `jq`, `ripgrep`, `fd`
- **dev tools** — `claude`, `docker-desktop`
- **system** — `ghostty`, `stats`, `linearmouse`, `macos`
- **toolchains** — `nvm`, `bun`, `uv`, `rustup`
- **editor** — `zed`, `neovim`

- Each role is sourced from `<role>/install.sh`
- Optional roles prompt before applying (or skip based on `ENABLE_OPTIONAL_*` variables)
- Optional roles that are already configured (e.g. `~/.claude/settings.json` exists) are noted and skipped without prompting
- `TAG` filters to a single role; tagged runs skip the optional prompt
- `CONFIRM_MODE=1` prompts before every role and every brew package; `ENABLE_OPTIONAL_*` overrides and the `already configured` auto-skip are bypassed
- Prints a summary of all changes at the end via `_log_summary`

### lib/utils.sh

Shared utility library sourced by all install scripts. Provides:

**Logging** — styled, section-banner output with status indicators:

| Function | Indicator | Purpose |
|----------|-----------|---------|
| `_log_ok` | `✓` | Successful action (deployed, created, removed) |
| `_log_skip` | `·` | No action needed (exists, no change, already installed) |
| `_log_dry` | `→` | Dry-run planned action |
| `_log_note` | `◆` | Informational note |
| `_log_err` | `✗` | Error message |

**Section layout** — `_log_group` renders a reverse-video banner above each cluster of related roles (`preflight`, `shell`, `cli tools`, `dev tools`, `system`, `toolchains`, `editor`) so groups read as one unmistakable visual marker. `_log_section` opens a bordered section for a role (with optional `[n/total]` counter), `_log_section_end` closes it with a per-section summary, and `_log_summary` prints the final totals.

**Brew helpers** — `ensure_brew_formula NAME` / `ensure_brew_cask NAME` are the public entry points each role calls to declare its own Homebrew dependencies (idempotent, CONFIRM_MODE-aware, dry-run-safe). `_log_brew_start` / `_log_brew_end` frame Homebrew install output, and `_brew_pipe` indents brew output under the section banner.

**File deployment:**

| Function | Purpose |
|----------|---------|
| `ensure_dir DIR [MODE]` | Create directory if missing (default `0755`) |
| `deploy_file SRC DEST [MODE]` | Copy file if changed, show inline diff, back up previous version |
| `deploy_template SRC DEST [MODE] [VARS]` | Run `envsubst` on a template then deploy the result |

Both `deploy_file` and `deploy_template` are idempotent — they skip when the destination matches and show an inline unified diff when updating.

**Sanitize:**

| Function | Purpose |
|----------|---------|
| `_sanitize_bak DEST` | Prompt to remove stale `.bak` files left by previous deploys |
| `_sanitize_dir DIR IGNORE_FILE MANAGED...` | Prompt to remove files in a directory that are not in the managed list or ignore file |

**Diff display** — `_log_diff` and `_log_diff_raw` render unified diffs inside the table border with color-coded additions/removals.

**Terminal width** — `_refresh_term_w` computes `_TERM_W` (clamped 40–120) and `_LOG_COL` (the name column width for item rows, clamped 20–44) and is wired to a `SIGWINCH` trap so layout adapts automatically when the terminal is resized. Width is detected via `stty size` (reads live `TIOCGWINSZ`), falling back to `$COLUMNS`, then `tput cols`, then 80. On narrow terminals (< 64 cols) the name column shrinks to prevent overflow; on wide terminals it stays at 44 chars.

**Helpers** — `_shorten` abbreviates paths for display, `_contains` checks array membership, `_optional_selected` handles interactive opt-in prompts with caching and `ENABLE_OPTIONAL_*` overrides.

### vars/main.sh

Shared defaults sourced before any role runs. Defines `OPTIONAL_ROLES`. See [Variables](#variables) for the full list. Homebrew package lists live inside each role's own `install.sh` now, not here.

### vars/local.sh

Machine-specific overrides, sourced after `vars/main.sh`. Gitignored — see `vars/local.sh.example` for a template. Holds values like `GIT_NAME`, `GIT_EMAIL`, and `ENABLE_OPTIONAL_*` flags.

### claude/files/statusline.sh

Status line script deployed to `~/.claude/statusline.sh` for the Claude Code terminal UI. Receives JSON on stdin from the Claude Code harness and outputs a pipe-separated status string, optionally followed by a second line listing plugin state:

| Segment | Source | Example |
|---------|--------|---------|
| Directory | `workspace.current_dir` | `dotfiles/neovim` |
| Model | `model.display_name` (stripped) | `Opus 4.6` |
| Context | `context_window.used_percentage` | `ctx:42%` |
| Rate limit | `rate_limits.five_hour` + countdown | `5h:15% \| 3h12m` |
| Plugins (2nd line) | `~/.claude/plugins/installed_plugins.json` + merged `enabledPlugins` | `plugins: +superpowers -rust-analyzer-lsp` |

The plugins line is only emitted when installed plugins apply to the current `cwd` (user-scoped plugins always, project-scoped plugins only when `cwd` is under their `projectPath`). Each plugin is prefixed with `+` when enabled or `-` when disabled, with effective state resolved in the order `.claude/settings.local.json` → `.claude/settings.json` → `~/.claude/settings.json`, matching Claude Code's own rule that a plugin counts as enabled only when `enabledPlugins[id]` is literal `true` (or a non-empty array of skill names) — everything else, including an absent key, is treated as disabled.

### Role install scripts

Each role has an `install.sh` sourced by the main orchestrator. These scripts use the `lib/utils.sh` helpers and are not standalone — they inherit the shell environment (variables, functions, `set -euo pipefail`) from the parent. See [Roles](#roles) for what each one deploys.

## Variables

`vars/main.sh` holds shared defaults. `vars/local.sh` is sourced after it if present — use it for machine-specific values. It is gitignored; see `vars/local.sh.example` for a template.

| Variable | Where | Description |
|----------|-------|-------------|
| `GIT_NAME` | `vars/local.sh` | Git commit author name |
| `GIT_EMAIL` | `vars/local.sh` | Git commit author email |
| `ENABLE_OPTIONAL_CLAUDE` | `vars/local.sh` | Auto-apply the optional Claude role instead of prompting |
| `ENABLE_OPTIONAL_STATS` | `vars/local.sh` | Auto-apply the optional Stats cask and role instead of prompting |
| `ENABLE_OPTIONAL_ZED` | `vars/local.sh` | Auto-apply the optional Zed cask and role instead of prompting |
| `ENABLE_OPTIONAL_UV_DEFAULT_PYTHON` | `vars/local.sh` | Auto-run `uv python install` during the `uv` role instead of prompting |
| `ENABLE_OPTIONAL_RUST_TOOLCHAIN` | `vars/local.sh` | Auto-run `rustup default stable` during the `rustup` role instead of prompting |
| `ENABLE_OPTIONAL_DOCKER_DESKTOP` | `vars/local.sh` | Auto-apply the optional Docker Desktop cask role instead of prompting |
| `ENABLE_OPTIONAL_LINEARMOUSE` | `vars/local.sh` | Auto-apply the optional LinearMouse cask role instead of prompting |
| `ENABLE_OPTIONAL_NVM_DEFAULT_NODE` | `vars/local.sh` | Auto-run `nvm install --lts` during the `nvm` role instead of prompting |
| `ENABLE_OPTIONAL_BUN` | `vars/local.sh` | Auto-apply the optional Bun toolchain role instead of prompting |
| `OPTIONAL_ROLES` | `vars/main.sh` | Roles that should prompt before applying |
| `CONFIRM_MODE` | inline env var | Set to `1` to prompt before every role and brew package for a single run (also via `make install-confirm`) |

## Roles

### xcode-select

Preflight step — runs `xcode-select --install` to bootstrap Apple's Command Line Tools (clang, make, git, and the rest) if `xcode-select -p` reports none. The installer is GUI-driven and asynchronous, so if it needs to run the role triggers it and aborts the orchestrator with a message asking you to re-run `make install` once the installer finishes. Has to run before `homebrew` because Homebrew itself fails without Command Line Tools.

---

### homebrew

Preflight step — verifies that Homebrew itself is installed and fails with install instructions if not. Individual packages are declared by the roles that need them via `ensure_brew_formula` / `ensure_brew_cask` (see [lib/utils.sh](#libutilssh)), so each role composes its own dependencies end-to-end.

---

### zsh

Deploys `~/.zshrc` as a static file.

**PATH**: Prepends `~/.local/bin` (where role-deployed scripts live).

**Plugins**: Sources `zsh-autocomplete` from its Homebrew location for real-time completion, `fzf` for fuzzy finding, and `nvm` so `node`/`npm` land on PATH for interactive shells — the latter is how `nvim`-launched processes such as Mason's Node-based LSP installs find them. Each of those tools is installed by its own sibling role (`zsh-autocomplete`, `fzf`, `nvm`); the `zsh` role itself only deploys `.zshrc`.

**Aliases**:

| Alias | Expands to | Description |
|-------|-----------|-------------|
| `ll` | `lssplit` | Lists directory contents split into Directories, Files, and Symlinks sections with Nerd Font icons, type-based colors, human-readable sizes, and a layout that adapts to terminal width (full / compact / grid). Set `LSSPLIT_ICONS=0` to disable glyphs |
| `nv` | `nvim` | Shortcut for Neovim |
| `nvf` | `nvim $(fzf)` | Open a file in Neovim via fzf |
| `caff` | `caffeinate` | Prevent system sleep |
| `caffd` | `caffeinate -d` | Prevent display sleep only |

**Key bindings**:

| Key | Action |
|-----|--------|
| Cmd+Left | Beginning of line |
| Cmd+Right | End of line |
| Option+Delete | Backward kill word |

**Prompt**: Two-line prompt using zsh's `vcs_info` hook.
- Line 1: Three cascading segments with rounded powerline separators (, ) — path on `136` (#af8700, amber), branch on `178` (#d7af00, golden), status symbols on `220` (#ffd700, yellow). Not full-width; bar ends after the last segment. Branch and status segments are hidden when not in a git repo or when the working tree is clean.
- Line 2: Success/failure indicator (`❯` green on success, red on failure), `%` (`#` for root)

Git status symbols: `⎇` branch, `□` unstaged, `■` staged, `↑N` ahead of remote, `↓N` behind remote.

**Local overrides**: Sources `~/.zshrc.local` at the end if the file exists. Use this for machine-specific aliases and config that doesn't belong in the shared repo.

---

### zsh-autocomplete

Installs [zsh-autocomplete](https://github.com/marlonrichert/zsh-autocomplete) via `ensure_brew_formula zsh-autocomplete`. The plugin is sourced from `.zshrc` (deployed by the `zsh` role) at interactive-shell startup.

---

### fzf

Installs [fzf](https://github.com/junegunn/fzf) via `ensure_brew_formula fzf`. The binary powers the `nvf` alias (`nvim $(fzf)`) and is sourced via `source <(fzf --zsh)` from `.zshrc` for key bindings and completion. It's also used indirectly by the `snacks.nvim` picker in the `neovim` role for its internal matcher.

---

### git

Deploys git configuration across two files.

**`~/.gitconfig`** (templated):
- Sets `user.name` and `user.email` from `GIT_NAME` / `GIT_EMAIL` — both must be set in `vars/local.sh`

**`~/.config/git/ignore`**:

Globally ignores `.claude/settings.local.json` (per-machine Claude overrides) and `.DS_Store`.

---

### lazygit

Deploys `~/Library/Application Support/lazygit/config.yml`.

**Theme**: White selected-line background.

**Custom commands**:

| Key | Context | Action |
|-----|---------|--------|
| `p` | files | Quick Look the selected file (images, video, PDF, SVG only) |
| `p` | commitFiles | Quick Look the selected commit file (images, video, PDF, SVG only) |

---

### jq

Installs the [jq](https://stedolan.github.io/jq/) command-line JSON processor via Homebrew. No config files — jq is consumed at runtime by the `claude` role's hook scripts and status line, so it's modeled as its own step to keep dependencies composable rather than hidden inside another role.

---

### ripgrep

Installs [ripgrep](https://github.com/BurntSushi/ripgrep) via `ensure_brew_formula ripgrep`. Used at runtime by `snacks.nvim`'s grep picker in the `neovim` role (and generally useful as a `grep` replacement).

---

### fd

Installs [fd](https://github.com/sharkdp/fd) via `ensure_brew_formula fd`. Used at runtime by `snacks.nvim`'s file picker in the `neovim` role (and generally useful as a `find` replacement).

---

### claude

Optional role. `make install` prompts before applying it unless `ENABLE_OPTIONAL_CLAUDE=1` is set in `vars/local.sh`.

Deploys Claude Code settings, hook scripts, and a status line script.

**Installation**: Checks for `claude` in PATH; installs via the official install script if missing. Anthropic’s current documented installs are npm or their native installer, so it remains separate from the Homebrew role.

**`~/.claude/settings.json`**:

- **System prompt**: Instructs Claude to be analytical, avoid filler, and — critically — never add AI metadata, signatures, or co-authorship markers to git commits, code, or documentation.
- **Attribution**: Disabled for both commits and PRs (empty strings) — prevents Co-Authored-By trailers and PR attribution at the settings level.
- **Sandbox**: Enabled.
- **Effort level**: Set to `"high"` — high reasoning effort on every request.
- **Hooks**: Wires the scripts below into `PreToolUse` and `PostToolUse`.

**`~/.claude/CLAUDE.md`**: Global Claude Code instruction file with project-agnostic rules (e.g. never use git worktrees unless explicitly asked, always ask via `AskUserQuestion`).

**`~/.claude/hooks/`**: Tool hook scripts deployed as executables.

| Script | Event | Matcher | Purpose |
|--------|-------|---------|---------|
| `block-dangerous.sh` | `PreToolUse` | `Bash` | Block destructive shell commands: `rm -rf /` or `~`, `git reset --hard`, force-push, `git clean -fd`, `DROP TABLE/DATABASE`, disk wipe (`> /dev/sda`, `mkfs.`), fork bomb |
| `protect-files.sh` | `PreToolUse` | `Edit`/`Write` | Guard `vars/local.sh`, `.env`, and `.claude/settings.local.json` from edits and writes |
| `check-syntax.sh` | `PostToolUse` | `Edit`/`Write` | Run `bash -n` against edited `.sh` files; fail the tool call on syntax errors |

**`~/.claude/statusline.sh`**: Status line script for the Claude Code terminal UI.

**Plugins**: Installs `code-simplifier` and `superpowers` from `claude-plugins-official` at user scope. `code-simplifier` refines recently modified code for clarity without changing behaviour. `superpowers` adds a curated bundle of skills, slash commands, and subagents for deeper engineering workflows (see [obra/superpowers](https://github.com/obra/superpowers)).

---

### docker-desktop

Optional role. `make install` prompts before applying it unless `ENABLE_OPTIONAL_DOCKER_DESKTOP=1` is set in `vars/local.sh`. Installs Docker Desktop via `ensure_brew_cask docker-desktop`; no additional config is deployed.

---

### ghostty

Deploys the Ghostty terminal emulator config to `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`.

Ghostty itself is installed via `ensure_brew_cask ghostty` at the top of this role's install script.

**Theme**: Separate light and dark variants using Apple System Colors (adapts to macOS appearance).

**Font**: SF Mono Terminal, Medium weight, 11pt.

**Cursor**: Block style.

**Shell integration**: Cursor and sudo disabled; title enabled.

**Splits**: Divider color set to `#808080` (mid-gray) for a prominent separator visible on both light and dark themes.

---

### stats

Optional role. `make install` prompts before applying it unless `ENABLE_OPTIONAL_STATS=1` is set in `vars/local.sh`. Stats.app itself is installed via `ensure_brew_cask stats` at the top of this role's install script, so one override gates both the cask install and the preference import.

Deploys the [Stats](https://github.com/exelban/stats) menu-bar app's preferences to `~/Library/Preferences/eu.exelban.Stats.plist` via `defaults import`, which routes the write through `cfprefsd` and avoids racing the live app.

The checked-in plist is stored as XML for reviewable diffs. The volatile `NSWindow Frame ...` key is stripped from the live plist before comparison so window-position noise doesn't trigger spurious updates.

---

### linearmouse

Optional role. `make install` prompts before applying it unless `ENABLE_OPTIONAL_LINEARMOUSE=1` is set in `vars/local.sh`. Installs the [LinearMouse](https://linearmouse.app/) macOS mouse customization app via `ensure_brew_cask linearmouse`; no additional config is deployed.

---

### macos

Applies macOS system defaults via `defaults write`. Each setting is checked for idempotency before writing; the affected system process (e.g. Dock) is restarted only when a value actually changes.

Currently managed settings:

| Setting | Domain | Key | Value |
|---|---|---|---|
| Fixed Space order | `com.apple.dock` | `mru-spaces` | `false` |

**Fixed Space order** — disables Mission Control's automatic promotion of the most-recently-used Space to position 1. Spaces stay in the order you arrange them manually.

---

### nvm

Installs [nvm](https://github.com/nvm-sh/nvm) via `ensure_brew_formula nvm` and ensures `~/.nvm` exists. If no default Node alias is set, the role invokes the shared `_optional_selected` helper to prompt before running `nvm install --lts && nvm alias default 'lts/*'` (gated by `ENABLE_OPTIONAL_NVM_DEFAULT_NODE`). The actual `nvm install` runs inside a `bash -c` subshell so `nvm.sh`'s shell-function layout doesn't collide with the orchestrator's `set -euo pipefail`.

nvm is sourced from `.zshrc` (deployed by the `zsh` role), which is how `node`/`npm` land on PATH for interactive shells and therefore for Mason's Node-based LSP installs (`bashls`, `jsonls`, `yamlls`, `pyright`, `ts_ls`).

---

### bun

Optional role. `make install` prompts before applying it unless `ENABLE_OPTIONAL_BUN=1` is set in `vars/local.sh`.

Installs the [Bun](https://bun.sh/) JavaScript runtime, package manager, and bundler. Bun is distributed via the official [`oven-sh/bun`](https://github.com/oven-sh/homebrew-bun) Homebrew tap rather than homebrew-core, so the role first ensures the tap is added (idempotent) and then installs the formula via `ensure_brew_formula bun`. Globally installed binaries land in `~/.bun/bin`; add that to `PATH` via `vars/local.sh` or `~/.zshrc.local` if you use `bun add -g`.

---

### rustup

Installs `rustup` via `ensure_brew_formula rustup`.

`brew install rustup` only installs the toolchain bootstrapper — `rustc`/`cargo` themselves only materialise once a default toolchain is selected. The role therefore runs an optional prompt (`rust-toolchain`, gated by `ENABLE_OPTIONAL_RUST_TOOLCHAIN`) that invokes `rustup default stable` unless `rustup show active-toolchain` already reports one. Cargo crates are not tracked — install them manually with `cargo install`.

---

### uv

Installs [uv](https://docs.astral.sh/uv/) via `ensure_brew_formula uv` — a fast Python package and project manager.

uv fetches Python versions on demand per-project, but having a globally managed version is convenient for ad-hoc scripts and `uvx` one-shot tool runs. The role runs an optional prompt (`uv-default-python`, gated by `ENABLE_OPTIONAL_UV_DEFAULT_PYTHON`) that invokes `uv python install` (fetches the latest stable CPython) unless a managed version is already present.

Shell completions are sourced via `eval "$(uv generate-shell-completion zsh)"` from `.zshrc` (deployed by the `zsh` role).

---

### zed

Optional role. `make install` prompts before applying it unless `ENABLE_OPTIONAL_ZED=1` is set in `vars/local.sh`. Zed itself is installed via `ensure_brew_cask zed` at the top of this role's install script, so one override gates both the cask install and the config deploy.

Deploys `~/.config/zed/settings.json` and `~/.config/zed/keymap.json`.

**Fonts**: UI uses `.SystemUIFont` (resolves to SF Pro on macOS) at 16pt. Editor buffer and built-in terminal use `SF Mono Terminal` at 12pt — same family as the Ghostty role, one point larger for the editor viewport. Weights are left at Zed defaults.

**Keymap overrides**:

- `Cmd+Ctrl+Left` → `pane::GoBack`, `Cmd+Ctrl+Right` → `pane::GoForward`. These shadow Zed's default Shrink/Expand Syntax Selection bindings, which remain available on `Ctrl+Shift+Left/Right`.
- `Cmd+Shift+J` → `pane::RevealInProjectPanel`.

**Theme**: `Catppuccin Latte` / `Catppuccin Mocha` following the system appearance — matches the Catppuccin Latte flavour used by the `neovim` role. Provided by the [`catppuccin`](https://github.com/catppuccin/zed) extension, which is auto-installed via the `auto_install_extensions` setting.

**Keymap**: `VSCode` base keymap.

**Diff view**: Unified style.

**Git panel**: Tree view enabled.

**Outline panel**: Docked on the right.

---

### neovim

Deploys `~/.config/nvim/init.lua`.

**Plugin manager**: [lazy.nvim](https://github.com/folke/lazy.nvim) (auto-bootstrapped on first launch).

**Plugins**:

| Plugin | Purpose |
|--------|---------|
| `neo-tree.nvim` + `neo-tree-diagnostics.nvim` | File manager sidebar with Files / Git / Issues (diagnostics) tabs |
| `nvim-treesitter` | Syntax highlighting and indentation; auto-installs parsers for Lua, Vim, Python, JS/TS, Bash, JSON, YAML, TOML, Markdown, Swift, Rust, C/C++/ObjC, Go, GDScript (incl. Godot `.tres`/`.tscn`) |
| `lualine.nvim` | Single global statusline (`globalstatus`) showing LSP clients, encoding, and filetype |
| `snacks.nvim` (picker) | Fuzzy finder for files, grep, buffers, LSP symbols, and command palette |
| `gitsigns.nvim` | Git diff signs and hunk navigation |
| `markdown-preview.nvim` | Live Mermaid/Markdown preview in browser (`<Space>mp`) |
| `nvim-lspconfig` + `mason.nvim` | LSP support with auto-installed servers |
| `blink.cmp` | Autocompletion (LSP, path, buffer sources) including command-line mode |
| `catppuccin` | Colorscheme (latte flavour) |

**LSP servers** (installed via Mason): `lua_ls`, `rust_analyzer`, `clangd`, `marksman` (markdown), `bashls` (shell), `jsonls`, `yamlls`, `taplo` (TOML), `pyright` (Python), `ts_ls` (JS/TS), `gopls`. `sourcekit` is configured directly (pre-installed on macOS). `gdscript` is also configured directly — Godot ships its own LSP server which Neovim connects to on TCP `127.0.0.1:6005` while the Godot editor is running with a project open.

**Runtime dependencies**: `ripgrep` and `fd` (used by `snacks.nvim`'s grep and file pickers), and `node`/`npm` via the `nvm` role (powers `bashls`/`jsonls`/`yamlls`/`pyright`/`ts_ls` Mason installs) are each installed by their own sibling roles. The `neovim` role itself only installs `neovim` and deploys `init.lua`; everything else is resolved on PATH at launch time. Because nvm exposes `node` only through an interactive-zsh shell function, `init.lua` prepends `~/.nvm/versions/node/*/bin` to `PATH` at startup so Node-based LSPs can resolve `#!/usr/bin/env node` regardless of how nvim was launched.

**Key bindings**:

| Key | Action |
|-----|--------|
| `<Space>e` | Move cursor to right window |
| `<Space>E` | Toggle file manager (neo-tree) |
| `<Space>j` | Reveal current file in neo-tree |
| `<Space>g` | Open neo-tree Git status panel |
| `<Space>i` | Open neo-tree Issues (diagnostics) panel |
| `<Space>v` | Select all (`ggVG`) |
| `<Space>J` | Join lines (default `J` behaviour) |
| `<Space>k` | Hover docs (LSP) |
| `<Space>b` | Build project (`:make`) |
| `H` / `L` | Start / end of line (past last character) |
| `J` / `K` | Bottom / top of file |
| `Alt+l` / `Alt+h` | Next word / previous word |
| `jk` (insert) | Escape to normal mode |
| `<Esc>` (normal) | Clear search highlight (`:nohlsearch`) |
| `Alt+Shift+H` / `Alt+Shift+L` | Previous / next buffer |
| `<Space>p` | Find files in project (snacks picker) |
| `<Space>P` | Command palette (keymaps, LSP actions, commands) |
| `<Space>o` | Document symbols in current buffer (snacks picker) |
| `<Space>O` | Workspace symbols across project (snacks picker) |
| `<Space>f` | Search lines in current buffer (snacks picker) |
| `<Space>fg` | Live grep (snacks picker) |
| `<Space>fb` | Buffers (snacks picker) |
| `]h` / `[h` | Next / previous git hunk |
| `<Space>gS` | Stage hunk |
| `<Space>gr` | Reset hunk |
| `<Space>gp` | Preview hunk |
| `<Space>mp` | Toggle Markdown/Mermaid browser preview |
| `gd` | Go to definition (LSP) |
| `gr` | Find references (LSP) |
| `gI` | Go to implementation (LSP) |
| `<Space>r` | Rename symbol (LSP) |
| `<Space>a` | Code action (LSP) |
| `<Space>=` | Format buffer or selection (LSP) |
| `<Space>x` | Open current file in system default app (`vim.ui.open`) |

Navigation keys (`H`, `L`, `J`, `K`, `Alt+l`, `Alt+h`) work in both normal and visual mode. `virtualedit=onemore` allows the cursor to move one position past the end of a line.

**Commands**: `:Q` closes all windows and exits Neovim immediately (`qall!`).

**Disabled defaults**: `s`, `S` (substitute — use `cl`/`cc`), `q`, `Q` (macro recording/replay) are mapped to `<Nop>` to prevent accidental triggers.

**Auto save**: Files are saved automatically on every text change, leaving insert mode, switching buffers, and losing focus. Only applies to named, modified file buffers (skips special buffers like terminals or neo-tree).

**neo-tree** opens automatically on startup, follows the current file, replaces netrw, and auto-refreshes when files change on disk (libuv watcher). Hidden files are visible by default (`filtered_items.visible = true`). The sidebar has three tabs: Files, Git, and Issues (diagnostics).

**Diagnostics** are shown as inline virtual text (`virtual_text`) and as signs in the gutter. LSP servers provide diagnostics automatically; build errors from `:make` also populate the quickfix list.

**Options**: `relativenumber`, `cursorline`, `scrolloff=8`, `clipboard="unnamedplus"` (system clipboard), `mouse="a"` (mouse support in all modes).

**Per-project config**: `exrc` is enabled, so Neovim loads `.nvim.lua` from the project root. Use this to set `makeprg` per project (e.g., `vim.opt.makeprg = "cargo build"`).

