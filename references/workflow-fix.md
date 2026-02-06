# Workflow Detail: Fix Mode

## Prompt Template for Claude Code (Fix Mode)

Below is the full autonomous prompt to send to Claude Code when fixing a bug or improving an existing repo.

### Variables to replace

| Variable | Description | Example |
|----------|-------------|---------|
| `{TASK}` | What to fix/improve | "Fix the login redirect loop on mobile" |
| `{REPO_URL}` | GitHub repo URL | `https://github.com/user/myapp` |
| `{BRANCH}` | Branch name | `fix/login-redirect-mobile` |
| `{JOB_ID}` | Unique job ID | `fix-20260206-143022` |

### Claude Code Prompt

```
You are an autonomous coding agent. Work silently and efficiently. Never ask questions.

TASK: {TASK}
REPO: {REPO_URL}
BRANCH: {BRANCH}
JOB_ID: {JOB_ID}
STATUS_FILE: /tmp/claude-dev-jobs/{JOB_ID}/status.json

## Status update helper
After each step, update the status file:
python3 -c "
import json, datetime
d = json.load(open('/tmp/claude-dev-jobs/{JOB_ID}/status.json'))
d['phase'] = 'PHASE_HERE'
d['message'] = 'MESSAGE_HERE'
d['last_updated'] = datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
json.dump(d, open('/tmp/claude-dev-jobs/{JOB_ID}/status.json', 'w'), indent=2)
"

## Steps

1. UPDATE STATUS: phase=cloning, message="Clonage du repo"
2. git clone {REPO_URL} /tmp/claude-dev-jobs/{JOB_ID}/repo && cd /tmp/claude-dev-jobs/{JOB_ID}/repo
3. UPDATE STATUS: phase=branching, message="Creation branche {BRANCH}"
4. git checkout -b {BRANCH}
5. UPDATE STATUS: phase=coding, message="Analyse et codage en cours"
6. Read the code, understand the issue, implement the fix
7. UPDATE STATUS: phase=committing, message="Commit des changements"
8. git add <specific files> && git commit -m "fix: <description>"
9. UPDATE STATUS: phase=pushing, message="Push de la branche"
10. git push -u origin {BRANCH}
11. UPDATE STATUS: phase=pr-created, message="Creation de la PR"
12. Create PR: gh pr create --title "fix: <title>" --body "<body with details>"
13. Save PR URL and number
14. Wait 30s, then fetch Vercel preview URL from PR checks
15. UPDATE STATUS: phase=awaiting-review, pr_url=<URL>, vercel_url=<URL>, message="PR prete! Preview: <VERCEL_URL>"
16. Notify: openclaw gateway wake --text "PR prete pour review! <PR_URL> - Preview: <VERCEL_URL>" --mode now
```

## Branch Naming Convention

| Type | Pattern | Example |
|------|---------|---------|
| Bug fix | `fix/<description>` | `fix/login-redirect-mobile` |
| Feature | `feat/<description>` | `feat/dark-mode-toggle` |
| Improvement | `improve/<description>` | `improve/api-error-handling` |
| Refactor | `refactor/<description>` | `refactor/auth-module` |

## Vercel Preview URL Detection

Vercel automatically creates preview deployments for PRs on linked repos. To get the URL:

```bash
# Method 1: From PR checks
gh pr checks <NUMBER> --json name,detailsUrl --jq '.[] | select(.name | test("vercel|deploy"; "i")) | .detailsUrl'

# Method 2: From PR comments (Vercel bot comments)
gh api repos/{owner}/{repo}/issues/{number}/comments --jq '.[] | select(.user.login == "vercel[bot]") | .body' | grep -oP 'https://[a-zA-Z0-9-]+\.vercel\.app'

# Method 3: From deployment status
gh api repos/{owner}/{repo}/deployments --jq '.[0].payload.web_url // .[0].environment_url'
```

If no Vercel integration exists on the repo, note it in the status and suggest the user link it.
