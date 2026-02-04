# NEBO Command Center

**Network of Error-fixing Bots and Operations**

Automated Claude Code and Codex session management with multi-channel notifications for **Discord**, Telegram, and WhatsApp.

---

## Features

✅ **Multi-Channel Notifications**
- Automatic routing to Discord, Telegram, or WhatsApp
- Notifications sent to the channel where command was invoked

✅ **Approval Management**
- Manual approval mode (default - full control)
- Auto-approve mode (fast execution, no interruptions)

✅ **Security Hardened**
- All CRITICAL and HIGH vulnerabilities fixed
- Command injection prevention
- Webhook token protection
- Full security audit included

✅ **Session Monitoring**
- Auto-detects approval prompts
- Web dashboard for oversight
- tmux-based session isolation

---

## Getting Started with Discord

**Primary use case:** Discord slash commands trigger Claude Code sessions with notifications routed back to Discord.

### Prerequisites Checklist

Before starting, ensure you have:

- [ ] **Discord Bot Created** (https://discord.com/developers/applications)
  - Bot token copied
  - Intents enabled: Presence, Server Members, Message Content
  - Scopes: `bot` + `applications.commands`
  - Bot invited to your server
  
- [ ] **OpenClaw/Clawdbot Installed** (https://docs.openclaw.ai/)
  - Gateway running: `openclaw status`
  - Discord channel configured in `~/.openclaw/openclaw.json`
  - Webhook enabled with secure token
  
- [ ] **Claude Code CLI Installed** (https://claude.ai/code)
  - Command available: `which claude`
  - Authenticated: `claude --version`
  
- [ ] **System Tools**
  - tmux: `which tmux`
  - jq: `which jq`
  - Node.js: `which node`

- [ ] **Discord IDs Collected**
  - Guild ID (your server ID)
  - Channel ID (where bot will send notifications)
  - Enable Developer Mode in Discord to get these

### How It Works

```
Discord User: /plan new-feature
     ↓
OpenClaw Bot detects slash command
     ↓
Skill extracts channel: discord:channel:1466888482793459813
     ↓
NEBO start-session.sh launches Claude Code in tmux
     ↓
Session registered: claude-1770236959 → discord:channel:123
     ↓
Monitor daemon polls session for approval prompts
     ↓
Approval detected → Notification sent to Discord
     ↓
User responds: "approve claude-1770236959" (or clicks button)
     ↓
Monitor handles approval → Claude Code continues
     ↓
Result posted to Discord when complete
```

### What You'll Get

Once setup is complete:

✅ **Slash commands in Discord**: `/plan`, `/implement`, `/review`, `/codex-review`  
✅ **Auto-approval or manual approval**: Choose your workflow  
✅ **Multi-session support**: Multiple team members can run sessions concurrently  
✅ **Web dashboard** (optional): Real-time monitoring at `https://your-domain.com`  
✅ **Channel routing**: Notifications go back to the channel where command was invoked  

**See full setup instructions below.** ⬇️

---

## Quick Start

### 1. Install Prerequisites

```bash
# Claude Code CLI
# Get from: https://claude.ai/code

# Codex CLI (optional)
npm install -g codex-cli

# OpenClaw/Clawdbot
# Follow: https://docs.openclaw.ai/

# System tools
sudo apt install tmux jq nodejs
```

### 2. Clone This Repository

```bash
git clone https://github.com/nebopartners/nebo-command-center.git
cd nebo-command-center
chmod +x *.sh lib/*.sh
```

### 3. Configure OpenClaw Webhook

Edit `~/.openclaw/openclaw.json`:

```json
{
  "hooks": {
    "enabled": true,
    "token": "YOUR_SECURE_TOKEN_HERE"
  }
}
```

Generate secure token:
```bash
openssl rand -hex 32
```

Set permissions:
```bash
chmod 600 ~/.openclaw/openclaw.json
```

### 4. Install Skills in OpenClaw

NEBO provides custom skills that integrate with OpenClaw's skill system. These become available as `/plan`, `/implement`, `/review`, etc.

**Step 1: Copy skills to OpenClaw workspace**

Find your OpenClaw workspace (usually `~/clawd` or `~/openclaw`):

```bash
# Example: if your workspace is ~/clawd
cp -r skills/* ~/clawd/skills/

# Or symlink to keep skills in sync with updates:
ln -s $(pwd)/skills/plan ~/clawd/skills/plan
ln -s $(pwd)/skills/implement ~/clawd/skills/implement
ln -s $(pwd)/skills/review ~/clawd/skills/review
ln -s $(pwd)/skills/codex-review ~/clawd/skills/codex-review
ln -s $(pwd)/skills/systematic-debugging-c ~/clawd/skills/systematic-debugging-c
```

**Step 2: Verify skills are loaded**

Restart OpenClaw gateway to load new skills:

```bash
openclaw gateway restart
```

Check that skills are available:

```bash
openclaw skills list
```

You should see output like:
```
Available skills:
- plan (Planning Phase)
- implement (Implementation Phase)
- review (Code Review Phase)
- codex-review (Security & Code Quality Review)
- systematic-debugging-c (Systematic Debugging)
...
```

**Step 3: Register Discord slash commands**

OpenClaw can register skills as Discord slash commands automatically.

Edit your OpenClaw config (`~/.openclaw/openclaw.json`):

```json
{
  "channels": {
    "discord": {
      "token": "YOUR_DISCORD_BOT_TOKEN",
      "guilds": {
        "YOUR_GUILD_ID": {
          "name": "Your Server Name",
          "slashCommands": {
            "enabled": true,
            "skills": [
              "plan",
              "implement",
              "review",
              "codex-review"
            ]
          }
        }
      }
    }
  }
}
```

**Step 4: Sync commands with Discord**

After config changes, sync the commands:

```bash
openclaw gateway restart
```

Or if OpenClaw supports command sync without restart:

```bash
openclaw discord sync-commands
```

**Step 5: Verify in Discord**

In your Discord server, type `/` in any channel where the bot has access. You should see:

```
/plan              - Start planning phase
/implement         - Start implementation phase
/review            - Start code review phase
/codex-review      - Security & quality review
```

**Alternative: Manual registration (if auto-sync doesn't work)**

If your OpenClaw version doesn't auto-register slash commands, you can do it manually:

```bash
# Install discord.js CLI tools
npm install -g discord-slash-commands-cli

# Register commands
discord-slash-commands register \
  --token YOUR_BOT_TOKEN \
  --guild YOUR_GUILD_ID \
  --commands discord-commands.json
```

Create `discord-commands.json`:

```json
[
  {
    "name": "plan",
    "description": "Start planning phase with Claude Code",
    "options": [
      {
        "name": "topic",
        "description": "Feature or topic to plan",
        "type": 3,
        "required": true
      }
    ]
  },
  {
    "name": "implement",
    "description": "Start implementation phase with Claude Code",
    "options": [
      {
        "name": "topic",
        "description": "Feature or topic to implement",
        "type": 3,
        "required": true
      }
    ]
  },
  {
    "name": "review",
    "description": "Start code review phase with Claude Code",
    "options": [
      {
        "name": "topic",
        "description": "Feature or topic to review",
        "type": 3,
        "required": true
      }
    ]
  },
  {
    "name": "codex-review",
    "description": "Security and code quality review with Codex",
    "options": [
      {
        "name": "path",
        "description": "Path to review (optional)",
        "type": 3,
        "required": false
      }
    ]
  }
]
```

**Troubleshooting: Skills not appearing**

```bash
# Check skills directory
ls -la ~/clawd/skills/

# Check skill frontmatter (must have user-invocable: true)
head -20 ~/clawd/skills/plan/SKILL.md

# Check OpenClaw logs for errors
journalctl -u openclaw-gateway -f

# Verify SKILL.md format
cat ~/clawd/skills/plan/SKILL.md
```

Each skill must have this frontmatter:

```yaml
---
name: plan
description: Planning Phase
user-invocable: true
---
```

### 5. Setup Discord Bot (If Not Already Done)

If you haven't set up a Discord bot yet, follow these steps:

**Step 1: Create Discord Application**

1. Go to https://discord.com/developers/applications
2. Click **New Application**
3. Name it (e.g., "NEBO Bot")
4. Go to **Bot** tab → Click **Add Bot**
5. **Copy the bot token** (you'll need this for OpenClaw config)

**Step 2: Configure Bot Permissions**

In the **Bot** tab, enable these intents:
- ✅ **Presence Intent**
- ✅ **Server Members Intent**
- ✅ **Message Content Intent**

**Step 3: Generate Invite URL**

In **OAuth2** → **URL Generator**:

**Scopes:**
- ✅ `bot`
- ✅ `applications.commands`

**Bot Permissions:**
- ✅ Read Messages/View Channels
- ✅ Send Messages
- ✅ Send Messages in Threads
- ✅ Embed Links
- ✅ Attach Files
- ✅ Add Reactions
- ✅ Use Slash Commands

Copy the generated URL and open it to invite the bot to your server.

**Step 4: Get Discord IDs**

In Discord client:
1. Enable **Developer Mode**: User Settings → Advanced → Developer Mode
2. Right-click your server → **Copy ID** (Guild ID)
3. Right-click the channel → **Copy ID** (Channel ID)

### 6. Configure Discord in OpenClaw

**In Discord:**
1. Get your OpenClaw bot running and connected to Discord
2. Note your Discord channel ID (from Step 4 above)

**In OpenClaw config (`~/.openclaw/openclaw.json`):**
```json
{
  "hooks": {
    "enabled": true,
    "token": "YOUR_SECURE_TOKEN_HERE"
  },
  "channels": {
    "discord": {
      "token": "YOUR_DISCORD_BOT_TOKEN",
      "defaultChannel": "YOUR_CHANNEL_ID"
    }
  }
}
```

**Verify webhook is working:**
```bash
TOKEN=$(jq -r '.hooks.token' ~/.openclaw/openclaw.json)
CHANNEL_ID="YOUR_CHANNEL_ID"

curl -X POST http://127.0.0.1:18789/hooks/agent \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"message\":\"✅ NEBO webhook test\",\"deliver\":true,\"channel\":\"discord\",\"to\":\"channel:$CHANNEL_ID\"}"
```

You should see the test message appear in Discord.

### 7. Setup Dashboard (Optional but Recommended)

The web dashboard provides real-time monitoring and quick approval actions.

**Install dashboard dependencies:**
```bash
cd dashboard
npm install
```

**Start the dashboard:**
```bash
# Uses the same token from ~/.openclaw/openclaw.json
node tmux-dashboard.js
```

**Access locally:**
```bash
TOKEN=$(jq -r '.hooks.token' ~/.openclaw/openclaw.json)
echo "Dashboard: http://localhost:3333/?token=$TOKEN"
```

**Setup Cloudflare Tunnel (Production):**

See [Dashboard Setup Guide](dashboard/README.md#cloudflare-tunnel-setup) for detailed instructions on:
- Installing `cloudflared`
- Creating a tunnel
- Configuring DNS
- Setting up Cloudflare Access for additional security

**Quick Cloudflare Tunnel Setup:**
```bash
# Install cloudflared
# See: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/

# Authenticate
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create nebo-dashboard

# Configure tunnel (edit config.yml)
cat > ~/.cloudflared/config.yml << EOF
tunnel: <tunnel-id>
credentials-file: /home/matt/.cloudflared/<tunnel-id>.json

ingress:
  - hostname: your-subdomain.yourdomain.com
    service: http://localhost:3333
  - service: http_status:404
EOF

# Add DNS record
cloudflared tunnel route dns nebo-dashboard your-subdomain.yourdomain.com

# Run tunnel
cloudflared tunnel run nebo-dashboard
```

**Access your dashboard:**
```
https://your-subdomain.yourdomain.com/?token=YOUR_TOKEN
```

### 8. Test It

From Discord (via OpenClaw bot):
```
/plan test-feature
```

You should receive a notification in Discord asking for approval.

**Or from Telegram/WhatsApp:**
Commands work the same way from any channel where OpenClaw is configured.

---

## Available Commands

### Discord Slash Commands

Once skills are installed and synced with Discord, you can use these slash commands:

**Planning:**
- `/plan topic:feature-name` - Create implementation plan (manual approval)
- `/plan-a topic:feature-name` - Create plan (auto-approve, fast mode)

**Implementation:**
- `/implement topic:feature-name` - Implement feature (manual approval)
- `/implement-a topic:feature-name` - Implement (auto-approve, fast mode)

**Review:**
- `/review topic:feature-name` - Code review (manual approval)
- `/review-a topic:feature-name` - Review (auto-approve, fast mode)

**Security & Debugging:**
- `/codex-review path:src/` - Security & quality review with Codex
- `/systematic-debugging-c bug:description` - Systematic debugging framework

**Example usage in Discord:**
```
/plan topic:kids-plans-m2
/implement topic:add-auth
/review topic:kids-plans-m2
/codex-review path:lib/
```

### Chat-style Commands (Alternative)

If slash commands aren't configured, you can also invoke skills via chat:

```
@NEBOBot /plan kids-plans-m2
@NEBOBot /implement add-auth
@NEBOBot /review kids-plans-m2
```

**Note:** Slash commands (with `/` prefix in Discord UI) provide better UX with autocomplete and parameter hints.

---

## Architecture

```
User (Discord / Telegram / WhatsApp)
         │
         │ Invokes /plan, /implement, etc.
         │
         ▼
    OpenClaw/Clawdbot
         │
         │ Extracts channel context
         │ Example: discord:channel:1466888482793459813
         │
         ▼
  start-session.sh --workdir DIR --channel "discord:channel:1466888482793459813" --prompt "/plan topic"
         │
         ├──► Registers session → channel mapping
         │
         ├──► Starts nebo-monitor.sh (if not running)
         │
         └──► Launches Claude Code / Codex in tmux
                      │
                      ▼
              nebo-monitor.sh polls for approval prompts
                      │
                      ├──► Auto-approve enabled? → handle-approval.sh
                      │
                      └──► Manual approval? → send-notification.sh
                                   │
                                   ▼
                          POST to OpenClaw webhook
                                   │
                                   ▼
                       Notification in Discord/Telegram/WhatsApp
```

---

## Configuration

### Update Project Paths

Edit skills to point to your project:

```bash
# In each skill's SKILL.md, change:
~/nebo-command-center/start-session.sh \
  --workdir /home/matt/bibleai \     # Change this to your project
  --channel "${CHANNEL}" \
  --prompt "..."
```

Files to update:
- `skills/plan/SKILL.md`
- `skills/plan-a/SKILL.md`
- `skills/implement/SKILL.md`
- `skills/implement-a/SKILL.md`
- `skills/review/SKILL.md`
- `skills/review-a/SKILL.md`
- `skills/codex-review/SKILL.md`
- `skills/systematic-debugging-c/SKILL.md`

### Enable Dashboard (Optional)

The web dashboard provides real-time monitoring of all Claude Code and Codex sessions.

**See detailed setup guide:** [dashboard/README.md](dashboard/README.md)

**Quick start:**
```bash
cd dashboard
npm install

# Dashboard automatically reads token from ~/.openclaw/openclaw.json
node tmux-dashboard.js

# Access locally:
TOKEN=$(jq -r '.hooks.token' ~/.openclaw/openclaw.json)
echo "Dashboard: http://localhost:3333/?token=$TOKEN"
```

**Production setup with Cloudflare Tunnel:**
- Provides secure HTTPS access without exposing ports
- Adds optional email/SSO authentication via Cloudflare Access
- Full instructions in [dashboard/README.md](dashboard/README.md)

---

## Security

### Audit Report

See `docs/security-audit-2026-02-04.md` for comprehensive security audit.

### Fixes Applied

✅ **CRITICAL:**
- Command injection prevention (execFileSync migration)
- Dashboard session send injection fixed

✅ **HIGH:**
- Auth token enforcement (no insecure defaults)
- Query param auth removed (prevents token leakage)
- Webhook token hidden from process list
- State directory permissions enforced

### Best Practices

- Use manual approval (`/plan`, `/implement`, `/review`) for production changes
- Use auto-approve (`/plan-a`, `/implement-a`, `/review-a`) for development
- Rotate webhook tokens regularly
- Review `docs/SECURITY_FIXES.md` for implementation details

---

## Troubleshooting

### No Notifications Received

**Step 1: Check OpenClaw webhook configured**
```bash
jq '.hooks' ~/.openclaw/openclaw.json
# Should show: {"enabled": true, "token": "..."}
```

**Step 2: Check Discord channel configured**
```bash
jq '.channels.discord' ~/.openclaw/openclaw.json
# Should show your Discord bot token and channel info
```

**Step 3: Check monitor running**
```bash
ps aux | grep nebo-monitor
# Should show running process
```

**Step 4: Test webhook manually (Discord)**
```bash
TOKEN=$(jq -r '.hooks.token' ~/.openclaw/openclaw.json)
CHANNEL_ID="1466888482793459813"  # Replace with your channel ID

curl -X POST http://127.0.0.1:18789/hooks/agent \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"message\":\"✅ NEBO test notification\",\"deliver\":true,\"channel\":\"discord\",\"to\":\"channel:$CHANNEL_ID\"}"
```

**Expected:** Message appears in Discord channel  
**If not:** Check OpenClaw logs: `journalctl -u openclaw-gateway -f`

**Step 5: Check session registry**
```bash
cat /tmp/nebo-orchestrator/channel-registry.json | jq .
# Should show your session → channel mapping
```

### Slash Commands Not Appearing in Discord

**Step 1: Verify bot has slash command scope**

Check bot invite URL includes `applications.commands` scope:
```
https://discord.com/api/oauth2/authorize?client_id=YOUR_CLIENT_ID&permissions=YOUR_PERMS&scope=bot%20applications.commands
```

If missing, re-invite the bot with correct scopes.

**Step 2: Check OpenClaw config**

```bash
jq '.channels.discord.guilds' ~/.openclaw/openclaw.json
```

Should show:
```json
{
  "YOUR_GUILD_ID": {
    "slashCommands": {
      "enabled": true,
      "skills": ["plan", "implement", "review"]
    }
  }
}
```

**Step 3: Restart OpenClaw to sync commands**

```bash
openclaw gateway restart
```

**Step 4: Wait for Discord cache**

Discord can take 1-5 minutes to update slash commands. If still not showing:

```bash
# Force re-sync (if OpenClaw supports it)
openclaw discord sync-commands --force
```

**Step 5: Check Discord guild commands**

Using Discord API (requires bot token):

```bash
BOT_TOKEN="YOUR_BOT_TOKEN"
GUILD_ID="YOUR_GUILD_ID"

curl -H "Authorization: Bot $BOT_TOKEN" \
  "https://discord.com/api/v10/applications/@me/guilds/$GUILD_ID/commands" | jq .
```

Should return array with your commands.

**Step 6: Verify skill frontmatter**

Each skill must have `user-invocable: true`:

```bash
head -10 ~/clawd/skills/plan/SKILL.md
```

Expected:
```yaml
---
name: plan
description: Planning Phase
user-invocable: true
---
```

**Step 7: Check OpenClaw logs**

```bash
journalctl -u openclaw-gateway -f | grep -i discord
```

Look for errors like:
- "Failed to register command"
- "Invalid token"
- "Missing scope"

**Common issues:**

❌ **Bot missing `applications.commands` scope** → Re-invite bot  
❌ **Skills not in OpenClaw workspace** → Copy skills and restart  
❌ **Guild ID wrong** → Double-check Discord Developer Mode IDs  
❌ **Bot token invalid** → Regenerate token in Discord Developer Portal  
❌ **Permissions insufficient** → Bot needs "Use Slash Commands" permission  

### Sessions Not Starting

```bash
# Check Claude Code installed
which claude

# Check tmux available  
which tmux

# Check workspace exists
ls -la /path/to/your/project
```

### Approval Commands Not Working

```bash
# Verify session exists
tmux list-sessions | grep claude-

# Check session format
# Valid: claude-1234567890
# Invalid: my-session (must start with "claude-" or "codex-")
```

**Full troubleshooting:** See `docs/CLAUDE_CODE_MONITORING_DESIGN.md`

---

## Directory Structure

```
nebo-command-center/
├── start-session.sh              # Start Claude/Codex sessions
├── nebo-monitor.sh               # Monitor daemon (detects approvals)
├── nebo-session.sh               # Legacy session starter
├── lib/
│   ├── handle-approval.sh        # Process approvals
│   ├── send-notification.sh      # Send to OpenClaw webhook
│   ├── register-session-channel.sh # Register channel mapping
│   ├── session-status.sh         # Detect session state
│   └── session-cleanup.sh        # Clean up sessions
├── skills/
│   ├── plan/                     # Manual approval planning
│   ├── plan-a/                   # Auto-approve planning
│   ├── implement/                # Manual approval implementation
│   ├── implement-a/              # Auto-approve implementation
│   ├── review/                   # Manual approval review
│   ├── review-a/                 # Auto-approve review
│   ├── codex-review/             # Security reviews
│   └── systematic-debugging-c/   # Systematic debugging
├── dashboard/                    # Web dashboard (optional)
├── docs/
│   ├── security-audit-2026-02-04.md      # Security audit
│   ├── SECURITY_FIXES.md                 # Fix documentation
│   └── CLAUDE_CODE_MONITORING_DESIGN.md  # Architecture
└── README.md                     # This file
```

---

## Advanced Usage

### Manual Session Start (Without Skills)

```bash
./start-session.sh \
  --workdir ~/myproject \
  --channel "discord:channel:1234567890" \
  --prompt "Create a hello world script"

# With auto-approve:
./start-session.sh \
  --workdir ~/myproject \
  --channel "discord:channel:1234567890" \
  --auto-approve \
  --prompt "Refactor authentication module"

# With Codex instead of Claude:
./start-session.sh \
  --workdir ~/myproject \
  --channel "discord:channel:1234567890" \
  --agent codex \
  --prompt "Review security of auth.py"
```

### Session Management

```bash
# List sessions
tmux list-sessions

# Attach to session
tmux attach -t claude-1234567890

# Detach: Ctrl+B, then D

# Kill session
tmux kill-session -t claude-1234567890

# Check monitor status
ps aux | grep nebo-monitor

# View monitor logs
tail -f /tmp/nebo-orchestrator/nebo-monitor.log
```

### Channel Registry

View registered sessions:
```bash
cat /tmp/nebo-orchestrator/channel-registry.json | jq .
```

Example output:
```json
{
  "claude-1234567890": {
    "channel": "discord:channel:1466888482793459813",
    "autoApprove": false
  },
  "claude-9876543210": {
    "channel": "telegram:chat:987654321",
    "autoApprove": true
  }
}
```

---

## Contributing

### For Team Members

1. Fork this repository
2. Make your changes
3. Test with `/plan test-feature`
4. Submit pull request

### Adding Custom Skills

Create new skill in `skills/your-skill/SKILL.md`:

```markdown
---
name: your-skill
description: What it does
user-invocable: true
---

# your-skill - Description

## When to Use
Trigger when user says...

## Workflow
1. Extract arguments
2. Start session with start-session.sh
3. Report session started
```

---

## Support

**GitHub:** https://github.com/nebopartners/nebo-command-center  
**Issues:** https://github.com/nebopartners/nebo-command-center/issues

**OpenClaw:**
- Docs: https://docs.openclaw.ai
- Discord: https://discord.com/invite/clawd

**Claude Code:**
- Docs: https://claude.ai/code

---

## License

MIT License - See LICENSE file for details.

Custom development workflow for team use.

---

## Quick Reference

```
┌────────────────────────────────────────────────┐
│ NEBO COMMAND CENTER QUICK REFERENCE            │
├────────────────────────────────────────────────┤
│ Start Session:                                 │
│   ./start-session.sh --workdir DIR \           │
│     --channel "discord:channel:123" \          │
│     --prompt "task"                            │
│                                                │
│ Skills (via OpenClaw):                         │
│   /plan [topic]        - Plan (manual)         │
│   /plan-a [topic]      - Plan (auto)           │
│   /implement [topic]   - Implement (manual)    │
│   /implement-a [topic] - Implement (auto)      │
│   /review [topic]      - Review (manual)       │
│   /review-a [topic]    - Review (auto)         │
│   /codex-review [path] - Security scan         │
│   /systematic-debugging-c [bug] - Debug        │
│                                                │
│ Approval:                                      │
│   approve <session>    - Approve once          │
│   always <session>     - Auto-approve all      │
│   deny <session>       - Reject                │
│   Or: 1, 2, 3                                  │
│                                                │
│ Session Management:                            │
│   tmux list-sessions                           │
│   tmux attach -t <session>                     │
│   tmux kill-session -t <session>               │
└────────────────────────────────────────────────┘
```
