#!/usr/bin/env bash
# Shared utilities for install scripts.

# When DRY_RUN=1, deploy functions show what would change without writing files
DRY_RUN="${DRY_RUN:-0}"

# ── Terminal / table width ─────────────────────────────────────────────────────
_TERM_W=$(tput cols 2>/dev/null || printf '%s' "${COLUMNS:-80}")
# Table width is terminal minus outer margins, clamped to 58–120 columns
_TBL_W=$(( _TERM_W - 2 ))
[ "$_TBL_W" -lt 58 ]  && _TBL_W=58
[ "$_TBL_W" -gt 120 ] && _TBL_W=120

# ── Colors (light-background safe) ───────────────────────────────────────────
_C_GRN=$'\033[32m'      # green — borders, structure
_C_GRN_B=$'\033[1;32m'  # bold green — ok status
_C_AMB=$'\033[33m'      # amber — dry-run, prompts
_C_RED=$'\033[31m'      # red — errors
_C_DIM=$'\033[2m'       # dim — skips, no-change labels
_C_BLD=$'\033[1m'       # bold — section titles
_C_RST=$'\033[0m'       # reset

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

# Visible (ANSI-stripped) length of a string — needed because ANSI escape
# codes inflate ${#s} but don't occupy display columns
_vis_len() {
  local ESC=$'\033' s
  s=$(printf '%s' "$1" | sed "s/${ESC}\[[0-9;]*m//g")
  printf '%s' "${#s}"
}

# Right-border padding: fill the gap between the status text and the trailing │
# so every row ends at the same column.  $1 = path display, $2 = status length
_rpad() {
  local pcol pad
  pcol=$(( ${#1} > 42 ? ${#1} : 42 ))
  pad=$(( _TBL_W - 9 - pcol - $2 ))
  [ "$pad" -lt 1 ] && pad=1
  printf '%*s' "$pad" ''
}

# Truncate status text so it never overflows the row width.
# Returns the original or a truncated-with-ellipsis version.
_fit_plain() {
  local pcol max
  pcol=$(( ${#1} > 42 ? ${#1} : 42 ))
  max=$(( _TBL_W - 10 - pcol ))  # 10 = 9 prefix overhead + 1 min gap before │
  if [ "$max" -lt 1 ]; then max=1; fi
  if [ "${#2}" -gt "$max" ]; then
    printf '%s…' "${2:0:$(( max - 1 ))}"
  else
    printf '%s' "$2"
  fi
}

# ── Log functions ─────────────────────────────────────────────────────────────

_log_ok() {
  local slen pad
  slen=$(_vis_len "$2")
  pad=$(_rpad "$1" "$slen")
  printf "  ${_C_GRN}│${_C_RST}  ${_C_GRN_B}✓${_C_RST}  %-42s  ${_C_GRN_B}%s${_C_RST}%s${_C_GRN}│${_C_RST}\n" \
    "$1" "$2" "$pad"
  _COUNT_OK=$(( _COUNT_OK + 1 ))
  _SECTION_OK=$(( _SECTION_OK + 1 ))
  _SECTION_CHANGED+=("$1")
}

_log_skip() {
  local status pad
  status=$(_fit_plain "$1" "$2")
  pad=$(_rpad "$1" "${#status}")
  printf "  ${_C_GRN}│${_C_RST}  ${_C_DIM}·  %-42s  %s${_C_RST}%s${_C_GRN}│${_C_RST}\n" \
    "$1" "$status" "$pad"
  _COUNT_SKIP=$(( _COUNT_SKIP + 1 ))
  _SECTION_SKIP=$(( _SECTION_SKIP + 1 ))
}

_log_dry() {
  local status pad
  status=$(_fit_plain "$1" "$2")
  pad=$(_rpad "$1" "${#status}")
  printf "  ${_C_GRN}│${_C_RST}  ${_C_AMB}→  %-42s  %s${_C_RST}%s${_C_GRN}│${_C_RST}\n" \
    "$1" "$status" "$pad"
  _COUNT_DRY=$(( _COUNT_DRY + 1 ))
  _SECTION_DRY=$(( _SECTION_DRY + 1 ))
  _SECTION_CHANGED+=("$1")
}

_log_note() {
  local status pad
  status=$(_fit_plain "$1" "$2")
  pad=$(_rpad "$1" "${#status}")
  printf "  ${_C_GRN}│${_C_RST}  ${_C_DIM}◆  %-42s  %s${_C_RST}%s${_C_GRN}│${_C_RST}\n" \
    "$1" "$status" "$pad"
}

_log_err() {
  local pad=$(( _TBL_W - 7 - ${#1} ))
  [ "$pad" -lt 0 ] && pad=0
  printf "  ${_C_GRN}│${_C_RST}  ${_C_RED}✗  %s${_C_RST}%*s${_C_GRN}│${_C_RST}\n" \
    "$1" "$pad" "" >&2
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
    local npad=$(( _TBL_W - 13 - ${#names} ))
    [ "$npad" -lt 0 ] && npad=0
    printf "  ${_C_GRN}│%*s│${_C_RST}\n" $(( _TBL_W - 2 )) ""
    printf "  ${_C_GRN}│${_C_RST}  ${_C_DIM}changed: %s${_C_RST}%*s${_C_GRN}│${_C_RST}\n" \
      "$names" "$npad" ""
  fi

  local s="" s_plain=""
  if [ "$DRY_RUN" = "1" ]; then
    if [ "$_SECTION_DRY" -gt 0 ]; then
      s="${_C_AMB}${_SECTION_DRY} plan${_C_RST}"; s_plain="${_SECTION_DRY} plan"
    fi
    if [ "$_SECTION_SKIP" -gt 0 ]; then
      s="${s:+${s}  ${_C_DIM}·${_C_RST}  }${_C_DIM}${_SECTION_SKIP} skip${_C_RST}"
      s_plain="${s_plain:+${s_plain}  ·  }${_SECTION_SKIP} skip"
    fi
  else
    if [ "$_SECTION_OK" -gt 0 ]; then
      s="${_C_GRN_B}${_SECTION_OK} ok${_C_RST}"; s_plain="${_SECTION_OK} ok"
    fi
    if [ "$_SECTION_SKIP" -gt 0 ]; then
      s="${s:+${s}  ${_C_DIM}·${_C_RST}  }${_C_DIM}${_SECTION_SKIP} skip${_C_RST}"
      s_plain="${s_plain:+${s_plain}  ·  }${_SECTION_SKIP} skip"
    fi
  fi
  if [ -z "$s" ]; then s="${_C_DIM}—${_C_RST}"; s_plain="—"; fi

  # Footer: "  └─ SUMMARY ────────────────────────────────┘" = TERM_W chars
  # "  └─" (4) + " " + summary + " " + right_dashes + "┘" (1) = TERM_W
  # right_dashes = TBL_W - 5 - len(summary)
  local right_dashes=$(( _TBL_W - 5 - ${#s_plain} ))
  [ "$right_dashes" -lt 1 ] && right_dashes=1
  local _right
  _right=$(printf '─%.0s' $(seq 1 "$right_dashes"))
  printf "  ${_C_GRN}└─${_C_RST} %s ${_C_GRN}%s┘${_C_RST}\n\n" "$s" "$_right"
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

  # fill_len reserves 1 char for the closing ┐
  local fill_len=$(( _TBL_W - 5 - ${#title} ))
  [ "$fill_len" -lt 1 ] && fill_len=1
  local fill
  fill=$(printf '─%.0s' $(seq 1 "$fill_len"))

  printf "\n  ${_C_GRN}┌─${_C_RST} ${_C_BLD}%s${_C_RST} ${_C_GRN}%s┐${_C_RST}\n" "$title" "$fill"
}

_log_summary() {
  [ "$_SECTION_OPEN" = "1" ] && _log_section_end

  local _sep
  _sep=$(printf '═%.0s' $(seq 1 "$_TBL_W"))
  printf "  ${_C_GRN}%s${_C_RST}\n" "$_sep"
  if [ "$DRY_RUN" = "1" ]; then
    printf "  ${_C_AMB}● %d plan${_C_RST}  ${_C_DIM}·  %d skip${_C_RST}\n\n" "$_COUNT_DRY" "$_COUNT_SKIP"
  else
    printf "  ${_C_GRN_B}● %d ok${_C_RST}  ${_C_DIM}·  %d skip${_C_RST}\n\n" "$_COUNT_OK" "$_COUNT_SKIP"
  fi
}

# ── Brew output helpers ───────────────────────────────────────────────────────

_log_brew_start() {
  local _bdiv pad
  _bdiv=$(printf '┄%.0s' $(seq 1 $(( _TBL_W - 4 ))))
  pad=$(_rpad "$1" 13)  # "installing..." = 13 chars
  printf "  ${_C_GRN}│${_C_RST}  ${_C_AMB}↓${_C_RST}  %-42s  ${_C_AMB}installing...${_C_RST}%s${_C_GRN}│${_C_RST}\n" \
    "$1" "$pad"
  printf "  ${_C_GRN}│  ${_C_DIM}%s${_C_GRN}│${_C_RST}\n" "$_bdiv"
}

_log_brew_end() {
  local _bdiv
  _bdiv=$(printf '┄%.0s' $(seq 1 $(( _TBL_W - 4 ))))
  printf "  ${_C_GRN}│  ${_C_DIM}%s${_C_GRN}│${_C_RST}\n" "$_bdiv"
}

_brew_pipe() {
  while IFS= read -r line; do
    printf "  ${_C_GRN}│${_C_RST}     %s\n" "$line"
  done
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
# same item (e.g. codex cask + codex role) only prompts once per run.
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

  # Check for an explicit override in vars/local.sh
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

  # Dry runs can't prompt interactively
  if [ "$DRY_RUN" = "1" ]; then
    _log_dry "$display" "optional ${kind} — would prompt to apply"
    return 1
  fi

  # Interactive prompt; reads from /dev/tty so piped input doesn't interfere
  printf "  ${_C_GRN}│${_C_RST}  ${_C_AMB}?${_C_RST}  %-42s  ${_C_AMB}optional ${kind} — apply? ${_C_BLD}[y/N]${_C_RST} " "$display"
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

# Print a unified diff between two files, colored and framed within the table border.
# Used by deploy functions to show what changed in an existing file.
_log_diff() {
  local udiff
  udiff=$(diff -u "$1" "$2" 2>/dev/null || true)
  [ -z "$udiff" ] && return
  _log_diff_raw "$udiff"
}

# Print pre-computed unified diff output within the table border.
# Skips --- / +++ headers and context lines; shows only hunks, adds, and deletes.
_log_diff_raw() {
  local line color
  local _ddiv
  _ddiv=$(printf '┄%.0s' $(seq 1 $(( _TBL_W - 4 ))))
  printf "  ${_C_GRN}│  ${_C_DIM}%s${_C_GRN}│${_C_RST}\n" "$_ddiv"
  while IFS= read -r line; do
    case "$line" in
      ---*|+++*) continue ;;
      @@*)  color="$_C_DIM" ;;
      +*)   color="$_C_GRN_B" ;;
      -*)   color="$_C_RED" ;;
      *)    continue ;;
    esac
    printf "  ${_C_GRN}│${_C_RST}     ${color}%s${_C_RST}\n" "$line"
  done <<< "$1"
  printf "  ${_C_GRN}│  ${_C_DIM}%s${_C_GRN}│${_C_RST}\n" "$_ddiv"
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
    printf "  ${_C_GRN}│${_C_RST}  ${_C_AMB}?${_C_RST}  %-42s  ${_C_AMB}stale backup — remove? ${_C_BLD}[y/N]${_C_RST} " "$display"
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
        printf "  ${_C_GRN}│${_C_RST}  ${_C_AMB}?${_C_RST}  %-42s  ${_C_AMB}not in dotfiles — remove? ${_C_BLD}[y/N]${_C_RST} " "$display"
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
