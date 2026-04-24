# Repository Guidelines

## Project Structure & Module Organization
This repository manages macOS dotfiles with plain Bash. Each managed tool lives in a top-level role directory such as `zsh/`, `git/`, `ghostty/`, or `neovim/`. Roles follow a consistent layout: `install.sh` for tasks, `files/` for static assets, and `templates/` for `envsubst` inputs when variables are injected. Shared orchestration lives in `install.sh`, common helpers in `lib/utils.sh`, and defaults in `vars/main.sh`. Machine-specific secrets and overrides belong in `vars/local.sh`, based on `vars/local.sh.example`.

## Build, Test, and Development Commands
Use `make install` to apply all roles in sequence. Use `make plan` for a dry run that shows intended changes and sanitize prompts without modifying files. Use `make install-tag TAG=git` to run a single role while iterating on it. For shell syntax checks, run `bash -n install.sh lib/utils.sh */install.sh vars/main.sh`.

## Coding Style & Naming Conventions
Shell scripts use `#!/usr/bin/env bash` with `set -euo pipefail` in entrypoints. Follow the existing style: two-space indentation, lowercase function names, and uppercase environment or shared variables such as `DOTFILES_DIR` and `DRY_RUN`. Keep role names short and directory names flat; new managed files should go under `<role>/files/` or `<role>/templates/` rather than ad hoc locations.

## Testing Guidelines
There is no formal automated test suite yet. Validate changes with `make plan`, then apply a focused role with `make install-tag TAG=<role>`. When editing deploy logic, also run `bash -n` over the touched scripts and verify the target file path in the relevant install script, for example `~/.zshrc` or `~/Library/Application Support/lazygit/config.yml`.

## Commit & Pull Request Guidelines
Recent commits use short, imperative summaries such as `Add neo-tree file manager plugin to neovim config` and `Remove terminal-notifier from Homebrew formulae`. Keep subjects concise, capitalized, and behavior-focused. Pull requests should explain which role changed, how it was validated (`make plan`, targeted install, manual app check), and include screenshots only for UI-facing config changes such as Ghostty or editor themes.

## Configuration Tips
Do not commit `vars/local.sh`; keep per-machine values there. Prefer idempotent install logic, and preserve the existing backup and sanitize behavior in `lib/utils.sh` when changing deployment flows.

## Agent-Specific Notes
Keep agent-specific instructions centralized in `AGENTS.md` or managed config files instead of duplicating guidance across multiple docs.

When asked to configure Claude Code (settings, hooks, permissions, etc.), always make changes in this repo first — edit `claude/templates/settings.json` or the relevant file under `claude/`. Never edit `~/.claude/settings.json` directly as the source of truth; the live file is rendered from this repo by `make install`.
