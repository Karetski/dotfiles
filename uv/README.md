# uv

Installs [uv](https://docs.astral.sh/uv/) via `ensure_brew_formula uv` — a fast Python package and project manager.

uv fetches Python versions on demand per-project, but a globally managed version is convenient for ad-hoc scripts and `uvx` one-shot tool runs. The role prompts (`uv-default-python`, gated by `ENABLE_OPTIONAL_UV_DEFAULT_PYTHON`) before invoking `uv python install` (fetches the latest stable CPython), unless a managed version is already present.

Shell completions are sourced via `eval "$(uv generate-shell-completion zsh)"` from `.zshrc` (deployed by the `zsh` role).
