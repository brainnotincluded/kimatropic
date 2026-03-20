#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CAPTURE="$SCRIPT_DIR/scripts/screen-capture.sh"
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
    ((PASS++)) || true
  else
    echo "FAIL: $desc (expected exit $expected, got $actual)"
    echo "  output: $output"
    ((FAIL++)) || true
  fi
}

expect_contains() {
  local desc="$1" pattern="$2"
  shift 2
  set +e
  output=$("$@" 2>&1)
  set -e
  if echo "$output" | grep -qi "$pattern"; then
    echo "PASS: $desc"
    ((PASS++)) || true
  else
    echo "FAIL: $desc (output missing '$pattern')"
    ((FAIL++)) || true
  fi
}

# Test 1: --help shows usage
expect_contains "shows usage with --help" "screenshot-viewports" "$CAPTURE" --help

# Test 2: No args shows usage
expect_exit "no args shows usage" 0 "$CAPTURE"

# Test 3: Unknown command fails
expect_exit "unknown command fails" 0 "$CAPTURE" unknown-command

# Test 4: screenshot-viewports creates files
TMPDIR_TEST=$(mktemp -d)
expect_exit "screenshot-viewports succeeds" 0 "$CAPTURE" screenshot-viewports "$TMPDIR_TEST"
if [ -f "$TMPDIR_TEST/desktop-1920x1080.png" ]; then
  echo "PASS: desktop screenshot created"
  ((PASS++)) || true
else
  echo "FAIL: desktop screenshot not created"
  ((FAIL++)) || true
fi
rm -rf "$TMPDIR_TEST"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
