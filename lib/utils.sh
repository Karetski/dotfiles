#!/usr/bin/env bash
# Shared utilities for install scripts.

# When DRY_RUN=1, deploy functions show what would change without writing files
DRY_RUN="${DRY_RUN:-0}"

# ── Terminal width (used for section header/footer dashes) ────────────────────
_TERM_W=$(tput cols 2>/dev/null || printf '%s' "${COLUMNS:-80}")
[ "$_TERM_W" -lt 60 ]  && _TERM_W=60
[ "$_TERM_W" -gt 120 ] && _TERM_W=120

# ── Colors (light-background safe) ───────────────────────────────────────────
_C_GRN=$'\033[32m'      # green — ok icon
_C_GRN_B=$'\033[1;32m'  # bold green — ok status text
_C_AMB=$'\033[33m'      # yellow — separators, dry-run, warnings
_C_YLW_B=$'\033[1;33m'  # bold yellow — section/summary separators
_C_RED=$'\033[31m'      # red — errors, diff deletes
_C_DIM=$'\033[2m'       # dim — skips, no-change labels
_C_BLD=$'\033[1m'       # bold
_C_RST=$'\033[0m'       # reset
_C_PUR=$'\033[35m'      # purple — accents
_C_PUR_B=$'\033[1;35m'  # bold purple — section titles, summary counts

# ── Counters ──────────────────────────────────────────────────────────────────
# Global counters (across all roles) shown in the final summary
_COUNT_OK=0
_COUNT_SKIP=0
_COUNT_DRY=0

# Per-section counters reset at each _log_section call
_SECTION_OK=0
_SECTION_SKIP=0
_SECTION_DRY=0
_SECTION_OPEN=0
_SECTION_CHANGED=()  # tracks filenames that changed within the current section

# ── Helpers ───────────────────────────────────────────────────────────────────

# Shorten a path for display: replace $HOME with ~, and if still >50 chars
# collapse to ../parent/basename (e.g. ../lazygit/config.yml)
_shorten() {
  local s="${1/#$HOME/\~}"
  if [ "${#s}" -gt 50 ]; then
    local base="${s##*/}"
    local dir="${s%/*}"
    local parent="${dir##*/}"
    printf '../%s/%s' "$parent" "$base"
  else
    printf '%s' "$s"
  fi
}

# Repeat a character N times: _repeat "-" 40
_repeat() {
  printf '%0.s'"$1" $(seq 1 "$2")
}

# ── Log functions ─────────────────────────────────────────────────────────────

_log_ok() {
  printf "  ${_C_GRN_B}✓${_C_RST} %-44s  ${_C_GRN_B}%s${_C_RST}\n" "$1" "$2"
  _COUNT_OK=$(( _COUNT_OK + 1 ))
  _SECTION_OK=$(( _SECTION_OK + 1 ))
  _SECTION_CHANGED+=("$1")
}

_log_skip() {
  printf "  ${_C_DIM}· %-44s  %s${_C_RST}\n" "$1" "$2"
  _COUNT_SKIP=$(( _COUNT_SKIP + 1 ))
  _SECTION_SKIP=$(( _SECTION_SKIP + 1 ))
}

_log_dry() {
  printf "  ${_C_AMB}→${_C_RST} %-44s  ${_C_AMB}%s${_C_RST}\n" "$1" "$2"
  _COUNT_DRY=$(( _COUNT_DRY + 1 ))
  _SECTION_DRY=$(( _SECTION_DRY + 1 ))
  _SECTION_CHANGED+=("$1")
}

_log_note() {
  printf "  ${_C_PUR}◆${_C_RST} %-44s  ${_C_DIM}%s${_C_RST}\n" "$1" "$2"
}

_log_err() {
  printf "  ${_C_RED}✗ %s${_C_RST}\n" "$1" >&2
}

# ── Section layout ────────────────────────────────────────────────────────────

_log_section_end() {
  [ "$_SECTION_OPEN" = "0" ] && return
  _SECTION_OPEN=0

  if [ "${#_SECTION_CHANGED[@]}" -gt 0 ]; then
    local names="" item
    for item in "${_SECTION_CHANGED[@]}"; do
      [ -z "$names" ] && names="$item" || names="$names, $item"
    done
    printf "  ${_C_DIM}changed: %s${_C_RST}\n" "$names"
  fi

  local s="" s_plain=""
  if [ "$DRY_RUN" = "1" ]; then
    if [ "$_SECTION_DRY" -gt 0 ]; then
      s="${_C_PUR_B}${_SECTION_DRY} plan${_C_RST}"; s_plain="${_SECTION_DRY} plan"
    fi
    if [ "$_SECTION_SKIP" -gt 0 ]; then
      s="${s:+${s}  ${_C_DIM}·${_C_RST}  }${_C_DIM}${_SECTION_SKIP} skip${_C_RST}"
      s_plain="${s_plain:+${s_plain}  ·  }${_SECTION_SKIP} skip"
    fi
  else
    if [ "$_SECTION_OK" -gt 0 ]; then
      s="${_C_PUR_B}${_SECTION_OK} ok${_C_RST}"; s_plain="${_SECTION_OK} ok"
    fi
    if [ "$_SECTION_SKIP" -gt 0 ]; then
      s="${s:+${s}  ${_C_DIM}·${_C_RST}  }${_C_DIM}${_SECTION_SKIP} skip${_C_RST}"
      s_plain="${s_plain:+${s_plain}  ·  }${_SECTION_SKIP} skip"
    fi
  fi
  if [ -z "$s" ]; then s="${_C_DIM}—${_C_RST}"; s_plain="—"; fi

  # Footer: "--- SUMMARY ---..." (3 + 1 + text + 1 + dashes = _TERM_W)
  local dashes_len=$(( _TERM_W - 5 - ${#s_plain} ))
  [ "$dashes_len" -lt 3 ] && dashes_len=3
  local dashes
  dashes=$(_repeat "-" "$dashes_len")
  printf "${_C_YLW_B}---${_C_RST} %s ${_C_YLW_B}%s${_C_RST}\n\n" "$s" "$dashes"
}

_log_section() {
  [ "$_SECTION_OPEN" = "1" ] && _log_section_end

  _SECTION_OK=0; _SECTION_SKIP=0; _SECTION_DRY=0
  _SECTION_OPEN=1
  _SECTION_CHANGED=()

  local name="$1" index="${2:-}" total="${3:-}"
  local title
  if [ -n "$index" ] && [ -n "$total" ]; then
    title="[${index}/${total}] ${name}"
  else
    title="$name"
  fi

  # Header: "--- TITLE ---..." (3 + 1 + text + 1 + dashes = _TERM_W)
  local dashes_len=$(( _TERM_W - 5 - ${#title} ))
  [ "$dashes_len" -lt 3 ] && dashes_len=3
  local dashes
  dashes=$(_repeat "-" "$dashes_len")
  printf "\n${_C_YLW_B}---${_C_RST} ${_C_PUR_B}%s${_C_RST} ${_C_YLW_B}%s${_C_RST}\n" "$title" "$dashes"
}

# Group header drawn ABOVE a cluster of related _log_section banners.
# Each group gets its own icon + accent colour (rotating through the
# existing palette) while sharing the heavy ━ rule so groups are
# visually one level above the ASCII-dash section headers.
_log_group() {
  [ "$_SECTION_OPEN" = "1" ] && _log_section_end

  local label="$1"
  local icon="" color=""
  case "$label" in
    preflight)   icon="✦" ; color="$_C_YLW_B" ;;
    shell)       icon="❯" ; color="$_C_GRN_B" ;;
    "cli tools") icon="◆" ; color="$_C_PUR_B" ;;
    apps)        icon="◉" ; color="$_C_AMB"   ;;
    toolchains)  icon="✧" ; color="$_C_GRN"   ;;
    editor)      icon="✎" ; color="$_C_PUR"   ;;
    *)           icon="◇" ; color="$_C_YLW_B" ;;
  esac

  # Header: "━━━ ICON LABEL ━━━..." (3 + 1 + 1 + 1 + text + 1 + dashes = _TERM_W)
  local dashes_len=$(( _TERM_W - 7 - ${#label} ))
  [ "$dashes_len" -lt 3 ] && dashes_len=3
  local dashes
  dashes=$(_repeat "━" "$dashes_len")
  printf "${color}━━━ %s ${_C_BLD}%s${_C_RST} ${color}%s${_C_RST}\n" "$icon" "$label" "$dashes"
}

_log_summary() {
  [ "$_SECTION_OPEN" = "1" ] && _log_section_end

  local sep
  sep=$(_repeat "=" "$_TERM_W")
  printf "${_C_YLW_B}%s${_C_RST}\n" "$sep"
  if [ "$DRY_RUN" = "1" ]; then
    printf "${_C_YLW_B}●${_C_RST} ${_C_PUR_B}%d plan${_C_RST}  ${_C_DIM}·  %d skip${_C_RST}\n\n" "$_COUNT_DRY" "$_COUNT_SKIP"
  else
    printf "${_C_YLW_B}●${_C_RST} ${_C_PUR_B}%d ok${_C_RST}  ${_C_DIM}·  %d skip${_C_RST}\n\n" "$_COUNT_OK" "$_COUNT_SKIP"
  fi
}

# ── Brew output helpers ───────────────────────────────────────────────────────

_log_brew_start() {
  printf "  ${_C_AMB}↓${_C_RST} %-44s  ${_C_AMB}installing...${_C_RST}\n" "$1"
}

_log_brew_end() {
  :
}

_brew_pipe() {
  while IFS= read -r line; do
    printf "    ${_C_DIM}%s${_C_RST}\n" "$line"
  done
}

# Ensure a Homebrew formula is installed. Each role calls this for its own
# CLI dependencies; CONFIRM_MODE=1 prompts per package for missing ones.
ensure_brew_formula() {
  local formula="$1"
  if [ "${CONFIRM_MODE:-0}" = "1" ] && ! brew list --formula "$formula" > /dev/null 2>&1; then
    _optional_selected "$formula" "formula" "$formula" || return 0
  fi
  if brew list --formula "$formula" > /dev/null 2>&1; then
    _log_skip "$formula" "already installed"
  elif [ "$DRY_RUN" = "1" ]; then
    _log_dry "$formula" "would install"
  else
    _log_brew_start "$formula"
    brew install "$formula" 2>&1 | _brew_pipe
    _log_brew_end
    _log_ok "$formula" "installed"
  fi
}

# Ensure a Homebrew cask is installed. --adopt claims existing .app installs
# instead of re-downloading them.
ensure_brew_cask() {
  local cask="$1"
  if [ "${CONFIRM_MODE:-0}" = "1" ] && ! brew list --cask "$cask" > /dev/null 2>&1; then
    _optional_selected "$cask" "cask" "$cask" || return 0
  fi
  if brew list --cask "$cask" > /dev/null 2>&1; then
    _log_skip "$cask" "already installed  (cask)"
  elif [ "$DRY_RUN" = "1" ]; then
    _log_dry "$cask" "would install  (cask)"
  else
    _log_brew_start "$cask"
    brew install --cask --adopt "$cask" 2>&1 | _brew_pipe
    _log_brew_end
    _log_ok "$cask" "installed  (cask)"
  fi
}

# Check if a value exists in a list: _contains "foo" "${array[@]}"
_contains() {
  local needle="$1" item
  shift || true
  for item in "$@"; do
    [ "$item" = "$needle" ] && return 0
  done
  return 1
}

# Convert an item name to its ENABLE_OPTIONAL_* suffix: "some-tool" → "SOME_TOOL"
_optional_token() {
  printf '%s' "$1" | tr '[:lower:]-' '[:upper:]_'
}

# Determine whether an optional item should be applied.
# Checks (in order): cached choice from earlier in this run, ENABLE_OPTIONAL_*
# env override, dry-run skip, interactive prompt. The result is cached so the
# same item (e.g. an optional cask + its role) only prompts once per run.
_optional_selected() {
  local key="$1" kind="$2" display="$3"
  local token cache_var override_var cached override reply=""
  token=$(_optional_token "$key")
  cache_var="_OPTIONAL_CHOICE_${token}"
  override_var="ENABLE_OPTIONAL_${token}"

  # Return cached decision from earlier in this run
  eval "cached=\${$cache_var:-}"
  if [ -n "$cached" ]; then
    if [ "$cached" = "1" ]; then
      return 0
    fi
    _log_skip "$display" "optional — skipped"
    return 1
  fi

  # Check for an explicit override in vars/local.sh.
  # CONFIRM_MODE deliberately bypasses overrides so the user is asked about
  # every step, even items they normally auto-apply via ENABLE_OPTIONAL_*.
  if [ "${CONFIRM_MODE:-0}" != "1" ]; then
    eval "override=\${$override_var:-}"
    case "$override" in
      1|true|TRUE|yes|YES|on|ON)
        eval "$cache_var=1"
        return 0
        ;;
      0|false|FALSE|no|NO|off|OFF)
        eval "$cache_var=0"
        _log_skip "$display" "optional — disabled"
        return 1
        ;;
    esac
  fi

  # Dry runs can't prompt interactively
  if [ "$DRY_RUN" = "1" ]; then
    _log_dry "$display" "optional ${kind} — would prompt to apply"
    return 1
  fi

  # Interactive prompt; reads from /dev/tty so piped input doesn't interfere
  printf "  ${_C_AMB}?${_C_RST} %-44s  ${_C_AMB}optional ${kind} — apply? ${_C_BLD}[y/N]${_C_RST} " "$display"
  read -r reply < /dev/tty 2>/dev/null || true
  if [ "$reply" = "y" ] || [ "$reply" = "Y" ]; then
    eval "$cache_var=1"
    return 0
  fi

  eval "$cache_var=0"
  _log_skip "$display" "optional — skipped"
  return 1
}

# ── Diff display ─────────────────────────────────────────────────────────────

# Print a unified diff between two files, colored and indented.
# Used by deploy functions to show what changed in an existing file.
_log_diff() {
  local udiff
  udiff=$(diff -u "$1" "$2" 2>/dev/null || true)
  [ -z "$udiff" ] && return
  _log_diff_raw "$udiff"
}

# Print pre-computed unified diff output.
# Skips --- / +++ headers and context lines; shows only hunks, adds, and deletes.
_log_diff_raw() {
  local line color
  printf '\n'
  while IFS= read -r line; do
    case "$line" in
      ---*|+++*) continue ;;
      @@*)  color="$_C_DIM" ;;
      +*)   color="$_C_GRN_B" ;;
      -*)   color="$_C_RED" ;;
      *)    continue ;;
    esac
    printf "    ${color}%s${_C_RST}\n" "$line"
  done <<< "$1"
  printf '\n'
}

# ── File deployment ───────────────────────────────────────────────────────────

ensure_dir() {
  local dir="$1" mode="${2:-0755}"
  local display
  display=$(_shorten "$dir")
  if [ ! -d "$dir" ]; then
    if [ "$DRY_RUN" = "1" ]; then
      _log_dry "$display" "would create"
    else
      mkdir -p "$dir" && chmod "$mode" "$dir"
      _log_ok "$display" "created"
    fi
  else
    _log_skip "$display" "exists"
  fi
}

# Core deploy logic shared by deploy_file and deploy_template.
# Compares src against dest; skips if identical, otherwise backs up and copies.
_deploy() {
  local src="$1" dest="$2" mode="${3:-0644}"
  local display
  display=$(_shorten "$dest")
  if [ ! -f "$dest" ] || ! diff -q "$src" "$dest" > /dev/null 2>&1; then
    if [ "$DRY_RUN" = "1" ]; then
      _log_dry "$display" "would deploy"
      # Show the diff so the user can review planned changes
      if [ -f "$dest" ]; then
        _log_diff "$dest" "$src"
      fi
    else
      local status="deployed" udiff=""
      if [ -f "$dest" ]; then
        # Count added/removed lines for the status summary
        local diff_out added removed
        diff_out=$(diff "$src" "$dest" 2>/dev/null || true)
        added=$(printf '%s\n' "$diff_out" | grep -c '^<' || true)
        removed=$(printf '%s\n' "$diff_out" | grep -c '^>' || true)
        [ -z "$added" ] && added=0
        [ -z "$removed" ] && removed=0
        status="deployed  ${_C_DIM}(+${added} -${removed})${_C_RST}"
        udiff=$(diff -u "$dest" "$src" 2>/dev/null || true)
      fi
      # Back up the previous version before overwriting
      [ -f "$dest" ] && cp "$dest" "${dest}.bak"
      cp "$src" "$dest" && chmod "$mode" "$dest"
      _log_ok "$display" "$status"
      # Show inline diff of what changed
      if [ -n "$udiff" ]; then
        _log_diff_raw "$udiff"
      fi
    fi
  else
    _log_skip "$display" "no change"
  fi
}

deploy_file() {
  _deploy "$1" "$2" "${3:-0644}"
}

# Offer to remove a stale .bak file left by a previous deploy.
# Called after deploy_file/deploy_template to clean up backups from prior runs.
_sanitize_bak() {
  local dest="$1"
  local bak="${dest}.bak"
  [ ! -f "$bak" ] && return
  local display
  display=$(_shorten "$bak")
  if [ "$DRY_RUN" = "1" ]; then
    _log_dry "$display" "stale backup — would prompt removal"
  else
    printf "  ${_C_AMB}?${_C_RST} %-44s  ${_C_AMB}stale backup — remove? ${_C_BLD}[y/N]${_C_RST} " "$display"
    local reply=""
    read -r reply < /dev/tty 2>/dev/null || true
    if [ "$reply" = "y" ] || [ "$reply" = "Y" ]; then
      rm -f "$bak"
      _log_ok "$display" "removed"
    fi
  fi
}

# Offer to remove files in DIR that are not in the managed list.
# Catches config files created outside this repo (e.g. by an app's own settings UI).
# IGNORE_FILE: path to a newline-delimited allowlist of extra filenames to keep
#              (# comments allowed), or "" to skip. Used by roles like lazygit and
#              neovim where the app creates its own state files alongside our config.
_sanitize_dir() {
  local dir="$1" ignore_file="$2"; shift 2
  [ ! -d "$dir" ] && return
  local item name found display reply line
  local -a ignore=()
  if [ -n "$ignore_file" ] && [ -f "$ignore_file" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in "#"*|"") continue ;; esac
      ignore+=("$line")
    done < "$ignore_file"
  fi
  while IFS= read -r item; do
    name=$(basename "$item")
    found=0
    for m; do [ "$name" = "$m" ] && found=1 && break; done
    for i in "${ignore[@]+"${ignore[@]}"}"; do [ "$name" = "$i" ] && found=1 && break; done
    if [ "$found" -eq 0 ]; then
      display=$(_shorten "$item")
      if [ "$DRY_RUN" = "1" ]; then
        _log_dry "$display" "not in dotfiles — would prompt removal"
      else
        printf "  ${_C_AMB}?${_C_RST} %-44s  ${_C_AMB}not in dotfiles — remove? ${_C_BLD}[y/N]${_C_RST} " "$display"
        reply=""
        read -r reply < /dev/tty 2>/dev/null || true
        if [ "$reply" = "y" ] || [ "$reply" = "Y" ]; then
          rm -f "$item"
          _log_ok "$display" "removed"
        fi
      fi
    fi
  done < <(find "$dir" -maxdepth 1 -type f 2>/dev/null)
}

# Expand envsubst variables in a template, then deploy the result.
# $4 (optional) restricts which variables are substituted (e.g. '$GIT_NAME $GIT_EMAIL')
# to avoid clobbering literal $ signs in the template.
deploy_template() {
  local src="$1" dest="$2" mode="${3:-0644}" vars="${4:-}"
  local tmp
  tmp=$(mktemp)
  if [ -n "$vars" ]; then
    envsubst "$vars" < "$src" > "$tmp"
  else
    envsubst < "$src" > "$tmp"
  fi
  _deploy "$tmp" "$dest" "$mode"
  rm -f "$tmp"
}
