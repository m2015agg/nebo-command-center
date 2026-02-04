# Plan Skill

Start Claude Code CLI planning session, watch for questions, then kill tmux so Matt continues in VS Code.

## Installation

This skill is in: `~/clawd/skills/plan/`

Clawdbot auto-discovers skills in the workspace `skills/` directory.

## Usage

Trigger the skill with:
```
/plan [topic]
```

Or:
```
"Start planning for [topic]"
"Plan [topic]"
```

## What It Does

1. **Creates tmux session** with Claude Code CLI in `/home/matt/bibleai`
2. **Sends** `/plan [topic]` command to Claude Code
3. **Watches** tmux output for Claude's questions (looks for "?" characters)
4. **Kills tmux** once questions appear (3+ "?" found)
5. **Matt continues** in VS Code → Recent Conversations

## Files

```
plan/
├── SKILL.md                        # Main skill instructions
├── scripts/
│   └── start-and-kill.sh          # Tmux watch-and-kill script
└── README.md                       # This file
```

## How It Works

The script:
1. Creates tmux session: `claude-plan-[timestamp]`
2. Runs `/home/matt/.npm-global/bin/claude` in `/home/matt/bibleai`
3. Sends `/plan [topic]` via tmux send-keys
4. Polls tmux capture-pane every 2 seconds (max 90 sec)
5. Kills session when 3+ "?" detected (indicates questions asked)

## Example Session

```
Matt: /plan python-mmr-rag

Lizi: 🚀 Starting Claude Code planning session for: python-mmr-rag
      📋 Session: claude-plan-1738252800
      ⏳ Waiting for Claude to ask questions...
      ✅ Claude has asked questions!
      🔪 Killing tmux session...
      
      ✅ Planning session completed for: python-mmr-rag
      
      📂 To continue:
         1. Open Claude Code in VS Code
         2. Recent Conversations → Search for 'python-mmr-rag'
         3. Answer the questions and continue planning
```

## Troubleshooting

**Skill not triggering?**
- Check skill is in `~/clawd/skills/plan/SKILL.md`
- Restart Clawdbot gateway: `clawdbot gateway restart`
- Check logs: `clawdbot gateway logs`

**Claude Code not starting?**
- Verify Claude Code installed: `npm list -g @anthropic-ai/claude-code`
- Check path in script: `/home/matt/.npm-global/bin/claude`
- Test manually: `tmux new -s test "cd /home/matt/bibleai && /home/matt/.npm-global/bin/claude"`

**Timeout without questions?**
- Session remains running: `tmux attach -t claude-plan-[timestamp]`
- Check Claude Code is responding: `tmux capture-pane -t claude-plan-[timestamp] -p`
- Kill manually: `tmux kill-session -t claude-plan-[timestamp]`

**"?" detection not working?**
- Script looks for 3+ "?" characters in tmux output
- Adjust threshold in script if needed
- Questions usually contain multiple "?" marks
