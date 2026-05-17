# macos

Applies macOS system defaults via `defaults write`. Each setting is checked for idempotency before writing; the affected system process (Finder, Dock) is restarted only when at least one value actually changes.

## Managed settings

| Setting | Domain | Key | Value |
|---------|--------|-----|-------|
| Finder — column view | `com.apple.finder` | `FXPreferredViewStyle` | `clmv` |
| Finder — group by kind | `com.apple.finder` | `FXPreferredGroupBy` | `Kind` |
| Finder — sort by kind | `com.apple.finder` | `FXPreferredSortOrder` | `kind` |
| Finder — folders on top | `com.apple.finder` | `_FXSortFoldersFirst` | `true` |
| Finder — search current folder | `com.apple.finder` | `FXDefaultSearchScope` | `SCcf` |
| Global — column view | `NSGlobalDomain` | `FXPreferredViewStyle` | `clmv` |
| Global — group by kind | `NSGlobalDomain` | `FXPreferredGroupBy` | `Kind` |
| Global — expanded save panel | `NSGlobalDomain` | `NSNavPanelExpandedStateForSaveMode` | `true` |
| Global — expanded save panel (v2) | `NSGlobalDomain` | `NSNavPanelExpandedStateForSaveMode2` | `true` |
| Global — expanded print panel | `NSGlobalDomain` | `PMPrintingExpandedStateForPrint` | `true` |
| Global — expanded print panel (v2) | `NSGlobalDomain` | `PMPrintingExpandedStateForPrint2` | `true` |
| Mission Control — fixed Space order | `com.apple.dock` | `mru-spaces` | `false` |

**Finder defaults** — column view, grouped and sorted by kind, with folders pinned to the top. Search defaults to the current folder rather than the whole Mac (`SCcf`). The same view/group preferences are mirrored into `NSGlobalDomain` so Open/Save panels behave the same way.

**Expanded panels** — Save and Print panels open in their expanded form by default (both legacy and v2 keys are set, since different apps read different ones).

**Fixed Space order** — disables Mission Control's automatic promotion of the most-recently-used Space to position 1. Spaces stay in the order you arrange them manually.
