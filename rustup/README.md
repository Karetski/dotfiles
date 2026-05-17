# rustup

Installs `rustup` via `ensure_brew_formula rustup`.

`brew install rustup` only installs the toolchain bootstrapper — `rustc`/`cargo` themselves only materialise once a default toolchain is selected. The role prompts (`rust-toolchain`, gated by `ENABLE_OPTIONAL_RUST_TOOLCHAIN`) before invoking `rustup default stable`, unless `rustup show active-toolchain` already reports one.

Cargo crates are not tracked — install them manually with `cargo install`.
