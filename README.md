# dotfiles

Plain-shell configuration management for a macOS development environment.
Each tool is a self-contained role (`zsh/`, `git/`, `neovim/`, …) with its
own install script and assets. Roles are idempotent — running them twice
changes nothing.

## Prerequisites

- macOS
- [Homebrew](https://brew.sh)

## Quick start

```bash
make install              # apply all roles; prompts to clean stale backups
make plan                 # dry run — show what would change
make install-tag TAG=git  # apply a single role by name
make install-confirm      # prompt [y/N] before every role and brew package
```

## Per-machine config

Copy `vars/local.sh.example` to `vars/local.sh` (gitignored) and set
`GIT_NAME` and `GIT_EMAIL` at minimum. Add `ENABLE_OPTIONAL_<NAME>=1` for
any optional role or step you want to auto-apply instead of being prompted.
The override name is derived by uppercasing the prompt key and replacing
dashes with underscores: `claude` → `ENABLE_OPTIONAL_CLAUDE`,
`docker-desktop` → `ENABLE_OPTIONAL_DOCKER_DESKTOP`,
`nvm-default-node` → `ENABLE_OPTIONAL_NVM_DEFAULT_NODE`.

## Optional roles

Whole roles that prompt before applying unless their override is set:

- `claude` — Claude Code settings, hooks, and status line
- `docker-desktop` — Docker Desktop cask
- `bun` — Bun JavaScript runtime

## Optional steps

Mandatory roles with an optional bootstrap step that prompts on first run:

- `nvm-default-node` (in `nvm`) — `nvm install --lts && nvm alias default 'lts/*'`
- `uv-default-python` (in `uv`) — `uv python install`
- `rust-toolchain` (in `rustup`) — `rustup default stable`

Each step skips itself silently once its target is configured (default Node
alias set, a managed Python present, an active rustup toolchain).

`make install-confirm` temporarily treats *every* role and brew package as
optional — useful on a fresh or unfamiliar machine to cherry-pick what
runs. It also bypasses `ENABLE_OPTIONAL_*` overrides so you're asked about
each item regardless.

## Roles

Grouped in the order `install.sh` applies them.

### preflight

| Role | What it does |
|------|--------------|
| `xcode-select` | Installs Apple Command Line Tools if missing |
| `homebrew` | Verifies Homebrew is installed (roles declare their own packages) |

### shell

| Role | What it does |
|------|--------------|
| [`zsh`](zsh/README.md) | `.zshrc` — PATH, plugins, aliases, two-line prompt |
| `zsh-autocomplete` | Real-time completion plugin (sourced by `zsh`) |

### cli tools

| Role | What it does |
|------|--------------|
| `fzf` | Fuzzy finder (sourced by `zsh`, used by `nvf` alias and Neovim) |
| [`git`](git/README.md) | `.gitconfig` and global gitignore |
| [`lazygit`](lazygit/README.md) | Theme + Quick Look custom commands |
| `jq` | JSON processor (used by `claude` hooks and status line) |
| `ripgrep` | Used by Neovim's snacks picker grep |
| `fd` | Used by Neovim's snacks picker files |

### dev tools

| Role | What it does |
|------|--------------|
| [`claude`](claude/README.md) | Claude Code settings, hooks, plugins, status line *(optional)* |
| `docker-desktop` | Docker Desktop cask *(optional)* |

### system

| Role | What it does |
|------|--------------|
| [`ghostty`](ghostty/README.md) | Ghostty terminal config |
| [`macos`](macos/README.md) | macOS system defaults (Dock, Spaces, …) |

### toolchains

| Role | What it does |
|------|--------------|
| [`nvm`](nvm/README.md) | Node version manager + optional default LTS install |
| [`bun`](bun/README.md) | Bun JS runtime via official tap *(optional)* |
| [`uv`](uv/README.md) | Fast Python package manager + optional Python install |
| [`rustup`](rustup/README.md) | Rust toolchain bootstrapper + optional `stable` install |

### editor

| Role | What it does |
|------|--------------|
| [`neovim`](neovim/README.md) | `init.lua` — plugins, LSP, keybindings |

## How it works

`install.sh` sources `lib/utils.sh` for helpers, `vars/main.sh` for shared
defaults, and `vars/local.sh` for per-machine overrides. It then iterates
roles in grouped order:

> preflight → shell → cli tools → dev tools → system → toolchains → editor

Each role is a directory with an `install.sh` plus `files/` (static assets
copied as-is) and/or `templates/` (run through `envsubst` first). Roles
declare their own Homebrew dependencies via `ensure_brew_formula` /
`ensure_brew_cask`, so each role is self-contained end-to-end.

For contributor conventions (style, commits, testing), see
[AGENTS.md](AGENTS.md).
