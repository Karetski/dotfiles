# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Shared Ansible configuration for macOS development environment. Manages zsh, git, lazygit, Claude Code, and Micro editor configs via idempotent playbooks.

This is the **shared/public** half of a two-repo setup. Machine-specific config (hostnames, proxies, work git identity) lives in a separate private repo that points `roles_path` here.

## Running

```bash
make install          # apply all roles
make plan             # dry-run, show what would change
make install-tag TAG=git  # apply a single role
```

Requires Ansible and Homebrew to already be installed. Homebrew installation is intentionally out of scope — the `homebrew` role will fail with instructions if `brew` is not found.

## Structure

Flat role layout (no `roles/` subdirectory). Each tool is a top-level directory with `main.yml`, `templates/`, and `files/` as needed.

| Role | Manages |
|------|---------|
| `homebrew/` | Verifies brew is installed, installs formulae and casks |
| `zsh/` | `~/.zshrc` via Jinja2 template |
| `git/` | `~/.gitconfig` (template), `~/.config/git/ignore` |
| `lazygit/` | `~/.config/lazygit/config.yml` |
| `claude/` | `~/.claude/settings.json` (template), `~/.claude/hooks/notify.sh` |
| `ghostty/` | `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` |
| `micro/` | `~/.config/micro/settings.json`, `~/.config/micro/bindings.json` |

## Variables

- `group_vars/all.yml` — shared defaults (sandbox, package list, feature flags)
- `group_vars/personal.yml` — personal git identity; work identity goes in the private repo
- `host_vars/<hostname>.yml` (private repo) — machine-specific overrides (proxy, etc.)

Key variables:
- `git_name` / `git_email` — injected into `~/.gitconfig` via template
- `claude_sandbox_enabled` — controls sandbox in `settings.json`

## Per-machine overrides

`~/.zshrc.local` is sourced at the end of `.zshrc` if it exists. Use it for machine-specific aliases and ad-hoc config that doesn't belong in either repo.

## Ghostty

Installed via Homebrew cask (`ghostty` in `homebrew_casks`). Config deployed by the `ghostty/` role to `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`.
