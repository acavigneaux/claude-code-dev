#!/usr/bin/env bash
# setup.sh — Install gh CLI, vercel CLI, and verify claude for claude-code-dev skill
set -euo pipefail

echo "=== Claude Code Dev — Setup ==="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }

# 1. Check Claude Code
echo ""
echo "--- Checking Claude Code ---"
if command -v claude &>/dev/null; then
  ok "claude found: $(claude --version 2>&1 | head -1)"
else
  fail "claude not found. Install Claude Code first: npm install -g @anthropic-ai/claude-code"
  exit 1
fi

# 2. Install GitHub CLI (gh)
echo ""
echo "--- Checking GitHub CLI (gh) ---"
if command -v gh &>/dev/null; then
  ok "gh already installed: $(gh --version | head -1)"
else
  warn "gh not found. Installing..."
  if command -v apt-get &>/dev/null; then
    # Debian/Ubuntu
    (type -p wget >/dev/null || apt-get install -y wget) \
      && mkdir -p -m 755 /etc/apt/keyrings \
      && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
      && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
      && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
      && apt-get update \
      && apt-get install -y gh
  elif command -v brew &>/dev/null; then
    brew install gh
  else
    fail "Cannot auto-install gh. Install manually: https://cli.github.com/"
    exit 1
  fi

  if command -v gh &>/dev/null; then
    ok "gh installed: $(gh --version | head -1)"
  else
    fail "gh installation failed"
    exit 1
  fi
fi

# 3. Check gh auth
echo ""
echo "--- Checking GitHub auth ---"
if gh auth status &>/dev/null 2>&1; then
  ok "gh authenticated"
else
  warn "gh not authenticated. Run: echo '<YOUR_GITHUB_TOKEN>' | gh auth login --with-token"
  echo "  Or interactively: gh auth login"
fi

# 4. Install Vercel CLI
echo ""
echo "--- Checking Vercel CLI ---"
if command -v vercel &>/dev/null; then
  ok "vercel already installed: $(vercel --version 2>&1 | head -1)"
else
  warn "vercel not found. Installing..."
  npm install -g vercel
  if command -v vercel &>/dev/null; then
    ok "vercel installed: $(vercel --version 2>&1 | head -1)"
  else
    fail "vercel installation failed"
    exit 1
  fi
fi

# 5. Check Vercel auth
echo ""
echo "--- Checking Vercel auth ---"
if vercel whoami &>/dev/null 2>&1; then
  ok "vercel authenticated as: $(vercel whoami 2>/dev/null)"
else
  warn "vercel not authenticated. Run: vercel login"
fi

# 6. Check git config
echo ""
echo "--- Checking git config ---"
if git config --global user.name &>/dev/null && git config --global user.email &>/dev/null; then
  ok "git configured: $(git config --global user.name) <$(git config --global user.email)>"
else
  warn "git user not configured. Set with:"
  echo "  git config --global user.name 'Your Name'"
  echo "  git config --global user.email 'your@email.com'"
fi

# 7. Create jobs directory
echo ""
echo "--- Setting up jobs directory ---"
mkdir -p /tmp/claude-dev-jobs
ok "Jobs directory ready: /tmp/claude-dev-jobs"

# 8. Summary
echo ""
echo "=== Setup Summary ==="
echo "claude:  $(command -v claude &>/dev/null && echo 'OK' || echo 'MISSING')"
echo "gh:      $(command -v gh &>/dev/null && echo 'OK' || echo 'MISSING')"
echo "gh auth: $(gh auth status &>/dev/null 2>&1 && echo 'OK' || echo 'NOT CONFIGURED')"
echo "vercel:  $(command -v vercel &>/dev/null && echo 'OK' || echo 'MISSING')"
echo "vercel auth: $(vercel whoami &>/dev/null 2>&1 && echo 'OK' || echo 'NOT CONFIGURED')"
echo "git:     $(git config --global user.name &>/dev/null && echo 'OK' || echo 'NEEDS CONFIG')"
echo ""
echo "=== Done ==="
