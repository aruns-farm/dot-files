#!/usr/bin/env zsh
# ============================================================
# macos.sh — Arun's macOS System Defaults
# Run: zsh macos.sh
# ============================================================

echo "⚙️  Applying macOS defaults..."

# ── Finder ───────────────────────────────────────────────────
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# ── Keyboard ─────────────────────────────────────────────────
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# ── Trackpad ─────────────────────────────────────────────────
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# ── Dock ─────────────────────────────────────────────────────
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.4
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock tilesize -int 40

# ── Screenshots ──────────────────────────────────────────────
mkdir -p ~/Desktop/Screenshots
defaults write com.apple.screencapture location ~/Desktop/Screenshots
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

# ── Menu Bar ─────────────────────────────────────────────────
defaults write com.apple.menuextra.battery ShowPercent YES

# ── TextEdit ─────────────────────────────────────────────────
defaults write com.apple.TextEdit RichText -int 0

# ── Restart affected apps ────────────────────────────────────
killall Finder 2>/dev/null
killall Dock 2>/dev/null

echo "✅  macOS defaults applied! Some changes need a logout to take effect."
