---
name: plan
description: Planning Phase (synced from Claude Code)
user-invocable: true
metadata: {"clawdbot":{"requires":{"bins":["claude"]}}}
---

# plan - Claude Code Command

**Auto-generated from:** `~/bibleai/.claude/commands/plan.md`

This skill invokes Claude Code's `/plan` command in your BibleAI project.

## When to Use

Trigger when Matt says:
- `/plan [args]`
- "plan [topic]"

## Workflow

### Step 1: Extract Arguments

Parse the command and extract any arguments/topic provided.

### Step 2: Get Channel Context

Extract current channel from session context (same as /implement):

```javascript
const sessionKey = getCurrentSessionKey();
let channel = "";

if (sessionKey.includes("discord:channel:")) {
  const match = sessionKey.match(/discord:channel:(\d+)/);
  if (match) channel = `discord:channel:${match[1]}`;
} else if (sessionKey.includes("telegram:")) {
  const match = sessionKey.match(/telegram:([^:]+):(\d+)/);
  if (match) channel = `telegram:${match[1]}:${match[2]}`;
}

if (!channel) {
  throw new Error("Could not determine channel from session context");
}
```

### Step 3: Start Claude Code with Iceman

Use integrated starter script with automatic monitoring:

```bash
~/nebo-command-center/start-session.sh \
  --workdir /home/matt/bibleai \
  --channel "${CHANNEL}" \
  --prompt "/plan ${ARGS}"
```

Parse session name from output and report to user:

```
✅ Planning started with monitoring

Session: claude-1770177123
Channel: discord:channel:1466888482793459813
Workdir: /home/matt/bibleai
Task: /plan ${ARGS}

You'll receive notifications in this channel when Claude Code needs approval.

Approval commands:
• approve claude-1770177123 - Allow once
• always claude-1770177123 - Allow all similar
• deny claude-1770177123 - Reject

Manual commands:
• tmux attach -t claude-1770177123 - View session
```

**Monitoring is automatic** - iceman daemon tracks session and sends notifications

### Step 4: Verify Plan Created

When Claude Code finishes:
```bash
# Check for plan file
ls -la /home/matt/bibleai/docs/plans/*[slug]*

# Verify plan has required sections
grep -E "(Goals|Tasks|Verification)" /home/matt/bibleai/docs/plans/YYYY-MM-DD-[slug].md
```

If plan file missing or incomplete, report error and exit.

### Step 5: Update State

Use helper scripts to update all tracking:

```bash
SLUG="[actual-slug]"
PLAN_FILE="docs/plans/YYYY-MM-DD-${SLUG}.md"
DESIGN_FILE=$(find /home/matt/bibleai/docs/design -name "*${SLUG}*" | head -1)
TASKS_COUNT=$(grep -c "^[0-9]\." "/home/matt/bibleai/${PLAN_FILE}" || echo 0)

# Write results file
~/clawd/scripts/write-results.sh "$SLUG" "plan" \
  "plan_file=${PLAN_FILE}" \
  "design_file=${DESIGN_FILE}" \
  "tasks_count=${TASKS_COUNT}"

# Update plan-status-overview.md
~/clawd/scripts/update-plan-overview.sh "$SLUG" "Planned"

# Update Notion status
~/clawd/scripts/update-notion-status.sh "$SLUG" "Planned"

# Update Notion plan file field
~/clawd/scripts/update-notion-field.sh "$SLUG" "Plan File" "$PLAN_FILE" \
  "https://github.com/m2015agg/bibleai/blob/main/${PLAN_FILE}"

# Update memory
echo "
## Active Work

**Slug:** ${SLUG}
**Phase:** plan
**Status:** Planned
**Plan File:** ${PLAN_FILE}
" >> /home/matt/clawd/memory/$(date +%Y-%m-%d).md
```

### Step 6: Report Results

```
✅ Planning complete for [slug]

📋 Summary:
- Plan file: docs/plans/YYYY-MM-DD-[slug].md
- Status: Planned
- Tasks: [count]

Next: `/implement [slug]`
```

## Key Rules

- ❌ **DO NOT answer questions for Matt** (relay them instead)
- ❌ **DO NOT write code yourself** (Claude Code does that)
- ❌ **DO NOT kill the session prematurely** (wait for completion)
- ❌ **DO NOT wait passively** (active monitoring every 2-3 minutes)
- ✅ **DO use pty:true** (required for interactive CLIs)
- ✅ **DO monitor actively** (check files, process, memory every 2-3 min)
- ✅ **DO report progress** (update Matt on status, don't go silent)
- ✅ **DO detect and report failures** (stuck, killed, timeout)

## Timeout & Failure Detection

**Signs of failure:**
- Process killed (signal 9) - check `process action:list`
- Stuck spinner for >5 minutes with no file activity
- Memory usage >2GB for Claude Code process
- No plan file after 15+ minutes

**When failure detected:**
1. Report immediately to Matt with details
2. Check what files were created/modified
3. Look for error logs or partial output
4. Offer to retry or write plan directly

## Technical Notes

**workdir:** /home/matt/bibleai  
**Claude Code loads:** MCP servers, .claude/commands/, project context  
**Startup time:** ~10-15 seconds  
**Process tool:** Used for stdin/stdout interaction

## Claude Code Command Definition

The actual workflow is defined in:  
`~/bibleai/.claude/commands/plan.md`

To update this skill, edit that file and run:  
`~/clawd/scripts/sync-claude-commands.sh`

## Notion Integration

When updating task status, use the official helper script:

```bash
# Update Notion task status
~/clawd/scripts/update-notion-status.sh "$SLUG" "Planned"
```

The script uses official Notion skill pattern (curl-based API calls with `~/.config/notion/api_key`).

**To update additional fields** (Plan File, Branch, etc.), use curl directly:

```bash
NOTION_KEY=$(cat ~/.config/notion/api_key)

# Query for task
RESPONSE=$(curl -s -X POST "https://api.notion.com/v1/data_sources/2f72dbd5708f81b3b79c000b6531ec8c/query" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H "Notion-Version: 2025-09-03" \
  -H "Content-Type: application/json" \
  -d '{"filter": {"property": "Slug", "rich_text": {"equals": "'$SLUG'"}}}')

PAGE_ID=$(echo "$RESPONSE" | jq -r '.results[0].id')

# Update properties
curl -s -X PATCH "https://api.notion.com/v1/pages/$PAGE_ID" \
  -H "Authorization: Bearer $NOTION_KEY" \
  -H "Notion-Version: 2025-09-03" \
  -H "Content-Type: application/json" \
  -d '{
    "properties": {
      "Plan File": {
        "rich_text": [{
          "text": {
            "content": "'$PLAN_FILE'",
            "link": {"url": "https://github.com/m2015agg/bibleai/blob/main/'$PLAN_FILE'"}
          }
        }]
      }
    }
  }'
```

**See:** Official Notion skill at `~/.npm-global/lib/node_modules/openclaw/skills/notion/SKILL.md` for full API reference.
