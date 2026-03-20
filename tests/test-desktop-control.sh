#!/usr/bin/env bash
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

# Test 1: No args shows usage
expect_contains "shows usage with no args" "usage" python3 "$CONTROL"

# Test 2: --help works
expect_contains "shows help" "screenshot" python3 "$CONTROL" --help

# Test 3: Unknown command fails
expect_exit "unknown command fails" 2 python3 "$CONTROL" unknown-command

# Test 4: Screenshot creates a file
TMPFILE=$(mktemp /tmp/kimatropic-test-XXXXXX.png)
rm -f "$TMPFILE"
expect_exit "screenshot succeeds" 0 python3 "$CONTROL" screenshot "$TMPFILE"
if [ -f "$TMPFILE" ] && [ -s "$TMPFILE" ]; then
  echo "PASS: screenshot file created and non-empty"
  ((PASS++)) || true
else
  echo "FAIL: screenshot file missing or empty"
  ((FAIL++)) || true
fi
rm -f "$TMPFILE"

# Test 5: Screenshot with region
TMPFILE=$(mktemp /tmp/kimatropic-test-XXXXXX.png)
rm -f "$TMPFILE"
expect_exit "screenshot region succeeds" 0 python3 "$CONTROL" screenshot "$TMPFILE" --region 0,0,100,100
if [ -f "$TMPFILE" ] && [ -s "$TMPFILE" ]; then
  echo "PASS: region screenshot created"
  ((PASS++)) || true
else
  echo "FAIL: region screenshot missing or empty"
  ((FAIL++)) || true
fi
rm -f "$TMPFILE"

# Test 6: Window-list returns JSON
set +e
output=$(python3 "$CONTROL" window-list 2>&1)
set -e
if echo "$output" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
  echo "PASS: window-list returns valid JSON"
  ((PASS++)) || true
else
  echo "FAIL: window-list output is not valid JSON"
  ((FAIL++)) || true
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
