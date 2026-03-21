#!/bin/bash
# bootstrap-new-machine.sh
# One-command setup: installs Claude Code memory management + learnings system.
# Run from the root of your cloned learnings repo:
#   git clone <your-repo-url> && cd <repo> && bash bootstrap-new-machine.sh

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"
LEARNINGS_DIR="$CLAUDE_DIR/learnings"

echo "=== Claude Code bootstrap ==="
echo "Repo: $REPO_DIR"
echo "Claude dir: $CLAUDE_DIR"
echo ""

# 1. Create directories
mkdir -p "$SCRIPTS_DIR"
mkdir -p "$CLAUDE_DIR"

# 2. Copy scripts
echo "[1/5] Installing hook scripts..."
cp "$REPO_DIR/snippets/memory-management/init-memory.sh" "$SCRIPTS_DIR/"
cp "$REPO_DIR/snippets/memory-management/memory-stop-hook.sh" "$SCRIPTS_DIR/"
chmod +x "$SCRIPTS_DIR/init-memory.sh"
chmod +x "$SCRIPTS_DIR/memory-stop-hook.sh"
echo "      -> $SCRIPTS_DIR/init-memory.sh"
echo "      -> $SCRIPTS_DIR/memory-stop-hook.sh"

# 3. Install global CLAUDE.md (skip if already customised)
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
  echo "[2/5] ~/.claude/CLAUDE.md already exists — skipping (review manually)"
  echo "      Template: $REPO_DIR/snippets/memory-management/CLAUDE.md.template"
else
  echo "[2/5] Installing global CLAUDE.md..."
  cp "$REPO_DIR/snippets/memory-management/CLAUDE.md.template" "$CLAUDE_DIR/CLAUDE.md"
  echo "      -> $CLAUDE_DIR/CLAUDE.md"
fi

# 4. Merge hooks into settings.json
echo "[3/5] Updating ~/.claude/settings.json..."
SETTINGS="$CLAUDE_DIR/settings.json"
SNIPPET="$REPO_DIR/snippets/memory-management/settings-snippet.json"

if [ ! -f "$SETTINGS" ]; then
  cp "$SNIPPET" "$SETTINGS"
  echo "      -> Created $SETTINGS"
else
  # Merge using python3 — preserve existing keys, add hooks
  python3 - "$SETTINGS" "$SNIPPET" << 'PYEOF'
import json, sys

with open(sys.argv[1]) as f:
    existing = json.load(f)
with open(sys.argv[2]) as f:
    snippet = json.load(f)

# Merge hooks sections
existing_hooks = existing.get("hooks", {})
for event, handlers in snippet.get("hooks", {}).items():
    if event not in existing_hooks:
        existing_hooks[event] = handlers
        print(f"      Added {event} hook")
    else:
        print(f"      {event} hook already present — skipping")

existing["hooks"] = existing_hooks

with open(sys.argv[1], "w") as f:
    json.dump(existing, f, indent=2)
    f.write("\n")
PYEOF
  echo "      -> Merged into $SETTINGS"
fi

# 5. Symlink or clone the learnings repo into ~/.claude/learnings
echo "[4/5] Setting up learnings directory..."
if [ -L "$LEARNINGS_DIR" ] || [ -d "$LEARNINGS_DIR" ]; then
  echo "      ~/.claude/learnings already exists — skipping"
else
  ln -s "$REPO_DIR" "$LEARNINGS_DIR"
  echo "      -> Symlinked $REPO_DIR -> $LEARNINGS_DIR"
fi

# 6. Verify jq is available (required by stop hook)
echo "[5/5] Checking dependencies..."
if ! command -v jq &>/dev/null; then
  echo "      WARNING: jq not found. Install it:"
  echo "        macOS:  brew install jq"
  echo "        Ubuntu: sudo apt install jq"
else
  echo "      jq: $(which jq) ✓"
fi

echo ""
echo "=== Done ==="
echo ""
echo "Next steps:"
echo "  1. Open a new Claude Code session to test (SessionStart hook should fire)"
echo "  2. If you haven't already, set the remote for this repo:"
echo "       cd $REPO_DIR && git remote add origin <your-github-url> && git push -u origin main"
echo ""
