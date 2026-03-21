#!/usr/bin/env bash
# ============================================================================
# kimi-preflight.sh — Verify all dependencies before running Kimi delegation
#
# Checks that the kimi CLI, git, jq, timeout/tac (GNU coreutils), and kimi
# credentials are present and meet minimum version requirements.
#
# Usage:
#   ./kimi-preflight.sh
#
# Exit codes:
#   0 — All checks passed
#   1 — One or more dependency checks failed (details on stderr)
# ============================================================================
set -euo pipefail

errors=()

# Check kimi CLI
if ! command -v kimi &>/dev/null; then
  errors+=("kimi CLI not found in PATH. Install: pip install kimi-cli")
else
  kimi_version=$(kimi --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
  required_version="1.19"
  if [ "$(printf '%s\n' "$required_version" "$kimi_version" | sort -V | head -1)" != "$required_version" ]; then
    errors+=("kimi CLI version $kimi_version < required $required_version. Run: pip install --upgrade kimi-cli")
  fi
fi

# Check git
if ! command -v git &>/dev/null; then
  errors+=("git not found in PATH")
fi

# Check jq
if ! command -v jq &>/dev/null; then
  errors+=("jq not found in PATH. Install: brew install jq")
fi

# Check timeout (GNU coreutils on macOS: brew install coreutils)
if ! command -v timeout &>/dev/null && ! command -v gtimeout &>/dev/null; then
  errors+=("timeout not found in PATH. Install: brew install coreutils")
fi

# Check tac (GNU coreutils on macOS)
if ! command -v tac &>/dev/null && ! command -v gtac &>/dev/null; then
  errors+=("tac not found in PATH. Install: brew install coreutils")
fi

# Check kimi credentials (credentials is a directory)
kimi_creds_dir="${HOME}/.kimi/credentials"
if [ ! -d "$kimi_creds_dir" ]; then
  errors+=("Kimi not logged in. Run: kimi login")
fi

# Report results
if [ ${#errors[@]} -gt 0 ]; then
  echo "kimi-preflight: ${#errors[@]} error(s) found:" >&2
  for err in "${errors[@]}"; do
    echo "  - $err" >&2
  done
  exit 1
fi

echo "kimi-preflight: all checks passed" >&2
exit 0
