#!/bin/bash
# Start Claude Code planning session, wait for questions, then kill tmux

TOPIC="$1"
SESSION_NAME="claude-plan-$(date +%s)"

if [ -z "$TOPIC" ]; then
    echo "❌ Usage: $0 <topic-name>"
    exit 1
fi

echo "🚀 Starting Claude Code planning session for: $TOPIC"
echo "📋 Session: $SESSION_NAME"

# Create tmux session and start claude
CLAUDE_BIN="/home/matt/.npm-global/bin/claude"
tmux new-session -d -s "$SESSION_NAME" -c /home/matt/bibleai "$CLAUDE_BIN"

# Wait for Claude to be ready (prompt appears)
# Claude Code takes ~10 seconds to load MCP servers and config
sleep 10

# Send /plan command
tmux send-keys -t "$SESSION_NAME" "/plan $TOPIC" C-m

# Wait a moment for command to register, then send another Enter to start processing
sleep 2
tmux send-keys -t "$SESSION_NAME" C-m

echo "⏳ Waiting for Claude to ask questions..."

# Watch the session for questions (look for "?" which indicates questions)
MAX_WAIT=90
ELAPSED=0
QUESTIONS_FOUND=0

while [ $ELAPSED -lt $MAX_WAIT ]; do
    # Capture last 50 lines of the pane
    OUTPUT=$(tmux capture-pane -t "$SESSION_NAME" -p -S -50)
    
    # Check if Claude has asked questions (multiple "?" chars suggest questions)
    QUESTION_COUNT=$(echo "$OUTPUT" | grep -o "?" | wc -l)
    
    if [ "$QUESTION_COUNT" -ge 3 ]; then
        echo "✅ Claude has asked questions!"
        QUESTIONS_FOUND=1
        break
    fi
    
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

if [ $QUESTIONS_FOUND -eq 1 ]; then
    echo "🔪 Killing tmux session..."
    tmux kill-session -t "$SESSION_NAME"
    echo ""
    echo "✅ Planning session completed for: $TOPIC"
    echo ""
    echo "📂 To continue:"
    echo "   1. Open Claude Code in VS Code"
    echo "   2. Recent Conversations → Search for '$TOPIC'"
    echo "   3. Answer the questions and continue planning"
    echo ""
    exit 0
else
    echo "⚠️  Timeout waiting for questions (${MAX_WAIT}s)"
    echo "🔍 Session is still running: $SESSION_NAME"
    echo "   Attach: tmux attach -t $SESSION_NAME"
    echo "   Kill: tmux kill-session -t $SESSION_NAME"
    exit 1
fi
