#!/usr/bin/env bash
set -euo pipefail

# Resolve the directory this script lives in (works when double-clicked in Finder)
cd "$(dirname "$0")"
ROOT="$(pwd)"

NODE="$ROOT/runtime/node"
OPENCLAW_ENTRY="$ROOT/app/node_modules/openclaw/openclaw.mjs"
export NODE_PATH="$ROOT/app/node_modules"
export PATH="$ROOT/runtime:$ROOT/bin:$PATH"

# Verify runtime
if [[ ! -x "$NODE" ]]; then
    echo ""
    echo "  [ERROR] Node.js runtime not found at: $NODE"
    echo "  The package may be corrupted. Please re-download."
    echo ""
    read -rp "  Press Enter to exit..."
    exit 1
fi

if [[ ! -f "$OPENCLAW_ENTRY" ]]; then
    echo ""
    echo "  [ERROR] OpenClaw not found at: $OPENCLAW_ENTRY"
    echo "  The package may be corrupted. Please re-download."
    echo ""
    read -rp "  Press Enter to exit..."
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
        echo "  Setup was interrupted. You can run it again later"
        echo "  by double-clicking start.command"
        echo ""
        read -rp "  Press Enter to exit..."
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

# Open browser (macOS)
open "http://127.0.0.1:18789/" 2>/dev/null &

# Run gateway in foreground
exec "$NODE" "$OPENCLAW_ENTRY" gateway --port 18789 --verbose
