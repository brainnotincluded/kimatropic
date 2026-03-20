#!/usr/bin/env bash
# desktop-preflight.sh — Verify desktop control dependencies
set -euo pipefail

OS="$(uname -s)"
errors=()
capabilities=()

# Check python3
if ! command -v python3 &>/dev/null; then
  errors+=("python3 not found in PATH")
else
  # Check pyautogui
  if python3 -c "import pyautogui" 2>/dev/null; then
    capabilities+=("click" "double-click" "right-click" "drag" "scroll" "type" "key" "screenshot")
  else
    errors+=("pyautogui not installed. Run: pip install pyautogui")
  fi

  # Check pygetwindow (bundled with pyautogui on most platforms)
  if python3 -c "import pygetwindow" 2>/dev/null; then
    capabilities+=("window-list" "window-focus" "window-resize")
  else
    errors+=("pygetwindow not installed. Run: pip install pygetwindow")
  fi
fi

# Check ffmpeg (video recording)
if command -v ffmpeg &>/dev/null; then
  capabilities+=("record-start" "record-stop")
else
  errors+=("ffmpeg not found. Video recording unavailable. Install: brew install ffmpeg")
fi

# Check platform-specific permissions
case "$OS" in
  Darwin)
    # macOS: Screen Recording permission is required but can't be checked programmatically
    # Just warn the user
    echo "Note: macOS requires Screen Recording permission for pyautogui screenshots." >&2
    echo "  Grant in: System Settings > Privacy & Security > Screen Recording" >&2
    ;;
esac

# Report errors
if [ ${#errors[@]} -gt 0 ]; then
  echo "Desktop preflight failed:" >&2
  for err in "${errors[@]}"; do
    echo "  - $err" >&2
  done
  exit 1
fi

# Report capabilities
echo "Desktop preflight OK ($(echo "$OS" | tr '[:upper:]' '[:lower:]'))"
echo "Capabilities: ${capabilities[*]}"
exit 0
