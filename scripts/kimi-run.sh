#!/usr/bin/env bash
# kimi-run.sh — Execute a task via Kimi CLI and return a lossy summary JSON
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Defaults
TASK=""
WORKDIR="$(pwd)"
MODE="single"
THINKING=false
TIMEOUT=300
BRANCH=""
ADD_DIR=""
SESSION=""
DRY_RUN=false

usage() {
  cat <<'USAGE'
Usage: kimi-run.sh --task "..." [OPTIONS]

Options:
  --task "..."        Task prompt for Kimi (required)
  --workdir <path>    Working directory (default: current dir)
  --mode <single|swarm>  Execution mode (default: single)
  --thinking          Enable thinking mode
  --timeout <secs>    Timeout in seconds (default: 300, swarm: 600)
  --branch <name>     Create git worktree for isolation
  --add-dir <path>    Additional directory for Kimi workspace
  --session <id>      Resume a previous Kimi session (for retries)
  --dry-run           Print planned command as JSON, don't execute
  --help              Show this help
USAGE
  exit 0
}

# Parse arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --task) TASK="$2"; shift 2 ;;
    --workdir) WORKDIR="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --thinking) THINKING=true; shift ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --add-dir) ADD_DIR="$2"; shift 2 ;;
    --session) SESSION="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --help) usage ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Validate required args
if [ -z "$TASK" ]; then
  echo "Error: --task is required" >&2
  exit 1
fi

# Adjust timeout for swarm mode
if [ "$MODE" = "swarm" ] && [ "$TIMEOUT" -eq 300 ]; then
  TIMEOUT=600
fi

# Resolve timeout and tac commands (macOS uses GNU coreutils with g prefix)
TIMEOUT_CMD=$(command -v timeout 2>/dev/null || command -v gtimeout 2>/dev/null || echo "")
TAC_CMD=$(command -v tac 2>/dev/null || command -v gtac 2>/dev/null || echo "")

# Run preflight (skip in dry-run mode)
if [ "$DRY_RUN" = false ]; then
  "$SCRIPT_DIR/kimi-preflight.sh" || exit 1
fi

# Setup worktree if --branch specified (before building command)
if [ -n "$BRANCH" ]; then
  REPO_ROOT=$(git -C "$WORKDIR" rev-parse --show-toplevel)
  WORKTREE_PATH="$REPO_ROOT/.worktrees/$BRANCH"
  if [ "$DRY_RUN" = false ]; then
    git -C "$WORKDIR" worktree add "$WORKTREE_PATH" -b "$BRANCH" 2>/dev/null || \
      git -C "$WORKDIR" worktree add "$WORKTREE_PATH" "$BRANCH" 2>/dev/null
  fi
  WORKDIR="$WORKTREE_PATH"
fi

# Build kimi command
KIMI_CMD=(kimi --print --work-dir "$WORKDIR")

if [ "$THINKING" = true ]; then
  KIMI_CMD+=(--thinking)
fi

if [ "$MODE" = "swarm" ]; then
  KIMI_CMD+=(--max-ralph-iterations -1)
fi

if [ -n "$ADD_DIR" ]; then
  KIMI_CMD+=(--add-dir "$ADD_DIR")
fi

if [ -n "$SESSION" ]; then
  KIMI_CMD+=(--session "$SESSION")
fi

KIMI_CMD+=(-p "$TASK")

# Dry-run: output planned command as JSON and exit
if [ "$DRY_RUN" = true ]; then
  jq -n \
    --arg cmd "${KIMI_CMD[*]}" \
    --arg workdir "$WORKDIR" \
    --arg mode "$MODE" \
    --arg timeout "$TIMEOUT" \
    --arg branch "$BRANCH" \
    '{kimi_command: $cmd, workdir: $workdir, mode: $mode, timeout: $timeout, branch: $branch}'
  exit 0
fi

# Record pre-existing sessions for this workdir
WORKDIR_ABS="$(cd "$WORKDIR" && pwd)"
WORKDIR_HASH=$(echo -n "$WORKDIR_ABS" | md5 -q 2>/dev/null || echo -n "$WORKDIR_ABS" | md5sum | cut -d' ' -f1)
SESSIONS_DIR="$HOME/.kimi/sessions/$WORKDIR_HASH"
PRE_SESSIONS=""
if [ -d "$SESSIONS_DIR" ]; then
  PRE_SESSIONS=$(ls "$SESSIONS_DIR" 2>/dev/null | sort)
fi

# Record git HEAD before Kimi runs (for accurate diff after Kimi may commit)
PRE_HEAD=""
if git -C "$WORKDIR" rev-parse --git-dir &>/dev/null; then
  PRE_HEAD=$(git -C "$WORKDIR" rev-parse HEAD 2>/dev/null || echo "")
fi

# Execute Kimi
START_TIME=$(date +%s)
KIMI_OUTPUT=$(mktemp)

set +e
if [ -n "$TIMEOUT_CMD" ]; then
  "$TIMEOUT_CMD" "$TIMEOUT" "${KIMI_CMD[@]}" > "$KIMI_OUTPUT" 2>&1
else
  "${KIMI_CMD[@]}" > "$KIMI_OUTPUT" 2>&1
fi
KIMI_EXIT=$?
set -e

END_TIME=$(date +%s)
WALL_TIME=$((END_TIME - START_TIME))

# Determine status
if [ "$KIMI_EXIT" -eq 124 ]; then
  # timeout killed it
  STATUS="failed"
  ERRORS='["Timed out after '"$TIMEOUT"'s"]'
elif [ "$KIMI_EXIT" -ne 0 ]; then
  STATUS="failed"
  ERRORS='["Kimi exited with code '"$KIMI_EXIT"'"]'
else
  STATUS="success"
  ERRORS='[]'
fi

# Get file changes from git (ground truth)
# Use PRE_HEAD to catch changes even if Kimi committed
FILES_MODIFIED='[]'
FILES_CREATED='[]'
FILES_DELETED='[]'

if git -C "$WORKDIR" rev-parse --git-dir &>/dev/null && [ -n "$PRE_HEAD" ]; then
  # Committed changes (diff PRE_HEAD to current HEAD)
  COMMITTED_M=$(git -C "$WORKDIR" diff --name-only --diff-filter=M "$PRE_HEAD" HEAD 2>/dev/null | jq -R -s 'split("\n") | map(select(length > 0))')
  COMMITTED_A=$(git -C "$WORKDIR" diff --name-only --diff-filter=A "$PRE_HEAD" HEAD 2>/dev/null | jq -R -s 'split("\n") | map(select(length > 0))')
  COMMITTED_D=$(git -C "$WORKDIR" diff --name-only --diff-filter=D "$PRE_HEAD" HEAD 2>/dev/null | jq -R -s 'split("\n") | map(select(length > 0))')
  # Uncommitted changes (working tree vs HEAD)
  UNSTAGED_M=$(git -C "$WORKDIR" diff --name-only --diff-filter=M 2>/dev/null | jq -R -s 'split("\n") | map(select(length > 0))')
  UNTRACKED=$(git -C "$WORKDIR" ls-files --others --exclude-standard 2>/dev/null | jq -R -s 'split("\n") | map(select(length > 0))')
  # Merge committed + uncommitted
  FILES_MODIFIED=$(jq -n --argjson a "$COMMITTED_M" --argjson b "$UNSTAGED_M" '$a + $b | unique')
  FILES_CREATED=$(jq -n --argjson a "$COMMITTED_A" --argjson b "$UNTRACKED" '$a + $b | unique')
  FILES_DELETED=$COMMITTED_D
fi

# Find new session ID
SESSION_ID="unknown"
if [ -d "$SESSIONS_DIR" ]; then
  POST_SESSIONS=$(ls "$SESSIONS_DIR" 2>/dev/null | sort)
  NEW_SESSION=$(comm -13 <(echo "$PRE_SESSIONS") <(echo "$POST_SESSIONS") | head -1)
  if [ -n "$NEW_SESSION" ]; then
    SESSION_ID="$NEW_SESSION"
  fi
fi

# Extract summary from context.jsonl
SUMMARY=""
CONTEXT_FILE="$SESSIONS_DIR/$SESSION_ID/context.jsonl"
if [ -f "$CONTEXT_FILE" ] && [ -n "$TAC_CMD" ]; then
  SUMMARY=$("$TAC_CMD" "$CONTEXT_FILE" | grep -m1 '"role".*"assistant"' | \
    jq -r '[.content[] | select(.type=="text") | .text] | join(" ")' 2>/dev/null | \
    head -c 500)
fi

if [ -z "$SUMMARY" ] && [ "$STATUS" = "success" ]; then
  SUMMARY="Task completed. Check file changes for details."
fi

# Extract warnings from kimi output
WARNINGS=$(grep -iE '(TODO|FIXME|WARN|WARNING)' "$KIMI_OUTPUT" 2>/dev/null | head -5 | jq -R -s 'split("\n") | map(select(length > 0))')
if [ -z "$WARNINGS" ] || [ "$WARNINGS" = "null" ]; then
  WARNINGS='[]'
fi

# Build final JSON
jq -n \
  --arg status "$STATUS" \
  --argjson files_modified "$FILES_MODIFIED" \
  --argjson files_created "$FILES_CREATED" \
  --argjson files_deleted "$FILES_DELETED" \
  --arg summary "$SUMMARY" \
  --argjson warnings "$WARNINGS" \
  --argjson errors "$ERRORS" \
  --arg session_id "$SESSION_ID" \
  --arg wall_time "$WALL_TIME" \
  '{
    status: $status,
    files_modified: $files_modified,
    files_created: $files_created,
    files_deleted: $files_deleted,
    summary: $summary,
    warnings: $warnings,
    errors: $errors,
    kimi_session_id: $session_id,
    wall_time_seconds: ($wall_time | tonumber)
  }'

# Cleanup
rm -f "$KIMI_OUTPUT"
