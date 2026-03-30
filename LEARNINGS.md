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

### 1.4 Portable Learnings Log with Auto-Push

**Added**: 2026-03-20
**Tags**: `#learnings` `#git` `#hooks` `#portability` `#knowledge-management`

**What I learned**

A dedicated git repo at `~/.claude/learnings/` acts as a portable, shareable
knowledge base for reusable Claude and AI insights. Each entry in `LEARNINGS.md`
follows a structured format (what/why/how + code file) so any learning can be
replicated on a new machine. A `post-commit` git hook auto-pushes to GitHub on
every commit — no manual push needed. A `bootstrap-new-machine.sh` script sets
up the entire system (scripts, CLAUDE.md, settings hooks, post-commit hook) with
one command.

Two update triggers:
- **Automatic**: the Stop hook nudges Claude after every substantive turn to
  check whether anything is a reusable learning (vs. project-specific context
  which goes to MEMORY.md instead)
- **Explicit**: say "save this as a learning" — Claude writes the entry, commits,
  and the post-commit hook pushes automatically

Key gotcha: `.git/hooks/` is not tracked by git. The bootstrap script must
explicitly recreate the post-commit hook on a new machine — it does this.

**Why it matters**

Without this, expertise with Claude accumulates only in your head and is lost
when switching machines, starting a new role, or onboarding someone else.
This system makes that expertise durable, transferable, and shareable.

**How to replicate on a new machine**

```bash
git clone https://github.com/ajubadardeen-web/claude-learnings.git
cd claude-learnings
bash bootstrap-new-machine.sh
```

**Code**: `snippets/memory-management/` (all hook scripts + settings + CLAUDE.md template)
`bootstrap-new-machine.sh` (full setup script)

---
### 1.5 Allowlisting Tools to Eliminate Permission Prompts

**Added**: 2026-03-20
**Tags**: `#permissions` `#settings` `#mcp` `#claude-code`

**What I learned**

Claude Code prompts for permission on every tool call by default. You can
eliminate these prompts by adding an `allow` array to the `permissions` block
in `~/.claude/settings.json`. Built-in tools use the tool name with a glob
pattern (e.g. `"Bash(*)"`) and MCP tools use the prefix `mcp__<server>__*`.
The `allow` rules for built-in tools do NOT apply to MCP tools — they must be
listed separately.

Example config:
```json
"permissions": {
  "allow": [
    "Bash(*)", "Edit(*)", "Write(*)", "Read(*)", "Glob(*)", "Grep(*)",
    "mcp__data-warehouse__*", "mcp__airbnb-core__*", "mcp__minerva__*",
    "mcp__diagnose__*", "mcp__dataportal-mcp__*",
    "mcp__google-drive-mcp__*", "mcp__gandalf__*", "mcp__glean-mcp__*"
  ]
}
```

**Why it matters**

Without this, Claude prompts before every file read, shell command, and MCP
call — constant interruptions that break flow, especially in data-heavy
sessions with many warehouse queries.

**How to replicate**

Edit `~/.claude/settings.json` and add the `permissions.allow` block above.
Takes effect immediately with no restart required.

**Code**: N/A — inline config snippet above is sufficient.

---
### 1.6 Use launchd Instead of cron on macOS

**Added**: 2026-03-22
**Tags**: `#scheduling` `#launchd` `#cron` `#macos` `#automation`

**What I learned**

macOS cron does not retroactively run jobs missed while the machine is asleep.
If a laptop is in Deep Idle at the scheduled time, the job is silently skipped
with no log, no retry, and no notification. `launchd` with
`StartCalendarInterval` solves this — it fires the missed job as soon as the
Mac wakes up. This is the Apple-recommended scheduler for macOS; cron is a
legacy compatibility layer.

Discovered this when a Sunday 21:03 cron job never ran because the Mac was
asleep, while a 22:07 job on the same night succeeded (Mac had woken by then).
`pmset -g log` confirmed the sleep/wake timeline.

**Why it matters**

Any recurring automation on a laptop (weekly reports, memory maintenance,
data pulls) is unreliable with cron because laptops sleep unpredictably.
Switching to launchd makes scheduled tasks resilient to sleep with zero
additional complexity.

**How to replicate**

1. Create a plist in `~/Library/LaunchAgents/com.claude.<job-name>.plist`
   (see template in `snippets/scheduling/launchd-template.plist`)
2. `launchctl load ~/Library/LaunchAgents/com.claude.<job-name>.plist`
3. Remove any corresponding crontab entry
4. Verify: `launchctl list | grep com.claude`

**Code**: `snippets/scheduling/launchd-template.plist`

---
### 2.2 Deep Document Research: Revision-History-Aware Multi-Doc Processing

**Added**: 2026-03-29
**Tags**: `#research` `#google-docs` `#revision-history` `#multi-doc` `#methodology`

**What I learned**

When studying a body of work across multiple Google Docs/Slides, reading content alone is insufficient -- you lose the temporal dimension of *when* information was added, which determines what's most current when docs conflict. The right approach is:

1. **Extract all doc IDs from URLs upfront** and deduplicate (same doc may appear with different tab/heading anchors)
2. **Spin off parallel sub-agents** (one per unique document) that each:
   - Read full content in markdown format (preserves structure)
   - List revision history (`gdrive_revisions` action=list, pageSize=100)
   - Strategically diff key revisions (earliest vs middle, middle vs latest) to build a change timeline
   - Return: title, detailed content summary, and chronological timeline of additions
3. **Read hub docs for linked references** -- central docs often link to additional docs. Spin off a second wave of agents for linked docs (1 level deep suffices)
4. **Stitch together chronologically** -- use revision timestamps across all docs to build a unified timeline, resolving conflicts by recency
5. **Save structured output** to memory: a doc inventory (IDs, owners, dates), a knowledge base (organized by topic), and a timeline

Key API details:
- `gdrive_revisions` with action="list" returns revision IDs + timestamps
- `gdrive_revisions` with action="diff" shows what changed between two revisions
- `gdrive_activity` (via the activity log) provides edit/comment/rename events even when revision API is restricted
- Rate limits apply -- budget ~3-4 diffs per doc before hitting limits
- For multi-tab docs, read each tab separately using the `tabId` parameter

**Google Slides specifics:**
- `gdrive_read_file` (text format) extracts all text but strips images -- good for quick scan
- `gdrive_slides_get_presentation_map` returns every element with objectId, type, text, and position geometry (EMU units) -- good for reconstructing layouts
- `gdrive_slides_get_slide` gives single-slide element detail
- **Limitation**: Grouped elements are opaque -- the API returns groups as containers without recursing into children. Decision tree diagrams, flow charts, and other grouped shapes are invisible.
- **Limitation**: Embedded images return as image-type elements with no visual content

**Auto-export slides as images (SOLVED):**
Use `~/.claude/scripts/export-slides.py` to export any Google Slides deck as high-res PNGs:
```
python3 ~/.claude/scripts/export-slides.py <presentation_id> [output_dir]
```
- Uses Drive API `files.export` to get PDF, then `pdftoppm` (poppler) to convert pages to 300 DPI PNGs
- First run opens browser for OAuth consent (one-time). Token saved at `~/.claude/scripts/slides-token.json`
- Prerequisites: `google-api-python-client`, `google-auth-oauthlib` (pip), `poppler` (brew)
- Client secret file must exist at `~/Downloads/client_secret_523208945357-*.json`
- Output: `slide-1.png`, `slide-2.png`, etc. in the output directory (default: `/tmp/slides-<id>/`)
- Read individual PNGs with the Read tool -- Claude is multimodal and can see all visual content (diagrams, charts, grouped elements, images)
- **This is the definitive approach for decks**: always export slides as images first, then read visually. The text-only MCP tools miss too much visual content (50%+ of a typical deck is diagrams/charts/images).

**Why it matters**

Documents about the same initiative often contradict each other because they were written at different times. A planning doc from November may have targets that were revised down in February's PRD. Without the temporal dimension, you can't tell which numbers are current. This methodology produces an accurate, conflict-resolved understanding that would take a human hours of manual cross-referencing.

**Actionable step**

For any new project with a corpus of Google Docs to study:
1. Collect all URLs, extract file IDs
2. Launch parallel agents with the prompt template: "Read content (markdown), list revisions (pageSize=100), diff key revisions, return: title + content summary + change timeline"
3. After first wave completes, scan content for linked doc URLs and launch a second wave
4. Synthesize into: doc inventory, knowledge base, unified timeline
5. Save to project memory files

**Code**: `~/.claude/scripts/export-slides.py` (slide image export script)

### 1.7 Three-Layer Knowledge Distillation System

**Added**: 2026-03-29
**Tags**: `#memory` `#domain-knowledge` `#knowledge-management` `#automation` `#hooks`

**What I learned**

Claude Code's memory system works best with three distinct knowledge layers, each with its own storage, routing, and lifecycle:

1. **Project memory** (`~/.claude/projects/<key>/memory/`) -- project-specific context (tables used, blockers, decisions). Auto-updated by Stop hook. Use topic subdirectories (`domain/`, `tools/`, `decisions/`) to keep MEMORY.md under 200 lines.
2. **Learnings** (`~/.claude/learnings/LEARNINGS.md`) -- reusable Claude/AI tooling insights. Manual trigger only ("save this as a learning"). Git-tracked with auto-push.
3. **Domain knowledge** (`~/.claude/domain-knowledge/`) -- business domain expertise that spans projects. Auto-updated by Stop hook. Organized by topic files (tables, policies, models, auth, metrics, teams).

The key insight: LEARNINGS covers *how to use the tools*, project memory covers *what you're doing right now*, and domain knowledge covers *what you know about your business domain*. Without the third layer, domain expertise discovered across many projects stays siloed in individual MEMORY.md files and never compounds.

The Stop hook triggers distillation by including all three destinations in its block reason. Widening the hook trigger to include MCP exploration tools (find_tables, get_table_schema, glean_search, etc.) ensures read-heavy data exploration sessions also trigger knowledge capture -- not just write-heavy sessions.

Weekly consolidation (via the existing memory-updater launchd job) handles decay of stale entries and deduplication across all three layers.

**Why it matters**

Without domain knowledge distillation, every new Claude Code session in a new project directory starts from zero on business domain context, even if you've explored the same tables and policies dozens of times in other projects. The domain knowledge corpus makes expertise compound across all projects automatically.

**Actionable step**

1. Create `~/.claude/domain-knowledge/` with topic files for your domain
2. Add a "Knowledge Routing" section to `~/.claude/CLAUDE.md` defining the three destinations
3. Update the Stop hook reason to include domain knowledge as a third check
4. Widen the Stop hook trigger set to include MCP exploration tools (data-warehouse, dataportal, Glean, Minerva)
5. Add decay/consolidation steps to the weekly memory-updater prompt
6. Trigger manually with "save this as domain knowledge"

**Code**: N/A -- changes spread across `~/.claude/CLAUDE.md` (Knowledge Routing section), `~/.claude/scripts/memory-stop-hook.sh` (widened triggers + third destination), `~/.claude/scripts/memory-update-prompt.txt` (Step 6 decay/consolidation), and `~/.claude/domain-knowledge/` (topic files).

---
<!-- NEW LEARNINGS ADDED BELOW THIS LINE -->

### 1.8 Inserting Tables into Existing Google Docs

**Added**: 2026-03-29
**Tags**: `#google-docs` `#tables` `#mcp` `#workaround`

**What I learned**

The Google Drive MCP `gdrive_edit_doc` tool only supports plain text operations (appendText, replaceAllText, insertText) — it cannot insert structured tables. But Google Docs API `batchUpdate` can, via `insertTable`, `insertText` (into cells), and `updateTableCellStyle` / `updateTextStyle` for formatting. The trick: use `google-api-python-client` (already installed in `~/.venv/insight_miner/`) with the OAuth token from `~/projects/meeting-processor/token.json` (scopes: `documents`, `drive.file`).

**Why it matters**

Tabular data rendered as plain text lines in Google Docs is unusable in professional PRDs. This was a known limitation that previously required a manual copy-paste workaround (create a companion doc with `gdrive_create` + `contentFormat: "html"`, then user copies tables manually). The direct API approach is fully automated.

**How to replicate**

1. Auth: load token from `~/projects/meeting-processor/token.json` + `credentials.json` into `google.oauth2.credentials.Credentials`
2. Build service: `build('docs', 'v1', credentials=creds)`
3. Read doc: `service.documents().get(documentId=..., includeTabsContent=True)` — parse tab body for element indices
4. Insert table: `batchUpdate` with `insertTable` request at target index
5. Re-read doc to discover cell paragraph indices (they're not predictable from table dimensions alone)
6. Fill cells: `insertText` into each cell's paragraph index — **process in REVERSE index order** to avoid shifting
7. Style: `updateTableCellStyle` for backgrounds, `updateTextStyle` for bold/color/font-size
8. For multi-tab docs, always include `tabId` in location objects

**Code**: `/tmp/insert_tables.py` — full reference implementation with 5-table insertion, header styling (#FF385C bg + white text), alternating row colors, and text formatting.

---


