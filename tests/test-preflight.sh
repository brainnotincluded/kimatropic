#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PREFLIGHT="$SCRIPT_DIR/scripts/kimi-preflight.sh"
PASS=0
FAIL=0

# Helper: expect exit code
expect_exit() {
  local desc="$1" expected="$2"
  shift 2
  set +e
  output=$("$@" 2>&1)
  actual=$?
  set -e
  if [ "$actual" -eq "$expected" ]; then
    echo "PASS: $desc"
    ((PASS++)) || true || true
  else
    echo "FAIL: $desc (expected exit $expected, got $actual)"
    echo "  output: $output"
    ((FAIL++)) || true || true
  fi
}

# Test 1: Preflight succeeds in normal environment (kimi, git, jq all present)
expect_exit "preflight passes with all deps" 0 "$PREFLIGHT"

# Test 2: Preflight fails when deps are missing (stripping PATH removes kimi, jq, etc.)
expect_exit "preflight fails with missing deps" 1 env PATH="/usr/bin:/bin" "$PREFLIGHT"

# Test 3: Script is executable
if [ -x "$PREFLIGHT" ]; then
  echo "PASS: script is executable"
  ((PASS++)) || true || true
else
  echo "FAIL: script is not executable"
  ((FAIL++)) || true || true
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
