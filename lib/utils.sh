#!/usr/bin/env bash
# Shared utilities for install scripts.

DRY_RUN="${DRY_RUN:-0}"

_COUNT_OK=0
_COUNT_SKIP=0
_COUNT_DRY=0

_shorten() { printf '%s' "${1/#$HOME/\~}"; }

_log_ok()   {
  printf '  \033[32m✓\033[0m  %-52s \033[32m%s\033[0m\n' "$1" "$2"
  _COUNT_OK=$(( _COUNT_OK + 1 ))
}
_log_skip() {
  printf '  \033[90m–\033[0m  %-52s \033[90m%s\033[0m\n' "$1" "$2"
  _COUNT_SKIP=$(( _COUNT_SKIP + 1 ))
}
_log_dry()  {
  printf '  \033[33m~\033[0m  %-52s \033[33m%s\033[0m\n' "$1" "$2"
  _COUNT_DRY=$(( _COUNT_DRY + 1 ))
}
_log_err()  { printf '  \033[31m✗\033[0m  %s\n' "$1" >&2; }

_log_section() {
  local title="$1"
  local fill_len=$(( 55 - ${#title} - 4 ))
  [ "$fill_len" -lt 1 ] && fill_len=1
  local fill
  fill=$(printf '─%.0s' $(seq 1 "$fill_len"))
  printf '\n\033[1m── %s %s\033[0m\n' "$title" "$fill"
}

_log_summary() {
  printf '\n\033[90m%s\033[0m\n' "───────────────────────────────────────────────────────"
  if [ "$DRY_RUN" = "1" ]; then
    printf '  \033[33m%d would change\033[0m  ·  \033[90m%d up to date\033[0m\n\n' "$_COUNT_DRY" "$_COUNT_SKIP"
  else
    printf '  \033[32m%d deployed\033[0m  ·  \033[90m%d up to date\033[0m\n\n' "$_COUNT_OK" "$_COUNT_SKIP"
  fi
}

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

_deploy() {
  local src="$1" dest="$2" mode="${3:-0644}"
  local display
  display=$(_shorten "$dest")
  if [ ! -f "$dest" ] || ! diff -q "$src" "$dest" > /dev/null 2>&1; then
    if [ "$DRY_RUN" = "1" ]; then
      _log_dry "$display" "would deploy"
    else
      [ -f "$dest" ] && cp "$dest" "${dest}.bak"
      cp "$src" "$dest" && chmod "$mode" "$dest"
      _log_ok "$display" "deployed"
    fi
  else
    _log_skip "$display" "up to date"
  fi
}

deploy_file() {
  _deploy "$1" "$2" "${3:-0644}"
}

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
