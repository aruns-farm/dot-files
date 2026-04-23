#!/usr/bin/env zsh
# ============================================================
# enable-bitwarden-ssh-agent.sh
#
# Point SSH_AUTH_SOCK at the Bitwarden desktop app SSH agent so
# ssh(1), git over SSH, and ssh-add use keys stored in Bitwarden.
#
# Docs: https://bitwarden.com/help/ssh-agent/#tab-macos-6VN1DmoAVFvm7ZWD95curS
#
# Prerequisites (manual):
#   - Bitwarden desktop 2025.1.2+ with Settings → Enable SSH agent
#   - SSH key items in your vault (create/import in the app)
#
# Usage:
#   zsh enable-bitwarden-ssh-agent.sh
#   zsh enable-bitwarden-ssh-agent.sh --socket ~/.bitwarden-ssh-agent.sock
#   zsh enable-bitwarden-ssh-agent.sh --launchctl
#   zsh enable-bitwarden-ssh-agent.sh --bashrc   # also update ~/.bashrc
# ============================================================

set -e

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

MARK_BEGIN='# >>> bitwarden-ssh-agent'
MARK_END='# <<< bitwarden-ssh-agent'

usage() {
  cat <<EOF
${BOLD}enable-bitwarden-ssh-agent.sh${NC}

  --socket PATH     Use this socket (skip auto-detect)
  --launchctl       macOS: also run launchctl setenv SSH_AUTH_SOCK (new terminals / GUI)
  --bashrc          Update ~/.bashrc as well as ~/.zshrc
  --zshrc-only      Only update ~/.zshrc (default)
  -h, --help        This help

Auto-detect picks the socket path from Bitwarden's install style (Mac App Store vs
.dmg, Linux default / snap / flatpak) per Bitwarden help docs.
EOF
}

SOCKET_OVERRIDE=""
DO_LAUNCHCTL=0
UPDATE_BASHRC=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --socket)       SOCKET_OVERRIDE="$2"; shift 2 ;;
    --launchctl)    DO_LAUNCHCTL=1; shift ;;
    --bashrc)       UPDATE_BASHRC=1; shift ;;
    --zshrc-only)   UPDATE_BASHRC=0; shift ;;
    -h|--help)      usage; exit 0 ;;
    *)              error "Unknown option: $1 (try --help)" ;;
  esac
done

detect_ssh_auth_sock() {
  local h="$HOME"
  case "$(uname -s)" in
    Darwin)
      # Mac App Store vs .dmg use different paths; prefer whichever socket exists when Bitwarden is running.
      local store="$h/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock"
      local dmg="$h/.bitwarden-ssh-agent.sock"
      if [[ -S "$store" ]]; then
        echo "$store"
      elif [[ -S "$dmg" ]]; then
        echo "$dmg"
      elif [[ -d "$h/Library/Containers/com.bitwarden.desktop" ]]; then
        echo "$store"
      else
        echo "$dmg"
      fi
      ;;
    Linux)
      if [[ -d "$h/.var/app/com.bitwarden.desktop" ]]; then
        echo "$h/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock"
      elif [[ -d "$h/snap/bitwarden" ]]; then
        echo "$h/snap/bitwarden/current/.bitwarden-ssh-agent.sock"
      else
        echo "$h/.bitwarden-ssh-agent.sock"
      fi
      ;;
    *)
      error "This script supports macOS and Linux. On Windows, disable the OpenSSH Authentication Agent service and set SSH_AUTH_SOCK in your environment per Bitwarden docs."
      ;;
  esac
}

strip_managed_block() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  local tmp
  tmp=$(mktemp)
  awk -v mstart="$MARK_BEGIN" -v mend="$MARK_END" '
    $0 == mstart {skip=1; next}
    $0 == mend {skip=0; next}
    !skip {print}
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
}

append_block() {
  local file="$1"
  local sock="$2"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  strip_managed_block "$file"
  cat >> "$file" <<EOF

$MARK_BEGIN
export SSH_AUTH_SOCK="$sock"
$MARK_END
EOF
}

if [[ -n "$SOCKET_OVERRIDE" ]]; then
  SOCK="$SOCKET_OVERRIDE"
else
  SOCK="$(detect_ssh_auth_sock)"
fi

echo ""
echo "${BOLD}🔑  Bitwarden SSH agent — shell configuration${NC}"
echo ""

info "Using SSH_AUTH_SOCK=$SOCK"
if [[ ! -S "$SOCK" ]]; then
  warn "Socket not found yet — open Bitwarden desktop, enable Settings → SSH agent, unlock vault, then run: ssh-add -L"
fi

if [[ "$(uname -s)" == "Darwin" ]] && (( DO_LAUNCHCTL )); then
  launchctl setenv SSH_AUTH_SOCK "$SOCK" && success "launchctl setenv SSH_AUTH_SOCK (restart Terminal for all contexts)"
else
  (( DO_LAUNCHCTL )) && warn "--launchctl only applies on macOS; ignored"
fi

append_block "$HOME/.zshrc" "$SOCK"
success "Updated ~/.zshrc"

if (( UPDATE_BASHRC )); then
  append_block "$HOME/.bashrc" "$SOCK"
  success "Updated ~/.bashrc"
fi

export SSH_AUTH_SOCK="$SOCK"

echo ""
info "Manual step: Bitwarden desktop → Settings → enable ${BOLD}SSH agent${NC} (2025.1.2+)."
info "Then unlock the vault and run: ${BOLD}ssh-add -L${NC} (should list keys from Bitwarden)."
echo ""

if command -v ssh-add &>/dev/null; then
  list_out=$(ssh-add -L 2>&1) || true
  if [[ "$list_out" == *'no identities'* ]]; then
    warn "Agent reports no identities yet — open Bitwarden, enable SSH agent, unlock, then try again."
  elif [[ "$list_out" == *'No such file'* ]] || [[ "$list_out" == *'Connection refused'* ]]; then
    warn "Could not talk to the agent socket. Is Bitwarden running with SSH agent enabled?"
  elif [[ -n "$list_out" ]]; then
    success "ssh-add -L looks good."
    echo "$list_out"
  fi
fi

echo ""
success "Done. Run ${BOLD}source ~/.zshrc${NC} in existing terminals (or open a new tab)."
echo ""
