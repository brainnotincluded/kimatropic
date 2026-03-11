#!/usr/bin/env bash
# kimi-preflight.sh — Verify all dependencies before running Kimi delegation
set -euo pipefail

errors=()

# Check kimi CLI
if ! command -v kimi &>/dev/null; then
  errors+=("kimi CLI not found in PATH. Install: pip install kimi-cli")
else
  kimi_version=$(kimi --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
  required="1.19"
  if [ "$(printf '%s\n' "$required" "$kimi_version" | sort -V | head -1)" != "$required" ]; then
    errors+=("kimi CLI version $kimi_version < required $required. Run: pip install --upgrade kimi-cli")
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
if [ ! -d "$HOME/.kimi/credentials" ]; then
  errors+=("Kimi not logged in. Run: kimi login")
fi

# Report
if [ ${#errors[@]} -gt 0 ]; then
  echo "Preflight failed:" >&2
  for err in "${errors[@]}"; do
    echo "  - $err" >&2
  done
  exit 1
fi

echo "Preflight OK" >&2
exit 0
