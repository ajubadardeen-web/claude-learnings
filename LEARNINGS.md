# Claude & AI Usage Learnings

A portable, shareable log of reusable insights from working with Claude.
Each entry includes an actionable step and a code file so any learning can be
replicated on a new machine in minutes.

**Quick setup on a new machine**: `bash bootstrap-new-machine.sh`

---

## Section 1: Claude Code Setup & Tooling

Learnings about configuring the Claude Code CLI, hooks, memory, and automation.

---

### 1.1 Persistent Project Memory

**Added**: 2026-03-20
**Tags**: `#memory` `#session-context` `#claude-code`

**What I learned**

Claude has no memory between sessions by default. Each session starts fresh.
Claude Code's auto-memory system (`~/.claude/projects/<key>/memory/`) solves
this — files placed there are loaded automatically at session start.

The key insight: `MEMORY.md` must stay under 200 lines or it gets truncated.
Move detail to topic files (`debugging.md`, `decisions.md`) and link from
`MEMORY.md`.

**Why it matters**

Without memory, Claude gives plausible-but-wrong answers in any project with
a specific data model, table naming conventions, or recurring gotchas. Setting
this up once eliminates re-explaining context every session.

**How to replicate**

1. Copy `snippets/memory-management/init-memory.sh` to `~/.claude/scripts/`
2. Copy `snippets/memory-management/CLAUDE.md.template` to `~/.claude/CLAUDE.md`
3. Add the `SessionStart` hook from `snippets/memory-management/settings-snippet.json`
   to `~/.claude/settings.json`
4. Make the script executable: `chmod +x ~/.claude/scripts/init-memory.sh`

Or just run `bash bootstrap-new-machine.sh`.

**Code**: `snippets/memory-management/`

---

### 1.2 Stop Hook for Memory Hygiene

**Added**: 2026-03-20
**Tags**: `#hooks` `#memory` `#stop-hook`

**What I learned**

Without a Stop hook, memory updates are entirely discretionary — Claude may or
may not save important context before a session ends. A `Stop` hook can block
Claude from stopping and inject a reminder to persist anything worth keeping.

Key mechanics:
- `Stop` fires after **every** Claude response, not just at true session end
- Output `{"decision": "block", "reason": "..."}` to block and feed a message back to Claude
- Check `stop_hook_active` in the input JSON to prevent infinite loops — on
  the second invocation, exit 0 to let Claude stop
- Only fire when the turn involved write/execute tools (Edit, Write, Bash, SQL)
  to avoid noise on read-only or conversational turns

**Why it matters**

Important findings (correct table names, resolved blockers, error patterns)
discovered mid-session get lost if the session ends before Claude saves them.
The Stop hook makes persistence reliable without requiring manual prompting.

**How to replicate**

1. Copy `snippets/memory-management/memory-stop-hook.sh` to `~/.claude/scripts/`
2. Add the `Stop` hook from `snippets/memory-management/settings-snippet.json`
   to `~/.claude/settings.json`
3. `chmod +x ~/.claude/scripts/memory-stop-hook.sh`

**Code**: `snippets/memory-management/memory-stop-hook.sh`

---

### 1.3 Global CLAUDE.md for Cross-Project Preferences

**Added**: 2026-03-20
**Tags**: `#claude-md` `#preferences` `#global-config`

**What I learned**

`~/.claude/CLAUDE.md` loads automatically for **every** project on your machine.
Use it to encode universal preferences (tone, no emojis, ask before irreversible
actions) and memory hygiene rules once, rather than repeating them in every
project's `CLAUDE.md`.

Hierarchy: global `~/.claude/CLAUDE.md` → project `./CLAUDE.md` → project
`./.claude/rules/*.md`. All load and stack.

**Why it matters**

Without a global CLAUDE.md, preferences have to be re-stated in every project
or re-explained every session. One file covers all projects permanently.

**How to replicate**

Copy `snippets/memory-management/CLAUDE.md.template` to `~/.claude/CLAUDE.md`.
Customize the Universal User Preferences section to your taste.

**Code**: `snippets/memory-management/CLAUDE.md.template`

---

## Section 2: Prompting & Model Behaviour

Learnings about how Claude behaves, where it goes wrong, and how to get better results.

---

### 2.1 Vanilla Claude vs Context-Aware Claude

**Added**: 2026-03-20
**Tags**: `#context` `#automated-responses` `#accuracy`

**What I learned**

Claude without project context produces confident, plausible-but-wrong answers.
In a real example: an automated doc-watcher script had a vanilla Claude instance
respond to a question about SQL queries. It used:
- The wrong ground-truth table (`trust.session__dim_ato_sessions` instead of
  `trust.casefile__dim_metainfo`)
- The wrong ML table (`jitney_events.*` instead of `trust_ml.*`)
- The wrong decision taxonomy (TP/FP/FN/TN instead of the project's four-label
  policy taxonomy)

All answers were internally consistent and looked reasonable — the error was
only detectable with project knowledge.

**Why it matters**

Any automated Claude workflow (doc watchers, scheduled scripts, CI hooks) will
produce wrong outputs unless project context is injected. This applies equally
to manual sessions — the first few responses in a new session without memory
are unreliable for project-specific questions.

**Actionable step**

For automated scripts: always pass a context prompt with project-specific facts
(table names, taxonomies, data model). Don't rely on Claude to infer them.

For manual sessions: verify that `MEMORY.md` was loaded (ask Claude "what do
you know about this project?" at the start of a session if unsure).

**Code**: N/A — this is a process guideline, not a setup script.

---
<!-- NEW LEARNINGS ADDED BELOW THIS LINE -->

