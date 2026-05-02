#!/usr/bin/env bash
# Shared variables for all install scripts.
# Machine-specific overrides go in vars/local.sh (gitignored).

# Roles that prompt before applying (unless ENABLE_OPTIONAL_<NAME>=1 in local.sh)
OPTIONAL_ROLES=(
  claude
  stats
  zed
  docker-desktop
  linearmouse
  bun
)
