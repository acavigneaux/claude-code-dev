# Troubleshooting claude-code-dev

This document covers the critical fixes required to make claude-code-dev work reliably on OpenClaw.

## The Three Critical Fixes

After extensive testing (2026-02-09), we identified three issues that prevent claude-code-dev from executing properly from Telegram/OpenClaw:

### 1. Missing `claude-run` Symlink

**Problem:**
- OpenClaw's TOOLS.md requires `claude-run` instead of `claude`
- Error in logs: `sh: 1: claude-run: not found`
- Skills fail to execute Claude Code commands

**Root Cause:**
- TOOLS.md contains rule: "MUST use `claude-run` instead of `claude` directly"
- Only `claude` binary exists, no `claude-run` alias

**Solution:**
```bash
ln -sf /usr/local/bin/claude /usr/local/bin/claude-run
```

**Validation:**
```bash
which claude-run        # Should return /usr/local/bin/claude-run
claude-run --version    # Should show Claude Code version
```

---

### 2. Session Lock Files Blocking Execution

**Problem:**
- Skills timeout with "All models failed" error
- Logs show: `session file locked (timeout 10000ms): pid=27`
- OpenClaw cannot execute because session files are locked

**Root Cause:**
- Stale lock files in `/data/.openclaw/agents/main/sessions/`
- Previous executions left `.lock` files that never got cleaned up
- OpenClaw waits for lock timeout (10 seconds) then fails

**Solution:**
```bash
rm -f /data/.openclaw/agents/main/sessions/*.lock
```

**Prevention:**
- Clean old session files periodically
- After crashes/restarts, clean locks before using skills

**Validation:**
```bash
# Should return no results
find /data/.openclaw/agents/main/sessions/ -name "*.lock"
```

---

### 3. Vercel Retry Loop (10x Deployments)

**Problem:**
- Vercel deployment command runs 10 times in a row
- Logs show: `vercel --yes --prod` called every 13-16 seconds
- Creates 10 queued deployments in Vercel dashboard
- Wastes resources and causes confusion

**Root Cause:**
- GPT-5.1 model doesn't wait long enough for Vercel to complete
- Vercel builds take 20-60 seconds
- Model retries command thinking it failed when it's still running

**Solution:**
Add explicit rules to `/data/.openclaw/IDENTITY.md`:

```markdown
## CRITICAL: Vercel Deployment Rules

**NEVER retry Vercel deployments automatically!**

When deploying to Vercel:
- 🛑 Execute `vercel --yes --prod` **ONLY ONCE**
- ⏳ Wait at least 60 seconds for the deployment to complete
- ❌ DO NOT retry if it seems slow - Vercel builds take 20-60 seconds
- ✅ After deployment, use `vercel ls <project-name>` to check status
- 📋 Only ONE deployment per request, NEVER multiple

**If deployment fails:**
- Check the error message
- Fix the issue
- Deploy again ONCE

**NEVER run vercel --yes --prod multiple times in a row!**
```

**Validation:**
- Test deployment: should see only 1 deployment in `vercel ls <project>`
- Check OpenClaw logs: should see only one `vercel --yes --prod` call

---

### 4. Git Push Authentication (Bonus Fix)

**Problem:**
- Git push fails with: `fatal: could not read Username for 'https://github.com'`
- Affects repos that weren't created with `gh repo create`

**Root Cause:**
- Git remote using HTTPS but no credentials configured
- Container environment has no interactive terminal for credentials

**Solution:**
Configure Git to use `gh` for authentication:

```bash
git config --global credential.helper '!gh auth git-credential'
```

**Alternative (Recommended):**
Always use `gh` for GitHub operations:
- ✅ `gh repo create <name> --public --source=. --push`
- ❌ `git push origin main` (will fail)

Add to `/data/.openclaw/IDENTITY.md`:

```markdown
## CRITICAL: GitHub Push Rules

**ALWAYS use gh for GitHub operations, NOT raw git commands!**

When pushing to GitHub:
- ✅ CORRECT: `gh repo create <name> --public --source=. --push`
- ❌ WRONG: `git push origin main` (will fail with HTTPS auth)

**Why:** Git credential helper is configured to use gh auth.

If repo already exists and you need to push:
- ✅ Use: `gh repo sync` or ensure remote uses gh credentials
- The credential helper will use gh token automatically
```

---

## Installation on New VPS

To set up claude-code-dev on a fresh OpenClaw instance:

### 1. Run the setup script

```bash
# From inside the OpenClaw container
cd /path/to/claude-code-dev
./scripts/setup.sh
```

This installs `gh`, `vercel`, and verifies `claude` is available.

### 2. Apply the critical fixes

```bash
# Fix 1: Create claude-run symlink
ln -sf /usr/local/bin/claude /usr/local/bin/claude-run

# Fix 2: Clean session locks (if any exist)
rm -f /data/.openclaw/agents/main/sessions/*.lock

# Fix 3 & 4: Add IDENTITY rules (see IDENTITY-RULES.md)
# Manually add the Vercel and GitHub rules to /data/.openclaw/IDENTITY.md

# Fix 4 (alternative): Configure git credential helper
git config --global credential.helper '!gh auth git-credential'
```

### 3. Verify everything works

```bash
# Check claude-run exists
which claude-run

# Check no locks exist
find /data/.openclaw/agents/main/sessions/ -name "*.lock"

# Check git config
git config --global credential.helper

# Test the skill from Telegram
# Send: "crée une app counter simple"
# Should work without approval blocking or retry loops
```

---

## Common Issues

### Skill doesn't execute from Telegram

**Symptoms:**
- No response from OpenClaw
- Timeout errors
- "All models failed"

**Checklist:**
1. ✅ Check `claude-run` exists: `which claude-run`
2. ✅ Clean session locks: `rm -f /data/.openclaw/agents/main/sessions/*.lock`
3. ✅ Verify skill is installed: `openclaw skills list | grep claude-code-dev`
4. ✅ Check OpenClaw logs: `docker logs -f openclaw-0nfu-openclaw-1`

### Vercel deploys multiple times

**Symptoms:**
- Multiple deployments in Vercel dashboard
- Logs show repeated `vercel --yes --prod` calls

**Fix:**
- Add anti-retry rules to `/data/.openclaw/IDENTITY.md` (see Fix #3 above)
- Restart OpenClaw container: `docker restart openclaw-0nfu-openclaw-1`

### Git push fails with authentication error

**Symptoms:**
- `fatal: could not read Username for 'https://github.com'`
- Push commands hang or fail

**Fix:**
- Use `gh` commands instead of raw `git push`
- OR configure credential helper: `git config --global credential.helper '!gh auth git-credential'`
- Add GitHub rules to IDENTITY.md (see Fix #4 above)

---

## Testing After Fixes

### Test 1: Simple app creation

From Telegram:
```
crée une app dice-roller avec un dé à 6 faces
```

**Expected:**
- App created in `/data/projects/dice-roller`
- Build passes
- GitHub repo created
- **Only 1 Vercel deployment**
- No approval blocking
- No timeout errors

### Test 2: Check deployment count

```bash
vercel ls dice-roller
```

**Expected:**
Should show only 1 production deployment (not 10).

### Test 3: Check logs for retries

```bash
docker logs openclaw-0nfu-openclaw-1 2>&1 | grep "vercel --yes --prod" | tail -20
```

**Expected:**
Should see only 1 occurrence per app, not multiple retry attempts.

---

## Success Metrics (After Fixes Applied)

- ✅ Skills execute automatically from Telegram without manual intervention
- ✅ No approval blocking or timeout errors
- ✅ Vercel deploys exactly once per request
- ✅ Git push operations succeed
- ✅ Apps created successfully with GitHub + Vercel

**Test results (2026-02-09):**
- Created dice-roller from Telegram: SUCCESS
- Only 1 Vercel deployment instead of 10: SUCCESS
- User confirmation: "ok ca a marché" and "ca a l'air de fonctionner"

---

## Files Modified During Fixes

1. `/usr/local/bin/claude-run` - created symlink to claude
2. `/data/.openclaw/agents/main/sessions/*.lock` - deleted all locks
3. `/data/.openclaw/IDENTITY.md` - added Vercel and GitHub rules
4. `~/.gitconfig` - configured credential helper

These fixes are now documented in this repository for easy reinstallation.
