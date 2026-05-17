# git

Deploys git configuration to the home directory.

## What it deploys

- **`~/.gitconfig`** (templated) — sets `user.name` and `user.email` from `GIT_NAME` / `GIT_EMAIL`. Both must be set in `vars/local.sh`.
- **`~/.config/git/ignore`** — globally ignores `.claude/settings.local.json` (per-machine Claude overrides) and `.DS_Store`.
