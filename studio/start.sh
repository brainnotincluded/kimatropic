#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting Kimatropic Studio..."

# Ensure uploads directory exists
mkdir -p "$SCRIPT_DIR/server/uploads"

# Install backend deps
echo "Installing backend dependencies..."
pip install -r "$SCRIPT_DIR/server/requirements.txt" -q 2>/dev/null

# Install frontend deps and build
echo "Installing frontend dependencies..."
cd "$SCRIPT_DIR/frontend"
npm install --silent 2>/dev/null
echo "Building frontend..."
npm run build 2>/dev/null

# Start server (serves built frontend)
cd "$SCRIPT_DIR/server"
echo ""
echo "Studio running at http://localhost:7860"
echo ""
python3 -m uvicorn main:socket_app --host 0.0.0.0 --port 7860
