#!/usr/bin/env bash
# ============================================================================
# kimi-run.sh — Execute a task via Kimi CLI and return a lossy summary JSON
#
# Delegates a task to the Kimi CLI, captures output, detects file changes
# via git, discovers the new Kimi session ID, and emits a structured JSON
# summary on stdout.
#
# Usage:
#   ./kimi-run.sh --task "Implement feature X" [OPTIONS]
#
# Exit codes:
#   0 — Completed (check .status in JSON for success/failed)
#   1 — Invalid arguments or preflight failure
# ============================================================================
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Argument defaults ---
task=""
workdir="$(pwd)"
mode="single"
thinking=false
timeout_secs=300
branch=""
add_dir=""
session=""
dry_run=false

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
    --task)    task="$2"; shift 2 ;;
    --workdir) workdir="$2"; shift 2 ;;
    --mode)    mode="$2"; shift 2 ;;
    --thinking) thinking=true; shift ;;
    --timeout) timeout_secs="$2"; shift 2 ;;
    --branch)  branch="$2"; shift 2 ;;
    --add-dir) add_dir="$2"; shift 2 ;;
    --session) session="$2"; shift 2 ;;
    --dry-run) dry_run=true; shift ;;
    --help)    usage ;;
    *) echo "kimi-run: unknown option: $1" >&2; exit 1 ;;
  esac
done

# Validate required args
if [ -z "$task" ]; then
  echo "kimi-run: --task is required" >&2
  exit 1
fi

# Adjust timeout for swarm mode
if [ "$mode" = "swarm" ] && [ "$timeout_secs" -eq 300 ]; then
  timeout_secs=600
fi

# Resolve timeout and tac commands (macOS uses GNU coreutils with g prefix)
timeout_cmd=$(command -v timeout 2>/dev/null || command -v gtimeout 2>/dev/null || echo "")
tac_cmd=$(command -v tac 2>/dev/null || command -v gtac 2>/dev/null || echo "")

# Run preflight (skip in dry-run mode)
if [ "$dry_run" = false ]; then
  "$SCRIPT_DIR/kimi-preflight.sh" >&2 || exit 1
fi

# Setup worktree if --branch specified (before building command)
if [ -n "$branch" ]; then
  repo_root=$(git -C "$workdir" rev-parse --show-toplevel)
  worktree_path="$repo_root/.worktrees/$branch"
  if [ "$dry_run" = false ]; then
    git -C "$workdir" worktree add "$worktree_path" -b "$branch" 2>/dev/null || \
      git -C "$workdir" worktree add "$worktree_path" "$branch" 2>/dev/null
  fi
  workdir="$worktree_path"
fi

# Build kimi command
kimi_cmd=(kimi --print --work-dir "$workdir")

if [ "$thinking" = true ]; then
  kimi_cmd+=(--thinking)
fi

if [ "$mode" = "swarm" ]; then
  kimi_cmd+=(--max-ralph-iterations -1)
fi

if [ -n "$add_dir" ]; then
  kimi_cmd+=(--add-dir "$add_dir")
fi

if [ -n "$session" ]; then
  kimi_cmd+=(--session "$session")
fi

kimi_cmd+=(-p "$task")

# Dry-run: output planned command as JSON and exit
if [ "$dry_run" = true ]; then
  jq -n \
    --arg cmd "${kimi_cmd[*]}" \
    --arg workdir "$workdir" \
    --arg mode "$mode" \
    --arg timeout "$timeout_secs" \
    --arg branch "$branch" \
    '{kimi_command: $cmd, workdir: $workdir, mode: $mode, timeout: $timeout, branch: $branch}'
  exit 0
fi

# Record pre-existing sessions for this workdir
workdir_abs="$(cd "$workdir" && pwd)"
workdir_hash=$(echo -n "$workdir_abs" | md5 -q 2>/dev/null || echo -n "$workdir_abs" | md5sum | cut -d' ' -f1)
sessions_dir="$HOME/.kimi/sessions/$workdir_hash"
pre_sessions=""
if [ -d "$sessions_dir" ]; then
  pre_sessions=$(ls "$sessions_dir" 2>/dev/null | sort)
fi

# Record git HEAD before Kimi runs (for accurate diff after Kimi may commit)
pre_head=""
if git -C "$workdir" rev-parse --git-dir &>/dev/null; then
  pre_head=$(git -C "$workdir" rev-parse HEAD 2>/dev/null || echo "")
fi

# Execute Kimi
start_time=$(date +%s)
kimi_output=$(mktemp)

# Ensure temp file is cleaned up on exit, even on unexpected failure
cleanup() {
  rm -f "$kimi_output"
}
trap cleanup EXIT

set +e
if [ -n "$timeout_cmd" ]; then
  "$timeout_cmd" "$timeout_secs" "${kimi_cmd[@]}" > "$kimi_output" 2>&1
else
  "${kimi_cmd[@]}" > "$kimi_output" 2>&1
fi
kimi_exit=$?
set -e

end_time=$(date +%s)
wall_time=$((end_time - start_time))

# Determine status
if [ "$kimi_exit" -eq 124 ]; then
  status="failed"
  errors_json='["Timed out after '"$timeout_secs"'s"]'
elif [ "$kimi_exit" -ne 0 ]; then
  status="failed"
  errors_json='["Kimi exited with code '"$kimi_exit"'"]'
else
  status="success"
  errors_json='[]'
fi

# Get file changes from git (ground truth)
# Use pre_head to catch changes even if Kimi committed
files_modified='[]'
files_created='[]'
files_deleted='[]'

if git -C "$workdir" rev-parse --git-dir &>/dev/null && [ -n "$pre_head" ]; then
  # Committed changes (diff pre_head to current HEAD)
  committed_m=$(git -C "$workdir" diff --name-only --diff-filter=M "$pre_head" HEAD 2>/dev/null | jq -R -s 'split("\n") | map(select(length > 0))')
  committed_a=$(git -C "$workdir" diff --name-only --diff-filter=A "$pre_head" HEAD 2>/dev/null | jq -R -s 'split("\n") | map(select(length > 0))')
  committed_d=$(git -C "$workdir" diff --name-only --diff-filter=D "$pre_head" HEAD 2>/dev/null | jq -R -s 'split("\n") | map(select(length > 0))')
  # Uncommitted changes (working tree vs HEAD)
  unstaged_m=$(git -C "$workdir" diff --name-only --diff-filter=M 2>/dev/null | jq -R -s 'split("\n") | map(select(length > 0))')
  untracked=$(git -C "$workdir" ls-files --others --exclude-standard 2>/dev/null | jq -R -s 'split("\n") | map(select(length > 0))')
  # Merge committed + uncommitted
  files_modified=$(jq -n --argjson a "$committed_m" --argjson b "$unstaged_m" '$a + $b | unique')
  files_created=$(jq -n --argjson a "$committed_a" --argjson b "$untracked" '$a + $b | unique')
  files_deleted=$committed_d
fi

# Find new session ID
session_id="unknown"
if [ -d "$sessions_dir" ]; then
  post_sessions=$(ls "$sessions_dir" 2>/dev/null | sort)
  new_session=$(comm -13 <(echo "$pre_sessions") <(echo "$post_sessions") | head -1)
  if [ -n "$new_session" ]; then
    session_id="$new_session"
  fi
fi

# Extract summary from context.jsonl
summary=""
context_file="$sessions_dir/$session_id/context.jsonl"
if [ -f "$context_file" ] && [ -n "$tac_cmd" ]; then
  summary=$("$tac_cmd" "$context_file" | grep -m1 '"role".*"assistant"' | \
    jq -r '[.content[] | select(.type=="text") | .text] | join(" ")' 2>/dev/null | \
    head -c 500)
fi

if [ -z "$summary" ] && [ "$status" = "success" ]; then
  summary="Task completed. Check file changes for details."
fi

# Extract warnings from kimi output
warnings=$(grep -iE '(TODO|FIXME|WARN|WARNING)' "$kimi_output" 2>/dev/null || true)
warnings=$(echo "$warnings" | head -5 | jq -R -s 'split("\n") | map(select(length > 0))')
if [ -z "$warnings" ] || [ "$warnings" = "null" ]; then
  warnings='[]'
fi

# Build final JSON
jq -n \
  --arg status "$status" \
  --argjson files_modified "$files_modified" \
  --argjson files_created "$files_created" \
  --argjson files_deleted "$files_deleted" \
  --arg summary "$summary" \
  --argjson warnings "$warnings" \
  --argjson errors "$errors_json" \
  --arg session_id "$session_id" \
  --arg wall_time "$wall_time" \
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

# Cleanup is handled by the EXIT trap
