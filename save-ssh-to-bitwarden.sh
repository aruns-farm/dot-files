#!/usr/bin/env zsh
# ============================================================
# save-ssh-to-bitwarden.sh
# One-time script to save your existing SSH keys to Bitwarden
# Run this ONCE on your current machine to back up your keys
# Usage: zsh save-ssh-to-bitwarden.sh
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo "${BOLD}ℹ  $1${NC}"; }
success() { echo "${GREEN}✅  $1${NC}"; }
warn()    { echo "${YELLOW}⚠️  $1${NC}"; }
error()   { echo "${RED}❌  $1${NC}"; exit 1; }

echo ""
echo "${BOLD}🔐  Backing up SSH keys to Bitwarden${NC}"
echo "This saves your keys so you can reuse them on new machines."
echo ""

# Check if keys exist
[[ ! -f ~/.ssh/office ]] && error "~/.ssh/office not found"
[[ ! -f ~/.ssh/personal ]] && error "~/.ssh/personal not found"

# Check Bitwarden CLI
command -v bw &>/dev/null || error "Bitwarden CLI (bw) not installed. Install with: brew install bitwarden-cli"

# Login to Bitwarden if needed
info "Checking Bitwarden connection..."
BW_STATUS=$(bw status 2>/dev/null | jq -r '.status' 2>/dev/null || echo "unauthenticated")

if [[ "$BW_STATUS" == "unauthenticated" ]]; then
  read -r "bw_email?Bitwarden email: "
  bw login "$bw_email"
fi

export BW_SESSION=$(bw unlock --raw)

if [[ -z "$BW_SESSION" ]]; then
  error "Failed to unlock Bitwarden"
fi

success "Bitwarden unlocked"
echo ""

# ── Save office key ──────────────────────────────────────────
info "Saving office SSH key..."
OFFICE_KEY=$(cat ~/.ssh/office)
bw create object file 0 \
  --name "ssh-office-key" \
  --notes "$OFFICE_KEY" \
  --session "$BW_SESSION" > /dev/null 2>&1 || \
  warn "Could not create as file attachment. Saving as secure note instead..."

# If file attachment didn't work, try as secure note
if ! bw get item "ssh-office-key" --session "$BW_SESSION" &>/dev/null; then
  echo ""
  warn "Manual step required: Add this to Bitwarden as a secure note:"
  echo ""
  echo "${BOLD}Name: ssh-office-key${NC}"
  echo "${BOLD}Content:${NC}"
  cat ~/.ssh/office
  echo ""
  echo "Then press Enter to continue..."
  read
else
  success "Office key saved to Bitwarden"
fi

# ── Save personal key ────────────────────────────────────────
info "Saving personal SSH key..."
PERSONAL_KEY=$(cat ~/.ssh/personal)
bw create object file 0 \
  --name "ssh-personal-key" \
  --notes "$PERSONAL_KEY" \
  --session "$BW_SESSION" > /dev/null 2>&1 || \
  warn "Could not create as file attachment. Saving as secure note instead..."

if ! bw get item "ssh-personal-key" --session "$BW_SESSION" &>/dev/null; then
  echo ""
  warn "Manual step required: Add this to Bitwarden as a secure note:"
  echo ""
  echo "${BOLD}Name: ssh-personal-key${NC}"
  echo "${BOLD}Content:${NC}"
  cat ~/.ssh/personal
  echo ""
  echo "Then press Enter to continue..."
  read
else
  success "Personal key saved to Bitwarden"
fi

# ── Save SSH config ──────────────────────────────────────────
info "Saving SSH config..."
SSH_CONFIG=$(cat ~/.ssh/config)

if ! bw get item "ssh-config" --session "$BW_SESSION" &>/dev/null; then
  echo ""
  warn "Manual step required: Add this to Bitwarden as a secure note:"
  echo ""
  echo "${BOLD}Name: ssh-config${NC}"
  echo "${BOLD}Content:${NC}"
  cat ~/.ssh/config
  echo ""
  echo "Then press Enter to continue..."
  read
else
  success "SSH config saved to Bitwarden"
fi

echo ""
echo "════════════════════════════════════════════════════"
echo "${GREEN}${BOLD}  Done! Your SSH keys are now backed up.${NC}"
echo "════════════════════════════════════════════════════"
echo ""
echo "  On new machines, setup.sh will pull these keys from Bitwarden."
echo ""
