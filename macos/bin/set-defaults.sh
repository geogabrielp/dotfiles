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
# NOTE: Finder per-folder settings win over FXPreferredViewStyle, so existing
# folders keep their view; this sets the default for new windows/folders.
echo "→ Finder"
defaults write com.apple.finder AppleShowAllFiles -bool true                # show hidden files
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"         # list view (clmv/icnv/glyv for others)
defaults write com.apple.finder ShowPathbar -bool true                      # path bar at the bottom
defaults write com.apple.finder ShowStatusBar -bool true                    # status bar at the bottom
defaults write com.apple.finder _FXSortFoldersFirst -bool true              # folders first when sorting
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true          # full path in the title bar
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"         # search in current folder
defaults write com.apple.finder AppleShowAllExtensions -bool true           # always show extensions
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false  # no "are you sure" on extension change

# Dock
echo "→ Dock"
defaults write com.apple.dock autohide -bool true           # auto-hide the Dock
defaults write com.apple.dock autohide-delay -float 0       # show instantly on hover
defaults write com.apple.dock show-recents -bool false      # hide the recent-apps section
defaults write com.apple.dock magnification -bool true      # magnify icons on hover
defaults write com.apple.dock tilesize -int 40              # icon size in px
defaults write com.apple.dock largesize -int 50             # magnified icon size in px

# Trackpad
echo "→ Trackpad"
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true  # tap-to-click (built-in trackpad)
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1      # tap-to-click (global mouse behavior)
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true  # tap-to-click (Bluetooth trackpad)

# Keyboard
# The whole NSAutomatic* family exists to make prose nicer and code worse:
# smart quotes turn " into “, smart dashes turn -- into —, and autocorrect
# rewrites flags and identifiers in any Cocoa text field (TextEdit, Notes,
# dialogs, browser inputs on some sites).
echo "→ Keyboard"
defaults write NSGlobalDomain KeyRepeat -int 2                         # fast key repeat
defaults write NSGlobalDomain InitialKeyRepeat -int 25                 # short initial delay
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3               # full keyboard access (Tab in dialogs)
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false     # repeat on hold, not the accent popup (vim/tmux)
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticTextCompletionEnabled -bool false  # no inline predictions (macOS 14+)

# External volumes: keep .DS_Store (and AppleDouble files) off network shares
# and USB drives, where other systems would see them as junk.
echo "→ External volumes"
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Screenshots
echo "→ Screenshots"
mkdir -p "${HOME}/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Pictures/Screenshots"   # screenshots folder
defaults write com.apple.screencapture type -string "png"                                # screenshot format
defaults write com.apple.screencapture disable-shadow -bool true                         # no window shadow in the capture
defaults write com.apple.screencapture show-thumbnail -bool false                        # no floating thumbnail after capturing

# Dialogs
echo "→ Save/print dialogs"
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true    # expanded save panel
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true   # expanded save panel (v2)
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true       # expanded print panel
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true      # expanded print panel (v2)

# Apply changes
echo "→ Restarting Finder, Dock & SystemUIServer..."
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true   # needed for the screencapture settings to apply

echo "✅ macOS defaults applied. Log out/in for some changes to take effect."
