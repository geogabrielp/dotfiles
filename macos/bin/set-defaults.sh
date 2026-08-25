#!/usr/bin/env bash

# set-defaults.sh - macOS system defaults (Finder, Dock, Trackpad, ...)

# Idempotent: every `defaults write` is safe to re-run as many times as you want.
# macOS only: guards on Darwin and skips gracefully on Linux/WSL.
# This is my *personal* set, review and edit before applying!

# Usage:
#   make macos                # run from the dotfiles repo
#   ./macos/bin/set-defaults.sh   # or directly from the repo (not stowed)

set -euo pipefail

# Guard: macOS only
if [[ "$(uname)" != "Darwin" ]]; then
    echo "⚠️  macOS only — skipping (you're on $(uname))."
    exit 0
fi

echo "🍎 Applying macOS defaults..."

# Finder
echo "→ Finder"
defaults write com.apple.finder AppleShowAllFiles -bool true          # show hidden files
defaults write com.apple.finder AppleShowAllExtensions -bool true     # always show extensions
defaults write com.apple.finder ShowPathbar -bool true                # path bar at the bottom
defaults write com.apple.finder ShowStatusBar -bool true              # status bar at the bottom
defaults write com.apple.finder _FXSortFoldersFirst -bool true        # folders first when sorting
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true    # full path in the title bar
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"   # search in current folder

# Dock
echo "→ Dock"
defaults write com.apple.dock autohide -bool true                     # auto-hide the Dock
defaults write com.apple.dock autohide-delay -float 0                 # show instantly on hover
defaults write com.apple.dock show-recents -bool false                # hide the recent-apps section
defaults write com.apple.dock magnification -bool true                # magnify icons on hover
defaults write com.apple.dock tilesize -int 40                        # icon size in px
defaults write com.apple.dock largesize -int 50                       # magnified icon size in px

# Trackpad
echo "→ Trackpad"
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true  # tap-to-click (built-in trackpad)
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1      # tap-to-click (global mouse behavior)
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true  # tap-to-click (Bluetooth trackpad)

# Keyboard
echo "→ Keyboard"
defaults write NSGlobalDomain KeyRepeat -int 2                         # fast key repeat
defaults write NSGlobalDomain InitialKeyRepeat -int 25                 # short initial delay
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3               # full keyboard access (Tab in dialogs)

# Screenshots
echo "→ Screenshots"
mkdir -p "${HOME}/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Pictures/Screenshots"   # screenshots folder
defaults write com.apple.screencapture type -string "png"                                # screenshot format

# Apply changes
echo "→ Restarting Finder & Dock..."
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true

echo "✅ macOS defaults applied. Log out/in for some changes to take effect."
