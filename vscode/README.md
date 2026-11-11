# vscode

Installs Visual Studio Code via `ensure_brew_cask visual-studio-code` and deploys user settings to `~/Library/Application Support/Code/User/settings.json`.

Settings changed in the VS Code UI are overwritten on the next install (the previous file is kept as `.bak`). Copy changes you want to keep into `files/settings.json`.

## Configuration

| Setting | Value |
|---------|-------|
| Theme | Light 2026 |
| Minimap | Disabled |
| Extension recommendations | Ignored |
| Markdown | `*.md` opens in the built-in preview (`vscode.markdown.preview.editor`); use **Reopen Editor With… → Text Editor** to edit |
