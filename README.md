# PortableClaw

OpenClaw 开箱即用便携版。下载、解压、双击，就能用。

Pre-built portable OpenClaw — download, extract, double-click, done.

## Quick Start

### Windows

1. Download `portableclaw-win-x64.zip`
2. Extract anywhere (Desktop, D:\, USB drive — wherever you like)
3. Double-click **`start.bat`**
4. First run will guide you through setup. After that, Gateway starts automatically.

### macOS

1. Download `portableclaw-darwin-arm64.tar.gz` (Apple Silicon) or `portableclaw-darwin-x64.tar.gz` (Intel)
2. Double-click to extract in Finder
3. Double-click **`start.command`**
4. If macOS shows "unidentified developer" warning: right-click > Open > Open

### Linux

1. Download `portableclaw-linux-x64.tar.gz` (or `linux-arm64`)
2. Extract: `tar xzf portableclaw-linux-x64.tar.gz`
3. Run: `./portableclaw-linux-x64/start.sh`

## Downloads

| Platform | Architecture | File |
|----------|-------------|------|
| Windows | x64 | `portableclaw-win-x64.zip` |
| macOS | Apple Silicon (M1/M2/M3/M4) | `portableclaw-darwin-arm64.tar.gz` |
| macOS | Intel | `portableclaw-darwin-x64.tar.gz` |
| Linux | x86_64 | `portableclaw-linux-x64.tar.gz` |
| Linux | ARM64 | `portableclaw-linux-arm64.tar.gz` |

> Download from [GitHub Releases](../../releases/latest).
>
> 国内下载慢？试试 [npmmirror 镜像](https://registry.npmmirror.com/-/binary/portableclaw/) 或 [Gitee Releases](https://gitee.com/)。

## What's Inside

Each package contains everything needed to run OpenClaw — no installation required:

- **Node.js 22** runtime (portable, no system install)
- **OpenClaw** with all dependencies pre-installed (including pre-compiled native modules)
- **Start script** that launches Gateway + opens Dashboard in browser
- **Update script** to pull the latest OpenClaw version
- **CLI wrapper** (`bin/openclaw`) for advanced terminal use

## Usage

### Starting the Gateway

Double-click `start.bat` (Windows) / `start.command` (macOS) / run `./start.sh` (Linux).

The script will:
1. On first run: guide you through API key setup (`openclaw onboard`)
2. Start the OpenClaw Gateway on `http://127.0.0.1:18789/`
3. Open the Dashboard in your browser

Close the terminal window or press `Ctrl+C` to stop.

### Using the CLI

For advanced usage, use the CLI wrapper in `bin/`:

```bash
# macOS / Linux
./bin/openclaw status
./bin/openclaw gateway status
./bin/openclaw message send --target +1234567890 --message "Hello"

# Windows (cmd or PowerShell)
.\bin\openclaw.cmd status
```

### Updating OpenClaw

Double-click `update.bat` (Windows) or run `./update.sh` (macOS/Linux).

The update script automatically detects your network and uses the fastest npm registry (npmjs.org or npmmirror.com for China mainland).

### Uninstalling

Delete the extracted folder. That's it. OpenClaw config lives in `~/.openclaw/` — delete that too for a clean removal.

## Building From Source

To build portable packages yourself (requires the target platform):

```bash
# Build for current platform
bash build.sh darwin-arm64

# Custom versions
NODE_VERSION=22.14.0 OPENCLAW_VERSION=latest bash build.sh linux-x64

# Use China mirrors for faster builds
NODE_MIRROR=https://npmmirror.com/mirrors/node NPM_REGISTRY=https://registry.npmmirror.com bash build.sh darwin-arm64
```

Output goes to `dist/`.

## How It Works

```
portableclaw-{platform}/
├── start.bat / start.command / start.sh   ← Double-click this
├── update.bat / update.sh                 ← Double-click to update
├── bin/openclaw[.cmd]                     ← CLI for terminal use
├── runtime/                               ← Bundled Node.js 22
├── app/node_modules/openclaw/             ← Pre-installed OpenClaw
└── VERSION
```

All native modules (sharp, node-pty, sqlite-vec) are pre-compiled during CI build — users never need to compile anything.

## License

MIT
