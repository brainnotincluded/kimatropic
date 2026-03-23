#!/usr/bin/env bash
# ============================================================================
# screen-capture.sh — High-level capture workflows for kimatropic
#
# Combines desktop-control.py commands into reusable capture sequences:
# multi-viewport screenshots, timed recordings, scripted interaction flows,
# and full-capture bundles.
#
# Usage:
#   ./screen-capture.sh <command> [args...]
#
# Exit codes:
#   0 — Capture completed successfully
#   1 — Missing arguments or unknown command
# ============================================================================
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly CONTROL="$SCRIPT_DIR/desktop-control.py"

usage() {
  cat <<'USAGE'
Usage: screen-capture.sh <command> [args...]

Commands:
  screenshot-viewports <output-dir>
    Take screenshots at 10 standard viewports (resizes active window).
    Produces: mobile-375x812.png, mobile-large-414x896.png, iphone-se-750x1334.png,
              galaxy-s25-1080x2340.png, ipad-mini-768x1024.png, tablet-landscape-1024x768.png,
              laptop-1366x768.png, fullhd-4x3-1440x1080.png, fullhd-16x9-1920x1080.png,
              fullhd-21x9-1920x823.png

  record-interaction <output-file> <duration-secs>
    Record screen video for N seconds.

  record-flow <script-file> <output-dir>
    Execute a flow script (navigate, click, scroll, type, screenshot, wait commands)
    while taking screenshots at each step.

  capture-full <output-dir>
    Full capture: screenshot-viewports + record 30s interaction.
USAGE
  exit 0
}

screenshot_viewports() {
  local outdir="$1"
  mkdir -p "$outdir"

  # Viewport definitions: name width height
  local viewport_list="
mobile-375x812 375 812
mobile-large-414x896 414 896
iphone-se-750x1334 750 1334
galaxy-s25-1080x2340 1080 2340
ipad-mini-768x1024 768 1024
tablet-landscape-1024x768 1024 768
laptop-1366x768 1366 768
fullhd-4x3-1440x1080 1440 1080
fullhd-16x9-1920x1080 1920 1080
fullhd-21x9-1920x823 1920 823
"

  echo "$viewport_list" | while read -r name w h; do
    # Skip empty lines
    [ -z "$name" ] && continue
    # Get the active window title for resize
    active_title=$(python3 "$CONTROL" window-list 2>/dev/null | python3 -c "
import sys,json
windows = json.load(sys.stdin)
# Pick first visible window (heuristic)
for w in windows:
    if w.get('visible', True) and w['title']:
        print(w['title'])
        break
" 2>/dev/null || echo "")

    if [ -n "$active_title" ]; then
      python3 "$CONTROL" window-resize "$active_title" "$w" "$h" 2>/dev/null || true
      sleep 1
    fi

    python3 "$CONTROL" screenshot "$outdir/${name}.png"
    echo "Captured: $outdir/${name}.png (${w}x${h})"
  done
}

record_interaction() {
  local outfile="$1"
  local duration="$2"

  python3 "$CONTROL" record-start "$outfile"
  echo "Recording for ${duration}s..."
  sleep "$duration"
  python3 "$CONTROL" record-stop
  echo "Saved: $outfile"
}

record_flow() {
  local script_file="$1"
  local outdir="$2"
  local step=0

  mkdir -p "$outdir"

  while IFS= read -r line || [ -n "$line" ]; do
    # Skip comments and empty lines
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue

    # Parse command
    read -r cmd rest <<< "$line"
    case "$cmd" in
      click)
        read -r x y <<< "$rest"
        python3 "$CONTROL" click "$x" "$y"
        ;;
      double-click)
        read -r x y <<< "$rest"
        python3 "$CONTROL" double-click "$x" "$y"
        ;;
      right-click)
        read -r x y <<< "$rest"
        python3 "$CONTROL" right-click "$x" "$y"
        ;;
      drag)
        read -r x1 y1 x2 y2 <<< "$rest"
        python3 "$CONTROL" drag "$x1" "$y1" "$x2" "$y2"
        ;;
      scroll)
        read -r dir amount <<< "$rest"
        python3 "$CONTROL" scroll "$dir" "$amount"
        ;;
      type)
        python3 "$CONTROL" type "$rest"
        ;;
      key)
        python3 "$CONTROL" key "$rest"
        ;;
      screenshot)
        python3 "$CONTROL" screenshot "$outdir/$rest"
        ;;
      wait)
        sleep "$rest"
        ;;
      record-start)
        python3 "$CONTROL" record-start "$outdir/$rest"
        ;;
      record-stop)
        python3 "$CONTROL" record-stop
        ;;
      window-focus)
        python3 "$CONTROL" window-focus "$rest"
        ;;
      navigate)
        # Open URL in default browser (cross-platform)
        case "$(uname -s)" in
          Darwin) open "$rest" ;;
          Linux) xdg-open "$rest" ;;
          *) start "$rest" ;;
        esac
        sleep 2
        ;;
      window-resize)
        read -r title w h <<< "$rest"
        python3 "$CONTROL" window-resize "$title" "$w" "$h"
        ;;
      *)
        echo "Unknown flow command: $cmd" >&2
        ;;
    esac

    ((step++)) || true
    echo "Step $step: $cmd $rest"
  done < "$script_file"

  echo "Flow complete: $step steps executed"
}

capture_full() {
  local outdir="$1"
  mkdir -p "$outdir"

  echo "=== Capturing viewports ==="
  screenshot_viewports "$outdir"

  echo ""
  echo "=== Recording 30s interaction ==="
  record_interaction "$outdir/interaction.mp4" 30

  echo ""
  echo "Full capture saved to: $outdir"
  ls -la "$outdir"
}

# Main dispatch
case "${1:-}" in
  screenshot-viewports) screenshot_viewports "$2" ;;
  record-interaction) record_interaction "$2" "$3" ;;
  record-flow) record_flow "$2" "$3" ;;
  capture-full) capture_full "$2" ;;
  --help|-h|"") usage ;;
  *) echo "Unknown command: $1" >&2; usage ;;
esac
