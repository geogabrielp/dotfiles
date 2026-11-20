# ~/.zprofile

# Runs once per LOGIN shell (before ~/.zshrc) - Put ONLY login-time environment here

# Homebrew (cross-platform)
# Detection lives in ~/.zshrc.d/10-env.zsh (single source of the prefixes);
# login shells also get the full brew environment from `brew shellenv`.
# Non-login shells get just the PATH from 10-env, which is cheaper.
if [[ -r "$HOME/.zshrc.d/10-env.zsh" ]]; then
    source "$HOME/.zshrc.d/10-env.zsh"
    if [[ -n "$HOMEBREW_PREFIX" && -x "$HOMEBREW_PREFIX/bin/brew" ]]; then
        eval "$("$HOMEBREW_PREFIX/bin/brew" shellenv)"
    fi
fi

# Machine-specific stuff goes in ~/.zprofile_local
# like OrbStack, init, secrets, extra PATHs, etc. (This file is not tracked by git.)
[[ -f "$HOME/.zprofile_local" ]] && source "$HOME/.zprofile_local"

# `brew shellenv` and shell integrations prepend without checking for
# duplicates. `path` is declared unique in 10-env, so re-assigning it dedupes.
path=($path)
