# ~/.zshrc.d/55-integrations.zsh - shell hooks for modern CLI tools

# Every block is guarded (`command -v`): it only runs if the binary
# exists, so it works on machines that don't have them installed.

# zoxide (smart cd: `z`)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"         # defines the `z` command
fi

# fzf (fuzzy finder)
# Key bindings (Ctrl+R history, Ctrl+T files, Alt+C dirs) + completion.
if command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --zsh)"               # interactive bindings + completion
fi

# eza (modern ls) - overrides the ls alias from 50-aliases
if command -v eza >/dev/null 2>&1; then
    # Colors are defined in ~/.config/eza/theme.yml. Loaded natively
    # by eza - do NOT set EZA_COLORS here, it would override the theme.

    alias ls='eza'                    # modern ls (icons + colors)
    alias ll='eza -l'                 # detailed listing
    alias la='eza -la'                # detailed + hidden
    alias lt='eza --tree --level=2'   # directory tree
fi

# bat (modern cat)
if command -v bat >/dev/null 2>&1; then
    alias cat='bat'                                     # cat with syntax highlighting
    alias catp='bat --plain'                            # plain cat (no highlighting)
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"   # colored man pages
fi

# lazygit (git TUI) - point it at the stowed config file.
# macOS default config dir is ~/Library/Application Support/lazygit (not
# ~/.config), so LG_CONFIG_FILE overrides it. On Linux this is a no-op.
if command -v lazygit >/dev/null 2>&1; then
    export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml"
fi

# mole (macOS cleaner/optimizer) - tab completion (binary is `mo`)
if command -v mo >/dev/null 2>&1; then
    eval "$(mo completion zsh)"
fi
