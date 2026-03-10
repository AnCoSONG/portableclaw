#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
ROOT="$(pwd)"

NODE="$ROOT/runtime/node"
export PATH="$ROOT/runtime:$PATH"
export OPENCLAW_HOME="$ROOT/data"

if [[ ! -x "$NODE" ]]; then
    echo "[ERROR] Node.js runtime not found. Package may be corrupted."
    exit 1
fi

echo ""
echo "  ================================================"
echo "    OpenClaw Updater"
echo "  ================================================"
echo ""

# Show current version
if [[ -f "$ROOT/VERSION" ]]; then
    echo "  Current version: $(cat "$ROOT/VERSION")"
fi

echo "  Detecting best registry..."

# Auto-detect npm registry (3s timeout, fallback to China mirror)
REGISTRY=$("$NODE" -e "
fetch('https://registry.npmjs.org/openclaw', { signal: AbortSignal.timeout(3000) })
  .then(() => console.log('https://registry.npmjs.org'))
  .catch(() => console.log('https://registry.npmmirror.com'))
" 2>/dev/null || echo "https://registry.npmmirror.com")

echo "  Registry: $REGISTRY"
echo ""
echo "  Installing latest version..."
echo ""

"$ROOT/runtime/npm" install openclaw@latest \
    --prefix "$ROOT/app" \
    --registry "$REGISTRY" \
    --no-fund --no-audit \
    --loglevel error

# Update VERSION file
NEW_VERSION=$("$NODE" -e "console.log(require('$ROOT/app/node_modules/openclaw/package.json').version)" 2>/dev/null || echo "unknown")
echo "$NEW_VERSION" > "$ROOT/VERSION"

echo ""
echo "  Updated to version: $NEW_VERSION"
echo ""
echo "  Done! Restart OpenClaw to use the new version."
echo ""
