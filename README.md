# claude-code-dev

Skill OpenClaw qui transforme Claude Code en agent de dev autonome. Tu lui demandes via Telegram, il code, fait une PR, deploy sur Vercel, et te tient au courant.

## Ce que ca fait

Tu envoies un message a OpenClaw sur Telegram :

> "Fix le bug de redirect sur https://github.com/acavigneaux/mon-app"

> "Cree-moi une app Next.js pour tracker mes depenses"

OpenClaw lance Claude Code qui :

1. Cree le dossier du projet (ou clone le repo)
2. Genere tout le code via `claude -p`
3. Verifie que le build passe
4. Cree un repo GitHub + push
5. Deploy sur Vercel
6. T'envoie les liens (GitHub + Vercel)

## Deux modes

| Mode | Declencheur | Exemple |
|------|------------|---------|
| **Create** | Nouvelle app from scratch | "Cree-moi une app de todo en Next.js" |
| **Fix** | Bug/amelioration sur repo existant | "Fix le login sur github.com/user/repo" |

## Architecture

```
Telegram --> OpenClaw (container Docker, GPT-5.1)
                |
                v
            bash elevated:true (dans le container)
                |
                v
            claude -p --dangerously-skip-permissions
                |
                v
            gh repo create + vercel --prod
                |
                v
            Liens GitHub + Vercel --> Telegram
```

### Comment ca marche

- OpenClaw tourne dans un container Docker (`openclaw-0nfu-openclaw-1`)
- Les commandes `bash elevated:true` s'executent **dans le container** avec privileges eleves
- Le container a `claude`, `gh`, `vercel`, `node`, `npm`, `git` installes
- Le working directory est `/data/projects/` (monte depuis le host, persistant)
- HOME du container = `/data` (configs d'auth dans `/data/.config/`, `/data/.claude/`, etc.)

## Setup

### Prerequis

- OpenClaw v2026.2+ avec Docker
- Compte GitHub (`gh auth login`)
- Compte Vercel (`vercel login`)
- Claude Code CLI authentifie

### Installation dans le container

1. Copier le skill dans OpenClaw :
```bash
docker cp claude-code-dev openclaw-0nfu-openclaw-1:/usr/local/lib/node_modules/openclaw/skills/claude-code-dev
```

2. Installer les outils dans le container :
```bash
# Claude CLI
docker cp /usr/local/bin/claude openclaw-0nfu-openclaw-1:/data/.openclaw/claude
docker exec openclaw-0nfu-openclaw-1 ln -sf /data/.openclaw/claude /usr/local/bin/claude

# gh CLI
docker exec openclaw-0nfu-openclaw-1 bash -c 'curl -sL https://github.com/cli/cli/releases/download/v2.67.0/gh_2.67.0_linux_amd64.tar.gz | tar xz -C /tmp && cp /tmp/gh_2.67.0_linux_amd64/bin/gh /usr/local/bin/gh'

# Vercel (via npm)
docker exec openclaw-0nfu-openclaw-1 npm install -g vercel
docker exec openclaw-0nfu-openclaw-1 ln -sf /skeleton/.npm-global/bin/vercel /usr/local/bin/vercel
```

3. Copier les configs d'auth (HOME=/data dans le container) :
```bash
# gh
docker exec openclaw-0nfu-openclaw-1 mkdir -p /data/.config/gh
docker cp ~/.config/gh/hosts.yml openclaw-0nfu-openclaw-1:/data/.config/gh/
docker cp ~/.config/gh/config.yml openclaw-0nfu-openclaw-1:/data/.config/gh/
docker exec openclaw-0nfu-openclaw-1 bash -c 'mkdir -p /root/.config && ln -sf /data/.config/gh /root/.config/gh'

# vercel
docker exec openclaw-0nfu-openclaw-1 mkdir -p /data/.local/share/com.vercel.cli
docker cp ~/.local/share/com.vercel.cli/auth.json openclaw-0nfu-openclaw-1:/data/.local/share/com.vercel.cli/
docker cp ~/.local/share/com.vercel.cli/config.json openclaw-0nfu-openclaw-1:/data/.local/share/com.vercel.cli/

# claude
docker exec openclaw-0nfu-openclaw-1 mkdir -p /data/.claude
docker cp ~/.claude/.credentials.json openclaw-0nfu-openclaw-1:/data/.claude/

# git
docker exec openclaw-0nfu-openclaw-1 git config --global user.name "USERNAME"
docker exec openclaw-0nfu-openclaw-1 git config --global user.email "USERNAME@users.noreply.github.com"
```

4. Verifier :
```bash
docker exec openclaw-0nfu-openclaw-1 openclaw skills list | grep claude-code-dev
docker exec openclaw-0nfu-openclaw-1 claude --version
docker exec openclaw-0nfu-openclaw-1 gh auth status
docker exec openclaw-0nfu-openclaw-1 vercel whoami
```

### Apres un restart du container

Les symlinks dans `/usr/local/bin/` et le binaire `gh` sont perdus. Relancer :

```bash
docker exec openclaw-0nfu-openclaw-1 ln -sf /data/.openclaw/claude /usr/local/bin/claude
docker exec openclaw-0nfu-openclaw-1 bash -c 'curl -sL https://github.com/cli/cli/releases/download/v2.67.0/gh_2.67.0_linux_amd64.tar.gz | tar xz -C /tmp && cp /tmp/gh_2.67.0_linux_amd64/bin/gh /usr/local/bin/gh'
docker exec openclaw-0nfu-openclaw-1 ln -sf /skeleton/.npm-global/bin/vercel /usr/local/bin/vercel
docker exec openclaw-0nfu-openclaw-1 bash -c 'mkdir -p /root/.config && ln -sf /data/.config/gh /root/.config/gh'
docker exec openclaw-0nfu-openclaw-1 git config --global user.name "USERNAME"
docker exec openclaw-0nfu-openclaw-1 git config --global user.email "USERNAME@users.noreply.github.com"
```

## Structure du skill

```
claude-code-dev/
├── SKILL.md          # Instructions pour OpenClaw (workflow CREATE + FIX)
├── README.md         # Ce fichier
├── scripts/
│   ├── setup.sh      # Installation des outils
│   └── status.sh     # Lecture du status des jobs (legacy)
└── references/
    ├── workflow-fix.md    # Detail du workflow mode fix
    └── workflow-create.md # Detail du workflow mode create
```

## Commandes utiles

```bash
# Verifier que le skill est detecte
docker exec openclaw-0nfu-openclaw-1 openclaw skills list | grep claude-code-dev

# Voir les projets en cours
docker exec openclaw-0nfu-openclaw-1 ls /data/projects/

# Tester claude dans le container
docker exec openclaw-0nfu-openclaw-1 claude -p "say hello" --max-turns 1
```
