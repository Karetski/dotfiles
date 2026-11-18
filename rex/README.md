# rex

Configures the Rex terminal. The app itself (Rex Beta) is installed manually — there is no Homebrew cask.

## Configuration

**`~/.config/rex/init.lua`** — key bindings (`rex.bind` / `rex.unbind`). Empty on purpose: Rex runs on its default keymap.

**Settings window** — stored in the `com.superlogical.rex` plist and applied with `defaults write`, each checked for idempotency. Quit Rex before applying: a running app rewrites its preferences on quit.

| Setting | Key | Value |
|---------|-----|-------|
| Interface style | `Workspace.interfaceStyle` | `useTheme` |
| Light theme | `Workspace.lightThemeID` | `merino-light` |
| Dark theme | `Workspace.darkThemeID` | `merino-dark` |
| Pane density | `Workspace.paneDensity` | `compact` |
| Inactive pane fade | `Workspace.inactivePaneFadeMode` | `both` |
| Standard inactive panes | `Workspace.usesStandardInactiveWindowPaneStyles` | `true` |
| Smooth resize | `Workspace.smoothResizeEnabled` | `true` |
| Tab icon tint | `Workspace.tabIconTintMode` | `off` |
| Tabs fill width | `Workspace.tabsFillAvailableSpace` | `false` |
| Generated titles | `Workspace.prefersGeneratedTitles` | `true` |
| Agents name sessions | `rex.agents.names-sessions` | `false` |
| Terminal font | `Workspace.terminalFontName` | `SF Mono Terminal` |
| Cursor style | `Workspace.terminalCursorStyle` | `block` |
| Force cursor style | `Workspace.terminalCursorStyleForced` | `false` |
| Improve text contrast | `Workspace.terminalImproveTextContrast` | `true` |
| Rounded selection | `Workspace.terminalSelectionRoundedCorners` | `true` |
| Smooth scrolling | `Workspace.terminalSmoothScrolling` | `false` |
| Theme palette | `Workspace.terminalUseThemePalette` | `false` |
| Display P3 | `Workspace.terminalUsesDisplayP3` | `false` |

Window frames, session state, update checks and `rex.server.*` runtime keys are left unmanaged.
