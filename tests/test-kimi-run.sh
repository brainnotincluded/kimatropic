#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
KIMI_RUN="$SCRIPT_DIR/scripts/kimi-run.sh"
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
    PASS=$((PASS + 1))
  else
    echo "FAIL: $desc (expected exit $expected, got $actual)"
    echo "  output: $output"
    FAIL=$((FAIL + 1))
  fi
}

expect_contains() {
  local desc="$1" pattern="$2"
  shift 2
  set +e
  output=$("$@" 2>&1)
  set -e
  if echo "$output" | grep -q "$pattern"; then
    echo "PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $desc (output missing '$pattern')"
    echo "  output: $output"
    FAIL=$((FAIL + 1))
  fi
}

# Test 1: Missing --task flag should fail
expect_exit "fails without --task" 1 "$KIMI_RUN"

# Test 2: --help shows usage
expect_contains "shows usage with --help" "Usage" "$KIMI_RUN" --help

# Test 3: Accepts --task with --dry-run (no actual kimi call)
expect_exit "dry-run succeeds with --task" 0 "$KIMI_RUN" --task "test task" --dry-run

# Test 4: Dry-run output is valid JSON
set +e
dry_output=$("$KIMI_RUN" --task "test task" --dry-run 2>/dev/null)
set -e
if echo "$dry_output" | jq . &>/dev/null; then
  echo "PASS: dry-run output is valid JSON"
  PASS=$((PASS + 1))
else
  echo "FAIL: dry-run output is not valid JSON"
  echo "  output: $dry_output"
  FAIL=$((FAIL + 1))
fi

# Test 5: Dry-run JSON contains expected kimi command
if echo "$dry_output" | jq -e '.kimi_command' &>/dev/null; then
  echo "PASS: dry-run JSON has kimi_command field"
  PASS=$((PASS + 1))
else
  echo "FAIL: dry-run JSON missing kimi_command"
  FAIL=$((FAIL + 1))
fi

# Test 6: Swarm mode changes timeout
set +e
swarm_output=$("$KIMI_RUN" --task "test" --mode swarm --dry-run 2>/dev/null)
set -e
swarm_timeout=$(echo "$swarm_output" | jq -r '.timeout')
if [ "$swarm_timeout" = "600" ]; then
  echo "PASS: swarm mode sets timeout to 600"
  PASS=$((PASS + 1))
else
  echo "FAIL: swarm mode timeout is $swarm_timeout, expected 600"
  FAIL=$((FAIL + 1))
fi

# Test 7: Dry-run with --thinking includes --thinking in command
if echo "$dry_output" | jq -r '.kimi_command' | grep -q "thinking"; then
  # Re-run with --thinking to be sure
  set +e
  think_output=$("$KIMI_RUN" --task "test" --thinking --dry-run 2>/dev/null)
  set -e
  if echo "$think_output" | jq -r '.kimi_command' | grep -q "\-\-thinking"; then
    echo "PASS: --thinking appears in kimi_command"
    PASS=$((PASS + 1))
  else
    echo "FAIL: --thinking not in kimi_command"
    FAIL=$((FAIL + 1))
  fi
else
  # Need to test with --thinking explicitly
  set +e
  think_output=$("$KIMI_RUN" --task "test" --thinking --dry-run 2>/dev/null)
  set -e
  if echo "$think_output" | jq -r '.kimi_command' | grep -q "\-\-thinking"; then
    echo "PASS: --thinking appears in kimi_command"
    PASS=$((PASS + 1))
  else
    echo "FAIL: --thinking not in kimi_command"
    FAIL=$((FAIL + 1))
  fi
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
