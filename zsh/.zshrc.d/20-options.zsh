# ~/.zshrc.d/20-options.zsh - history and shell options

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY         # append to history file instead of overwriting
setopt EXTENDED_HISTORY       # record a timestamp for each command
setopt HIST_EXPIRE_DUPS_FIRST # expire duplicate entries first
setopt HIST_FIND_NO_DUPS      # don't show duplicates when searching history
setopt HIST_IGNORE_ALL_DUPS   # ignore duplicates when saving
setopt HIST_IGNORE_DUPS       # don't add a repeated command
setopt HIST_IGNORE_SPACE      # ignore commands starting with a space
setopt HIST_SAVE_NO_DUPS      # don't save duplicates
setopt HIST_REDUCE_BLANKS     # strip excess whitespace before saving
setopt HIST_VERIFY            # confirm before running !/fc history commands
setopt SHARE_HISTORY          # share history across shells in real time

# Shell Behavior
setopt AUTO_CD                # jump to a directory by typing its path alone
setopt NO_BEEP                # disable annoying beeps
setopt INTERACTIVE_COMMENTS   # allow comments mid-command
setopt AUTO_PUSHD             # automatically pushd on cd
setopt PUSHD_IGNORE_DUPS      # no duplicates in the directory stack
