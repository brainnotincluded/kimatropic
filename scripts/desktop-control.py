#!/usr/bin/env python3
"""Cross-platform desktop automation via pyautogui.

Provides a CLI interface for Claude to drive desktop interactions:
click, drag, scroll, type, screenshot, window management, video recording.

Each command emits a JSON result on stdout describing the action taken,
making it easy to chain into higher-level orchestration scripts.

Usage:
    python3 desktop-control.py <command> [args...]

Commands:
    click <x> <y>                        Click at coordinates
    double-click <x> <y>                 Double-click at coordinates
    right-click <x> <y>                  Right-click at coordinates
    drag <x1> <y1> <x2> <y2> [--duration N]  Drag from (x1,y1) to (x2,y2)
    scroll <direction> <amount>          Scroll up/down/left/right by amount
    type <text>                          Type text string
    key <combo>                          Press key combination (e.g. ctrl+c)
    screenshot <file> [--region x,y,w,h] Take screenshot
    record-start <file>                  Start video recording (ffmpeg)
    record-stop                          Stop video recording
    window-list                          List windows as JSON
    window-focus <title>                 Focus window by title substring
    window-resize <title> <w> <h>        Resize window
    mouse-position                       Print current mouse x,y

Exit codes:
    0 — Success
    1 — Command-specific error (invalid args, missing window, etc.)
    2 — No command specified
"""

from __future__ import annotations

import argparse
import json
import os
import platform
import signal
import subprocess
import sys
import time
import tempfile
from typing import Any

import pyautogui

__version__ = "0.3.0"

# Safety: prevent pyautogui from moving to corners to trigger OS failsafes
pyautogui.FAILSAFE = True
# Small pause between actions for stability
pyautogui.PAUSE = 0.1

PIDFILE = os.path.join(os.environ.get("TMPDIR", "/tmp"), "kimatropic-ffmpeg.pid")


def _emit(result: dict[str, Any]) -> None:
    """Print a JSON result to stdout."""
    print(json.dumps(result))


def _screenshot_macos(file_path: str, region: tuple[int, int, int, int] | None = None) -> tuple[int, int]:
    """Take a screenshot on macOS using screencapture CLI.
    
    Returns (width, height) of the captured image.
    Raises RuntimeError if screencapture fails (e.g., missing Screen Recording permission).
    """
    cmd = ["screencapture"]
    if region:
        x, y, w, h = region
        cmd.extend(["-R", f"{x},{y},{w},{h}"])
    cmd.append("-x")  # no sound
    cmd.append(file_path)
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        err = result.stderr.strip() if result.stderr else "unknown error"
        if "could not create image" in err.lower() or result.returncode == 1:
            raise RuntimeError(
                "Screen Recording permission required. "
                "Grant it in: System Settings > Privacy & Security > Screen Recording, "
                "then restart your terminal."
            )
        raise RuntimeError(f"screencapture failed: {err}")
    
    # Verify the file is a valid image and get its dimensions
    try:
        from PIL import Image
        with Image.open(file_path) as img:
            return img.width, img.height
    except Exception as e:
        raise RuntimeError(f"Screenshot file invalid: {e}")


def _screenshot_fallback(file_path: str, region: tuple[int, int, int, int] | None = None) -> tuple[int, int]:
    """Fallback screenshot using pyautogui/PIL."""
    if region:
        img = pyautogui.screenshot(region=region)
    else:
        img = pyautogui.screenshot()
    img.save(file_path)
    return img.width, img.height


def cmd_click(args: argparse.Namespace) -> None:
    """Click at the given (x, y) coordinates."""
    pyautogui.click(args.x, args.y)
    _emit({"action": "click", "x": args.x, "y": args.y})


def cmd_double_click(args: argparse.Namespace) -> None:
    """Double-click at the given (x, y) coordinates."""
    pyautogui.doubleClick(args.x, args.y)
    _emit({"action": "double-click", "x": args.x, "y": args.y})


def cmd_right_click(args: argparse.Namespace) -> None:
    """Right-click at the given (x, y) coordinates."""
    pyautogui.rightClick(args.x, args.y)
    _emit({"action": "right-click", "x": args.x, "y": args.y})


def cmd_drag(args: argparse.Namespace) -> None:
    """Drag from (x1, y1) to (x2, y2) with optional duration."""
    duration: float = args.duration if args.duration else 0.5
    pyautogui.moveTo(args.x1, args.y1)
    pyautogui.drag(args.x2 - args.x1, args.y2 - args.y1, duration=duration)
    _emit({"action": "drag", "from": [args.x1, args.y1], "to": [args.x2, args.y2]})


def cmd_scroll(args: argparse.Namespace) -> None:
    """Scroll in the given direction by the specified amount."""
    direction: str = args.direction.lower()
    amount: int = args.amount
    if direction == "up":
        pyautogui.scroll(amount)
    elif direction == "down":
        pyautogui.scroll(-amount)
    elif direction == "left":
        pyautogui.hscroll(-amount)
    elif direction == "right":
        pyautogui.hscroll(amount)
    else:
        print(f"Unknown direction: {direction}", file=sys.stderr)
        sys.exit(1)
    _emit({"action": "scroll", "direction": direction, "amount": amount})


def cmd_type(args: argparse.Namespace) -> None:
    """Type a text string character by character."""
    pyautogui.typewrite(args.text, interval=0.02)
    _emit({"action": "type", "length": len(args.text)})


def cmd_key(args: argparse.Namespace) -> None:
    """Press a key combination (e.g. ctrl+c)."""
    keys: list[str] = args.combo.split("+")
    pyautogui.hotkey(*keys)
    _emit({"action": "key", "combo": args.combo})


def cmd_screenshot(args: argparse.Namespace) -> None:
    """Take a screenshot, optionally restricted to a region."""
    region: tuple[int, int, int, int] | None = None
    if args.region:
        parts: list[int] = [int(x) for x in args.region.split(",")]
        if len(parts) != 4:
            print("Region must be x,y,w,h", file=sys.stderr)
            sys.exit(1)
        region = (parts[0], parts[1], parts[2], parts[3])
    
    system = platform.system()
    try:
        if system == "Darwin":
            width, height = _screenshot_macos(args.file, region)
        else:
            width, height = _screenshot_fallback(args.file, region)
        _emit({"action": "screenshot", "file": args.file, "size": [width, height]})
    except RuntimeError as e:
        _emit({"action": "screenshot", "error": str(e), "file": args.file})
        sys.exit(1)


def cmd_record_start(args: argparse.Namespace) -> None:
    """Start an ffmpeg screen recording in the background."""
    system: str = platform.system()
    if system == "Darwin":
        input_fmt = ["-f", "avfoundation", "-i", "1:none"]
    elif system == "Linux":
        display: str = os.environ.get("DISPLAY", ":0.0")
        input_fmt = ["-f", "x11grab", "-i", display]
    elif system == "Windows":
        input_fmt = ["-f", "gdigrab", "-i", "desktop"]
    else:
        print(f"Unsupported platform: {system}", file=sys.stderr)
        sys.exit(1)

    ffmpeg_cmd: list[str] = ["ffmpeg", "-y", "-framerate", "30"] + input_fmt + [
        "-c:v", "libx264", "-preset", "ultrafast", "-crf", "23",
        args.file,
    ]

    proc = subprocess.Popen(ffmpeg_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    with open(PIDFILE, "w") as f:
        f.write(str(proc.pid))
    _emit({"action": "record-start", "file": args.file, "pid": proc.pid})


def cmd_record_stop(args: argparse.Namespace) -> None:
    """Stop a running ffmpeg screen recording."""
    if not os.path.exists(PIDFILE):
        print("No recording in progress", file=sys.stderr)
        sys.exit(1)
    with open(PIDFILE) as f:
        pid: int = int(f.read().strip())
    try:
        os.kill(pid, signal.SIGINT)
        # Wait briefly for ffmpeg to finalize
        time.sleep(2)
    except ProcessLookupError:
        pass
    os.remove(PIDFILE)
    _emit({"action": "record-stop", "pid": pid})


def _get_all_windows() -> list[dict[str, Any]]:
    """Return a list of visible windows with title, position, size, and visibility.

    On macOS, pygetwindow lacks getAllWindows(), so we use the Quartz
    framework directly. On other platforms, we fall back to pygetwindow.
    """
    system: str = platform.system()
    if system == "Darwin":
        try:
            from Quartz import (CGWindowListCopyWindowInfo,
                                kCGWindowListOptionOnScreenOnly,
                                kCGNullWindowID)
            wl = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID)
            windows = []
            for w in wl:
                title = w.get("kCGWindowOwnerName", "")
                wname = w.get("kCGWindowName", "")
                display_title = f"{title} - {wname}" if wname else title
                if not display_title:
                    continue
                bounds = w.get("kCGWindowBounds", {})
                windows.append({
                    "title": display_title,
                    "position": [int(bounds.get("X", 0)), int(bounds.get("Y", 0))],
                    "size": [int(bounds.get("Width", 0)), int(bounds.get("Height", 0))],
                    "visible": bool(w.get("kCGWindowIsOnscreen", False)),
                })
            return windows
        except ImportError:
            pass
    # Fallback: pygetwindow (works on Windows/Linux)
    import pygetwindow as gw
    windows = []
    for w in gw.getAllWindows():
        if w.title:
            windows.append({
                "title": w.title,
                "position": [w.left, w.top],
                "size": [w.width, w.height],
                "visible": w.visible if hasattr(w, 'visible') else True,
            })
    return windows


def cmd_window_list(args: argparse.Namespace) -> None:
    """List all visible windows as JSON."""
    try:
        windows: list[dict[str, Any]] = _get_all_windows()
        print(json.dumps(windows, indent=2))
    except ImportError:
        print("pygetwindow not installed", file=sys.stderr)
        sys.exit(1)


def _macos_find_process(title: str) -> str | None:
    """Find the best-matching process name on macOS for window focus/resize."""
    windows = _get_all_windows()
    # Exact match first
    for w in windows:
        owner = w["title"].split(" - ")[0] if " - " in w["title"] else w["title"]
        if title.lower() == w["title"].lower() or title.lower() == owner.lower():
            return owner
    # Substring match
    for w in windows:
        owner = w["title"].split(" - ")[0] if " - " in w["title"] else w["title"]
        if title.lower() in w["title"].lower() or title.lower() in owner.lower():
            return owner
    return None


def cmd_window_focus(args: argparse.Namespace) -> None:
    """Focus a window by title substring match."""
    try:
        if platform.system() == "Darwin":
            app_name = _macos_find_process(args.title)
            if not app_name:
                _emit({"action": "window-focus", "error": f"No window matching '{args.title}'"})
                sys.exit(1)
            # Use AppleScript for reliable window focusing on macOS
            result = subprocess.run([
                "osascript", "-e",
                f'tell application "System Events" to set frontmost of process "{app_name}" to true'
            ], capture_output=True, text=True, check=False)
            if result.returncode != 0:
                # Fallback: try tell application directly
                subprocess.run([
                    "osascript", "-e",
                    f'tell application "{app_name}" to activate'
                ], capture_output=True, check=False)
            _emit({"action": "window-focus", "title": app_name})
        else:
            import pygetwindow as gw
            win_matches = [w for w in gw.getAllWindows() if args.title.lower() in w.title.lower()]
            if not win_matches:
                _emit({"action": "window-focus", "error": f"No window matching '{args.title}'"})
                sys.exit(1)
            win = win_matches[0]
            win.activate()
            _emit({"action": "window-focus", "title": win.title})
    except ImportError:
        print("pygetwindow not installed", file=sys.stderr)
        sys.exit(1)


def cmd_window_resize(args: argparse.Namespace) -> None:
    """Resize a window by title substring match."""
    try:
        if platform.system() == "Darwin":
            app_name = _macos_find_process(args.title)
            if not app_name:
                _emit({"action": "window-resize", "error": f"No window matching '{args.title}'"})
                sys.exit(1)
            # Use AppleScript for reliable window resizing on macOS
            script = (
                f'tell application "System Events" to tell process "{app_name}" '
                f'to set size of front window to {{{args.w}, {args.h}}}'
            )
            result = subprocess.run(["osascript", "-e", script], capture_output=True, text=True, check=False)
            if result.returncode != 0:
                # Try alternative: set bounds of front window
                script2 = (
                    f'tell application "System Events" to tell process "{app_name}" '
                    f'to set bounds of front window to {{0, 0, {args.w}, {args.h}}}'
                )
                subprocess.run(["osascript", "-e", script2], capture_output=True, text=True, check=False)
            _emit({"action": "window-resize", "title": app_name, "size": [args.w, args.h]})
        else:
            import pygetwindow as gw
            win_matches = [w for w in gw.getAllWindows() if args.title.lower() in w.title.lower()]
            if not win_matches:
                _emit({"action": "window-resize", "error": f"No window matching '{args.title}'"})
                sys.exit(1)
            win = win_matches[0]
            win.resizeTo(args.w, args.h)
            _emit({"action": "window-resize", "title": win.title, "size": [args.w, args.h]})
    except ImportError:
        print("pygetwindow not installed", file=sys.stderr)
        sys.exit(1)


def cmd_mouse_position(args: argparse.Namespace) -> None:
    """Print the current mouse cursor position."""
    pos = pyautogui.position()
    _emit({"x": pos.x, "y": pos.y})


def main() -> None:
    """Parse CLI arguments and dispatch to the appropriate command handler."""
    parser = argparse.ArgumentParser(
        description="Cross-platform desktop automation for kimatropic",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    subparsers = parser.add_subparsers(dest="command")

    # click
    p = subparsers.add_parser("click")
    p.add_argument("x", type=int)
    p.add_argument("y", type=int)
    p.set_defaults(func=cmd_click)

    # double-click
    p = subparsers.add_parser("double-click")
    p.add_argument("x", type=int)
    p.add_argument("y", type=int)
    p.set_defaults(func=cmd_double_click)

    # right-click
    p = subparsers.add_parser("right-click")
    p.add_argument("x", type=int)
    p.add_argument("y", type=int)
    p.set_defaults(func=cmd_right_click)

    # drag
    p = subparsers.add_parser("drag")
    p.add_argument("x1", type=int)
    p.add_argument("y1", type=int)
    p.add_argument("x2", type=int)
    p.add_argument("y2", type=int)
    p.add_argument("--duration", type=float, default=0.5)
    p.set_defaults(func=cmd_drag)

    # scroll
    p = subparsers.add_parser("scroll")
    p.add_argument("direction", choices=["up", "down", "left", "right"])
    p.add_argument("amount", type=int)
    p.set_defaults(func=cmd_scroll)

    # type
    p = subparsers.add_parser("type")
    p.add_argument("text")
    p.set_defaults(func=cmd_type)

    # key
    p = subparsers.add_parser("key")
    p.add_argument("combo")
    p.set_defaults(func=cmd_key)

    # screenshot
    p = subparsers.add_parser("screenshot")
    p.add_argument("file")
    p.add_argument("--region", default=None, help="x,y,w,h")
    p.set_defaults(func=cmd_screenshot)

    # record-start
    p = subparsers.add_parser("record-start")
    p.add_argument("file")
    p.set_defaults(func=cmd_record_start)

    # record-stop
    p = subparsers.add_parser("record-stop")
    p.set_defaults(func=cmd_record_stop)

    # window-list
    p = subparsers.add_parser("window-list")
    p.set_defaults(func=cmd_window_list)

    # window-focus
    p = subparsers.add_parser("window-focus")
    p.add_argument("title")
    p.set_defaults(func=cmd_window_focus)

    # window-resize
    p = subparsers.add_parser("window-resize")
    p.add_argument("title")
    p.add_argument("w", type=int)
    p.add_argument("h", type=int)
    p.set_defaults(func=cmd_window_resize)

    # mouse-position
    p = subparsers.add_parser("mouse-position")
    p.set_defaults(func=cmd_mouse_position)

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(2)

    args.func(args)


if __name__ == "__main__":
    main()
