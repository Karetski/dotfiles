#!/usr/bin/env bash
# RTK (Rust Token Killer) hook for Claude Code.
# Intercepts tool calls and rewrites shell commands to use rtk for token savings.

if command -v rtk >/dev/null 2>&1; then
  rtk hook claude
else
  # Passthrough if rtk is not installed
  cat
fi
