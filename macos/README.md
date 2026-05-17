# macos

Applies macOS system defaults via `defaults write`. Each setting is checked for idempotency before writing; the affected system process (e.g. Dock) is restarted only when a value actually changes.

## Managed settings

| Setting | Domain | Key | Value |
|---------|--------|-----|-------|
| Fixed Space order | `com.apple.dock` | `mru-spaces` | `false` |

**Fixed Space order** — disables Mission Control's automatic promotion of the most-recently-used Space to position 1. Spaces stay in the order you arrange them manually.
