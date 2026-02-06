# Workflow Detail: Create Mode

## Prompt Template for Claude Code (Create Mode)

Full autonomous prompt for creating a new app from scratch with GitHub repo + Vercel deployment.

### Variables to replace

| Variable | Description | Example |
|----------|-------------|---------|
| `{TASK}` | What to build | "A task management app with drag-and-drop" |
| `{APP_NAME}` | Project/repo name | `task-manager` |
| `{FRAMEWORK}` | Framework to use | `nextjs` (default) |
| `{JOB_ID}` | Unique job ID | `create-20260206-150000` |

### Framework Detection

| User says | Framework |
|-----------|-----------|
| "Next.js", "React", "Vercel app", default | `npx create-next-app@latest` |
| "Nuxt", "Vue" | `npx nuxi@latest init` |
| "SvelteKit" | `npx sv create` |
| "Astro" | `npm create astro@latest` |
| "Remix" | `npx create-remix@latest` |
| Unspecified | Default to Next.js (best Vercel integration) |

### Claude Code Prompt

```
You are an autonomous coding agent. Work silently and efficiently. Never ask questions.

TASK: Create a new application — {TASK}
APP_NAME: {APP_NAME}
FRAMEWORK: {FRAMEWORK}
JOB_ID: {JOB_ID}
STATUS_FILE: /tmp/claude-dev-jobs/{JOB_ID}/status.json

## Steps

1. UPDATE STATUS: phase=setup, message="Preparation du projet {APP_NAME}"
2. mkdir -p /tmp/claude-dev-jobs/{JOB_ID} && cd /tmp/claude-dev-jobs/{JOB_ID}
3. Scaffold project using {FRAMEWORK} CLI into directory named {APP_NAME}
4. cd {APP_NAME}
5. UPDATE STATUS: phase=coding, message="Scaffolding termine, implementation en cours"
6. Implement what the user asked for — build the actual features
7. Test locally if possible (npm run build)
8. UPDATE STATUS: phase=pushing, message="Creation du repo GitHub"
9. git init && git add . && git commit -m "feat: initial implementation of {APP_NAME}"
10. gh repo create {APP_NAME} --public --source=. --remote=origin --push
11. Save repo URL
12. UPDATE STATUS: phase=pushing, repo=<REPO_URL>, message="Repo cree, liaison Vercel en cours"
13. Link to Vercel:
    - vercel link --yes (auto-detect framework)
    - vercel --yes (trigger first deployment)
    - Or: vercel project add and vercel git connect for GitHub integration
14. Get production URL from vercel output
15. UPDATE STATUS: phase=pr-created, message="Creation PR pour review"
16. git checkout -b feat/initial-implementation
17. git push -u origin feat/initial-implementation
18. gh pr create --title "feat: initial implementation of {APP_NAME}" --body "<description>"
19. Wait 30s for Vercel preview deploy
20. Get Vercel preview URL
21. UPDATE STATUS: phase=awaiting-review, pr_url=<URL>, vercel_url=<URL>, repo=<REPO_URL>, message="App creee! Repo: <REPO> — Preview: <VERCEL_URL>"
22. Notify: openclaw gateway wake --text "Nouvelle app {APP_NAME} prete! Repo: <REPO_URL> — Preview: <VERCEL_URL>" --mode now
```

## Vercel Project Setup Notes

### If user has Vercel GitHub integration (recommended)
- Every push/PR auto-deploys
- Preview URL generated per PR automatically
- Just `vercel link` and `vercel git connect`

### If no GitHub integration
- Manual deploy with `vercel --yes`
- Get URL from output
- Set up with `vercel project add`

### Production vs Preview
- `vercel --prod` → production deployment
- Each PR → automatic preview deployment (if GitHub integration active)
- Preview URLs look like: `https://<project>-<hash>-<team>.vercel.app`
