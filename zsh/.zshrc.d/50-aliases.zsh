# ~/.zshrc.d/50-aliases.zsh - aliases (and ls colors)

# ls colors (fallback; eza overrides in 55-integrations.zsh)
if [[ "$(uname)" == "Darwin" ]]; then
    alias ls='ls -G'
else
    autoload -Uz colors && colors
    command -v dircolors >/dev/null 2>&1 && eval "$(dircolors -b)"
    alias ls='ls --color=auto'
fi

# Colorized completions - needs LS_COLORS (set above on Linux via dircolors).
# Must run AFTER the dircolors block, so it lives here (not in 30-plugins).
[[ -n "$LS_COLORS" ]] && zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# --------------------------------- Aliases ---------------------------------

# Shell / config
alias zconfig="nano ~/.zshrc"                           # edit main zsh config
alias zaliases="nano ~/.zshrc.d/50-aliases.zsh"         # edit THIS file
alias reload="source ~/.zshrc"                          # reload config
alias e="$EDITOR"                                       # open $EDITOR (nano)
alias c="clear"                                         # clear screen
alias q="exit"                                          # quick exit

# Git
alias g="git"                                           # git
alias gs="git status"                                   # status
alias ga="git add"                                      # stage
alias gc="git commit"                                   # commit
alias gd="git diff"                                     # diff
alias gp="git push"                                     # push
alias gl="git pull"                                     # pull
alias glg="git log --oneline --graph"                   # history graph

# TUI tools
alias lgit="lazygit"                                    # visual git TUI
alias ldocker="lazydocker"                              # visual docker TUI

# Files / listing
alias ll="ls -la"                                       # detailed listing
alias la="ls -lah"                                      # detailed + hidden
alias grep="grep --color=auto"                          # colorized grep
alias mkdir="mkdir -p"                                  # nested dirs
alias tree="tree -L 2"                                  # directory tree (2 levels)
alias x="extract"                                       # extract archives (fn in 60-functions)

# Search
# fd is much faster than find and respects .gitignore
if command -v fd >/dev/null 2>&1; then
    alias f='fd'                                        # quick file search
else
    alias f='find . -name'                              # fallback: classic find
fi

# History
alias h='fc -l 1'                                       # numbered history
