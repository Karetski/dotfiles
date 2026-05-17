# neovim

Deploys `~/.config/nvim/init.lua`. Plugin manager is [lazy.nvim](https://github.com/folke/lazy.nvim) (auto-bootstrapped on first launch).

## Plugins

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

## LSP servers

Installed via Mason: `lua_ls`, `rust_analyzer`, `clangd`, `marksman` (markdown), `bashls` (shell), `jsonls`, `yamlls`, `taplo` (TOML), `pyright` (Python), `ts_ls` (JS/TS), `gopls`.

Configured directly (not via Mason): `sourcekit` (pre-installed on macOS) and `gdscript` (Godot ships its own LSP server which Neovim connects to on TCP `127.0.0.1:6005` while the Godot editor is running with a project open).

## Runtime dependencies

`ripgrep` and `fd` (used by `snacks.nvim`'s grep and file pickers) and `node`/`npm` via the `nvm` role (powers `bashls`/`jsonls`/`yamlls`/`pyright`/`ts_ls` Mason installs) are each installed by their own sibling roles. The `neovim` role itself only installs `neovim` and deploys `init.lua`; everything else is resolved on PATH at launch time.

Because nvm exposes `node` only through an interactive-zsh shell function, `init.lua` prepends `~/.nvm/versions/node/*/bin` to `PATH` at startup so Node-based LSPs can resolve `#!/usr/bin/env node` regardless of how nvim was launched.

## Key bindings

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

## Commands

`:Q` closes all windows and exits Neovim immediately (`qall!`).

## Disabled defaults

`s`, `S` (substitute — use `cl`/`cc`), `q`, `Q` (macro recording/replay) are mapped to `<Nop>` to prevent accidental triggers.

## Auto save

Files are saved automatically on every text change, leaving insert mode, switching buffers, and losing focus. Only applies to named, modified file buffers (skips special buffers like terminals or neo-tree).

## neo-tree

Opens automatically on startup, follows the current file, replaces netrw, and auto-refreshes when files change on disk (libuv watcher). Hidden files are visible by default (`filtered_items.visible = true`). The sidebar has three tabs: Files, Git, and Issues (diagnostics).

## Diagnostics

Shown as inline virtual text (`virtual_text`) and as signs in the gutter. LSP servers provide diagnostics automatically; build errors from `:make` also populate the quickfix list.

## Options

`relativenumber`, `cursorline`, `scrolloff=8`, `clipboard="unnamedplus"` (system clipboard), `mouse="a"` (mouse support in all modes).

## Per-project config

`exrc` is enabled, so Neovim loads `.nvim.lua` from the project root. Use this to set `makeprg` per project (e.g., `vim.opt.makeprg = "cargo build"`).
