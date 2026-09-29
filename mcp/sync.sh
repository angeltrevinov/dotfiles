#!/usr/bin/env bash
# sync.sh — Generate MCP configs for all AI tools from one source
# Source of truth: mcp-servers.json (in this directory)
#
# Usage: ./sync.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE="$SCRIPT_DIR/mcp-servers.json"

if [ ! -f "$SOURCE" ]; then
  echo "ERROR: $SOURCE not found." >&2
  exit 1
fi

# ── OpenCode ───────────────────────────────────────────────────────────────
OPENCODE_DIR="$HOME/.config/opencode"
mkdir -p "$OPENCODE_DIR"

python3 -c "
import json
with open('$SOURCE') as f:
    servers = json.load(f)
config = {
    '\$schema': 'https://opencode.ai/config.json',
    'mcp': {'servers': servers}
}
with open('$OPENCODE_DIR/opencode.jsonc', 'w') as f:
    json.dump(config, f, indent=2)
    f.write('\n')
print('✓ OpenCode config updated')
"

# ── VS Code ────────────────────────────────────────────────────────────────
VSCODE_DIR="$HOME/.config/Code/User"
mkdir -p "$VSCODE_DIR"

# If mcp.json is a symlink (from dotfiles), write to the source instead
VSCODE_MCP="$VSCODE_DIR/mcp.json"
if [[ -L "$VSCODE_MCP" ]]; then
    VSCODE_MCP="$(readlink -f "$VSCODE_MCP")"
fi

python3 -c "
import json
with open('$SOURCE') as f:
    servers = json.load(f)

vscode_servers = {}
for name, cfg in servers.items():
    if cfg['type'] == 'remote':
        vscode_servers[name] = {'type': 'http', 'url': cfg['url']}
    elif cfg['type'] == 'local':
        vscode_servers[name] = {
            'type': 'stdio',
            'command': cfg['command'][0],
            'args': cfg['command'][1:]
        }

config = {'servers': vscode_servers}
with open('$VSCODE_MCP', 'w') as f:
    json.dump(config, f, indent=2)
    f.write('\n')
print('✓ VS Code config updated')
"

# ── Claude CLI ─────────────────────────────────────────────────────────────
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"

python3 -c "
import json
with open('$SOURCE') as f:
    servers = json.load(f)

claude_servers = {}
for name, cfg in servers.items():
    if cfg['type'] == 'remote':
        claude_servers[name] = {'type': 'http', 'url': cfg['url']}
    elif cfg['type'] == 'local':
        claude_servers[name] = {
            'type': 'stdio',
            'command': cfg['command'][0],
            'args': cfg['command'][1:]
        }

config = {'mcpServers': claude_servers}
with open('$CLAUDE_DIR/settings.json', 'w') as f:
    json.dump(config, f, indent=2)
    f.write('\n')
print('✓ Claude CLI config updated')
"

# ── Cursor ──────────────────────────────────────────────────────────────────
CURSOR_DIR="$HOME/.cursor"
mkdir -p "$CURSOR_DIR"

python3 -c "
import json
with open('$SOURCE') as f:
    servers = json.load(f)

cursor_servers = {}
for name, cfg in servers.items():
    if cfg['type'] == 'remote':
        cursor_servers[name] = {'type': 'http', 'url': cfg['url']}
    elif cfg['type'] == 'local':
        cursor_servers[name] = {
            'type': 'stdio',
            'command': cfg['command'][0],
            'args': cfg['command'][1:]
        }

config = {'mcpServers': cursor_servers}
with open('$CURSOR_DIR/mcp.json', 'w') as f:
    json.dump(config, f, indent=2)
    f.write('\n')
print('✓ Cursor config updated')
"

# ── Windsurf ───────────────────────────────────────────────────────────────
WINDSURF_DIR="$HOME/.codeium/windsurf"
mkdir -p "$WINDSURF_DIR"

python3 -c "
import json
with open('$SOURCE') as f:
    servers = json.load(f)

windsurf_servers = {}
for name, cfg in servers.items():
    if cfg['type'] == 'remote':
        windsurf_servers[name] = {'type': 'http', 'url': cfg['url']}
    elif cfg['type'] == 'local':
        windsurf_servers[name] = {
            'type': 'stdio',
            'command': cfg['command'][0],
            'args': cfg['command'][1:]
        }

config = {'mcpServers': windsurf_servers}
with open('$WINDSURF_DIR/mcp_config.json', 'w') as f:
    json.dump(config, f, indent=2)
    f.write('\n')
print('✓ Windsurf config updated')
"

echo ""
echo "All MCP configs synced from $SOURCE"
