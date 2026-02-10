# IDENTITY.md Rules for claude-code-dev

Add these rules to `/data/.openclaw/IDENTITY.md` to prevent common issues with claude-code-dev skill.

---

## CRITICAL: GitHub Push Rules

**ALWAYS use gh for GitHub operations, NOT raw git commands!**

When pushing to GitHub:
- ✅ CORRECT: `gh repo create <name> --public --source=. --push`
- ❌ WRONG: `git push origin main` (will fail with HTTPS auth)

**Why:** Git credential helper is configured to use gh auth.

If repo already exists and you need to push:
- ✅ Use: `gh repo sync` or ensure remote uses gh credentials
- The credential helper will use gh token automatically

---

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

---

## How to Apply

1. Open `/data/.openclaw/IDENTITY.md` in your editor
2. Add the above sections to the file (anywhere after the header)
3. Save the file
4. Restart OpenClaw container: `docker restart openclaw-0nfu-openclaw-1`

## Validation

After applying these rules:
- Vercel should deploy exactly once per request (not 10 times)
- Git push operations should use `gh` commands and succeed
- Check with: `vercel ls <project-name>` should show only 1 deployment
