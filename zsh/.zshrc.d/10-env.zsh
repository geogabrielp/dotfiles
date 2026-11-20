# ~/.zshrc.d/10-env.zsh - environment variables and PATH

# Editor
export EDITOR="nano"
export VISUAL="nano"
export CLICOLOR=1                           # colorize ls output (native on macOS)

# Bat (pager)
export BAT_THEME="Catppuccin Mocha"         # bat syntax highlighting theme

# Eza (modern ls)
export EZA_CONFIG_DIR="$HOME/.config/eza"   # theme: ~/.config/eza/theme.yml

# ---------------------------------------------------------------------------
# Homebrew (macOS: /opt/homebrew | /usr/local · Linux: /home/linuxbrew)
# This is the ONLY place the prefixes are listed. ~/.zprofile sources this
# file and then runs `brew shellenv` for the full login environment; here we
# only fix PATH, which is what non-login shells are missing.
# ---------------------------------------------------------------------------
typeset -U path                             # never keep duplicate entries
if [[ -z "$HOMEBREW_PREFIX" ]]; then
    for _brew_prefix in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew; do
        if [[ -x "$_brew_prefix/bin/brew" ]]; then
            export HOMEBREW_PREFIX="$_brew_prefix"
            break
        fi
    done
    unset _brew_prefix
fi
# Add brew's bin to PATH (avoids duplicating if already there)
if [[ -n "$HOMEBREW_PREFIX" && ":$PATH:" != *":$HOMEBREW_PREFIX/bin:"* ]]; then
    export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$PATH"
fi
