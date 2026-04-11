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
step()    { echo "\n${BOLD}━━━  $1  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }

# ── Config — Edit these before running ───────────────────────
DOTFILES_REPO=""        # e.g. git@github.com:arun/dotfiles.git
DOTFILES_DIR="$HOME/.dotfiles"
NODE_VERSION="lts"
BW_EMAIL="arun.vinland@gmail.com"

# Bitwarden item names — match exactly what you saved in Bitwarden
# You have two SSH keys: office and personal
BW_SSH_OFFICE_KEY="ssh-office-key"      # office GitHub key
BW_SSH_PERSONAL_KEY="ssh-personal-key"  # personal GitHub key
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

# ══════════════════════════════════════════════════════════════
# STEP 1 — Xcode CLI Tools
# ══════════════════════════════════════════════════════════════
step "1 / 13  Xcode CLI Tools"

if ! xcode-select -p &>/dev/null; then
  info "Installing Xcode CLI tools..."
  xcode-select --install
  until xcode-select -p &>/dev/null; do sleep 5; done
  success "Xcode CLI tools installed"
else
  success "Already installed — skipping"
fi

# ══════════════════════════════════════════════════════════════
# STEP 2 — Homebrew + Brewfile
# ══════════════════════════════════════════════════════════════
step "2 / 13  Homebrew"

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

# ══════════════════════════════════════════════════════════════
# STEP 3 — Bitwarden Login + Pull SSH Keys
# ══════════════════════════════════════════════════════════════
step "3 / 13  Bitwarden + SSH Keys"

# ── Bitwarden login ──────────────────────────────────────────
if ! command -v bw &>/dev/null; then
  error "Bitwarden CLI (bw) not found. Check Brewfile."
fi

echo ""
info "Logging into Bitwarden..."
BW_STATUS=$(bw status 2>/dev/null | jq -r '.status' 2>/dev/null || echo "unauthenticated")

if [[ "$BW_STATUS" == "unauthenticated" ]]; then
  bw login "$BW_EMAIL"
fi

info "Unlocking Bitwarden vault..."
export BW_SESSION=$(bw unlock --raw)

if [[ -z "$BW_SESSION" ]]; then
  error "Failed to unlock Bitwarden — check your master password."
fi
success "Bitwarden unlocked"

# ── SSH Key setup — multiple keys (office + personal) ────────
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"

KEYS_EXIST=0
[[ -f "$HOME/.ssh/office" ]] && [[ -f "$HOME/.ssh/personal" ]] && KEYS_EXIST=1

if [[ $KEYS_EXIST -eq 1 ]]; then
  success "SSH keys already exist — skipping pull from Bitwarden"
else
  info "Pulling SSH keys from Bitwarden..."

  # Pull office key
  OFFICE_KEY=$(bw get notes "$BW_SSH_OFFICE_KEY" --session "$BW_SESSION" 2>/dev/null)
  if [[ -n "$OFFICE_KEY" ]]; then
    echo "$OFFICE_KEY" > "$HOME/.ssh/office"
    chmod 600 "$HOME/.ssh/office"
    success "Office SSH key restored"
  else
    warn "Could not find '$BW_SSH_OFFICE_KEY' in Bitwarden"
  fi

  # Pull personal key
  PERSONAL_KEY=$(bw get notes "$BW_SSH_PERSONAL_KEY" --session "$BW_SESSION" 2>/dev/null)
  if [[ -n "$PERSONAL_KEY" ]]; then
    echo "$PERSONAL_KEY" > "$HOME/.ssh/personal"
    chmod 600 "$HOME/.ssh/personal"
    success "Personal SSH key restored"
  else
    warn "Could not find '$BW_SSH_PERSONAL_KEY' in Bitwarden"
  fi

  # Load keys into ssh-agent
  eval "$(ssh-agent -s)" &>/dev/null
  [[ -f "$HOME/.ssh/office" ]]   && ssh-add --apple-use-keychain "$HOME/.ssh/office" 2>/dev/null || true
  [[ -f "$HOME/.ssh/personal" ]] && ssh-add --apple-use-keychain "$HOME/.ssh/personal" 2>/dev/null || true

  if [[ -z "$OFFICE_KEY" ]] || [[ -z "$PERSONAL_KEY" ]]; then
    echo ""
    warn "One or both SSH keys missing from Bitwarden."
    warn "Run on your current machine: zsh save-ssh-to-bitwarden.sh"
    warn "Then run setup.sh again on this new machine."
    read -r "?Press Enter to continue..."
  else
    success "SSH keys loaded into ssh-agent"
  fi
fi

# ── Write SSH config ─────────────────────────────────────────
if [[ ! -f "$HOME/.ssh/config" ]]; then
  # Pull from Bitwarden if available
  SSH_CONFIG=$(bw get notes "$BW_SSH_CONFIG" --session "$BW_SESSION" 2>/dev/null)

  if [[ -n "$SSH_CONFIG" ]]; then
    echo "$SSH_CONFIG" > "$HOME/.ssh/config"
    success "SSH config restored from Bitwarden"
  else
    # Write default config (matches your current setup)
    cat > "$HOME/.ssh/config" << 'EOF'
Host *
  AddKeysToAgent yes
  UseKeychain yes

# Office GitHub account
Host github-office
  HostName github.com
  User git
  IdentityFile ~/.ssh/office
  IdentitiesOnly yes

# Personal GitHub account
Host github-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/personal
  IdentitiesOnly yes

Host github-personal.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/personal
  IdentitiesOnly yes

# Default GitHub (personal)
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/personal
  IdentitiesOnly yes
EOF
    success "SSH config written with office + personal setup"
  fi

  chmod 600 "$HOME/.ssh/config"
fi

# ══════════════════════════════════════════════════════════════
# STEP 4 — Oh My Zsh + .zshrc
# ══════════════════════════════════════════════════════════════
step "4 / 13  Oh My Zsh + Shell Config"

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

if [[ -f "$SCRIPT_DIR/.zshrc" ]]; then
  [[ -f "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)" && warn "Backed up existing .zshrc"
  cp "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
  success ".zshrc installed"
fi

# ══════════════════════════════════════════════════════════════
# STEP 5 — NVM + Node + pnpm + wrangler
# ══════════════════════════════════════════════════════════════
step "5 / 13  NVM + Node + pnpm"

export NVM_DIR="$HOME/.nvm"
mkdir -p "$NVM_DIR"
[ -s "$BREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$BREW_PREFIX/opt/nvm/nvm.sh"

if command -v nvm &>/dev/null; then
  nvm install "$NODE_VERSION"
  nvm alias default "$NODE_VERSION"
  nvm use default
  success "Node $(node --version) set as default"
  npm install -g pnpm   && success "pnpm installed"
  npm install -g wrangler && success "wrangler installed"
else
  warn "NVM not sourced — check Brewfile"
fi

# ══════════════════════════════════════════════════════════════
# STEP 6 — Pyenv + Python
# ══════════════════════════════════════════════════════════════
step "6 / 13  Pyenv + Python"

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

# ══════════════════════════════════════════════════════════════
# STEP 7 — Dotfiles Repo
# ══════════════════════════════════════════════════════════════
step "7 / 13  Dotfiles"

if [[ -n "$DOTFILES_REPO" ]]; then
  if [[ ! -d "$DOTFILES_DIR" ]]; then
    info "Cloning dotfiles..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  else
    info "Pulling latest dotfiles..."
    git -C "$DOTFILES_DIR" pull
  fi

  # Symlink nvim config
  [[ -d "$DOTFILES_DIR/nvim" ]] && mkdir -p "$HOME/.config" && \
    ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim" && success "nvim config symlinked"

  # Symlink SSH config if present in dotfiles
  [[ -f "$DOTFILES_DIR/ssh/config" ]] && \
    ln -sf "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config" && success "SSH config symlinked"

  success "Dotfiles ready"
else
  warn "DOTFILES_REPO not set — skipping (fill it in at the top of setup.sh)"
fi

# ══════════════════════════════════════════════════════════════
# STEP 8 — Git Config (interactive, per-context emails)
# ══════════════════════════════════════════════════════════════
step "8 / 13  Git Config"

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

# ══════════════════════════════════════════════════════════════
# STEP 9 — Cloudflare Tunnel
# ══════════════════════════════════════════════════════════════
step "9 / 12  Cloudflare Tunnel"

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

# ══════════════════════════════════════════════════════════════
# STEP 10 — Folder Structure
# ══════════════════════════════════════════════════════════════
step "10 / 12  Folder Structure"
zsh "$SCRIPT_DIR/folder-structure.sh"

# ══════════════════════════════════════════════════════════════
# STEP 11 — macOS Defaults
# ══════════════════════════════════════════════════════════════
step "11 / 12  macOS Defaults"

read -r "apply_macos?Apply macOS system defaults (faster keyboard, better Finder, Dock)? [y/N] "
[[ "$apply_macos" =~ ^[Yy]$ ]] && zsh "$SCRIPT_DIR/macos.sh" || info "Skipping macOS defaults"

# ══════════════════════════════════════════════════════════════
# STEP 12 — Health Check
# ══════════════════════════════════════════════════════════════
step "12 / 12  Health Check"

echo ""
echo "${BOLD}Tools:${NC}"

check_tool() {
  local name="$1" cmd="$2"
  command -v "$cmd" &>/dev/null \
    && echo "  ${GREEN}✓${NC}  $name" \
    || echo "  ${RED}✗${NC}  $name — NOT FOUND"
}

check_tool "brew"        "brew"
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
