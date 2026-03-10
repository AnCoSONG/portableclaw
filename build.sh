#!/usr/bin/env bash
set -euo pipefail

# PortableClaw Build Script
# Builds a self-contained portable OpenClaw package for a given platform.
# Usage: bash build.sh <target>
# Targets: darwin-arm64, darwin-x64, linux-x64, linux-arm64, win-x64, win-arm64

NODE_VERSION="${NODE_VERSION:-22.14.0}"
OPENCLAW_VERSION="${OPENCLAW_VERSION:-latest}"
DIST_DIR="dist"

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERR]${NC}  $*"; exit 1; }

TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
    echo -e "${BOLD}PortableClaw Builder${NC}"
    echo ""
    echo "Usage: bash build.sh <target>"
    echo ""
    echo "Targets:"
    echo "  darwin-arm64   macOS Apple Silicon"
    echo "  darwin-x64     macOS Intel"
    echo "  linux-x64      Linux x86_64"
    echo "  linux-arm64    Linux ARM64"
    echo "  win-x64        Windows x86_64"
    echo "  win-arm64      Windows ARM64"
    echo ""
    echo "Environment variables:"
    echo "  NODE_VERSION       Node.js version (default: $NODE_VERSION)"
    echo "  OPENCLAW_VERSION   OpenClaw version or dist-tag (default: latest)"
    echo "  NODE_MIRROR        Node.js download mirror (default: https://nodejs.org/dist)"
    echo "  NPM_REGISTRY       npm registry (default: https://registry.npmjs.org)"
    exit 1
fi

case "$TARGET" in
    darwin-arm64) NODE_OS="darwin";  NODE_ARCH="arm64"; IS_WIN=false ;;
    darwin-x64)   NODE_OS="darwin";  NODE_ARCH="x64";   IS_WIN=false ;;
    linux-x64)    NODE_OS="linux";   NODE_ARCH="x64";   IS_WIN=false ;;
    linux-arm64)  NODE_OS="linux";   NODE_ARCH="arm64"; IS_WIN=false ;;
    win-x64)      NODE_OS="win";     NODE_ARCH="x64";   IS_WIN=true  ;;
    win-arm64)    NODE_OS="win";     NODE_ARCH="arm64"; IS_WIN=true  ;;
    *) error "Unknown target: $TARGET. Run without arguments to see usage." ;;
esac

NODE_MIRROR="${NODE_MIRROR:-https://nodejs.org/dist}"
NPM_REGISTRY="${NPM_REGISTRY:-https://registry.npmjs.org}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="$(mktemp -d)"
PACKAGE_NAME="portableclaw-${TARGET}"
PACKAGE_DIR="${WORK_DIR}/${PACKAGE_NAME}"

cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

info "Building ${BOLD}${PACKAGE_NAME}${NC}"
info "Node.js: v${NODE_VERSION} | OpenClaw: ${OPENCLAW_VERSION}"
info "Working directory: ${WORK_DIR}"
echo ""

# ---------------------------------------------------------------------------
# 1. Download Node.js portable
# ---------------------------------------------------------------------------
info "Downloading Node.js v${NODE_VERSION} for ${NODE_OS}-${NODE_ARCH}..."

if [[ "$IS_WIN" == true ]]; then
    NODE_ARCHIVE="node-v${NODE_VERSION}-${NODE_OS}-${NODE_ARCH}.zip"
else
    NODE_ARCHIVE="node-v${NODE_VERSION}-${NODE_OS}-${NODE_ARCH}.tar.gz"
fi
NODE_URL="${NODE_MIRROR}/v${NODE_VERSION}/${NODE_ARCHIVE}"

curl -fSL --retry 3 --progress-bar -o "${WORK_DIR}/${NODE_ARCHIVE}" "$NODE_URL"
success "Downloaded ${NODE_ARCHIVE}"

# ---------------------------------------------------------------------------
# 2. Extract Node.js
# ---------------------------------------------------------------------------
info "Extracting Node.js..."

NODE_EXTRACTED="node-v${NODE_VERSION}-${NODE_OS}-${NODE_ARCH}"
if [[ "$IS_WIN" == true ]]; then
    if command -v unzip &>/dev/null; then
        unzip -q "${WORK_DIR}/${NODE_ARCHIVE}" -d "$WORK_DIR"
    elif command -v powershell &>/dev/null; then
        powershell -Command "Expand-Archive -Path '${WORK_DIR}/${NODE_ARCHIVE}' -DestinationPath '${WORK_DIR}' -Force"
    else
        error "Neither unzip nor powershell available to extract .zip"
    fi
else
    tar -xzf "${WORK_DIR}/${NODE_ARCHIVE}" -C "$WORK_DIR"
fi
success "Extracted Node.js"

# ---------------------------------------------------------------------------
# 3. Assemble package directory
# ---------------------------------------------------------------------------
info "Assembling package structure..."
mkdir -p "${PACKAGE_DIR}/runtime"
mkdir -p "${PACKAGE_DIR}/app"
mkdir -p "${PACKAGE_DIR}/bin"

if [[ "$IS_WIN" == true ]]; then
    cp "${WORK_DIR}/${NODE_EXTRACTED}/node.exe" "${PACKAGE_DIR}/runtime/"
    cp "${WORK_DIR}/${NODE_EXTRACTED}/npm.cmd"  "${PACKAGE_DIR}/runtime/" 2>/dev/null || true
    cp "${WORK_DIR}/${NODE_EXTRACTED}/npx.cmd"  "${PACKAGE_DIR}/runtime/" 2>/dev/null || true
    cp -r "${WORK_DIR}/${NODE_EXTRACTED}/node_modules" "${PACKAGE_DIR}/runtime/"
else
    cp "${WORK_DIR}/${NODE_EXTRACTED}/bin/node" "${PACKAGE_DIR}/runtime/"
    mkdir -p "${PACKAGE_DIR}/runtime/lib"
    cp -r "${WORK_DIR}/${NODE_EXTRACTED}/lib/node_modules" "${PACKAGE_DIR}/runtime/lib/"
    # Create npm/npx wrapper scripts (symlinks to .js don't get +x reliably)
    cat > "${PACKAGE_DIR}/runtime/npm" <<'WRAPPER'
#!/usr/bin/env bash
DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$DIR/node" "$DIR/lib/node_modules/npm/bin/npm-cli.js" "$@"
WRAPPER
    cat > "${PACKAGE_DIR}/runtime/npx" <<'WRAPPER'
#!/usr/bin/env bash
DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$DIR/node" "$DIR/lib/node_modules/npm/bin/npx-cli.js" "$@"
WRAPPER
    chmod +x "${PACKAGE_DIR}/runtime/node"
    chmod +x "${PACKAGE_DIR}/runtime/npm"
    chmod +x "${PACKAGE_DIR}/runtime/npx"
fi
success "Runtime assembled"

# ---------------------------------------------------------------------------
# 4. Install OpenClaw with the bundled npm
# ---------------------------------------------------------------------------
info "Installing OpenClaw (${OPENCLAW_VERSION}) via npm..."

if [[ "$IS_WIN" == true ]]; then
    NODE_BIN="${PACKAGE_DIR}/runtime/node.exe"
    NPM_CLI="${PACKAGE_DIR}/runtime/node_modules/npm/bin/npm-cli.js"
else
    NODE_BIN="${PACKAGE_DIR}/runtime/node"
    NPM_CLI="${PACKAGE_DIR}/runtime/lib/node_modules/npm/bin/npm-cli.js"
fi

# Ensure bundled Node.js is first on PATH so npm child processes use it
RUNTIME_DIR="$(cd "$(dirname "$NODE_BIN")" && pwd)"
export PATH="${RUNTIME_DIR}:${PATH}"

"$NODE_BIN" "$NPM_CLI" install "openclaw@${OPENCLAW_VERSION}" \
    --prefix "${PACKAGE_DIR}/app" \
    --registry "$NPM_REGISTRY" \
    --no-fund --no-audit \
    --loglevel error

success "OpenClaw installed"

# Record version (use host node for cross-platform builds where $NODE_BIN may not be executable)
OPENCLAW_PKG_JSON="${PACKAGE_DIR}/app/node_modules/openclaw/package.json"
if [[ -f "$OPENCLAW_PKG_JSON" ]]; then
    INSTALLED_VERSION=$("$NODE_BIN" -e "console.log(require('${OPENCLAW_PKG_JSON}').version)" 2>/dev/null \
        || node -e "console.log(require('${OPENCLAW_PKG_JSON}').version)" 2>/dev/null \
        || grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$OPENCLAW_PKG_JSON" | head -1 | grep -o '"[^"]*"$' | tr -d '"' \
        || echo "$OPENCLAW_VERSION")
else
    INSTALLED_VERSION="$OPENCLAW_VERSION"
fi
echo "$INSTALLED_VERSION" > "${PACKAGE_DIR}/VERSION"
info "Installed version: ${INSTALLED_VERSION}"

# ---------------------------------------------------------------------------
# 5. Trim Node.js runtime (remove unnecessary files)
# ---------------------------------------------------------------------------
info "Trimming runtime..."

if [[ "$IS_WIN" == true ]]; then
    rm -f "${PACKAGE_DIR}/runtime/CHANGELOG.md" 2>/dev/null || true
    rm -f "${PACKAGE_DIR}/runtime/README.md" 2>/dev/null || true
    rm -f "${PACKAGE_DIR}/runtime/LICENSE" 2>/dev/null || true
    rm -rf "${PACKAGE_DIR}/runtime/include" 2>/dev/null || true
else
    rm -rf "${WORK_DIR}/${NODE_EXTRACTED}/include" 2>/dev/null || true
    rm -rf "${WORK_DIR}/${NODE_EXTRACTED}/share" 2>/dev/null || true
fi

# Trim npm docs/man
if [[ "$IS_WIN" == true ]]; then
    NPM_DIR="${PACKAGE_DIR}/runtime/node_modules/npm"
else
    NPM_DIR="${PACKAGE_DIR}/runtime/lib/node_modules/npm"
fi
rm -rf "${NPM_DIR}/man" 2>/dev/null || true
rm -rf "${NPM_DIR}/docs" 2>/dev/null || true
rm -rf "${NPM_DIR}/changelogs" 2>/dev/null || true
rm -f "${NPM_DIR}/CHANGELOG.md" 2>/dev/null || true

success "Runtime trimmed"

# ---------------------------------------------------------------------------
# 6. Copy template scripts
# ---------------------------------------------------------------------------
info "Copying scripts from template..."

TEMPLATE_DIR="${SCRIPT_DIR}/template"

if [[ "$IS_WIN" == true ]]; then
    cp "${TEMPLATE_DIR}/start.bat"        "${PACKAGE_DIR}/start.bat"
    cp "${TEMPLATE_DIR}/start.bat"        "${PACKAGE_DIR}/开始.bat"
    cp "${TEMPLATE_DIR}/update.bat"       "${PACKAGE_DIR}/update.bat"
    cp "${TEMPLATE_DIR}/bin/openclaw.cmd" "${PACKAGE_DIR}/bin/openclaw.cmd"
else
    cp "${TEMPLATE_DIR}/start.command"    "${PACKAGE_DIR}/start.command"
    cp "${TEMPLATE_DIR}/start.command"    "${PACKAGE_DIR}/开始.command"
    cp "${TEMPLATE_DIR}/start.sh"         "${PACKAGE_DIR}/start.sh"
    cp "${TEMPLATE_DIR}/update.sh"        "${PACKAGE_DIR}/update.sh"
    cp "${TEMPLATE_DIR}/bin/openclaw"     "${PACKAGE_DIR}/bin/openclaw"
    chmod +x "${PACKAGE_DIR}/start.command"
    chmod +x "${PACKAGE_DIR}/开始.command"
    chmod +x "${PACKAGE_DIR}/start.sh"
    chmod +x "${PACKAGE_DIR}/update.sh"
    chmod +x "${PACKAGE_DIR}/bin/openclaw"
fi

# Copy README
cp "${SCRIPT_DIR}/README.txt" "${PACKAGE_DIR}/README.txt" 2>/dev/null || true

success "Scripts copied"

# ---------------------------------------------------------------------------
# 6.5. Code-sign macOS binaries (requires APPLE_SIGNING_IDENTITY env var)
# ---------------------------------------------------------------------------
if [[ "$NODE_OS" == "darwin" && -n "${APPLE_SIGNING_IDENTITY:-}" ]]; then
    info "Code-signing macOS binaries with: ${APPLE_SIGNING_IDENTITY}"
    SIGN_COUNT=0
    while IFS= read -r -d '' candidate; do
        if file "$candidate" | grep -q 'Mach-O'; then
            codesign --force --options runtime --timestamp \
                --sign "$APPLE_SIGNING_IDENTITY" "$candidate"
            ((SIGN_COUNT++))
        fi
    done < <(find "$PACKAGE_DIR" -type f -print0)
    success "Signed ${SIGN_COUNT} Mach-O binaries"
fi

# ---------------------------------------------------------------------------
# 7. Package
# ---------------------------------------------------------------------------
info "Packaging..."

mkdir -p "${SCRIPT_DIR}/${DIST_DIR}"

if [[ "$IS_WIN" == true ]]; then
    ARCHIVE="${PACKAGE_NAME}.zip"
    if command -v zip &>/dev/null; then
        (cd "$WORK_DIR" && zip -qr "${SCRIPT_DIR}/${DIST_DIR}/${ARCHIVE}" "$PACKAGE_NAME")
    elif command -v 7z &>/dev/null; then
        (cd "$WORK_DIR" && 7z a -tzip -mx=5 -bso0 "${SCRIPT_DIR}/${DIST_DIR}/${ARCHIVE}" "$PACKAGE_NAME")
    elif command -v python3 &>/dev/null; then
        python3 -c "
import zipfile, os, sys
src = os.path.join('${WORK_DIR}', '${PACKAGE_NAME}')
dst = os.path.join('${SCRIPT_DIR}', '${DIST_DIR}', '${ARCHIVE}')
with zipfile.ZipFile(dst, 'w', zipfile.ZIP_DEFLATED) as zf:
    for root, dirs, files in os.walk(src):
        for f in files:
            fp = os.path.join(root, f)
            zf.write(fp, os.path.relpath(fp, '${WORK_DIR}'))
"
    else
        error "No zip tool available (tried: zip, 7z, python3)"
    fi
else
    ARCHIVE="${PACKAGE_NAME}.tar.gz"
    tar -czf "${SCRIPT_DIR}/${DIST_DIR}/${ARCHIVE}" -C "$WORK_DIR" "$PACKAGE_NAME"
fi

ARCHIVE_SIZE=$(du -sh "${SCRIPT_DIR}/${DIST_DIR}/${ARCHIVE}" | cut -f1)
success "Package created: ${DIST_DIR}/${ARCHIVE} (${ARCHIVE_SIZE})"

echo ""
echo -e "${GREEN}${BOLD}Build complete!${NC}"
echo -e "  Target:  ${TARGET}"
echo -e "  Node.js: v${NODE_VERSION}"
echo -e "  OpenClaw: ${INSTALLED_VERSION}"
echo -e "  Package: ${DIST_DIR}/${ARCHIVE}"
