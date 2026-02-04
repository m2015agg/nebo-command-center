---
name: systematic-debugging-c
description: Systematic Debugging using Claude Code
user-invocable: true
metadata: {"clawdbot":{"requires":{"bins":["claude"]}}}
---

# systematic-debugging-c - Systematic Debugging with Claude Code

Invokes Claude Code's `/systematic-debugging` command to debug issues using the four-phase framework:
1. Root cause investigation
2. Pattern analysis  
3. Hypothesis testing
4. Implementation

## When to Use

Trigger when Matt says:
- `/systematic-debugging-c [bug description]`
- "debug [issue] with claude"
- "systematic debugging for [bug]"

## What This Does

Uses Claude Code's systematic debugging workflow instead of ad-hoc fixes:
- **Phase 1:** Root cause investigation (no guessing)
- **Phase 2:** Pattern analysis (find similar issues)
- **Phase 3:** Hypothesis testing (verify before fixing)
- **Phase 4:** Implementation (minimal, targeted fix)

## Workflow

### Step 1: Extract Bug Description

Parse the command and extract the bug/issue description:

```javascript
const bugDescription = extractedArgs; // e.g., "tests failing in auth module"
```

### Step 2: Get Channel Context

Extract current channel from session context:

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

### Step 3: Start Claude Code with Debugging Command

Use NEBO with the systematic debugging command:

```bash
~/nebo-command-center/start-session.sh \
  --workdir /home/matt/bibleai \
  --channel "${CHANNEL}" \
  --prompt "/systematic-debugging ${BUG_DESCRIPTION}"
```

Parse session name from output and report to user.

### Step 4: Report Session Started

```
🐛 **Systematic Debugging Started**

Session: claude-1770233690
Workdir: /home/matt/bibleai
Bug: ${BUG_DESCRIPTION}

Claude Code will follow the systematic debugging framework:
1. Root cause investigation
2. Pattern analysis
3. Hypothesis testing
4. Implementation

You'll receive notifications in this channel when Claude Code needs approval.

Approval commands:
• approve claude-1770233690 - Allow once
• always claude-1770233690 - Allow all similar
• deny claude-1770233690 - Reject

Manual commands:
• tmux attach -t claude-1770233690 - View session
```

**Monitoring is automatic** - NEBO daemon tracks session and sends notifications.

## Example Usage

**Debug failing tests:**
```
/systematic-debugging-c tests failing in auth module
```

**Debug performance issue:**
```
/systematic-debugging-c API endpoint slow on production
```

**Debug crash:**
```
systematic debugging for app crash on startup
```

## Why Use This Instead of Regular /implement?

| Approach | When to Use |
|----------|-------------|
| `/implement` | You know what to build/change |
| `/systematic-debugging-c` | You have a bug but don't know the cause |

**Systematic debugging** ensures:
- ✅ Root cause found before attempting fix
- ✅ No cargo-cult debugging ("try this and see")
- ✅ Pattern recognition (similar bugs elsewhere)
- ✅ Hypothesis testing (verify understanding)
- ✅ Minimal, targeted fixes

## Key Rules

- ❌ **DO NOT skip investigation** (always find root cause first)
- ❌ **DO NOT guess fixes** (test hypotheses before implementing)
- ✅ **DO use instrumentation** (add logging/tests to verify)
- ✅ **DO check for patterns** (similar bugs in codebase)
- ✅ **DO verify fix works** (run tests, reproduce bug)

## Technical Notes

**Workdir:** /home/matt/bibleai  
**Session prefix:** `claude-TIMESTAMP`  
**NEBO monitoring:** Auto-enabled with channel routing  
**Command:** `/systematic-debugging` in Claude Code

## Related Skills

- `/implement` - Implementation phase (when you know what to build)
- `/review` - Code review phase (after implementation)
- `/codex-review` - Security & quality review

## Success Criteria

After `/systematic-debugging-c`:
- ✅ Root cause identified and documented
- ✅ Hypothesis tested and verified
- ✅ Fix implemented with minimal changes
- ✅ Tests passing (bug no longer reproducible)
- ✅ Similar patterns checked/fixed elsewhere
