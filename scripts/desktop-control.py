#!/usr/bin/env python3
"""desktop-control.py — Cross-platform desktop automation via pyautogui.

Provides a CLI interface for Claude to drive desktop interactions:
click, drag, scroll, type, screenshot, window management, video recording.

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
"""

import argparse
import json
import os
import platform
import signal
import subprocess
import sys
import time

import pyautogui

# Safety: prevent pyautogui from moving to corners to trigger OS failsafes
pyautogui.FAILSAFE = True
# Small pause between actions for stability
pyautogui.PAUSE = 0.1

PIDFILE = os.path.join(os.environ.get("TMPDIR", "/tmp"), "kimatropic-ffmpeg.pid")


def cmd_click(args):
    pyautogui.click(args.x, args.y)
    print(json.dumps({"action": "click", "x": args.x, "y": args.y}))


def cmd_double_click(args):
    pyautogui.doubleClick(args.x, args.y)
    print(json.dumps({"action": "double-click", "x": args.x, "y": args.y}))


def cmd_right_click(args):
    pyautogui.rightClick(args.x, args.y)
    print(json.dumps({"action": "right-click", "x": args.x, "y": args.y}))


def cmd_drag(args):
    duration = args.duration if args.duration else 0.5
    pyautogui.moveTo(args.x1, args.y1)
    pyautogui.drag(args.x2 - args.x1, args.y2 - args.y1, duration=duration)
    print(json.dumps({"action": "drag", "from": [args.x1, args.y1], "to": [args.x2, args.y2]}))


def cmd_scroll(args):
    direction = args.direction.lower()
    amount = args.amount
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
    print(json.dumps({"action": "scroll", "direction": direction, "amount": amount}))


def cmd_type(args):
    pyautogui.typewrite(args.text, interval=0.02)
    print(json.dumps({"action": "type", "length": len(args.text)}))


def cmd_key(args):
    keys = args.combo.split("+")
    pyautogui.hotkey(*keys)
    print(json.dumps({"action": "key", "combo": args.combo}))


def cmd_screenshot(args):
    if args.region:
        parts = [int(x) for x in args.region.split(",")]
        if len(parts) != 4:
            print("Region must be x,y,w,h", file=sys.stderr)
            sys.exit(1)
        img = pyautogui.screenshot(region=(parts[0], parts[1], parts[2], parts[3]))
    else:
        img = pyautogui.screenshot()
    img.save(args.file)
    print(json.dumps({"action": "screenshot", "file": args.file, "size": [img.width, img.height]}))


def cmd_record_start(args):
    system = platform.system()
    if system == "Darwin":
        input_fmt = ["-f", "avfoundation", "-i", "1:none"]
    elif system == "Linux":
        display = os.environ.get("DISPLAY", ":0.0")
        input_fmt = ["-f", "x11grab", "-i", display]
    elif system == "Windows":
        input_fmt = ["-f", "gdigrab", "-i", "desktop"]
    else:
        print(f"Unsupported platform: {system}", file=sys.stderr)
        sys.exit(1)

    cmd = ["ffmpeg", "-y", "-framerate", "30"] + input_fmt + [
        "-c:v", "libx264", "-preset", "ultrafast", "-crf", "23",
        args.file
    ]

    proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    with open(PIDFILE, "w") as f:
        f.write(str(proc.pid))
    print(json.dumps({"action": "record-start", "file": args.file, "pid": proc.pid}))


def cmd_record_stop(args):
    if not os.path.exists(PIDFILE):
        print("No recording in progress", file=sys.stderr)
        sys.exit(1)
    with open(PIDFILE) as f:
        pid = int(f.read().strip())
    try:
        os.kill(pid, signal.SIGINT)
        # Wait briefly for ffmpeg to finalize
        time.sleep(2)
    except ProcessLookupError:
        pass
    os.remove(PIDFILE)
    print(json.dumps({"action": "record-stop", "pid": pid}))


def _get_all_windows():
    """Cross-platform helper to get all windows.

    Returns list of dicts with title, position, size, visible keys.
    On macOS, pygetwindow lacks getAllWindows(), so we use Quartz directly.
    On other platforms, we use pygetwindow.getAllWindows().
    """
    system = platform.system()
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


def cmd_window_list(args):
    try:
        windows = _get_all_windows()
        print(json.dumps(windows, indent=2))
    except ImportError:
        print("pygetwindow not installed", file=sys.stderr)
        sys.exit(1)


def cmd_window_focus(args):
    try:
        import pygetwindow as gw
        # Use getAllTitles on macOS, getAllWindows on other platforms
        if platform.system() == "Darwin":
            titles = [t for t in gw.getAllTitles() if t.strip()]
            matches = [t for t in titles if args.title.lower() in t.lower()]
            if not matches:
                print(json.dumps({"action": "window-focus", "error": f"No window matching '{args.title}'"}))
                sys.exit(1)
            # On macOS, activate() is a module-level function that activates by app name
            # Use AppleScript for reliable window focusing
            subprocess.run([
                "osascript", "-e",
                f'tell application "{matches[0].strip()}" to activate'
            ], capture_output=True)
            print(json.dumps({"action": "window-focus", "title": matches[0].strip()}))
        else:
            matches = [w for w in gw.getAllWindows() if args.title.lower() in w.title.lower()]
            if not matches:
                print(json.dumps({"action": "window-focus", "error": f"No window matching '{args.title}'"}))
                sys.exit(1)
            win = matches[0]
            win.activate()
            print(json.dumps({"action": "window-focus", "title": win.title}))
    except ImportError:
        print("pygetwindow not installed", file=sys.stderr)
        sys.exit(1)


def cmd_window_resize(args):
    try:
        import pygetwindow as gw
        if platform.system() == "Darwin":
            titles = [t for t in gw.getAllTitles() if t.strip()]
            matches = [t for t in titles if args.title.lower() in t.lower()]
            if not matches:
                print(json.dumps({"action": "window-resize", "error": f"No window matching '{args.title}'"}))
                sys.exit(1)
            app_name = matches[0].strip()
            # Use AppleScript for reliable window resizing on macOS
            subprocess.run([
                "osascript", "-e",
                f'tell application "System Events" to tell process "{app_name}" '
                f'to set size of front window to {{{args.w}, {args.h}}}'
            ], capture_output=True)
            print(json.dumps({"action": "window-resize", "title": app_name, "size": [args.w, args.h]}))
        else:
            matches = [w for w in gw.getAllWindows() if args.title.lower() in w.title.lower()]
            if not matches:
                print(json.dumps({"action": "window-resize", "error": f"No window matching '{args.title}'"}))
                sys.exit(1)
            win = matches[0]
            win.resizeTo(args.w, args.h)
            print(json.dumps({"action": "window-resize", "title": win.title, "size": [args.w, args.h]}))
    except ImportError:
        print("pygetwindow not installed", file=sys.stderr)
        sys.exit(1)


def cmd_mouse_position(args):
    pos = pyautogui.position()
    print(json.dumps({"x": pos.x, "y": pos.y}))


def main():
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
