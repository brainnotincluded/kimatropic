#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PREFLIGHT="$SCRIPT_DIR/scripts/desktop-preflight.sh"
PASS=0
FAIL=0

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

# Test 1: Preflight succeeds when pyautogui + ffmpeg are available
expect_exit "preflight passes with deps" 0 "$PREFLIGHT"

# Test 2: Preflight fails with stripped PATH (no python3)
expect_exit "preflight fails without python3" 1 env PATH="/usr/bin:/bin" "$PREFLIGHT"

# Test 3: Script is executable
if [ -x "$PREFLIGHT" ]; then
  echo "PASS: script is executable"
  ((PASS++)) || true || true
else
  echo "FAIL: script is not executable"
  ((FAIL++)) || true || true
fi

# Test 4: Output includes capability report
set +e
output=$("$PREFLIGHT" 2>&1)
set -e
if echo "$output" | grep -q "click\|screenshot\|record"; then
  echo "PASS: output includes capability report"
  ((PASS++)) || true || true
else
  echo "FAIL: output missing capability report"
  ((FAIL++)) || true || true
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
