#!/usr/bin/env zsh
# ============================================================
# setup.sh — Arun's Dev Workflow Automation
#
# Run this on a fresh Mac to get fully set up.
# Usage: zsh setup.sh
#
# What it does:
#   1.  Installs Xcode CLI tools
#   2.  Installs Homebrew + all packages via Brewfile
#   3.  Logs into Bitwarden + pulls SSH keys
#   4.  Installs Oh My Zsh + copies .zshrc
#   5.  Sets up NVM + Node + pnpm + wrangler
#   6.  Sets up Pyenv + Python
#   7.  Clones dotfiles repo + symlinks configs
#   8.  Configures git (interactive — prompts for emails)
#   9.  Sets up Cloudflare tunnel config
#  10.  Creates folder structure
#  11.  Applies macOS defaults
#  12.  Health check
# ============================================================

set -e

# ── Colors ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo "${BLUE}ℹ  $1${NC}"; }
success() { echo "${GREEN}✅  $1${NC}"; }
warn()    { echo "${YELLOW}⚠️  $1${NC}"; }
error()   { echo "${RED}❌  $1${NC}"; exit 1; }

# Step control:
#   START_STEP  — first step to run (set via top-level prompt or env var)
#   RUN_ALL     — when 1, no further per-step prompts (user picked 'a' or
#                 set SKIP_PROMPTS=1)
#   _STEP_NUM   — internal counter; auto-incremented by step()
START_STEP="${START_STEP:-1}"
RUN_ALL=0
[[ "$SKIP_PROMPTS" == "1" ]] && RUN_ALL=1
_STEP_NUM=0

# step <name> — prints header, decides whether to run this step.
# Returns 0 (run) or 1 (skip). Wrap each step body in: if step "..."; then ... fi
step() {
  _STEP_NUM=$((_STEP_NUM + 1))

  # Below the user-chosen start step → silently skip with a one-line marker
  if (( _STEP_NUM < START_STEP )); then
    echo "${YELLOW}↷  Jumping past step $_STEP_NUM ($1)${NC}"
    return 1
  fi

  echo "\n${BOLD}━━━  $1  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  (( RUN_ALL == 1 )) && return 0

  read -r "_ans?   Run this step? [Y]es / [n]o / [a]ll remaining / [q]uit: "
  case "$_ans" in
    [Nn]*) info "Skipped."; return 1 ;;
    [Aa]*) info "Running this and all remaining steps without further prompts."; RUN_ALL=1; return 0 ;;
    [Qq]*) info "Quitting at user request."; exit 0 ;;
    *) return 0 ;;
  esac
}

# ── Config — Edit these before running ───────────────────────
DOTFILES_REPO="git@github.com:aruns-farm/dot-files.git"
DOTFILES_DIR="$HOME/Documents/dot-files"
NODE_VERSION="lts"
BW_EMAIL="arun.vinland@gmail.com"

# Bitwarden item names — match exactly what you saved in Bitwarden
# You have two SSH keys: office and personal
BW_SSH_OFFICE_KEY="ssh-office"          # office GitHub key
BW_SSH_PERSONAL_KEY="ssh-personal"      # personal GitHub key
BW_SSH_CONFIG="ssh-config"              # your SSH config file

# ── Sanity checks ────────────────────────────────────────────
[[ "$OSTYPE" != "darwin"* ]] && error "macOS only."

ARCH=$(uname -m)
BREW_PREFIX=$([[ "$ARCH" == "arm64" ]] && echo "/opt/homebrew" || echo "/usr/local")
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "${BOLD}🚀  Arun's Dev Setup — Starting...${NC}"
echo "   Machine: $(uname -n)  |  Chip: $ARCH  |  $(date)"
echo ""

# ── Start step + run mode ────────────────────────────────────
# Skip this entirely with: SKIP_PROMPTS=1 START_STEP=5 zsh setup.sh
if [[ "$SKIP_PROMPTS" != "1" ]]; then
  echo "Steps:"
  echo "   1. Xcode CLI Tools         5. NVM + Node + pnpm       9. Cloudflare Tunnel"
  echo "   2. Homebrew                6. Pyenv + Python         10. Folder Structure"
  echo "   3. Bitwarden + SSH Keys    7. Dotfiles (chezmoi)     11. macOS Defaults"
  echo "   4. Oh My Zsh + Shell       8. Git Config             12. Health Check"
  echo ""
  read -r "_start?Start at which step? [Enter=1, 1-12, or 'a' to run all without prompts]: "
  case "$_start" in
    [Aa]*) START_STEP=1; RUN_ALL=1 ;;
    ''|0)  START_STEP=1 ;;
    *)     START_STEP="$_start" ;;
  esac
  echo ""
fi

# ══════════════════════════════════════════════════════════════
# STEP 1 — Xcode CLI Tools
# ══════════════════════════════════════════════════════════════
if step "1 / 13  Xcode CLI Tools"; then
  if ! xcode-select -p &>/dev/null; then
    info "Installing Xcode CLI tools..."
    xcode-select --install
    until xcode-select -p &>/dev/null; do sleep 5; done
    success "Xcode CLI tools installed"
  else
    success "Already installed — skipping"
  fi
fi

# ══════════════════════════════════════════════════════════════
# STEP 2 — Homebrew + Brewfile
# ══════════════════════════════════════════════════════════════
if step "2 / 13  Homebrew"; then
  if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$($BREW_PREFIX/bin/brew shellenv)"
    success "Homebrew installed"
  else
    success "Already installed — updating..."
    brew update
  fi

  if [[ -f "$SCRIPT_DIR/Brewfile" ]]; then
    info "Installing packages from Brewfile..."
    brew bundle --file="$SCRIPT_DIR/Brewfile"
    success "All Brewfile packages installed"
  else
    warn "Brewfile not found — skipping"
  fi
fi

# ══════════════════════════════════════════════════════════════
# STEP 3 — Bitwarden Login + Pull SSH Keys
# ══════════════════════════════════════════════════════════════
if step "3 / 13  Bitwarden + SSH Keys"; then
  if ! command -v bw &>/dev/null; then
    error "Bitwarden CLI (bw) not found. Check Brewfile."
  fi

  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"

  # Deploy public keys committed in the repo (safe to share) so ssh has a
  # fingerprint to pin via IdentityFile + IdentitiesOnly. Private keys are
  # held by the Bitwarden SSH agent (or fetched below as a fallback).
  for pub in office personal; do
    if [[ -f "$SCRIPT_DIR/ssh/$pub.pub" ]]; then
      cp "$SCRIPT_DIR/ssh/$pub.pub" "$HOME/.ssh/$pub.pub"
      chmod 644 "$HOME/.ssh/$pub.pub"
    else
      warn "Missing $SCRIPT_DIR/ssh/$pub.pub — add it to the repo"
    fi
  done

  # Figure out what (if anything) we actually need from Bitwarden.
  # Skipping login/unlock entirely when nothing is missing means no master
  # password prompt on a re-run.
  NEED_OFFICE=0;   [[ ! -f "$HOME/.ssh/office" ]]   && NEED_OFFICE=1
  NEED_PERSONAL=0; [[ ! -f "$HOME/.ssh/personal" ]] && NEED_PERSONAL=1
  NEED_CONFIG=0;   [[ ! -f "$HOME/.ssh/config" ]]   && NEED_CONFIG=1

  if (( NEED_OFFICE + NEED_PERSONAL + NEED_CONFIG == 0 )); then
    success "SSH keys + config already in place — skipping Bitwarden entirely"
  else
    echo ""
    info "Logging into Bitwarden..."
    BW_STATUS=$(bw status 2>/dev/null | jq -r '.status' 2>/dev/null || echo "unauthenticated")
    if [[ "$BW_STATUS" == "unauthenticated" ]]; then
      # Interactive: prompts for master password + 2FA if enabled
      bw login "$BW_EMAIL"
    fi

    info "Unlocking Bitwarden vault..."
    # Read password ourselves so the prompt is always visible.
    # `bw unlock --raw` inside $(...) detects non-TTY stdout and silently
    # waits, which used to make this step look frozen. Pass via env var
    # (--passwordenv) so bw doesn't try to prompt at all.
    read -rs "?Bitwarden master password: " BW_PW
    echo
    export BW_SESSION=$(BW_PASSWORD="$BW_PW" bw unlock --passwordenv BW_PASSWORD --raw)
    unset BW_PW

    if [[ -z "$BW_SESSION" ]]; then
      error "Failed to unlock Bitwarden — check your master password."
    fi
    success "Bitwarden unlocked"

    info "Syncing Bitwarden vault..."
    bw sync --session "$BW_SESSION" >/dev/null

    # `</dev/null` so bw can never silently prompt on stdin — if something is
    # wrong (bad session, item not found), it must fail fast instead of hanging.
    bw_get_note() {
      bw get notes "$1" --session "$BW_SESSION" </dev/null 2>/dev/null || true
    }

    if (( NEED_OFFICE )); then
      OFFICE_KEY=$(bw_get_note "$BW_SSH_OFFICE_KEY")
      if [[ -n "$OFFICE_KEY" ]]; then
        echo "$OFFICE_KEY" > "$HOME/.ssh/office"
        chmod 600 "$HOME/.ssh/office"
        success "Office SSH key restored"
      else
        warn "Could not find '$BW_SSH_OFFICE_KEY' in Bitwarden"
      fi
    fi

    if (( NEED_PERSONAL )); then
      PERSONAL_KEY=$(bw_get_note "$BW_SSH_PERSONAL_KEY")
      if [[ -n "$PERSONAL_KEY" ]]; then
        echo "$PERSONAL_KEY" > "$HOME/.ssh/personal"
        chmod 600 "$HOME/.ssh/personal"
        success "Personal SSH key restored"
      else
        warn "Could not find '$BW_SSH_PERSONAL_KEY' in Bitwarden"
      fi
    fi

    # Load keys into ssh-agent
    eval "$(ssh-agent -s)" &>/dev/null
    [[ -f "$HOME/.ssh/office" ]]   && ssh-add --apple-use-keychain "$HOME/.ssh/office" 2>/dev/null || true
    [[ -f "$HOME/.ssh/personal" ]] && ssh-add --apple-use-keychain "$HOME/.ssh/personal" 2>/dev/null || true

    if (( NEED_CONFIG )); then
      SSH_CONFIG=$(bw_get_note "$BW_SSH_CONFIG")
      if [[ -n "$SSH_CONFIG" ]]; then
        echo "$SSH_CONFIG" > "$HOME/.ssh/config"
        success "SSH config restored from Bitwarden"
      else
        cat > "$HOME/.ssh/config" << 'EOF'
# Private keys live in the Bitwarden SSH agent (SSH_AUTH_SOCK is set in
# ~/.zshrc). IdentityFile points to the PUBLIC half so ssh knows which
# fingerprint to ask the agent for; IdentitiesOnly yes stops it from
# offering every key the agent holds.

# Office GitHub account
Host github-office
  HostName github.com
  User git
  IdentityFile ~/.ssh/office.pub
  IdentitiesOnly yes

# Personal GitHub account
Host github-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/personal.pub
  IdentitiesOnly yes

# Default GitHub (personal)
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/personal.pub
  IdentitiesOnly yes
EOF
        success "SSH config written with office + personal setup"
      fi
      chmod 600 "$HOME/.ssh/config"
    fi
  fi
fi

# ══════════════════════════════════════════════════════════════
# STEP 4 — Oh My Zsh + Shell Config
# ══════════════════════════════════════════════════════════════
if step "4 / 13  Oh My Zsh + Shell Config"; then
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    info "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    success "Oh My Zsh installed"
  else
    success "Already installed — skipping"
  fi

  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]] && \
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

  [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# ══════════════════════════════════════════════════════════════
# STEP 5 — NVM + Node + pnpm + wrangler
# ══════════════════════════════════════════════════════════════
if step "5 / 13  NVM + Node + pnpm"; then
  export NVM_DIR="$HOME/.nvm"
  mkdir -p "$NVM_DIR"
  [ -s "$BREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$BREW_PREFIX/opt/nvm/nvm.sh"

  if command -v nvm &>/dev/null; then
    # "lts" is a config convenience — nvm itself needs --lts / lts/*
    if [[ "$NODE_VERSION" == "lts" ]]; then
      nvm install --lts
      nvm alias default 'lts/*'
    else
      nvm install "$NODE_VERSION"
      nvm alias default "$NODE_VERSION"
    fi
    nvm use default
    success "Node $(node --version) set as default"
    npm install -g pnpm   && success "pnpm installed"
    npm install -g wrangler && success "wrangler installed"
  else
    warn "NVM not sourced — check Brewfile"
  fi
fi

# ══════════════════════════════════════════════════════════════
# STEP 6 — Pyenv + Python
# ══════════════════════════════════════════════════════════════
if step "6 / 13  Pyenv + Python"; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)" 2>/dev/null || true

  if command -v pyenv &>/dev/null; then
    PYTHON_VERSION=$(pyenv install --list | grep -E "^\s+3\.[0-9]+\.[0-9]+$" | tail -1 | tr -d ' ')
    pyenv install -s "$PYTHON_VERSION"
    pyenv global "$PYTHON_VERSION"
    success "Python $(python3 --version) set as global"
  else
    warn "pyenv not found — skipping"
  fi
fi

# ══════════════════════════════════════════════════════════════
# STEP 7 — Dotfiles via chezmoi
# ══════════════════════════════════════════════════════════════
if step "7 / 13  Dotfiles (chezmoi)"; then
  if [[ -n "$DOTFILES_REPO" ]]; then
    if [[ ! -d "$DOTFILES_DIR" ]]; then
      info "Cloning dotfiles..."
      git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    else
      info "Pulling latest dotfiles..."
      git -C "$DOTFILES_DIR" pull
    fi
  else
    warn "DOTFILES_REPO not set — skipping clone (fill it in at the top of setup.sh)"
  fi

  # ── Apply dotfiles with chezmoi ───────────────────────────────
  if command -v chezmoi &>/dev/null; then
    info "Applying dotfiles with chezmoi..."
    # Write chezmoi config pointing at the repo (idempotent)
    mkdir -p "$HOME/.config/chezmoi"
    cat > "$HOME/.config/chezmoi/chezmoi.toml" << EOF
sourceDir = "$DOTFILES_DIR"
EOF
    chezmoi apply --source "$DOTFILES_DIR" --force
    success "Dotfiles applied"
  else
    warn "chezmoi not found — check Brewfile"
  fi
fi

# ══════════════════════════════════════════════════════════════
# STEP 8 — Git Config (interactive, per-context emails)
# ══════════════════════════════════════════════════════════════
if step "8 / 13  Git Config"; then
  echo ""
  echo "${BOLD}Git identity setup — press Enter to keep the shown default.${NC}"
  echo ""

  read -r "git_name?Your full name [Arun]: "
  git_name="${git_name:-Arun}"

  read -r "personal_email?Personal email (default + personal + professional) [arun.vinland@gmail.com]: "
  personal_email="${personal_email:-arun.vinland@gmail.com}"

  read -r "office_email?Office/work email: "
  if [[ -z "$office_email" ]]; then
    warn "No office email entered — office folder will use personal email"
    office_email="$personal_email"
  fi

  read -r "pro_email?Professional/freelance email (Enter to reuse personal): "
  pro_email="${pro_email:-$personal_email}"

# ── Write main .gitconfig ────────────────────────────────────
cat > "$HOME/.gitconfig" << EOF
[user]
  name  = $git_name
  email = $personal_email

[core]
  editor   = nvim
  pager    = delta
  autocrlf = input

[init]
  defaultBranch = main

[pull]
  rebase = false

[push]
  autoSetupRemote = true

[interactive]
  diffFilter = delta --color-only

[delta]
  navigate     = true
  light        = false
  side-by-side = true
  line-numbers = true

[alias]
  st   = status
  co   = checkout
  br   = branch
  lg   = log --oneline --graph --decorate --all
  undo = reset HEAD~1 --mixed
  wip  = commit -am "wip"
  oops = commit --amend --no-edit

[credential]
  helper = osxkeychain

# ── Auto-switch identity by folder ───────────────────────────
[includeIf "gitdir:~/dev/office/"]
  path = ~/.gitconfig-office
[includeIf "gitdir:~/Documents/office/"]
  path = ~/.gitconfig-office

[includeIf "gitdir:~/dev/personal/"]
  path = ~/.gitconfig-personal
[includeIf "gitdir:~/Documents/personal/"]
  path = ~/.gitconfig-personal

[includeIf "gitdir:~/dev/professional/"]
  path = ~/.gitconfig-professional
[includeIf "gitdir:~/Documents/professional/"]
  path = ~/.gitconfig-professional
EOF

# ── Per-context gitconfig files ──────────────────────────────
cat > "$HOME/.gitconfig-office" << EOF
[user]
  name  = $git_name
  email = $office_email
EOF

cat > "$HOME/.gitconfig-personal" << EOF
[user]
  name  = $git_name
  email = $personal_email
EOF

cat > "$HOME/.gitconfig-professional" << EOF
[user]
  name  = $git_name
  email = $pro_email
EOF

success "Git configured!"
echo ""
echo "  Default:       $git_name <$personal_email>"
echo "  Office:        $git_name <$office_email>"
echo "  Professional:  $git_name <$pro_email>"
echo ""
echo "  Switches automatically based on folder. Verify with: git config user.email"
fi

# ══════════════════════════════════════════════════════════════
# STEP 9 — Cloudflare Tunnel
# ══════════════════════════════════════════════════════════════
if step "9 / 13  Cloudflare Tunnel"; then
  CLOUDFLARE_DIR="$HOME/.cloudflared"
  mkdir -p "$CLOUDFLARE_DIR"

  if [[ ! -f "$CLOUDFLARE_DIR/config.yml" ]]; then
    cat > "$CLOUDFLARE_DIR/config.yml" << 'EOF'
# Cloudflare Tunnel Config
# Docs: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/

# tunnel: <your-tunnel-id>
# credentials-file: ~/.cloudflared/<tunnel-id>.json

ingress:
  # - hostname: dev.yourdomain.com
  #   service: http://localhost:3000
  - service: http_status:404
EOF
    success "Cloudflared config created at ~/.cloudflared/config.yml"
    warn "Edit it with your tunnel ID and routes, then run: cloudflared tunnel login"
  else
    success "Cloudflared config already exists — skipping"
  fi
fi

# ══════════════════════════════════════════════════════════════
# STEP 10 — Folder Structure
# ══════════════════════════════════════════════════════════════
if step "10 / 13  Folder Structure"; then
  zsh "$SCRIPT_DIR/folder-structure.sh"
fi

# ══════════════════════════════════════════════════════════════
# STEP 11 — macOS Defaults
# ══════════════════════════════════════════════════════════════
if step "11 / 13  macOS Defaults"; then
  zsh "$SCRIPT_DIR/macos.sh"
fi

# ══════════════════════════════════════════════════════════════
# STEP 12 — Health Check
# ══════════════════════════════════════════════════════════════
if step "12 / 13  Health Check"; then

echo ""
echo "${BOLD}Tools:${NC}"

check_tool() {
  local name="$1" cmd="$2"
  command -v "$cmd" &>/dev/null \
    && echo "  ${GREEN}✓${NC}  $name" \
    || echo "  ${RED}✗${NC}  $name — NOT FOUND"
}

check_tool "brew"        "brew"
check_tool "chezmoi"     "chezmoi"
check_tool "git"         "git"
check_tool "gh"          "gh"
check_tool "node"        "node"
check_tool "pnpm"        "pnpm"
check_tool "nvim"        "nvim"
check_tool "tmux"        "tmux"
check_tool "cloudflared" "cloudflared"
check_tool "bw"          "bw"
check_tool "wrangler"    "wrangler"
check_tool "fzf"         "fzf"
check_tool "rg"          "rg"
check_tool "fd"          "fd"
check_tool "bat"         "bat"
check_tool "eza"         "eza"
check_tool "zoxide"      "zoxide"
check_tool "jq"          "jq"
check_tool "starship"    "starship"
check_tool "lazygit"     "lazygit"
check_tool "delta"       "delta"
check_tool "pyenv"       "pyenv"
check_tool "direnv"      "direnv"
check_tool "gpg"         "gpg"
check_tool "pre-commit"  "pre-commit"
check_tool "tldr"        "tldr"

echo ""
echo "${BOLD}SSH Key:${NC}"
[[ -f "$HOME/.ssh/id_ed25519.pub" ]] \
  && echo "  ${GREEN}✓${NC}  $(cat ~/.ssh/id_ed25519.pub)" \
  || echo "  ${RED}✗${NC}  No SSH key found"

echo ""
echo "${BOLD}Git Identities:${NC}"
echo "  Default:       $(git config --global user.name) <$(git config --global user.email)>"
[[ -f "$HOME/.gitconfig-office" ]]       && echo "  Office:        $(git config -f ~/.gitconfig-office user.email)"
[[ -f "$HOME/.gitconfig-professional" ]] && echo "  Professional:  $(git config -f ~/.gitconfig-professional user.email)"

echo ""
echo "${BOLD}Folders:${NC}"
for dir in \
  "$HOME/Documents/office" "$HOME/Documents/personal" "$HOME/Documents/professional" \
  "$HOME/dev/office" "$HOME/dev/personal" "$HOME/dev/professional" "$HOME/dev/sandbox"; do
  [[ -d "$dir" ]] \
    && echo "  ${GREEN}✓${NC}  $dir" \
    || echo "  ${RED}✗${NC}  $dir"
done
fi

echo ""
echo "════════════════════════════════════════════════════"
echo "${GREEN}${BOLD}  Done! Restart your terminal to apply all changes.${NC}"
echo "════════════════════════════════════════════════════"
echo ""
echo "  Next steps:"
echo "  1. Set DOTFILES_REPO at the top of setup.sh, then re-run"
echo "  2. Run: cloudflared tunnel login"
echo "  3. Test git identity: cd ~/dev/office/any-repo && git config user.email"
echo ""
