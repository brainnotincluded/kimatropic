#!/usr/bin/env bash
# Live integration test — requires Kimi CLI logged in and working
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
KIMI_RUN="$SCRIPT_DIR/scripts/kimi-run.sh"
PASS=0
FAIL=0

# Create a temp git repo for testing
TEST_DIR=$(mktemp -d)
git -C "$TEST_DIR" init -q
echo "hello" > "$TEST_DIR/test.txt"
git -C "$TEST_DIR" add .
git -C "$TEST_DIR" commit -q -m "initial"

echo "Running live test in $TEST_DIR..."

# Test: Run kimi on a trivial task
# Capture stdout (JSON) only; stderr (preflight messages, diagnostics) flows to terminal
STDERR_TMP=$(mktemp)
set +e
output=$("$KIMI_RUN" --task "Create a file called hello.py with a single line: print('hello world')" --workdir "$TEST_DIR" --timeout 120 2>"$STDERR_TMP")
exit_code=$?
set -e

echo "Exit code: $exit_code"
if [ -s "$STDERR_TMP" ]; then
  echo "Stderr (diagnostics):"
  cat "$STDERR_TMP"
fi
rm -f "$STDERR_TMP"
echo "Stdout (JSON output):"
echo "$output"

# Validate output is JSON
if echo "$output" | jq . &>/dev/null; then
  echo "PASS: output is valid JSON"
  PASS=$((PASS + 1))
else
  echo "FAIL: output is not valid JSON"
  FAIL=$((FAIL + 1))
fi

# Validate status field
status=$(echo "$output" | jq -r '.status')
if [ "$status" = "success" ] || [ "$status" = "failed" ] || [ "$status" = "partial" ]; then
  echo "PASS: status field is valid ($status)"
  PASS=$((PASS + 1))
else
  echo "FAIL: unexpected status: $status"
  FAIL=$((FAIL + 1))
fi

# Validate summary is non-empty
summary=$(echo "$output" | jq -r '.summary')
if [ -n "$summary" ] && [ "$summary" != "null" ]; then
  echo "PASS: summary is non-empty"
  PASS=$((PASS + 1))
else
  echo "FAIL: summary is empty"
  FAIL=$((FAIL + 1))
fi

# Validate wall_time is a number
wall_time=$(echo "$output" | jq -r '.wall_time_seconds')
if [ "$wall_time" -ge 0 ] 2>/dev/null; then
  echo "PASS: wall_time_seconds is a number ($wall_time)"
  PASS=$((PASS + 1))
else
  echo "FAIL: wall_time_seconds is not a valid number: $wall_time"
  FAIL=$((FAIL + 1))
fi

# Cleanup
rm -rf "$TEST_DIR"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
