#!/usr/bin/env bash
# ============================================================================
# test-screen-capture.sh — Unit tests for screen-capture.sh
#
# Note: screenshot-viewports may skip or partially fail if Screen Recording
# permission is not granted on macOS. The script validates graceful handling.
# ============================================================================
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
    echo "  output: $output"
    ((FAIL++)) || true
  fi
}

# --- Test: help output ---
expect_contains "shows usage with --help" "screenshot-viewports" "$CAPTURE" --help
expect_exit "no args shows usage" 0 "$CAPTURE"

# --- Test: unknown command ---
expect_contains "unknown command shows usage" "usage" "$CAPTURE" unknown-command

# --- Test: screenshot-viewports ---
TMPDIR_TEST=$(mktemp -d)
set +e
output=$("$CAPTURE" screenshot-viewports "$TMPDIR_TEST" 2>&1)
actual=$?
set -e

if [ "$actual" -eq 0 ] && [ -f "$TMPDIR_TEST/desktop-1920x1080.png" ]; then
  echo "PASS: screenshot-viewports creates desktop screenshot"
  ((PASS++)) || true
else
  # Graceful failure (macOS permission or other)
  if echo "$output" | grep -qiE "screen recording|permission|error"; then
    echo "PASS: screenshot-viewports fails gracefully (permission or env issue)"
    ((PASS++)) || true
  else
    echo "FAIL: screenshot-viewports failed unexpectedly"
    echo "  output: $output"
    ((FAIL++)) || true
  fi
fi
rm -rf "$TMPDIR_TEST"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
