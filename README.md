# Claude & AI Usage Learnings

Personal log of reusable insights from working with Claude Code and AI tools.
Portable, shareable, and actionable — every entry has a code file or step to
replicate the learning on a new machine.

## Quick Setup (new machine)

```bash
git clone https://github.com/ajubadardeen-web/claude-learnings.git
cd claude-learnings
bash bootstrap-new-machine.sh
```

That installs:
- `~/.claude/scripts/init-memory.sh` — auto-scaffolds project memory on session start
- `~/.claude/scripts/memory-stop-hook.sh` — nudges Claude to save findings before stopping
- `~/.claude/CLAUDE.md` — global preferences and memory/learnings instructions
- `~/.claude/settings.json` — hooks wired up

## Structure

```
LEARNINGS.md                        # Main doc — two sections (see below)
README.md                           # This file
bootstrap-new-machine.sh            # One-command setup
snippets/
  memory-management/
    init-memory.sh                  # SessionStart hook script
    memory-stop-hook.sh             # Stop hook script
    CLAUDE.md.template              # Global CLAUDE.md template
    settings-snippet.json           # Hook config for settings.json
```

## Sections in LEARNINGS.md

- **Section 1: Claude Code Setup & Tooling** — hooks, memory, settings, automation
- **Section 2: Prompting & Model Behaviour** — context, accuracy, workflow patterns

## Adding a New Learning

Say **"save this as a learning"** during any Claude session. Claude will:
1. Add a new entry to `LEARNINGS.md`
2. Save any associated code to `snippets/<category>/`
3. Commit and push

Or add manually — follow the entry format in `LEARNINGS.md`.
