#!/bin/bash
# init-memory.sh — auto-scaffold memory directory for new Claude Code projects
# Runs on SessionStart. Safe to run repeatedly (no-op if MEMORY.md already exists).

# Match Claude Code's internal project key encoding:
# - Replace all '/' with '-' (leading slash becomes leading '-')
# - Replace all '_' with '-'
PROJECT_KEY=$(pwd | sed 's|/|-|g' | sed 's|_|-|g')
MEMORY_DIR="$HOME/.claude/projects/$PROJECT_KEY/memory"

if [ ! -f "$MEMORY_DIR/MEMORY.md" ]; then
  mkdir -p "$MEMORY_DIR"
  cat > "$MEMORY_DIR/MEMORY.md" << 'EOF'
# Project Memory

## Environment

- **Working dir**: (fill in)
- **Key tools / stack**: (fill in)

## Current State

- (fill in — what is actively in progress)

## Known Blockers

- None yet

## User Preferences

- Concise, technical responses
- No emojis
- Prefer data-backed recommendations over intuition
- Ask before taking irreversible actions

## Recurring Issues

- (fill in as patterns are discovered)

## Links to Detailed Notes

- (create topic files and link here, e.g. debugging.md, decisions.md)
EOF
  echo "[memory-init] Created memory scaffold at $MEMORY_DIR/MEMORY.md"
fi
