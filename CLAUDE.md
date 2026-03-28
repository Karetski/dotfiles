# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Plain shell script configuration for macOS development environment. Manages zsh, git, lazygit, Claude Code, Ghostty, and Micro editor configs via idempotent install scripts.

## Running

```bash
make install          # apply all roles
make plan             # dry-run, show what would change
make install-tag TAG=git  # apply a single role
```

Requires only Homebrew. The `homebrew` role will fail with instructions if `brew` is not found.

## Structure

Flat role layout. Each tool is a top-level directory with `install.sh`, `templates/`, and `files/` as needed.

| Role | Manages |
|------|---------|
| `homebrew/` | Verifies brew is installed, installs formulae and casks |
| `zsh/` | `~/.zshrc` (static file) |
| `git/` | `~/.gitconfig` (`envsubst` template), `~/.config/git/ignore` |
| `lazygit/` | `~/Library/Application Support/lazygit/config.yml` |
| `claude/` | `~/.claude/settings.json` (`envsubst` template), `~/.claude/statusline.sh` |
| `ghostty/` | `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` |
| `micro/` | `~/.config/micro/settings.json`, `~/.config/micro/bindings.json` |

## Variables

All shared variables live in `vars/main.sh` and are sourced by `install.sh` before any role runs.

Key variables:
- `GIT_NAME` / `GIT_EMAIL` — injected into `~/.gitconfig` via `envsubst`; set in `vars/local.sh` (not committed)
- `CLAUDE_SANDBOX_ENABLED` — controls sandbox in `settings.json`
- `HOMEBREW_FORMULAE` / `HOMEBREW_CASKS` — package lists

## Per-machine overrides

`vars/local.sh` is sourced after `vars/main.sh` if it exists. It is gitignored. Use it to set `GIT_NAME`, `GIT_EMAIL`, and any other machine-specific values. See `vars/local.sh.example`.

`~/.zshrc.local` is sourced at the end of `.zshrc` if it exists. Use it for machine-specific aliases and ad-hoc config.

## Ghostty

Installed via Homebrew cask (`ghostty` in `HOMEBREW_CASKS`). Config deployed by the `ghostty/` role to `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`.
