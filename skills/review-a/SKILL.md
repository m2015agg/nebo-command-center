---
name: review-a
description: Code Review Phase (Auto-Approve Mode)
user-invocable: true
metadata: {"clawdbot":{"requires":{"bins":["claude"]}}}
---

# review-a - Claude Code Review with Auto-Approve

Invokes Claude Code's `/review` command with **automatic approval enabled** - no manual intervention needed.

## When to Use

Trigger when Matt says:
- `/review-a [args]`
- "review-a [topic]"
- "fast review [topic]"

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
  --auto-approve \
  --prompt "/review ${ARGS}"
```

Parse session name from output and report to user:

```
✅ Review started with monitoring

Session: claude-1770177123
Channel: discord:channel:1466888482793459813
Workdir: /home/matt/bibleai
Task: /review ${ARGS}

You'll receive notifications in this channel when Claude Code needs approval.

Approval commands:
• approve claude-1770177123 - Allow once
• always claude-1770177123 - Allow all similar
• deny claude-1770177123 - Reject

Manual commands:
• tmux attach -t claude-1770177123 - View session
```

**Monitoring is automatic** - iceman daemon tracks session and sends notifications

### Step 4: Verify Review Complete

When Claude Code finishes:
```bash
cd /home/matt/bibleai

# Verify tests ran and passed
# (check for test output in Claude Code logs)

# Verify branch is up to date
git fetch
git status
```

If tests failed, report error and exit. Do not proceed to state updates.

### Step 5: Update State

Use helper scripts to update all tracking:

```bash
cd /home/matt/bibleai

SLUG="[actual-slug]"
BRANCH=$(git branch --show-current)
TEST_STATUS="passing"  # From verification step
COVERAGE="[from test output if available]"

# Write results file
~/clawd/scripts/write-results.sh "$SLUG" "review" \
  "branch=${BRANCH}" \
  "test_status=${TEST_STATUS}" \
  "coverage=${COVERAGE}"

# Update plan-status-overview.md (move to Code Review)
CURRENT_BRANCH=$(git branch --show-current)
git checkout main
~/clawd/scripts/update-plan-overview.sh "$SLUG" "Code Review"
git checkout "$CURRENT_BRANCH"

# Update Notion status
~/clawd/scripts/update-notion-status.sh "$SLUG" "Reviewing"

# Update Notion test status field
~/clawd/scripts/update-notion-field.sh "$SLUG" "Test Status" "Passing"

# Update memory
echo "
## Active Work

**Slug:** ${SLUG}
**Phase:** review
**Status:** Reviewing
**Tests:** Passing
" >> /home/matt/clawd/memory/$(date +%Y-%m-%d).md
```

### Step 6: Report Results

```
✅ Review complete for [slug]

📋 Summary:
- Branch: feature/[slug]
- Tests: Passing
- Status: Reviewing

Next: `/finalize [slug]`
```

## Key Rules

- ❌ **DO NOT answer questions for Matt** (relay them instead)
- ❌ **DO NOT write code yourself** (Claude Code does that)
- ❌ **DO NOT kill the session prematurely** (wait for completion)
- ✅ **DO use pty:true** (required for interactive CLIs)
- ✅ **DO monitor output regularly** (check for questions)
- ✅ **DO report progress** (keep Matt informed)

## Technical Notes

**workdir:** /home/matt/bibleai  
**Claude Code loads:** MCP servers, .claude/commands/, project context  
**Startup time:** ~10-15 seconds  
**Process tool:** Used for stdin/stdout interaction

## Claude Code Command Definition

The actual workflow is defined in:  
`~/bibleai/.claude/commands/review.md`

To update this skill, edit that file and run:  
`~/clawd/scripts/sync-claude-commands.sh`

## Notion Integration

When updating task status, use the official helper script:

```bash
# Update Notion task status
~/clawd/scripts/update-notion-status.sh "$SLUG" "[STATUS]"
```

The script uses official Notion skill pattern (curl-based API calls with `~/.config/notion/api_key`).

**To update additional fields** (Branch, PR URL, Test Status, etc.), use curl directly:

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
      "Branch": {
        "rich_text": [{
          "text": {
            "content": "'$BRANCH'",
            "link": {"url": "https://github.com/m2015agg/bibleai/tree/'$BRANCH'"}
          }
        }]
      }
    }
  }'
```

**See:** Official Notion skill at `~/.npm-global/lib/node_modules/openclaw/skills/notion/SKILL.md` for full API reference.
