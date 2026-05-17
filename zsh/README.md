# zsh

Deploys `~/.zshrc` as a static file.

## PATH

Prepends `~/.local/bin` (where role-deployed scripts live).

## Plugins

Sources `zsh-autocomplete` from its Homebrew location for real-time completion, `fzf` for fuzzy finding, and `nvm` so `node`/`npm` land on PATH for interactive shells — the latter is how `nvim`-launched processes such as Mason's Node-based LSP installs find them. Each of those tools is installed by its own sibling role (`zsh-autocomplete`, `fzf`, `nvm`); the `zsh` role itself only deploys `.zshrc`.

## Aliases

| Alias | Expands to | Description |
|-------|-----------|-------------|
| `ll` | `lssplit` | Lists directory contents split into Directories, Files, and Symlinks sections with Nerd Font icons, type-based colors, human-readable sizes, and a layout that adapts to terminal width. Set `LSSPLIT_ICONS=0` to disable glyphs |
| `nv` | `nvim` | Shortcut for Neovim |
| `nvf` | `nvim $(fzf)` | Open a file in Neovim via fzf |
| `caff` | `caffeinate` | Prevent system sleep |
| `caffd` | `caffeinate -d` | Prevent display sleep only |

## Key bindings

| Key | Action |
|-----|--------|
| Cmd+Left | Beginning of line |
| Cmd+Right | End of line |
| Option+Delete | Backward kill word |

## Prompt

Two-line prompt using zsh's `vcs_info` hook.

- **Line 1**: three cascading segments with rounded powerline separators — path on `136` (amber), branch on `178` (golden), status symbols on `220` (yellow). Not full-width; the bar ends after the last segment. Branch and status segments are hidden when not in a git repo or when the working tree is clean. Segments wrap to the next row when they overflow the terminal width.
- **Line 2**: success/failure indicator (`❯` green on success, red on failure), `%` (`#` for root).

Git status symbols: `⎇` branch, `□` unstaged, `■` staged, `↑N` ahead of remote, `↓N` behind remote.

## Local overrides

Sources `~/.zshrc.local` at the end if the file exists. Use this for machine-specific aliases and config that doesn't belong in the shared repo.
