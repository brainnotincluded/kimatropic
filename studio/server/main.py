"""
Kimatropic Studio -- FastAPI backend for UI component review.

Serves the React frontend, manages a review queue in memory,
and pushes real-time updates over Socket.IO.
"""

import os
import uuid
from datetime import datetime, timezone
from typing import List, Optional
from pathlib import Path

from fastapi import FastAPI, File, Form, UploadFile, HTTPException, Request
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware
import socketio
import aiofiles

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
BASE_DIR = Path(__file__).resolve().parent
UPLOADS_DIR = BASE_DIR / "uploads"
FRONTEND_DIST_DIR = BASE_DIR.parent / "frontend" / "dist"

UPLOADS_DIR.mkdir(parents=True, exist_ok=True)

# ---------------------------------------------------------------------------
# In-memory queue
# ---------------------------------------------------------------------------
queue_items: List[dict] = []
_demo_seeded = False


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def get_demo_items() -> List[dict]:
    return [
        {
            "id": str(uuid.uuid4()),
            "component_name": "Button Component",
            "screenshot_path": "",
            "code_snippet": (
                '<div style="display: flex; gap: 12px; align-items: center; padding: 20px;">\n'
                '  <button style="padding: 10px 20px; border-radius: 8px; border: none; '
                'background: linear-gradient(135deg, #7C6EF6, #5B9CF6); color: white; '
                'font-weight: 500; font-size: 14px; cursor: pointer; '
                'box-shadow: 0 2px 8px rgba(124,110,246,0.25);">Primary</button>\n'
                '  <button style="padding: 10px 20px; border-radius: 8px; border: 1px solid #E4E3F1; '
                'background: white; color: #2D2B42; font-weight: 500; font-size: 14px; '
                'cursor: pointer;">Secondary</button>\n'
                '  <button style="padding: 10px 20px; border-radius: 8px; border: none; '
                'background: #5CC99B; color: #1A3D2E; font-weight: 500; font-size: 14px; '
                'cursor: pointer;">Success</button>\n'
                '  <button style="padding: 10px 20px; border-radius: 8px; border: none; '
                'background: #E8677A; color: white; font-weight: 500; font-size: 14px; '
                'cursor: pointer;">Danger</button>\n'
                '</div>'
            ),
            "viewport": "1200x800",
            "status": "pending",
            "feedback_history": [],
            "created_at": _now_iso(),
        },
        {
            "id": str(uuid.uuid4()),
            "component_name": "Card Layout",
            "screenshot_path": "",
            "code_snippet": (
                '<div style="max-width: 400px; padding: 24px; background: white; '
                'border-radius: 12px; border: 1px solid #E4E3F1; '
                'box-shadow: 0 1px 3px rgba(124,110,246,0.08); font-family: sans-serif;">\n'
                '  <div style="width: 100%; height: 180px; background: linear-gradient(135deg, #F5F3FF, #EBF2FF); '
                'border-radius: 8px; margin-bottom: 16px; display: flex; align-items: center; '
                'justify-content: center; color: #8B89A3; font-size: 14px;">Image Placeholder</div>\n'
                '  <h3 style="margin: 0 0 8px; color: #2D2B42; font-size: 18px; font-weight: 600;">Card Title</h3>\n'
                '  <p style="margin: 0 0 16px; color: #8B89A3; font-size: 14px; line-height: 1.5;">'
                'This is a sample card component with a pastel design system.</p>\n'
                '  <div style="display: flex; gap: 8px;">\n'
                '    <span style="padding: 4px 10px; border-radius: 20px; background: #E8F8F0; '
                'color: #5CC99B; font-size: 12px; font-weight: 500;">Tag 1</span>\n'
                '    <span style="padding: 4px 10px; border-radius: 20px; background: #F5F3FF; '
                'color: #7C6EF6; font-size: 12px; font-weight: 500;">Tag 2</span>\n'
                '  </div>\n'
                '</div>'
            ),
            "viewport": "768x1024",
            "status": "pending",
            "feedback_history": [],
            "created_at": _now_iso(),
        },
        {
            "id": str(uuid.uuid4()),
            "component_name": "Navigation Bar",
            "screenshot_path": "",
            "code_snippet": (
                '<nav style="height: 56px; background: white; border-bottom: 1px solid #E4E3F1; '
                'display: flex; align-items: center; padding: 0 24px; font-family: sans-serif; '
                'box-shadow: 0 1px 3px rgba(124,110,246,0.08);">\n'
                '  <span style="font-weight: 600; font-size: 16px; '
                'background: linear-gradient(135deg, #7C6EF6, #5B9CF6); '
                '-webkit-background-clip: text; -webkit-text-fill-color: transparent;">AppName</span>\n'
                '  <div style="margin-left: auto; display: flex; gap: 24px; font-size: 14px;">\n'
                '    <a href="#" style="color: #7C6EF6; text-decoration: none; font-weight: 500;">Dashboard</a>\n'
                '    <a href="#" style="color: #8B89A3; text-decoration: none;">Settings</a>\n'
                '    <a href="#" style="color: #8B89A3; text-decoration: none;">Profile</a>\n'
                '  </div>\n'
                '  <div style="margin-left: 24px; width: 32px; height: 32px; border-radius: 50%; '
                'background: linear-gradient(135deg, #7C6EF6, #5B9CF6); display: flex; '
                'align-items: center; justify-content: center; color: white; font-size: 13px; '
                'font-weight: 600;">K</div>\n'
                '</nav>'
            ),
            "viewport": "1920x1080",
            "status": "pending",
            "feedback_history": [],
            "created_at": _now_iso(),
        },
    ]


# ---------------------------------------------------------------------------
# Socket.IO
# ---------------------------------------------------------------------------
sio = socketio.AsyncServer(
    async_mode="asgi",
    cors_allowed_origins="*",
)

# ---------------------------------------------------------------------------
# FastAPI app
# ---------------------------------------------------------------------------
app = FastAPI(title="Kimatropic Studio API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Serve uploaded files
app.mount("/uploads", StaticFiles(directory=str(UPLOADS_DIR)), name="uploads")


# ---------------------------------------------------------------------------
# API routes
# ---------------------------------------------------------------------------
@app.get("/api/queue")
async def get_queue() -> JSONResponse:
    global queue_items, _demo_seeded
    if not queue_items and not _demo_seeded:
        queue_items = get_demo_items()
        _demo_seeded = True
    return JSONResponse(content={"items": queue_items})


@app.post("/api/queue")
async def create_queue_item(request: Request) -> JSONResponse:
    global queue_items
    body = await request.json()

    for field in ("component_name",):
        if field not in body:
            raise HTTPException(status_code=400, detail=f"Missing required field: {field}")

    new_item = {
        "id": str(uuid.uuid4()),
        "screenshot_path": body.get("screenshot_path", ""),
        "component_name": body["component_name"],
        "code_snippet": body.get("code_snippet", ""),
        "viewport": body.get("viewport", "1200x800"),
        "status": "pending",
        "feedback_history": [],
        "created_at": _now_iso(),
    }

    queue_items.append(new_item)

    await sio.emit("queue_update", {"items": queue_items})

    return JSONResponse(content=new_item, status_code=201)


@app.post("/api/gather")
async def gather_components(request: Request) -> JSONResponse:
    """Scan a working directory for React/HTML component files and add them to the queue."""
    global queue_items, _demo_seeded
    _demo_seeded = True  # Mark demo as seeded so it doesn't re-seed

    body = await request.json()
    workdir = body.get("workdir", ".")

    scan_dir = Path(workdir).resolve()
    if not scan_dir.is_dir():
        raise HTTPException(status_code=400, detail=f"Directory not found: {scan_dir}")

    extensions = {".tsx", ".jsx", ".html"}
    added_items: List[dict] = []

    for root, _dirs, files in os.walk(scan_dir):
        # Skip node_modules, dist, build, .git, etc.
        root_path = Path(root)
        skip_dirs = {"node_modules", "dist", "build", ".git", ".next", "__pycache__", ".venv", "venv"}
        if any(part in skip_dirs for part in root_path.parts):
            continue

        for fname in sorted(files):
            fpath = root_path / fname
            suffix = fpath.suffix.lower()
            if suffix not in extensions:
                continue

            try:
                content = fpath.read_text(encoding="utf-8", errors="ignore")
            except Exception:
                continue

            # Skip empty or very large files
            if not content.strip() or len(content) > 50_000:
                continue

            component_name = fpath.stem
            # Make a human-friendly name from the filename
            display_name = component_name.replace("-", " ").replace("_", " ")
            # Title-case it
            display_name = " ".join(word.capitalize() for word in display_name.split())

            rel_path = str(fpath.relative_to(scan_dir))

            new_item = {
                "id": str(uuid.uuid4()),
                "component_name": f"{display_name} ({rel_path})",
                "screenshot_path": "",
                "code_snippet": content,
                "viewport": "1200x800",
                "status": "pending",
                "feedback_history": [],
                "created_at": _now_iso(),
            }

            queue_items.append(new_item)
            added_items.append(new_item)

    await sio.emit("queue_update", {"items": queue_items})

    return JSONResponse(content={
        "count": len(added_items),
        "items": added_items,
        "workdir": str(scan_dir),
    })


@app.post("/api/feedback/{item_id}")
async def submit_feedback(
    item_id: str,
    action: str = Form(...),
    comment: str = Form(""),
    attachment: Optional[UploadFile] = File(None),
) -> JSONResponse:
    global queue_items

    item = next((qi for qi in queue_items if qi["id"] == item_id), None)
    if item is None:
        raise HTTPException(status_code=404, detail="Queue item not found")

    if action not in ("approve", "reject"):
        raise HTTPException(status_code=400, detail="Invalid action")

    attachment_path = ""
    if attachment is not None and attachment.filename:
        ext = Path(attachment.filename).suffix
        unique_name = f"{uuid.uuid4()}{ext}"
        dest = UPLOADS_DIR / unique_name
        async with aiofiles.open(dest, "wb") as f:
            content = await attachment.read()
            await f.write(content)
        attachment_path = f"/uploads/{unique_name}"

    item["status"] = "approved" if action == "approve" else "rejected"

    feedback_entry = {
        "action": action,
        "comment": comment,
        "attachment_path": attachment_path,
        "timestamp": _now_iso(),
    }
    item["feedback_history"].append(feedback_entry)

    await sio.emit("feedback_update", {
        "item_id": item_id,
        "feedback": feedback_entry,
        "item": item,
    })

    return JSONResponse(content={"message": "Feedback submitted", "item": item})


@app.get("/api/feedback/{item_id}")
async def get_feedback(item_id: str) -> JSONResponse:
    item = next((qi for qi in queue_items if qi["id"] == item_id), None)
    if item is None:
        raise HTTPException(status_code=404, detail="Queue item not found")
    return JSONResponse(content={"feedback_history": item.get("feedback_history", [])})


# ---------------------------------------------------------------------------
# Socket.IO events
# ---------------------------------------------------------------------------
@sio.event
async def connect(sid: str, environ: dict) -> None:
    print(f"[ws] client connected: {sid}")


@sio.event
async def disconnect(sid: str) -> None:
    print(f"[ws] client disconnected: {sid}")


@sio.on("get_queue")
async def handle_get_queue(sid: str) -> None:
    global queue_items, _demo_seeded
    if not queue_items and not _demo_seeded:
        queue_items = get_demo_items()
        _demo_seeded = True
    await sio.emit("queue_update", {"items": queue_items}, room=sid)


# ---------------------------------------------------------------------------
# SPA fallback -- serve frontend dist for any non-API path
# ---------------------------------------------------------------------------
@app.get("/{full_path:path}")
async def serve_spa(full_path: str) -> FileResponse:
    """Serve frontend build. Falls back to index.html for client-side routing."""
    if not FRONTEND_DIST_DIR.exists():
        raise HTTPException(
            status_code=503,
            detail="Frontend not built yet. Run `npm run build` in studio/frontend/",
        )

    file_path = FRONTEND_DIST_DIR / full_path
    if file_path.is_file():
        return FileResponse(file_path)
    # SPA fallback
    index = FRONTEND_DIST_DIR / "index.html"
    if index.is_file():
        return FileResponse(index)
    raise HTTPException(status_code=404, detail="Not found")


# ---------------------------------------------------------------------------
# Wrap with Socket.IO ASGI app -- this is what uvicorn must run
# ---------------------------------------------------------------------------
socket_app = socketio.ASGIApp(sio, app)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(socket_app, host="0.0.0.0", port=7860)
