#!/usr/bin/env bash
# ============================================================================
# test-desktop-control.sh — Unit tests for desktop-control.py
#
# Note: screenshot tests may fail on macOS without Screen Recording permission.
# The script validates that the failure is graceful (clear JSON error).
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONTROL="$SCRIPT_DIR/scripts/desktop-control.py"
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

expect_json_field() {
  local desc="$1" field="$2"
  shift 2
  set +e
  output=$("$@" 2>&1)
  set -e
  if echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if '$field' in d else 1)" 2>/dev/null; then
    echo "PASS: $desc"
    ((PASS++)) || true
  else
    echo "FAIL: $desc (JSON missing field '$field')"
    echo "  output: $output"
    ((FAIL++)) || true
  fi
}

# --- Basic CLI tests ---
expect_contains "shows usage with no args" "usage" python3 "$CONTROL"
expect_contains "shows help" "screenshot" python3 "$CONTROL" --help
expect_exit "unknown command fails" 2 python3 "$CONTROL" unknown-command

# --- Mouse position ---
expect_json_field "mouse-position returns JSON with x" "x" python3 "$CONTROL" mouse-position

# --- Window list ---
set +e
output=$(python3 "$CONTROL" window-list 2>&1)
set -e
if echo "$output" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
  echo "PASS: window-list returns valid JSON"
  ((PASS++)) || true
else
  echo "FAIL: window-list output is not valid JSON"
  echo "  output: $output"
  ((FAIL++)) || true
fi

# --- Screenshot tests ---
# On macOS without Screen Recording permission, screenshot fails gracefully.
TMPFILE=$(mktemp /tmp/kimatropic-test-XXXXXX.png)
rm -f "$TMPFILE"

set +e
output=$(python3 "$CONTROL" screenshot "$TMPFILE" 2>&1)
actual=$?
set -e

if [ "$actual" -eq 0 ] && [ -f "$TMPFILE" ] && [ -s "$TMPFILE" ]; then
  echo "PASS: screenshot succeeds and file is non-empty"
  ((PASS++)) || true
  rm -f "$TMPFILE"

  # Region screenshot only testable if full screenshot works
  TMPFILE=$(mktemp /tmp/kimatropic-test-XXXXXX.png)
  rm -f "$TMPFILE"
  set +e
  output=$(python3 "$CONTROL" screenshot "$TMPFILE" --region 0,0,100,100 2>&1)
  actual=$?
  set -e
  if [ "$actual" -eq 0 ] && [ -f "$TMPFILE" ] && [ -s "$TMPFILE" ]; then
    echo "PASS: region screenshot succeeds"
    ((PASS++)) || true
  else
    echo "FAIL: region screenshot failed"
    echo "  output: $output"
    ((FAIL++)) || true
  fi
  rm -f "$TMPFILE"
else
  # Should fail gracefully with JSON error containing permission info
  if echo "$output" | grep -q '"error"'; then
    echo "PASS: screenshot fails gracefully with JSON error (Screen Recording permission likely missing)"
    ((PASS++)) || true
  else
    echo "FAIL: screenshot failed without graceful JSON error"
    echo "  output: $output"
    ((FAIL++)) || true
  fi
  rm -f "$TMPFILE"

  # Skip region test when full screenshot unavailable
  echo "SKIP: region screenshot (full screenshot unavailable)"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
