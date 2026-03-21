#!/bin/bash
# memory-stop-hook.sh — only prompt memory update when substantive work was done
#
# Only blocks if the last turn used write/execute tools (Edit, Write, Bash, SQL query).
# Read-only or conversational turns exit silently.

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
# Look at the last 50 lines of the transcript for tool use in the final turn
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

# Substantive turn — prompt a memory check
jq -n '{
  "decision": "block",
  "reason": "Memory check: save anything worth persisting to MEMORY.md (tables, blockers, errors, decisions), then stop."
}'
