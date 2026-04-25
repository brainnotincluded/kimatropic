#!/usr/bin/env bash
# ============================================================================
# claude-tmux-bridge.sh — Bridge between Kimi and Claude Code running in tmux
#
# Enables Kimi (or any external agent) to send messages to an interactive
# Claude Code session and read responses back.
#
# Usage:
#   ./claude-tmux-bridge.sh list
#   ./claude-tmux-bridge.sh send <session-name> "<message>"
#   ./claude-tmux-bridge.sh read <session-name> [--wait]
#   ./claude-tmux-bridge.sh exchange <session-name> "<message>"
#   ./claude-tmux-bridge.sh start <session-name> <workdir>
#
# Exit codes:
#   0 — Success
#   1 — Missing arguments, tmux not found, or session not found
#   2 — Timeout waiting for response
# ============================================================================
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default settings
WAIT_POLL_INTERVAL=2
WAIT_STABLE_THRESHOLD=3
WAIT_MAX_TIMEOUT=120

usage() {
  cat <<'USAGE'
Usage: claude-tmux-bridge.sh <command> [args...]

Commands:
  list
    List all tmux sessions and indicate which appear to be running Claude Code.

  send <session-name> "<message>"
    Send a message to the specified tmux session. The message is typed
    character-by-character to avoid shell interpretation issues.

  read <session-name> [--wait]
    Capture the current pane output of the tmux session.
    With --wait, polls until output stabilizes (Claude idle).

  exchange <session-name> "<message>"
    Send a message and wait for the response. Returns the new output
    that appeared after sending the message.

  start <session-name> <workdir>
    Create a new tmux session running Claude Code in the given directory.
    If the session already exists, attaches to it.

  stop <session-name>
    Kill the tmux session.

Options:
  --wait-timeout <secs>   Max seconds to wait for response (default: 120)
  --wait-stable <count>   Consecutive stable polls before considering done (default: 3)
  --help                  Show this help
USAGE
  exit 0
}

# --- Dependency check ---
if ! command -v tmux &>/dev/null; then
  echo '{"error": "tmux not found in PATH. Install: brew install tmux"}' >&2
  exit 1
fi

# --- Helpers ---
_is_claude_session() {
  local session="$1"
  # Check pane command (claude runs as node process)
  local pane_cmd
  pane_cmd=$(tmux list-panes -t "$session" -F '#{pane_current_command}' 2>/dev/null | head -1)
  if echo "$pane_cmd" | grep -qiE "claude|node"; then
    return 0
  fi
  # Check recent output for Claude Code UI patterns
  local pane_output
  pane_output=$(tmux capture-pane -t "$session" -p 2>/dev/null | tail -20)
  if echo "$pane_output" | grep -qiE "claude code|▐▛███▜▌|◉ .* /effort|◉ .* /compact|◉ .* /normal|❯"; then
    return 0
  fi
  return 1
}

_escape_for_tmux() {
  # Escape special characters for tmux send-keys
  local msg="$1"
  # Replace backslash with double backslash
  msg="${msg//\\/\\\\}"
  # Replace quotes with escaped quotes
  msg="${msg//\"/\\\"}"
  # Replace dollar signs to prevent expansion
  msg="${msg//\$/\\$}"
  # Replace semicolons to prevent command chaining
  msg="${msg//;/\\;}"
  printf '%s' "$msg"
}

cmd_list() {
  local sessions
  sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)
  
  if [ -z "$sessions" ]; then
    echo '{"sessions": [], "claude_sessions": []}'
    return
  fi

  local all_sessions=()
  local claude_sessions=()
  
  while IFS= read -r s; do
    [ -z "$s" ] && continue
    all_sessions+=("$s")
    if _is_claude_session "$s"; then
      claude_sessions+=("$s")
    fi
  done <<< "$sessions"

  # Build JSON arrays safely
  local all_json="["
  local first=true
  if [ ${#all_sessions[@]} -gt 0 ]; then
    for s in "${all_sessions[@]}"; do
      if [ "$first" = true ]; then first=false; else all_json+=","; fi
      all_json+="\"$s\""
    done
  fi
  all_json+="]"

  local claude_json="["
  first=true
  if [ ${#claude_sessions[@]} -gt 0 ]; then
    for s in "${claude_sessions[@]}"; do
      if [ "$first" = true ]; then first=false; else claude_json+=","; fi
      claude_json+="\"$s\""
    done
  fi
  claude_json+="]"

  echo "{\"sessions\": $all_json, \"claude_sessions\": $claude_json}"
}

cmd_send() {
  local session="$1"
  local message="$2"

  if ! tmux has-session -t "$session" 2>/dev/null; then
    echo "{\"error\": \"tmux session '$session' not found\"}" >&2
    exit 1
  fi

  # Send the message character by character using tmux send-keys
  # This avoids shell interpretation issues
  printf '%s' "$message" | tmux load-buffer -
  tmux paste-buffer -t "$session" -d
  tmux send-keys -t "$session" Enter

  echo "{\"action\": \"send\", \"session\": \"$session\", \"message_length\": ${#message}}"
}

cmd_read() {
  local session="$1"
  local wait_flag=false

  shift
  while [ $# -gt 0 ]; do
    case "$1" in
      --wait) wait_flag=true; shift ;;
      *) shift ;;
    esac
  done

  if ! tmux has-session -t "$session" 2>/dev/null; then
    echo "{\"error\": \"tmux session '$session' not found\"}" >&2
    exit 1
  fi

  if [ "$wait_flag" = false ]; then
    local output
    output=$(tmux capture-pane -t "$session" -p -S -1000 2>/dev/null || true)
    # Escape for JSON
    output=$(printf '%s' "$output" | jq -R -s '.')
    echo "{\"session\": \"$session\", \"output\": $output}"
    return
  fi

  # Wait mode: poll until output stabilizes
  local prev_output=""
  local stable_count=0
  local start_time
  start_time=$(date +%s)

  echo "{\"status\": \"waiting\", \"session\": \"$session\", \"max_timeout\": $WAIT_MAX_TIMEOUT, \"stable_threshold\": $WAIT_STABLE_THRESHOLD}" >&2

  while true; do
    sleep "$WAIT_POLL_INTERVAL"

    local current_output
    current_output=$(tmux capture-pane -t "$session" -p -S -1000 2>/dev/null || true)

    if [ "$current_output" = "$prev_output" ]; then
      ((stable_count++)) || true
      echo "{\"status\": \"polling\", \"stable_count\": $stable_count, \"elapsed\": $(($(date +%s) - start_time))}" >&2
    else
      stable_count=0
      prev_output="$current_output"
      echo "{\"status\": \"activity_detected\", \"elapsed\": $(($(date +%s) - start_time))}" >&2
    fi

    if [ "$stable_count" -ge "$WAIT_STABLE_THRESHOLD" ]; then
      # Output is stable — Claude is likely idle
      local output_json
      output_json=$(printf '%s' "$current_output" | jq -R -s '.')
      echo "{\"status\": \"ready\", \"session\": \"$session\", \"output\": $output_json, \"elapsed_seconds\": $(($(date +%s) - start_time))}"
      return
    fi

    if [ "$(($(date +%s) - start_time))" -ge "$WAIT_MAX_TIMEOUT" ]; then
      local output_json
      output_json=$(printf '%s' "$current_output" | jq -R -s '.')
      echo "{\"status\": \"timeout\", \"session\": \"$session\", \"output\": $output_json, \"elapsed_seconds\": $WAIT_MAX_TIMEOUT}" >&2
      exit 2
    fi
  done
}

cmd_exchange() {
  local session="$1"
  local message="$2"

  # Record state before sending
  local pre_output
  pre_output=$(tmux capture-pane -t "$session" -p -S -1000 2>/dev/null || true)

  # Send message
  cmd_send "$session" "$message" >/dev/null

  # Wait for response
  local result
  if ! result=$(cmd_read "$session" --wait 2>/dev/null); then
    echo "{\"error\": \"Timeout waiting for response from $session\"}" >&2
    exit 2
  fi

  # Extract the full output and compute the delta
  local full_output
  full_output=$(echo "$result" | jq -r '.output')

  # Simple delta: return the last N lines of output
  # A more sophisticated diff could be implemented, but for tmux interaction
  # the caller usually wants the latest response
  local delta
  delta=$(echo "$full_output" | tail -n 50)
  local delta_json
  delta_json=$(printf '%s' "$delta" | jq -R -s '.')

  echo "{\"action\": \"exchange\", \"session\": \"$session\", \"full_output\": $(echo "$result" | jq '.output'), \"delta\": $delta_json, \"elapsed_seconds\": $(echo "$result" | jq -r '.elapsed_seconds // 0')}"
}

cmd_start() {
  local session="$1"
  local workdir="${2:-$(pwd)}"

  if tmux has-session -t "$session" 2>/dev/null; then
    echo "{\"action\": \"start\", \"session\": \"$session\", \"status\": \"already_exists\", \"workdir\": \"$workdir\"}"
    return
  fi

  if ! command -v claude &>/dev/null; then
    echo "{\"error\": \"claude CLI not found in PATH\"}" >&2
    exit 1
  fi

  tmux new-session -d -s "$session" -c "$workdir" "claude"
  sleep 2

  echo "{\"action\": \"start\", \"session\": \"$session\", \"status\": \"created\", \"workdir\": \"$workdir\"}"
}

cmd_stop() {
  local session="$1"

  if ! tmux has-session -t "$session" 2>/dev/null; then
    echo "{\"error\": \"tmux session '$session' not found\"}" >&2
    exit 1
  fi

  tmux kill-session -t "$session"
  echo "{\"action\": \"stop\", \"session\": \"$session\", \"status\": \"killed\"}"
}

# --- Main dispatch ---
case "${1:-}" in
  list)     cmd_list ;;
  send)     shift; [ $# -ge 2 ] || { usage; exit 1; }; cmd_send "$1" "$2" ;;
  read)     shift; [ $# -ge 1 ] || { usage; exit 1; }; cmd_read "$@" ;;
  exchange) shift; [ $# -ge 2 ] || { usage; exit 1; }; cmd_exchange "$1" "$2" ;;
  start)    shift; [ $# -ge 1 ] || { usage; exit 1; }; cmd_start "$1" "${2:-$(pwd)}" ;;
  stop)     shift; [ $# -ge 1 ] || { usage; exit 1; }; cmd_stop "$1" ;;
  --help|-h|"") usage ;;
  *) echo "Unknown command: $1" >&2; usage; exit 1 ;;
esac
