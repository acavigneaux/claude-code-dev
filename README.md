# claude-code-dev

Skill OpenClaw qui transforme Claude Code en agent de dev autonome. Tu lui demandes via Telegram, il code, fait une PR, deploy sur Vercel, et te tient au courant.

## Ce que ca fait

Tu envoies un message a OpenClaw sur Telegram :

> "Fix le bug de redirect sur https://github.com/acavigneaux/mon-app"

> "Cree-moi une app Next.js pour tracker mes depenses"

OpenClaw lance Claude Code en arriere-plan qui :

1. Clone le repo (ou cree un nouveau projet)
2. Cree une branche de travail
3. Code le fix / la feature
4. Commit + push
5. Cree une PR sur GitHub
6. Recupere le lien de preview Vercel
7. T'envoie le lien pour tester

Pendant ce temps, un **cron OpenClaw** t'envoie un update toutes les minutes.

Apres test, tu peux :
- Donner des corrections ("change le bouton en bleu")
- Valider ("c'est bon, merge")

A la fin, Claude Code merge la PR, supprime la branche, et nettoie tout.

## Deux modes

| Mode | Declencheur | Exemple |
|------|------------|---------|
| **Fix** | Bug/amelioration sur repo existant | "Fix le login sur github.com/user/repo" |
| **Create** | Nouvelle app from scratch | "Cree-moi une app de todo en Next.js" |

## Architecture

```
Telegram → OpenClaw (orchestrateur, GPT-5.1)
               ↓
           Claude Code (arriere-plan sur le host VPS)
               ↓
           Status JSON (/tmp/claude-dev-jobs/<id>/status.json)
               ↓
           Cron OpenClaw (update Telegram toutes les 1 min)
```

## Structure du skill

```
claude-code-dev/
├── SKILL.md                         # Instructions pour OpenClaw
├── scripts/
│   ├── setup.sh                     # Installation gh, vercel, node
│   └── status.sh                    # Lecture du status des jobs
└── references/
    ├── workflow-fix.md              # Detail du workflow mode fix
    └── workflow-create.md           # Detail du workflow mode create
```

## Setup (deja fait sur le VPS)

Les outils suivants sont installes et authentifies sur le host :

| Outil | Version | Compte |
|-------|---------|--------|
| `claude` (Claude Code) | 2.1.34 | Anthropic |
| `gh` (GitHub CLI) | 2.86.0 | acavigneaux |
| `vercel` | 50.12.3 | acavigneaux-3921 |
| `node` | 22.22.0 | — |

Si besoin de reinstaller :

```bash
bash /root/claude-code-dev/scripts/setup.sh
```

## Ou c'est installe

- **Skill dans OpenClaw** : `/usr/local/lib/node_modules/openclaw/skills/claude-code-dev/` (dans le container Docker `openclaw-0nfu-openclaw-1`)
- **Source sur le host** : `/root/claude-code-dev/`
- **Jobs en cours** : `/tmp/claude-dev-jobs/<job-id>/status.json`

Pour mettre a jour le skill dans le container apres un changement :

```bash
docker cp /root/claude-code-dev openclaw-0nfu-openclaw-1:/usr/local/lib/node_modules/openclaw/skills/claude-code-dev
```

## Commandes utiles

```bash
# Verifier que le skill est detecte
docker exec openclaw-0nfu-openclaw-1 openclaw skills info claude-code-dev

# Voir le status du dernier job
cat /tmp/claude-dev-jobs/$(ls -t /tmp/claude-dev-jobs/ | head -1)/status.json

# Lister les crons actifs
docker exec openclaw-0nfu-openclaw-1 openclaw cron list

# Envoyer un message test sur Telegram
docker exec openclaw-0nfu-openclaw-1 openclaw message send --channel telegram --target 6897220925 --message "Test"
```

## En cas de probleme

Si Claude Code bloque, dis a OpenClaw :
- "kill le job" → il tue la session et supprime le cron
- "ou en es-tu ?" → il lit le status.json et te repond
- "relance" → il redemarre depuis la ou ca a plante

OpenClaw peut aussi detecter tout seul si le status n'a pas bouge depuis 5 minutes et agir.
