#!/bin/bash
# register-session-channel.sh - Register a Claude Code session with its source channel
# Usage: register-session-channel.sh <session-name> <channel-target> [auto-approve]
#
# Example:
#   register-session-channel.sh claude-1234567 "discord:channel:1466888482793459813"
#   register-session-channel.sh claude-7654321 "discord:channel:123" "auto-approve"

set -e

SESSION="${1:-}"
CHANNEL="${2:-}"
AUTO_APPROVE="${3:-}"

if [ -z "$SESSION" ] || [ -z "$CHANNEL" ]; then
    echo "Usage: $0 <session-name> <channel-target> [auto-approve]" >&2
    echo "" >&2
    echo "Example:" >&2
    echo "  $0 claude-1234567 'discord:channel:1466888482793459813'" >&2
    echo "  $0 claude-1234567 'discord:channel:123' 'auto-approve'" >&2
    exit 1
fi

# Validate channel format
if [[ ! "$CHANNEL" =~ ^(discord|telegram|whatsapp):(channel|chat|user):.+ ]]; then
    echo "Error: Invalid channel format: $CHANNEL" >&2
    echo "Expected format: service:type:id" >&2
    echo "Examples:" >&2
    echo "  discord:channel:1466888482793459813" >&2
    echo "  telegram:chat:987654321" >&2
    echo "  whatsapp:user:+1234567890" >&2
    exit 1
fi

# Find state directory
STATE_DIR="${NEBO_MONITOR_STATE_DIR:-/tmp/nebo-orchestrator}"
CHANNEL_REGISTRY="$STATE_DIR/channel-registry.json"

# Create state dir if needed
mkdir -p "$STATE_DIR"
chmod 700 "$STATE_DIR"

# Update registry
TEMP_FILE=$(mktemp)

# Determine auto-approve setting
if [ "$AUTO_APPROVE" = "auto-approve" ]; then
    AUTO_APPROVE_JSON="true"
else
    AUTO_APPROVE_JSON="false"
fi

if [ -f "$CHANNEL_REGISTRY" ]; then
    jq --arg sess "$SESSION" \
       --arg chan "$CHANNEL" \
       --argjson auto "$AUTO_APPROVE_JSON" \
       '.[$sess] = {channel: $chan, autoApprove: $auto}' \
       "$CHANNEL_REGISTRY" > "$TEMP_FILE"
else
    jq -n --arg sess "$SESSION" \
          --arg chan "$CHANNEL" \
          --argjson auto "$AUTO_APPROVE_JSON" \
          '{($sess): {channel: $chan, autoApprove: $auto}}' > "$TEMP_FILE"
fi

mv "$TEMP_FILE" "$CHANNEL_REGISTRY"
chmod 600 "$CHANNEL_REGISTRY"

if [ "$AUTO_APPROVE" = "auto-approve" ]; then
    echo "✓ Registered session '$SESSION' → channel '$CHANNEL' (AUTO-APPROVE ENABLED)"
else
    echo "✓ Registered session '$SESSION' → channel '$CHANNEL'"
fi
