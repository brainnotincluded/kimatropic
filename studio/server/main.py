"""
Kimatropic Studio — FastAPI backend for UI component review.

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
                'export function Button({ children, variant = "primary" }: ButtonProps) {\n'
                '  return (\n'
                '    <button\n'
                '      className={clsx(\n'
                '        "px-4 py-2 rounded-md font-medium transition-colors",\n'
                '        variant === "primary" && "bg-cyan-500 text-white hover:bg-cyan-600",\n'
                '        variant === "ghost" && "bg-transparent text-gray-300 hover:bg-white/5"\n'
                "      )}\n"
                "    >\n"
                "      {children}\n"
                "    </button>\n"
                "  );\n"
                "}"
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
                'export function Card({ title, children }: CardProps) {\n'
                '  return (\n'
                '    <div className="bg-[#15181C] rounded-lg border border-[#2A3038] p-6">\n'
                '      <h3 className="text-lg font-semibold text-white mb-3">{title}</h3>\n'
                '      <div className="text-gray-400">{children}</div>\n'
                "    </div>\n"
                "  );\n"
                "}"
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
                'export function Navbar() {\n'
                '  return (\n'
                '    <nav className="h-14 bg-[#0F1114] border-b border-[#2A3038] flex items-center px-6">\n'
                '      <span className="font-semibold text-white">App</span>\n'
                '      <div className="ml-auto flex gap-4 text-sm text-gray-400">\n'
                '        <a href="#" className="hover:text-white transition-colors">Dashboard</a>\n'
                '        <a href="#" className="hover:text-white transition-colors">Settings</a>\n'
                "      </div>\n"
                "    </nav>\n"
                "  );\n"
                "}"
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
# SPA fallback — serve frontend dist for any non-API path
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
# Wrap with Socket.IO ASGI app — this is what uvicorn must run
# ---------------------------------------------------------------------------
socket_app = socketio.ASGIApp(sio, app)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(socket_app, host="0.0.0.0", port=7860)
