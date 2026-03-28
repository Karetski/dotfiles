#!/usr/bin/env bash
# Shared utilities for install scripts.

DRY_RUN="${DRY_RUN:-0}"

_log_ok()   { printf '  \033[32m✓\033[0m  %s\n' "$1"; }
_log_skip() { printf '  \033[90m–\033[0m  %s\033[0m\n' "$1"; }
_log_dry()  { printf '  \033[33m~\033[0m  %s\n' "$1"; }
_log_err()  { printf '  \033[31m✗\033[0m  %s\n' "$1" >&2; }

ensure_dir() {
  local dir="$1" mode="${2:-0755}"
  if [ ! -d "$dir" ]; then
    if [ "$DRY_RUN" = "1" ]; then
      _log_dry "mkdir -p $dir"
    else
      mkdir -p "$dir" && chmod "$mode" "$dir"
      _log_ok "created $dir"
    fi
  else
    _log_skip "$dir"
  fi
}

_deploy() {
  local src="$1" dest="$2" mode="${3:-0644}"
  if [ ! -f "$dest" ] || ! diff -q "$src" "$dest" > /dev/null 2>&1; then
    if [ "$DRY_RUN" = "1" ]; then
      _log_dry "$dest"
    else
      [ -f "$dest" ] && cp "$dest" "${dest}.bak"
      cp "$src" "$dest" && chmod "$mode" "$dest"
      _log_ok "$dest"
    fi
  else
    _log_skip "$dest"
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
