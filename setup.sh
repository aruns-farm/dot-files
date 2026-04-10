#!/usr/bin/env zsh
# ============================================================
# setup.sh — Arun's Dev Workflow Automation
#
# Run this on a fresh Mac to get fully set up.
# Usage: zsh setup.sh
#
# Fresh Mac (typical — same GitHub SSH identity everywhere):
#   1. bw login
#   2. export BW_SESSION="$(bw unlock --raw)"
#   3. Set BITWARDEN_SSH_ITEM_ID below (Bitwarden item that has your private key attached)
#   4. zsh setup.sh
#
# One-time on your *first* Mac ever: generate ~/.ssh/id_ed25519, attach that file to
# a Bitwarden item, copy the item's ID into BITWARDEN_SSH_ITEM_ID, add the .pub key
# to GitHub once — after that, new machines only run the four steps above (no new key).
#
# What it does:
#   1. Installs Xcode CLI tools
#   2. Installs Homebrew + all packages via Brewfile
#   3. Restores SSH private key from Bitwarden (or skips if key already exists)
#   4. Installs Oh My Zsh + copies .zshrc
#   5. Sets up NVM + Node + pnpm
#   6. Sets up Pyenv + Python
#   7. Clones your dotfiles repo + symlinks configs
#   8. Clones your secrets repo + copies .env files
#   9. Configures git globals
#  10. Sets up Cloudflare tunnel config
#  11. Creates folder structure
#  12. Applies macOS defaults
#  13. Health check
# ============================================================

set -e  # exit on error

# ── Colors ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ── Helpers ──────────────────────────────────────────────────
info()    { echo "${BLUE}ℹ  $1${NC}"; }
success() { echo "${GREEN}✅  $1${NC}"; }
warn()    { echo "${YELLOW}⚠️  $1${NC}"; }
error()   { echo "${RED}❌  $1${NC}"; exit 1; }
step()    { echo "\n${BOLD}━━━  $1  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }

# ── Config — Edit these before running ───────────────────────
GIT_NAME="Arun"
GIT_EMAIL="arun.vinland@gmail.com"
DOTFILES_REPO=""        # e.g. git@github.com:arun/dotfiles.git
SECRETS_REPO=""         # e.g. git@github.com:arun/secrets.git (private, git-crypted)
DOTFILES_DIR="$HOME/.dotfiles"
SECRETS_DIR="$HOME/.secrets"
NODE_VERSION="lts"      # or pin to e.g. "20"

# SSH — private key lives in Bitwarden (attachment); same key on every machine
BITWARDEN_SSH_ITEM_ID=""           # Bitwarden item UUID (Login/Secure Note with attachment)
BITWARDEN_SSH_ATTACHMENT_NAME="id_ed25519"  # attachment filename in that item

# ── Sanity check: must be on macOS ───────────────────────────
if [[ "$OSTYPE" != "darwin"* ]]; then
  error "This script is for macOS only."
fi

# ── Sanity check: Apple Silicon path ─────────────────────────
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
  BREW_PREFIX="/opt/homebrew"
else
  BREW_PREFIX="/usr/local"
fi

echo ""
echo "${BOLD}🚀  Arun's Dev Setup — Starting...${NC}"
echo "   Machine: $(uname -n)  |  Chip: $ARCH  |  $(date)"
echo ""

# ══════════════════════════════════════════════════════════════
# STEP 1 — Xcode CLI Tools
# ══════════════════════════════════════════════════════════════
step "1 / 13  Xcode CLI Tools"

if ! xcode-select -p &>/dev/null; then
  info "Installing Xcode CLI tools (a dialog will appear)..."
  xcode-select --install
  # Wait until it's done
  until xcode-select -p &>/dev/null; do sleep 5; done
  success "Xcode CLI tools installed"
else
  success "Xcode CLI tools already installed — skipping"
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
  success "Homebrew already installed — updating..."
  brew update
fi

# Install everything from Brewfile
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "$SCRIPT_DIR/Brewfile" ]]; then
  info "Installing packages from Brewfile..."
  brew bundle --file="$SCRIPT_DIR/Brewfile"
  success "All Brewfile packages installed"
else
  warn "Brewfile not found next to setup.sh — skipping brew bundle"
fi

# Ensure Homebrew tools (bw, jq, …) are on PATH for the rest of this script
if [[ -x "$BREW_PREFIX/bin/brew" ]]; then
  eval "$("$BREW_PREFIX/bin/brew" shellenv)"
fi

# ══════════════════════════════════════════════════════════════
# STEP 3 — SSH Key (restore from Bitwarden; never auto-generate)
# ══════════════════════════════════════════════════════════════
step "3 / 13  SSH Key"

write_ssh_config_if_missing() {
  if [[ -f "$HOME/.ssh/config" ]]; then
    return 0
  fi
  cat > "$HOME/.ssh/config" << 'EOF'
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519

Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
EOF
  chmod 600 "$HOME/.ssh/config"
  success "Wrote ~/.ssh/config"
}

add_ssh_key_to_agent() {
  if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
    return 0
  fi
  # One agent for this script; load key into Apple keychain
  if [[ -n "${SSH_AUTH_SOCK:-}" ]] || pgrep -xq ssh-agent; then
    ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519" 2>/dev/null || ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null || true
  else
    eval "$(ssh-agent -s)" >/dev/null
    ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519" 2>/dev/null || ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null || true
  fi
}

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
  write_ssh_config_if_missing
  add_ssh_key_to_agent
  success "SSH private key already present — skipping Bitwarden"
else
  if [[ -z "$BITWARDEN_SSH_ITEM_ID" ]]; then
    error "No ~/.ssh/id_ed25519 and BITWARDEN_SSH_ITEM_ID is empty.
  First Mac: ssh-keygen -t ed25519 -C \"$GIT_EMAIL\" -f ~/.ssh/id_ed25519 -N \"\"
  Attach ~/.ssh/id_ed25519 to a Bitwarden item, copy that item's ID into BITWARDEN_SSH_ITEM_ID in setup.sh,
  add ~/.ssh/id_ed25519.pub to GitHub once, then on this machine set BITWARDEN_SSH_ITEM_ID and re-run after: bw login && export BW_SESSION=\"\$(bw unlock --raw)\""
  fi

  if ! command -v bw &>/dev/null; then
    error "Bitwarden CLI (bw) not found. Install it (brew install bitwarden-cli / Brewfile) and re-run."
  fi

  if ! command -v jq &>/dev/null; then
    error "jq not found (needed for Bitwarden item JSON). Install via Brewfile and re-run."
  fi

  bw_status_json="$(bw status 2>/dev/null || true)"
  bw_state="$(echo "$bw_status_json" | jq -r '.status // empty')"
  if [[ -z "$bw_state" || "$bw_state" == "null" ]]; then
    error "Could not read Bitwarden status. Try: bw login && export BW_SESSION=\"\$(bw unlock --raw)\""
  fi
  if [[ "$bw_state" == "unauthenticated" ]]; then
    error "Bitwarden is not logged in. Run: bw login"
  fi
  if [[ "$bw_state" == "locked" ]]; then
    error "Bitwarden is locked. Run: export BW_SESSION=\"\$(bw unlock --raw)\" then re-run setup.sh"
  fi

  info "Downloading SSH private key from Bitwarden..."
  item_json="$(bw get item "$BITWARDEN_SSH_ITEM_ID")"
  attach_id="$(echo "$item_json" | jq -r --arg name "$BITWARDEN_SSH_ATTACHMENT_NAME" '.attachments[]? | select(.fileName == $name) | .id' | head -n1)"
  if [[ -z "$attach_id" || "$attach_id" == "null" ]]; then
    error "No attachment named \"$BITWARDEN_SSH_ATTACHMENT_NAME\" on Bitwarden item $BITWARDEN_SSH_ITEM_ID. Attach your private key with that exact filename (or change BITWARDEN_SSH_ATTACHMENT_NAME)."
  fi

  bw get attachment "$attach_id" --itemid "$BITWARDEN_SSH_ITEM_ID" --output "$HOME/.ssh/id_ed25519"
  chmod 600 "$HOME/.ssh/id_ed25519"

  if [[ ! -f "$HOME/.ssh/id_ed25519.pub" ]]; then
    ssh-keygen -y -f "$HOME/.ssh/id_ed25519" >"$HOME/.ssh/id_ed25519.pub"
    chmod 644 "$HOME/.ssh/id_ed25519.pub"
    success "Derived id_ed25519.pub from private key"
  fi

  write_ssh_config_if_missing
  add_ssh_key_to_agent
  success "SSH key restored from Bitwarden"
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
  success "Oh My Zsh already installed — skipping"
fi

# Install zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
  info "Installing zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
  info "Installing zsh-syntax-highlighting..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# Copy .zshrc
if [[ -f "$SCRIPT_DIR/.zshrc" ]]; then
  if [[ -f "$HOME/.zshrc" ]]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
    warn "Backed up existing .zshrc"
  fi
  cp "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
  success ".zshrc installed"
else
  warn ".zshrc not found next to setup.sh — skipping"
fi

# ══════════════════════════════════════════════════════════════
# STEP 5 — NVM + Node + pnpm
# ══════════════════════════════════════════════════════════════
step "5 / 13  NVM + Node + pnpm"

export NVM_DIR="$HOME/.nvm"

if [[ ! -d "$NVM_DIR" ]]; then
  info "Installing NVM..."
  mkdir -p "$NVM_DIR"
fi

# Source nvm from brew
[ -s "$BREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$BREW_PREFIX/opt/nvm/nvm.sh"

if ! command -v nvm &>/dev/null; then
  warn "NVM not found even after brew install — check Brewfile"
else
  info "Installing Node $NODE_VERSION..."
  nvm install "$NODE_VERSION"
  nvm alias default "$NODE_VERSION"
  nvm use default
  success "Node $(node --version) installed and set as default"

  info "Installing pnpm..."
  npm install -g pnpm
  success "pnpm $(pnpm --version) installed"

  info "Installing wrangler (Cloudflare CLI)..."
  npm install -g wrangler
  success "wrangler installed"
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
  info "Installing Python $PYTHON_VERSION..."
  pyenv install -s "$PYTHON_VERSION"
  pyenv global "$PYTHON_VERSION"
  success "Python $(python3 --version) set as global"
else
  warn "pyenv not found — skipping Python setup"
fi

# ══════════════════════════════════════════════════════════════
# STEP 7 — Dotfiles Repo
# ══════════════════════════════════════════════════════════════
step "7 / 13  Dotfiles"

if [[ -n "$DOTFILES_REPO" ]]; then
  if [[ ! -d "$DOTFILES_DIR" ]]; then
    info "Cloning dotfiles from $DOTFILES_REPO..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    success "Dotfiles cloned to $DOTFILES_DIR"
  else
    info "Dotfiles already cloned — pulling latest..."
    git -C "$DOTFILES_DIR" pull
  fi

  # Symlink nvim config if present
  if [[ -d "$DOTFILES_DIR/nvim" ]]; then
    mkdir -p "$HOME/.config"
    ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
    success "nvim config symlinked"
  fi

  # Symlink .gitconfig if present
  if [[ -f "$DOTFILES_DIR/.gitconfig" ]]; then
    ln -sf "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
    success ".gitconfig symlinked"
  fi
else
  warn "DOTFILES_REPO not set — skipping dotfiles clone"
  warn "Set it at the top of setup.sh once you create the repo"
fi

# ══════════════════════════════════════════════════════════════
# STEP 8 — Secrets Repo (.env files)
# ══════════════════════════════════════════════════════════════
step "8 / 13  Secrets / .env Files"

if [[ -n "$SECRETS_REPO" ]]; then
  if [[ ! -d "$SECRETS_DIR" ]]; then
    info "Cloning secrets repo from $SECRETS_REPO..."
    git clone "$SECRETS_REPO" "$SECRETS_DIR"
    success "Secrets cloned to $SECRETS_DIR"
  else
    info "Secrets already cloned — pulling latest..."
    git -C "$SECRETS_DIR" pull
  fi

  # If git-crypt is set up, unlock it
  if command -v git-crypt &>/dev/null && [[ -f "$SECRETS_DIR/.git-crypt/keys/default" ]]; then
    info "Unlocking secrets with git-crypt..."
    git -C "$SECRETS_DIR" crypt unlock
    success "Secrets unlocked"
  fi

  # Copy .env files into their project directories
  # Convention: secrets repo mirrors ~/dev structure
  # e.g. secrets/office/my-project/.env → ~/dev/office/my-project/.env
  info "Copying .env files to project directories..."
  find "$SECRETS_DIR" -name ".env" | while read -r env_file; do
    relative="${env_file#$SECRETS_DIR/}"
    target="$HOME/dev/$relative"
    target_dir="$(dirname "$target")"
    if [[ -d "$target_dir" ]]; then
      cp "$env_file" "$target"
      success "  Copied .env → $target"
    else
      warn "  Target dir not found: $target_dir (skipping)"
    fi
  done
else
  warn "SECRETS_REPO not set — skipping secrets clone"
  warn "Set it at the top of setup.sh once you create the private repo"
fi

# ══════════════════════════════════════════════════════════════
# STEP 9 — Git Global Config
# ══════════════════════════════════════════════════════════════
step "9 / 13  Git Config"

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global core.editor "nvim"
git config --global init.defaultBranch "main"
git config --global pull.rebase false
git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.light false
git config --global delta.side-by-side true
git config --global alias.lg "log --oneline --graph --decorate --all"
git config --global alias.st "status"
git config --global alias.co "checkout"
git config --global alias.br "branch"

success "Git configured for $GIT_NAME <$GIT_EMAIL>"

# ══════════════════════════════════════════════════════════════
# STEP 10 — Cloudflare Tunnel
# ══════════════════════════════════════════════════════════════
step "10 / 13  Cloudflare Tunnel"

CLOUDFLARE_DIR="$HOME/.cloudflared"
mkdir -p "$CLOUDFLARE_DIR"

if [[ ! -f "$CLOUDFLARE_DIR/config.yml" ]]; then
  info "Creating starter cloudflared config..."
  cat > "$CLOUDFLARE_DIR/config.yml" << 'EOF'
# Cloudflare Tunnel Config
# Docs: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/

# tunnel: <your-tunnel-id>         # fill in after: cloudflared tunnel create <name>
# credentials-file: /Users/YOUR_USER/.cloudflared/<tunnel-id>.json

ingress:
  # Example: route local port 3000 to a hostname
  # - hostname: dev.yourdomain.com
  #   service: http://localhost:3000
  - service: http_status:404   # catch-all (required)
EOF
  success "Cloudflared config created at $CLOUDFLARE_DIR/config.yml"
  warn "Edit $CLOUDFLARE_DIR/config.yml with your tunnel ID and routes"
else
  success "Cloudflared config already exists — skipping"
fi

if command -v cloudflared &>/dev/null; then
  info "To authenticate with Cloudflare, run: cloudflared tunnel login"
fi

# ══════════════════════════════════════════════════════════════
# STEP 11 — Folder Structure
# ══════════════════════════════════════════════════════════════
step "11 / 13  Folder Structure"

zsh "$SCRIPT_DIR/folder-structure.sh"

# ══════════════════════════════════════════════════════════════
# STEP 12 — macOS Defaults
# ══════════════════════════════════════════════════════════════
step "12 / 13  macOS Defaults"

read -r "?Apply macOS system defaults (faster keyboard, better Finder, etc.)? [y/N] " apply_macos
if [[ "$apply_macos" =~ ^[Yy]$ ]]; then
  zsh "$SCRIPT_DIR/macos.sh"
else
  info "Skipping macOS defaults"
fi

# ══════════════════════════════════════════════════════════════
# STEP 13 — Health Check
# ══════════════════════════════════════════════════════════════
step "13 / 13  Health Check"

echo ""
echo "${BOLD}Checking installed tools...${NC}"
echo ""

check_tool() {
  local name="$1"
  local cmd="$2"
  if command -v "$cmd" &>/dev/null; then
    local version
    version=$($cmd --version 2>/dev/null | head -1 || echo "installed")
    echo "  ${GREEN}✓${NC}  $name — $version"
  else
    echo "  ${RED}✗${NC}  $name — NOT FOUND"
  fi
}

check_tool "brew"         "brew"
check_tool "git"          "git"
check_tool "gh"           "gh"
check_tool "node"         "node"
check_tool "pnpm"         "pnpm"
check_tool "nvim"         "nvim"
check_tool "tmux"         "tmux"
check_tool "cloudflared"  "cloudflared"
check_tool "bw"           "bw"
check_tool "wrangler"     "wrangler"
check_tool "fzf"          "fzf"
check_tool "rg"           "rg"
check_tool "fd"           "fd"
check_tool "bat"          "bat"
check_tool "eza"          "eza"
check_tool "zoxide"       "zoxide"
check_tool "jq"           "jq"
check_tool "starship"     "starship"
check_tool "lazygit"      "lazygit"
check_tool "delta"        "delta"
check_tool "pyenv"        "pyenv"
check_tool "direnv"       "direnv"
check_tool "gpg"          "gpg"
check_tool "git-crypt"    "git-crypt"
check_tool "pre-commit"   "pre-commit"
check_tool "tldr"         "tldr"

echo ""
echo "${BOLD}SSH Key:${NC}"
if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
  echo "  ${GREEN}✓${NC}  $(cat ~/.ssh/id_ed25519.pub)"
else
  echo "  ${RED}✗${NC}  No SSH key found"
fi

echo ""
echo "${BOLD}Git Config:${NC}"
echo "  Name:   $(git config --global user.name)"
echo "  Email:  $(git config --global user.email)"

echo ""
echo "${BOLD}Folder Structure:${NC}"
for dir in "$HOME/Documents/office" "$HOME/Documents/personal" "$HOME/Documents/professional" "$HOME/dev"; do
  [[ -d "$dir" ]] && echo "  ${GREEN}✓${NC}  $dir" || echo "  ${RED}✗${NC}  $dir"
done

echo ""
echo "════════════════════════════════════════════════════"
echo "${GREEN}${BOLD}  Setup complete! Restart your terminal to apply all changes.${NC}"
echo "════════════════════════════════════════════════════"
echo ""
echo "  Next steps:"
echo "  1. Set DOTFILES_REPO in setup.sh and re-run (if not already)"
echo "  2. Set SECRETS_REPO in setup.sh and re-run (if not already)"
echo "  3. Run: cloudflared tunnel login"
echo "  4. If Bitwarden was not used before setup: bw login (for day-to-day bw use)"
echo ""
