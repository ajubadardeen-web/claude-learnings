#!/bin/bash
# memory-stop-hook.sh — prompt memory + learnings update after substantive turns
#
# Flow:
#   1. Stop fires after every Claude response
#   2. If stop_hook_active=true: second invocation, let Claude stop
#   3. Check if the turn used write/execute tools — exit silently if not
#   4. Block once and inject a dual reminder: project memory + global learnings

INPUT=$(cat)

# Second invocation in this stop cycle — let Claude stop
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0
fi

TRANSCRIPT="$(echo "$INPUT" | jq -r '.transcript_path')"

# If no transcript, exit silently
if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  exit 0
fi

# Check if the last assistant turn used any write/execute tools
SUBSTANTIVE=$(tail -50 "$TRANSCRIPT" 2>/dev/null | python3 -c "
import sys, json
tools_used = set()
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        entry = json.loads(line)
        if entry.get('type') == 'tool_use':
            tools_used.add(entry.get('name', ''))
    except:
        pass

write_tools = {
    'Edit', 'Write', 'NotebookEdit', 'Bash',
    'mcp__data-warehouse__execute_query',
    'mcp__google-drive-mcp__gdrive_edit_doc',
    'mcp__google-drive-mcp__gdrive_manage_comment',
    'mcp__google-drive-mcp__gdrive_edit_sheet',
}
hit = tools_used & write_tools
print('yes' if hit else 'no')
" 2>/dev/null)

if [ "$SUBSTANTIVE" != "yes" ]; then
  exit 0
fi

# Substantive turn — prompt memory check + learnings check
jq -n '{
  "decision": "block",
  "reason": "Before stopping: (1) save any project-specific findings to MEMORY.md (tables, blockers, errors, decisions); (2) if anything from this turn is a reusable Claude/AI/technical insight — not project-specific — add it to ~/.claude/learnings/LEARNINGS.md with a snippet and commit+push. Then stop."
}'
