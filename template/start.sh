#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
ROOT="$(pwd)"

NODE="$ROOT/runtime/node"
OPENCLAW_ENTRY="$ROOT/app/node_modules/openclaw/openclaw.mjs"
export NODE_PATH="$ROOT/app/node_modules"
export PATH="$ROOT/runtime:$ROOT/bin:$PATH"

if [[ ! -x "$NODE" ]]; then
    echo ""
    echo "  [ERROR] Node.js runtime not found at: $NODE"
    echo "  The package may be corrupted. Please re-download."
    exit 1
fi

if [[ ! -f "$OPENCLAW_ENTRY" ]]; then
    echo ""
    echo "  [ERROR] OpenClaw not found at: $OPENCLAW_ENTRY"
    echo "  The package may be corrupted. Please re-download."
    exit 1
fi

# First run: onboard if no config exists
if [[ ! -f "$HOME/.openclaw/openclaw.json" ]]; then
    echo ""
    echo "  ================================================"
    echo "    OpenClaw - First Run Setup"
    echo "  ================================================"
    echo ""
    echo "  Welcome! Let's configure OpenClaw for first use."
    echo ""
    "$NODE" "$OPENCLAW_ENTRY" onboard || {
        echo ""
        echo "  Setup was interrupted. Run ./start.sh again to retry."
        exit 1
    }
    echo ""
fi

echo ""
echo "  ================================================"
echo "    OpenClaw Gateway"
echo "  ================================================"
echo ""
echo "  Dashboard:  http://127.0.0.1:18789/"
echo "  Press Ctrl+C to stop"
echo ""

# Try to open browser (Linux: xdg-open)
if command -v xdg-open &>/dev/null; then
    xdg-open "http://127.0.0.1:18789/" 2>/dev/null &
fi

exec "$NODE" "$OPENCLAW_ENTRY" gateway --port 18789 --verbose
