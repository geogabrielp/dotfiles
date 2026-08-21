# ~/.zshrc.d/30-plugins.zsh - zsh plugins (Sheldon) + completions

# Plugins via Sheldon (declarative manager)
if command -v sheldon >/dev/null 2>&1; then
    eval "$(sheldon source)"
fi

# Completion (compinit) runs AFTER sheldon
# sheldon adds zsh-completions to fpath; compinit reads from there
autoload -Uz compinit && compinit

zstyle ':completion:*' menu select                          # arrow-key navigable menu
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive matching
zstyle ':completion:*' complete-options                     # complete long options (git --verbose)
zstyle ':completion:*' group-name ''                        # group results (commands/files)
