#!/usr/bin/env zsh
# ============================================================
# macos.sh — Arun's macOS System Defaults
# Makes your Mac feel like YOUR Mac again on a fresh setup
# Run: zsh macos.sh
# ============================================================

echo "⚙️  Applying macOS defaults..."

# ── Finder ───────────────────────────────────────────────────
# Show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true
# Show file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Show path bar at bottom of Finder
defaults write com.apple.finder ShowPathbar -bool true
# Show status bar in Finder
defaults write com.apple.finder ShowStatusBar -bool true
# Use list view in Finder by default
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true
# Search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# ── Keyboard ─────────────────────────────────────────────────
# Faster key repeat (lower = faster)
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
# Disable autocorrect
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
# Disable auto-capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
# Disable smart dashes
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
# Disable smart quotes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# ── Trackpad ─────────────────────────────────────────────────
# Enable tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# ── Dock ─────────────────────────────────────────────────────
# Auto-hide the Dock
defaults write com.apple.dock autohide -bool true
# Remove the auto-hide delay
defaults write com.apple.dock autohide-delay -float 0
# Faster animation when hiding/showing Dock
defaults write com.apple.dock autohide-time-modifier -float 0.4
# Don't show recent apps in Dock
defaults write com.apple.dock show-recents -bool false
# Smaller dock icons
defaults write com.apple.dock tilesize -int 40

# ── Screenshots ──────────────────────────────────────────────
# Save screenshots to ~/Desktop/Screenshots
mkdir -p ~/Desktop/Screenshots
defaults write com.apple.screencapture location ~/Desktop/Screenshots
# Save screenshots as PNG
defaults write com.apple.screencapture type -string "png"
# Disable screenshot shadow
defaults write com.apple.screencapture disable-shadow -bool true

# ── Menu Bar ─────────────────────────────────────────────────
# Show battery percentage
defaults write com.apple.menuextra.battery ShowPercent YES

# ── Activity Monitor ─────────────────────────────────────────
# Show all processes
defaults write com.apple.ActivityMonitor ShowCategory -int 0
# Sort by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

# ── TextEdit ─────────────────────────────────────────────────
# Use plain text mode by default
defaults write com.apple.TextEdit RichText -int 0

# ── Safari (dev defaults) ────────────────────────────────────
# Show full URL in address bar
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true
# Enable dev menu
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
defaults write com.apple.Safari IncludeDevelopMenu -bool true

# ── Restart affected apps ────────────────────────────────────
echo "↻  Restarting Finder and Dock..."
killall Finder 2>/dev/null
killall Dock 2>/dev/null

echo "✅  macOS defaults applied! Some changes require a logout/restart to take effect."
