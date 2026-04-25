#!/usr/bin/env bash
# ============================================================================
# test-tmux-bridge.sh — Unit tests for claude-tmux-bridge.sh
#
# Requires tmux to be installed. Creates a temporary tmux session for testing.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BRIDGE="$SCRIPT_DIR/scripts/claude-tmux-bridge.sh"
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

expect_json_valid() {
  local desc="$1"
  shift
  set +e
  output=$("$@" 2>&1)
  set -e
  if echo "$output" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
    echo "PASS: $desc"
    ((PASS++)) || true
  else
    echo "FAIL: $desc (invalid JSON)"
    echo "  output: $output"
    ((FAIL++)) || true
  fi
}

# --- Pre-flight: tmux installed ---
if ! command -v tmux &>/dev/null; then
  echo "SKIP: tmux not installed"
  exit 0
fi

# --- Test: list returns valid JSON ---
expect_json_valid "list returns valid JSON" "$BRIDGE" list

# --- Test: list JSON has sessions array ---
set +e
output=$("$BRIDGE" list 2>&1)
set -e
if echo "$output" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if 'sessions' in d else 1)" 2>/dev/null; then
  echo "PASS: list JSON has sessions field"
  ((PASS++)) || true
else
  echo "FAIL: list JSON missing sessions field"
  echo "  output: $output"
  ((FAIL++)) || true
fi

# --- Test: read non-existent session fails ---
expect_exit "read missing session fails" 1 "$BRIDGE" read nonexistent-session-12345

# --- Test: send to non-existent session fails ---
expect_exit "send missing session fails" 1 "$BRIDGE" send nonexistent-session-12345 "hello"

# --- Test: create temp session and interact ---
TEST_SESSION="kimatropic-bridge-test-$$"
tmux new-session -d -s "$TEST_SESSION" "bash"

# Test read
expect_json_valid "read returns valid JSON" "$BRIDGE" read "$TEST_SESSION"

# Test send
expect_json_valid "send returns valid JSON" "$BRIDGE" send "$TEST_SESSION" "echo hello_from_test"

# Wait for command to execute
sleep 1

# Verify output contains our command
set +e
output=$("$BRIDGE" read "$TEST_SESSION" 2>&1)
set -e
if echo "$output" | grep -q "hello_from_test"; then
  echo "PASS: read output contains sent command"
  ((PASS++)) || true
else
  echo "FAIL: read output missing sent command"
  echo "  output: $output"
  ((FAIL++)) || true
fi

# Cleanup
tmux kill-session -t "$TEST_SESSION" 2>/dev/null || true

# --- Test: stop non-existent session fails ---
expect_exit "stop missing session fails" 1 "$BRIDGE" stop nonexistent-session-12345

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
