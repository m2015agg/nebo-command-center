---
name: implement
description: Implementation Phase (Uses Iceman monitoring)
user-invocable: true
metadata: {"clawdbot":{"requires":{"bins":["claude"]}}}
---

# implement - Claude Code with Iceman Monitoring

Uses nebo-command-center for automatic approval notifications with channel routing.

## When to Use

Trigger when Matt says:
- `/implement [args]`
- "implement [topic]"

## Features

- ✅ Uses `start-session.sh` from nebo-command-center
- ✅ Automatic channel registration (notifications route to correct Discord/Telegram/WhatsApp channel)
- ✅ Monitor daemon auto-starts if needed
- ✅ Approval commands work from any channel: `approve session-name`

## Workflow

### Step 1: Extract Arguments

Parse the command and extract any arguments/topic provided.

### Step 2: Get Channel Context

Extract current channel from session context:

```javascript
// Get current session key: agent:main:discord:channel:1466888482793459813
const sessionKey = getCurrentSessionKey();

// Parse channel from session key
let channel = "";
if (sessionKey.includes("discord:channel:")) {
  const match = sessionKey.match(/discord:channel:(\d+)/);
  if (match) {
    channel = `discord:channel:${match[1]}`;
  }
} else if (sessionKey.includes("telegram:")) {
  // Extract telegram channel
  const match = sessionKey.match(/telegram:([^:]+):(\d+)/);
  if (match) {
    channel = `telegram:${match[1]}:${match[2]}`;
  }
}

if (!channel) {
  throw new Error("Could not determine channel from session context");
}
```

### Step 3: Start Claude Code with Iceman

Use the integrated starter script:

```bash
~/nebo-command-center/start-session.sh \
  --workdir /home/matt/bibleai \
  --channel "${CHANNEL}" \
  --prompt "/implement ${ARGS}"
```

**Full implementation:**

```javascript
const args = extractedArgs; // e.g., "m2-plan" or "feature-x"
const channel = extractedChannel; // e.g., "discord:channel:1466888482793459813"

const result = exec({
  command: `~/nebo-command-center/start-session.sh \\
    --workdir /home/matt/bibleai \\
    --channel "${channel}" \\
    --prompt "/implement ${args}"`,
  timeout: 30
});

// Parse session name from output
const output = result.stdout || "";
const sessionMatch = output.match(/Session name: ([\w-]+)/);
const sessionName = sessionMatch ? sessionMatch[1] : "unknown";

return {
  sessionName,
  channel,
  message: `✅ Started Claude Code session: ${sessionName}\n\nChannel: ${channel}\n\nYou'll receive Discord notifications when approval is needed.\n\nApproval commands:\n• approve ${sessionName} - Allow once\n• always ${sessionName} - Allow all similar\n• deny ${sessionName} - Reject\n\nMonitor: tmux attach -t ${sessionName}`
};
```

### Step 4: Confirm to User

Report session details:

```
✅ Implementation started with monitoring

Session: claude-1770177123
Channel: discord:channel:1466888482793459813
Workdir: /home/matt/bibleai
Task: /implement feature-x

Monitor daemon: Running (PID 12345)

You'll receive notifications in this channel when Claude Code needs approval.

Approval commands (in this channel):
• approve claude-1770177123 - Allow once
• always claude-1770177123 - Allow all similar
• deny claude-1770177123 - Reject

Manual commands:
• tmux attach -t claude-1770177123 - View session
• tmux kill-session -t claude-1770177123 - Stop session
```

## Handling Approval Commands

When user responds with approval commands:

```
User: "approve claude-1770177123"
```

Match pattern and call iceman handler:

```bash
# Detect approval command
if message.match(/^(approve|always|deny)\s+(claude-\d+)$/i) {
  const action = match[1].toLowerCase();
  const session = match[2];
  
  // Call iceman approval handler
  exec({
    command: `~/nebo-command-center/lib/handle-approval.sh ${action} ${session}`
  });
  
  return `✓ Session '${session}' ${action} command sent`;
}
```

## Session Status

Check session status:

```bash
~/nebo-command-center/lib/session-status.sh <session-name> --json
```

## Monitor Daemon Status

Check if monitor is running:

```bash
cat /tmp/nebo-orchestrator/master-monitor.pid 2>/dev/null
```

Start monitor if not running:

```bash
~/nebo-command-center/nebo-monitor.sh &
```

## Channel Registry

View registered sessions:

```bash
cat /tmp/nebo-orchestrator/channel-registry.json | jq .
```

Example output:
```json
{
  "claude-1770177123": "discord:channel:1466888482793459813",
  "claude-1770177456": "telegram:chat:987654321"
}
```

## Cleanup

When session ends, registry entry is automatically cleaned up by monitor daemon.

Manual cleanup if needed:

```bash
tmux kill-session -t <session-name>
# Registry will be cleaned on next monitor cycle
```

## Implementation Benefits

- **Multi-channel support**: Works from Discord, Telegram, WhatsApp
- **Automatic monitoring**: No manual checking required
- **Clean approval flow**: Simple commands in chat
- **Session isolation**: Multiple concurrent implementations supported

## Troubleshooting

### No notifications received

1. Check webhook token:
   ```bash
   jq -r '.hooks.token' ~/.openclaw/openclaw.json
   ```

2. Check monitor daemon:
   ```bash
   cat /tmp/nebo-orchestrator/master-monitor.pid
   ps aux | grep master-monitor
   ```

3. Check registry:
   ```bash
   jq . /tmp/nebo-orchestrator/channel-registry.json
   ```

### Approval commands not working

1. Verify session name is correct
2. Check session exists:
   ```bash
   tmux list-sessions | grep <session-name>
   ```

3. Check monitor logs:
   ```bash
   tail -50 /tmp/nebo-orchestrator/master-monitor.log
   ```

### Wrong channel receives notification

1. Check registry entry:
   ```bash
   jq '."<session-name>"' /tmp/nebo-orchestrator/channel-registry.json
   ```

2. Re-register if wrong:
   ```bash
   ~/nebo-command-center/lib/register-session-channel.sh <session-name> "discord:channel:123"
   ```

## Configuration

### Required

**Webhook Token** in `~/.openclaw/openclaw.json`:
```json
{
  "hooks": {
    "token": "your-webhook-token-here"
  }
}
```

### Optional

**Custom State Directory:**
```bash
export CLAUDE_MONITOR_STATE_DIR="/path/to/state"
```

**Custom Poll Interval:**
```bash
~/nebo-command-center/nebo-monitor.sh --poll-interval 5  # Check every 5 seconds
```

## Security

- ✅ Command injection fixed (uses `-l` flag)
- ✅ Secure temp directories (chmod 700)
- ✅ Input validation on session names and channels
- ⚠️ Webhook token in config file (ensure chmod 600)
- ⚠️ Registry file world-readable by default (improvement needed)

## Related Files

- `/home/matt/nebo-command-center/start-claude-session.sh` - Session starter
- `/home/matt/nebo-command-center/nebo-monitor.sh` - Monitor daemon
- `/home/matt/nebo-command-center/lib/register-session-channel.sh` - Channel registration
- `/home/matt/nebo-command-center/lib/handle-approval.sh` - Approval handler
