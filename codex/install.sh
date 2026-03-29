#!/usr/bin/env bash

ensure_dir "$HOME/.codex"
deploy_file "$DOTFILES_DIR/codex/files/instructions.md" "$HOME/.codex/instructions.md"
_sanitize_bak "$HOME/.codex/instructions.md"

config_path="$HOME/.codex/config.toml"
managed_header="$DOTFILES_DIR/codex/templates/config-header.toml"
tmp_filtered=$(mktemp)
tmp_merged=$(mktemp)

if [ -f "$config_path" ]; then
  awk '
    BEGIN { skip_docs_mcp = 0 }
    {
      if (skip_docs_mcp) {
        if ($0 ~ /^\[/) {
          skip_docs_mcp = 0
        } else {
          next
        }
      }
      if ($0 ~ /^\[mcp_servers\.openaiDeveloperDocs\]/) {
        skip_docs_mcp = 1
        next
      }
      if ($0 ~ /^(approval_policy|sandbox_mode|commit_attribution|model_instructions_file)[[:space:]]*=/) {
        next
      }
      print
    }
  ' "$config_path" > "$tmp_filtered"
else
  : > "$tmp_filtered"
fi

{
  envsubst '$HOME' < "$managed_header"
  if [ -s "$tmp_filtered" ]; then
    printf '\n'
    cat "$tmp_filtered"
  fi
} > "$tmp_merged"

_deploy "$tmp_merged" "$config_path" "0644"
_sanitize_bak "$config_path"

rm -f "$tmp_filtered" "$tmp_merged"
