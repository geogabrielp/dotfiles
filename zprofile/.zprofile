# ~/.zprofile

# Runs once per LOGIN shell (before ~/.zshrc) - Put ONLY login-time environment here

# Homebrew shellenv (cross-platform)
# Note: (10-env.zsh also builds a PATH fallback for non-login shells.)
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"                 # macOS Apple Silicon
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"                    # macOS Intel
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"    # Linux/WSL
fi

# Machine-specific stuff goes in ~/.zprofile_local
# like OrbStack, init, secrets, extra PATHs, etc. (This file is not tracked by git.)
[[ -f "$HOME/.zprofile_local" ]] && source "$HOME/.zprofile_local"
