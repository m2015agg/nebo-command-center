---
name: codex-review
description: Security & Code Quality Review using Codex (NEBO monitoring)
user-invocable: true
metadata: {"clawdbot":{"requires":{"bins":["codex"]}}}
---

# codex-review - Security & Quality Review with Codex

Uses Codex CLI for comprehensive code review focusing on security, cleanliness, best practices, and "all the smart dope stuff."

## When to Use

Trigger when Matt says:
- `/codex-review [files/dirs]`
- "review security of [path]"
- "check code quality [path]"
- "codex review my code"

## What Gets Reviewed

**Security:**
- Vulnerability scanning (OWASP Top 10)
- Authentication/authorization issues
- Input validation & sanitization
- SQL injection, XSS, CSRF risks
- Secrets & credential exposure
- Dependency vulnerabilities

**Code Quality:**
- Code smells & anti-patterns
- Performance bottlenecks
- Error handling gaps
- Type safety issues
- Unused/dead code
- Code complexity (cyclomatic)

**Best Practices:**
- Architecture patterns
- SOLID principles
- DRY violations
- Naming conventions
- Documentation gaps
- Test coverage

**"Smart Dope Stuff":**
- Scalability concerns
- Race conditions
- Memory leaks
- Edge case handling
- API design flaws
- Database query optimization

## Workflow

### Step 1: Extract Arguments

Parse the command and extract file/directory to review.

If no path provided, default to current project root or recently changed files:
```bash
# Default: Review git changes
git diff --name-only main...HEAD
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

### Step 3: Build Review Prompt

Create detailed prompt for Codex focusing on security & quality:

```bash
REVIEW_PATH="${ARGS:-$(git diff --name-only main...HEAD | tr '\n' ' ')}"

PROMPT="Comprehensive security and code quality review:

Target: ${REVIEW_PATH}

Review Checklist:
1. Security Vulnerabilities
   - Authentication/authorization flaws
   - Input validation issues
   - Injection vulnerabilities (SQL, XSS, command)
   - Sensitive data exposure
   - Security misconfigurations
   - Known CVEs in dependencies

2. Code Quality
   - Anti-patterns and code smells
   - Performance issues
   - Error handling completeness
   - Type safety concerns
   - Dead/unreachable code
   - Complexity hotspots

3. Best Practices
   - Architecture violations
   - SOLID principle adherence
   - DRY violations
   - Naming & documentation
   - Test coverage gaps

4. Advanced Issues
   - Concurrency/race conditions
   - Memory leak risks
   - Edge case handling
   - Scalability concerns
   - Database query optimization

Severity Levels:
- CRITICAL: Immediate security risk or data loss
- HIGH: Major bug or security concern
- MEDIUM: Quality issue or technical debt
- LOW: Style/convention improvement

Output Format:
- Summary (3-5 lines)
- Issues by severity (with file:line references)
- Recommended fixes
- Priority order for remediation"
```

### Step 4: Start Codex with NEBO Monitoring

Use NEBO with `--agent codex` flag:

```bash
~/nebo-command-center/start-session.sh \
  --workdir /home/matt/bibleai \
  --channel "${CHANNEL}" \
  --agent codex \
  --prompt "${PROMPT}"
```

Parse session name from output and report to user.

### Step 5: Report Session Started

```
🔍 **Security & Quality Review Started**

Session: codex-1770225688
Agent: Codex
Workdir: /home/matt/bibleai
Reviewing: ${REVIEW_PATH}

Focus Areas:
✓ Security vulnerabilities
✓ Code quality & cleanliness
✓ Best practices
✓ Performance & scalability

You'll receive notifications in this channel when Codex needs approval.

Approval commands:
• approve codex-1770225688 - Allow once
• always codex-1770225688 - Allow all similar
• deny codex-1770225688 - Reject

Manual commands:
• tmux attach -t codex-1770225688 - View session
• ~/nebo-command-center/lib/session-status.sh codex-1770225688 - Check status
```

**Monitoring is automatic** - NEBO daemon tracks session and sends notifications.

## Example Usage

**Review recent changes:**
```
/codex-review
```

**Review specific file:**
```
/codex-review api/routes/auth.py
```

**Review entire module:**
```
/codex-review BibleLizi_API/app/services/
```

**Review before commit:**
```
review security before I commit
```

## Output Format

Codex will provide structured review output:

```markdown
## Security & Quality Review Report

### Summary
Reviewed 12 files (850 lines). Found 3 CRITICAL, 5 HIGH, 8 MEDIUM issues.
Primary concern: SQL injection in user query endpoint.

### CRITICAL Issues

#### 1. SQL Injection Vulnerability
**File:** `api/routes/search.py:45`
**Issue:** Unsanitized user input directly concatenated into SQL query
**Risk:** Database compromise, data exfiltration
**Fix:**
```python
# BAD
query = f"SELECT * FROM users WHERE name = '{user_input}'"

# GOOD
query = "SELECT * FROM users WHERE name = %s"
cursor.execute(query, (user_input,))
```
**Priority:** Fix immediately

### HIGH Issues
...

### Recommendations
1. Fix CRITICAL issues before deployment
2. Add input validation middleware
3. Update dependencies (3 CVEs found)
4. Increase test coverage (currently 42%, target 80%)
```

## Key Rules

- ❌ **DO NOT auto-fix issues** (Codex reviews only, doesn't edit)
- ❌ **DO NOT skip security checks** (always run full checklist)
- ✅ **DO provide file:line references** (exact locations)
- ✅ **DO prioritize by severity** (CRITICAL first)
- ✅ **DO include example fixes** (show correct pattern)
- ✅ **DO check dependencies** (npm audit, pip check, etc.)

## Advanced Options

### Deep Security Scan

For extra thorough security review:
```bash
~/nebo-command-center/start-session.sh \
  --workdir /home/matt/bibleai \
  --channel "${CHANNEL}" \
  --agent codex \
  --prompt "Deep security audit with OWASP Top 10 focus: ${REVIEW_PATH}. Include dependency CVE scan, secrets detection, and penetration test recommendations."
```

### Performance Review

For performance-focused review:
```bash
PROMPT="Performance & scalability review: ${REVIEW_PATH}. Focus on: database query optimization, N+1 queries, caching opportunities, memory leaks, algorithmic complexity, async/await patterns."
```

### Pre-Production Checklist

Before deploying to production:
```bash
PROMPT="Pre-production security & quality gate: ${REVIEW_PATH}. Verify: no hardcoded secrets, all inputs validated, error handling comprehensive, logging secure, dependencies up-to-date, tests passing."
```

## Integration with Development Workflow

**After implementation (`/implement`):**
1. Run `/codex-review` on changed files
2. Fix CRITICAL & HIGH issues
3. Run `/review` (Claude Code tests)
4. Commit when clean

**Before creating PR:**
```bash
# Review PR diff
/codex-review $(git diff --name-only main...HEAD)
```

**Scheduled reviews:**
Use NEBO cron to run weekly security scans on entire codebase.

## Technical Notes

**Agent:** Uses Codex CLI (not Claude Code)  
**Workdir:** Defaults to current project  
**Session prefix:** `codex-TIMESTAMP`  
**NEBO monitoring:** Auto-enabled with channel routing  
**Output:** Structured markdown report with severity levels

## Codex vs Claude Code

| Feature | Codex | Claude Code |
|---------|-------|-------------|
| Security scanning | ✅ Specialized | ⚠️ General |
| Code quality | ✅ Deep analysis | ✅ Good |
| Performance review | ✅ Detailed | ✅ Basic |
| Auto-fix | ❌ Review only | ✅ Can edit |
| Best for | Pre-commit review | Implementation |

## Related Skills

- `/review` - Claude Code full review (tests + fixes)
- `/implement` - Implementation phase
- `/plan` - Planning phase

## Troubleshooting

### Codex not installed

```bash
# Install Codex CLI
npm install -g codex-cli
# or check installation docs
```

### Review taking too long

Codex reviews are thorough - large codebases may take 5-10 minutes.
Narrow scope to specific files for faster results:
```
/codex-review api/routes/auth.py api/models/user.py
```

### No issues found

Good news! But consider:
- Check Codex actually reviewed the files (not empty diff)
- Try deep security scan mode
- Review may have focused on different areas (request specific focus)

## Success Criteria

After `/codex-review`:
- ✅ No CRITICAL security issues
- ✅ All HIGH issues documented with fixes
- ✅ No hardcoded secrets or credentials
- ✅ Input validation present
- ✅ Dependencies up-to-date (no known CVEs)
- ✅ Code quality acceptable (no major anti-patterns)

**If criteria not met:** Fix issues before proceeding to `/review` or deployment.
