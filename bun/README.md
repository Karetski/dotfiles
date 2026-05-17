# bun

Optional role. `make install` prompts before applying it unless `ENABLE_OPTIONAL_BUN=1` is set in `vars/local.sh`.

Installs the [Bun](https://bun.sh/) JavaScript runtime, package manager, and bundler. Bun is distributed via the official [`oven-sh/bun`](https://github.com/oven-sh/homebrew-bun) Homebrew tap rather than homebrew-core, so the role first ensures the tap is added (idempotent) and then installs the formula via `ensure_brew_formula bun`.

Globally installed binaries land in `~/.bun/bin`; add that to `PATH` via `vars/local.sh` or `~/.zshrc.local` if you use `bun add -g`.
