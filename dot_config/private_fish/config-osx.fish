# ~/.config/fish/config-osx.fish
# Base: craftzdog/dotfiles. [ported] = carried over from your old .zshrc.

if type -q eza
    alias ll "eza -l -g --icons"
    alias lla "ll -a"
end

# Fzf (his)
set -g FZF_PREVIEW_FILE_CMD "bat --style=numbers --color=always --line-range :500"
set -g FZF_LEGACY_KEYBINDINGS 0

# ── [ported] Homebrew ────────────────────────────────────────
if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv | source
end

# ── [ported] mise — replaces nvm + pyenv in fish ─────────────
# Reads .nvmrc / .node-version / .python-version automatically, so your
# projects keep working. zsh still uses nvm/pyenv; the two don't interfere.
if type -q mise
    mise activate fish | source
end

# ── [ported] zoxide (your 70-dir history), exposed as `z` ────
if type -q zoxide
    zoxide init fish --cmd z | source
end

# ── [ported] direnv ──────────────────────────────────────────
if type -q direnv
    direnv hook fish | source
end

# ── [ported] fzf defaults ────────────────────────────────────
set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND

# ── [ported] better CLI defaults ─────────────────────────────
alias lt "eza --tree --level=2 --icons"
alias cat "bat --paging=never"
alias vi nvim

# ── [ported] git aliases ─────────────────────────────────────
alias gs "git status"
alias ga "git add"
alias gc "git commit"
alias gp "git push"
alias gl "git pull"
alias gd "git diff"
alias gb "git branch"
alias gco "git checkout"
alias lg lazygit

# ── [ported] cloudflare ──────────────────────────────────────
alias tunnel "cloudflared tunnel"
alias trun "cloudflared tunnel run"

# ── [ported] quick navigation ────────────────────────────────
alias docs "cd ~/Documents"
alias office "cd ~/Documents/office"
alias personal "cd ~/Documents/personal"
alias professional "cd ~/Documents/professional"
alias dev "cd ~/dev"

# ── [ported] aerospace ───────────────────────────────────────
alias cycle-start "~/Documents/dot-files/aerospace-cycle-ctl.sh start"
alias cycle-stop "~/Documents/dot-files/aerospace-cycle-ctl.sh stop"

# ── [ported] misc ────────────────────────────────────────────
alias reload "source ~/.config/fish/config.fish"
alias fishconfig "nvim ~/.config/fish/config.fish"
alias ip "curl -s ifconfig.me; and echo"
alias ports "lsof -i -P -n | grep LISTEN"
alias brewup "brew update; and brew upgrade; and brew cleanup"

# ── [ported] Bitwarden SSH agent ─────────────────────────────
set -gx SSH_AUTH_SOCK "$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock"

# ── [ported] Android / Java toolchain ────────────────────────
set -gx ANDROID_HOME "$HOME/Library/Android/sdk"
fish_add_path $ANDROID_HOME/platform-tools $ANDROID_HOME/emulator
set -gx JAVA_HOME "/Applications/Android Studio.app/Contents/jbr/Contents/Home"
fish_add_path $JAVA_HOME/bin

# ── [ported] LM Studio CLI ───────────────────────────────────
fish_add_path $HOME/.lmstudio/bin
