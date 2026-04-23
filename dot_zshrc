# ============================================================
# .zshrc — Arun's Zsh Config
# ============================================================

# ── Oh My Zsh ────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""  # using starship instead

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  direnv
)

source $ZSH/oh-my-zsh.sh

# ── Homebrew (Apple Silicon) ─────────────────────────────────
eval "$(/opt/homebrew/bin/brew shellenv)"

# ── NVM ──────────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# auto-switch node version when .nvmrc is present in a project
autoload -U add-zsh-hook
load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"
  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")
    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# ── Pyenv ────────────────────────────────────────────────────
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# ── Zoxide (smarter cd) ──────────────────────────────────────
eval "$(zoxide init zsh)"
alias cd="z"

# ── Starship Prompt ──────────────────────────────────────────
eval "$(starship init zsh)"

# ── Direnv ───────────────────────────────────────────────────
eval "$(direnv hook zsh)"

# ── FZF ──────────────────────────────────────────────────────
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# ── Better CLI Defaults ──────────────────────────────────────
alias ls="eza --icons --group-directories-first"
alias ll="eza -la --icons --group-directories-first --git"
alias lt="eza --tree --level=2 --icons"
alias cat="bat --paging=never"
alias grep="rg"
alias find="fd"
alias vim="nvim"
alias vi="nvim"

# ── Git Aliases ──────────────────────────────────────────────
alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias gd="git diff"
alias gb="git branch"
alias gco="git checkout"
alias lg="lazygit"

# ── Cloudflare ───────────────────────────────────────────────
alias tunnel="cloudflared tunnel"
alias trun="cloudflared tunnel run"

# ── Quick Navigation ─────────────────────────────────────────
alias docs="cd ~/Documents"
alias office="cd ~/Documents/office"
alias personal="cd ~/Documents/personal"
alias professional="cd ~/Documents/professional"
alias dev="cd ~/dev"

# ── Misc ─────────────────────────────────────────────────────
alias reload="source ~/.zshrc"
alias zshconfig="nvim ~/.zshrc"
alias ip="curl -s ifconfig.me && echo"
alias ports="lsof -i -P -n | grep LISTEN"
alias brewup="brew update && brew upgrade && brew cleanup"

# ── Bitwarden: unlock and export session key ─────────────────
bwunlock() {
  export BW_SESSION=$(bw unlock --raw)
  echo "✓ Bitwarden unlocked"
}

# ── PATH ─────────────────────────────────────────────────────
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# ── Editor ───────────────────────────────────────────────────
export EDITOR="nvim"
export VISUAL="nvim"

# ── History ──────────────────────────────────────────────────
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY
setopt HIST_IGNORE_SPACE
