#!/bin/bash
# session-cleanup.sh - Kill a session and clean up associated resources
# Usage: session-cleanup.sh <session-name>
#
# Actions:
#   1. Kill the tmux session
#   2. Remove channel registry entry
#   3. Remove notification state

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SESSION="${1:-}"

if [ -z "$SESSION" ]; then
    echo "Usage: $0 <session-name>" >&2
    exit 1
fi

# State directories
STATE_DIR="${NEBO_MONITOR_STATE_DIR:-/tmp/nebo-orchestrator}"
CHANNEL_REGISTRY="$STATE_DIR/channel-registry.json"
NOTIFY_STATE_DIR="$STATE_DIR/notify-state"

echo "[Cleanup] Session: $SESSION"

# Step 1: Kill tmux session
if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "[Cleanup] Killing tmux session..."
    tmux kill-session -t "$SESSION"
    echo "[Cleanup] ✓ Session killed"
else
    echo "[Cleanup] Session not found (already killed?)"
fi

# Step 2: Remove from channel registry
if [ -f "$CHANNEL_REGISTRY" ]; then
    if jq -e --arg sess "$SESSION" '.[$sess]' "$CHANNEL_REGISTRY" >/dev/null 2>&1; then
        echo "[Cleanup] Removing from channel registry..."
        TEMP_FILE=$(mktemp)
        jq --arg sess "$SESSION" 'del(.[$sess])' "$CHANNEL_REGISTRY" > "$TEMP_FILE"
        mv "$TEMP_FILE" "$CHANNEL_REGISTRY"
        echo "[Cleanup] ✓ Registry entry removed"
    fi
fi

# Step 3: Remove notification state
NOTIFY_STATE_FILE="$NOTIFY_STATE_DIR/$SESSION.state"
if [ -f "$NOTIFY_STATE_FILE" ]; then
    echo "[Cleanup] Removing notification state..."
    rm -f "$NOTIFY_STATE_FILE"
    echo "[Cleanup] ✓ Notification state removed"
fi

echo ""
echo "[Cleanup] ✓ Session '$SESSION' cleaned up"
