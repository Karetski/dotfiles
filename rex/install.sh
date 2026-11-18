#!/usr/bin/env bash
# Rex Beta.app is installed manually (no Homebrew cask); this role only manages config
ensure_dir "$HOME/.config/rex"
deploy_file "$DOTFILES_DIR/rex/files/init.lua" "$HOME/.config/rex/init.lua"

_sanitize_bak "$HOME/.config/rex/init.lua"
_sanitize_dir "$HOME/.config/rex" "" "init.lua"

# App settings (Settings window) live in the com.superlogical.rex plist, not
# init.lua. Quit Rex before applying: a running app rewrites them on quit.
_REX_DOMAIN="com.superlogical.rex"

# Appearance
_defaults_string "Rex — interface style"        "$_REX_DOMAIN" "Workspace.interfaceStyle"     "useTheme"
_defaults_string "Rex — light theme"            "$_REX_DOMAIN" "Workspace.lightThemeID"       "merino-light"
_defaults_string "Rex — dark theme"             "$_REX_DOMAIN" "Workspace.darkThemeID"        "merino-dark"
_defaults_string "Rex — pane density"           "$_REX_DOMAIN" "Workspace.paneDensity"        "compact"
_defaults_string "Rex — inactive pane fade"     "$_REX_DOMAIN" "Workspace.inactivePaneFadeMode" "both"
_defaults_bool   "Rex — standard inactive panes" "$_REX_DOMAIN" "Workspace.usesStandardInactiveWindowPaneStyles" "true"
_defaults_bool   "Rex — smooth resize"          "$_REX_DOMAIN" "Workspace.smoothResizeEnabled" "true"

# Tabs and sessions
_defaults_string "Rex — tab icon tint"          "$_REX_DOMAIN" "Workspace.tabIconTintMode"    "off"
_defaults_bool   "Rex — tabs fill width"        "$_REX_DOMAIN" "Workspace.tabsFillAvailableSpace" "false"
_defaults_bool   "Rex — generated titles"       "$_REX_DOMAIN" "Workspace.prefersGeneratedTitles" "true"
_defaults_bool   "Rex — agents name sessions"   "$_REX_DOMAIN" "rex.agents.names-sessions"    "false"

# Terminal
_defaults_string "Rex — terminal font"          "$_REX_DOMAIN" "Workspace.terminalFontName"   "SF Mono Terminal"
_defaults_string "Rex — cursor style"           "$_REX_DOMAIN" "Workspace.terminalCursorStyle" "block"
_defaults_bool   "Rex — force cursor style"     "$_REX_DOMAIN" "Workspace.terminalCursorStyleForced" "false"
_defaults_bool   "Rex — improve text contrast"  "$_REX_DOMAIN" "Workspace.terminalImproveTextContrast" "true"
_defaults_bool   "Rex — rounded selection"      "$_REX_DOMAIN" "Workspace.terminalSelectionRoundedCorners" "true"
_defaults_bool   "Rex — smooth scrolling"       "$_REX_DOMAIN" "Workspace.terminalSmoothScrolling" "false"
_defaults_bool   "Rex — theme palette"          "$_REX_DOMAIN" "Workspace.terminalUseThemePalette" "false"
_defaults_bool   "Rex — Display P3"             "$_REX_DOMAIN" "Workspace.terminalUsesDisplayP3" "false"
