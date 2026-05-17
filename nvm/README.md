# nvm

Installs [nvm](https://github.com/nvm-sh/nvm) via `ensure_brew_formula nvm` and ensures `~/.nvm` exists.

If no default Node alias is set, the role prompts before running `nvm install --lts && nvm alias default 'lts/*'` (gated by `ENABLE_OPTIONAL_NVM_DEFAULT_NODE`). The actual `nvm install` runs inside a `bash -c` subshell so `nvm.sh`'s shell-function layout doesn't collide with the orchestrator's `set -euo pipefail`.

nvm is sourced from `.zshrc` (deployed by the `zsh` role), which is how `node`/`npm` land on PATH for interactive shells — and therefore for Mason's Node-based LSP installs in Neovim (`bashls`, `jsonls`, `yamlls`, `pyright`, `ts_ls`).
