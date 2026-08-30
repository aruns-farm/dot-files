# ============================================================
# Brewfile — Arun's Dev Setup
# Run: brew bundle
# ============================================================

# ── Taps ─────────────────────────────────────────────────────
tap "nikitabobko/tap"      # aerospace
tap "supabase/tap"
tap "localstack/tap"

# ── Dotfiles ─────────────────────────────────────────────────
brew "chezmoi"

# ── Core / Git ───────────────────────────────────────────────
brew "git"
brew "gpg"
brew "delta"
brew "lazygit"
brew "gh"

# ── Shell Experience ─────────────────────────────────────────
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"
brew "starship"
brew "fzf"
brew "zoxide"
brew "direnv"

# ── Terminal Utilities ───────────────────────────────────────
brew "tmux"
brew "bat"
brew "eza"
brew "fd"
brew "ripgrep"
brew "jq"
brew "tldr"
brew "httpie"

# ── Editor ───────────────────────────────────────────────────
brew "neovim"

# ── Node / JS ────────────────────────────────────────────────
brew "nvm"

# ── Python ───────────────────────────────────────────────────
brew "pyenv"
brew "pre-commit"
brew "python@3.10"

# ── Cloud / Backend ──────────────────────────────────────────
brew "awscli"
brew "supabase/tap/supabase"
brew "localstack/tap/localstack-cli"

# ── Mobile / Media ───────────────────────────────────────────
brew "watchman"
brew "ffmpeg"
cask "android-platform-tools"

# ── Cloudflare ───────────────────────────────────────────────
brew "cloudflared"

# ── Security / Secrets ───────────────────────────────────────
brew "bitwarden-cli"

# ── Mac Utilities ────────────────────────────────────────────
brew "mas"

# ── GUI Apps ─────────────────────────────────────────────────
cask "iterm2"
cask "visual-studio-code"
cask "aerospace"

# ── Fonts ────────────────────────────────────────────────────
cask "font-meslo-lg-nerd-font"
cask "font-hack-nerd-font"

# ── Terminal workflow (craftzdog setup, added 2026-08-30) ────
# Shell
brew "fish"                 # primary shell (zsh kept as fallback)
brew "mise"                 # node + python versions in fish (replaces nvm/pyenv there)
# Git
brew "git-delta"            # diff pager
brew "ghq"                  # repo organiser, used by fish's Ctrl-F jump
brew "peco"                 # fuzzy picker for craftzdog's git aliases
# Neovim toolchain
brew "tree-sitter-cli"      # required by nvim-treesitter's main branch
brew "stylua"               # lua formatter
brew "shfmt"                # shell formatter

# ── GUI Apps ─────────────────────────────────────────────────
cask "ghostty"              # primary terminal (iterm2 kept as fallback)

# ── Fonts ────────────────────────────────────────────────────
cask "font-plemol-jp-nf"    # craftzdog's terminal font
