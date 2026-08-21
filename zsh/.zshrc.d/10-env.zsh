# ~/.zshrc.d/10-env.zsh - environment variables and PATH

# Editor
export EDITOR="nano"
export VISUAL="nano"
export CLICOLOR=1                           # colorize ls output (native on macOS)

# Bat (pager)
export BAT_THEME="Catppuccin Mocha"         # bat syntax highlighting theme

# Eza (modern ls)
export EZA_CONFIG_DIR="$HOME/.config/eza"   # theme: ~/.config/eza/theme.yml

# Homebrew (macOS: /opt/homebrew | /usr/local · Linux: /home/linuxbrew)
if [[ -x /opt/homebrew/bin/brew ]]; then
    export HOMEBREW_PREFIX="/opt/homebrew"
elif [[ -x /usr/local/bin/brew ]]; then
    export HOMEBREW_PREFIX="/usr/local"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
fi
# Add brew's bin to PATH (avoids duplicating if already there)
if [[ -n "$HOMEBREW_PREFIX" && ":$PATH:" != *":$HOMEBREW_PREFIX/bin:"* ]]; then
    export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$PATH"
fi
