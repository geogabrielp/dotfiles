# ~/.zshrc.d/40-prompt.zsh - git prompt (vcs_info)

setopt PROMPT_SUBST

# Command execution time (right prompt). Uses the built-in zsh/datetime
# module with no external dependencies. Shows how long the last command took.
zmodload zsh/datetime

# When the current command started (epoch seconds, float). 0 = no command yet.
typeset -g _cmd_start_time=0

# Fired right before a command runs — record the start time.
preexec() { _cmd_start_time=$EPOCHREALTIME }

# Format an elapsed time as a short human string: 0.4s / 12s / 1m 30s.
_cmd_format_elapsed() {
  local secs=$1
  local whole=${secs%.*}
  [[ -z $whole ]] && whole=0
  if (( whole >= 60 )); then
    print -r -- "$(( whole / 60 ))m $(( whole % 60 ))s"
  elif (( whole >= 10 )); then
    print -r -- "${whole}s"
  else
    printf '%.1fs' "$secs"
  fi
}

# Startup banner
# Prints "Last login" (tracked in ~/.lastlogin) and the shell startup
# time, both in faded gray, once on the first prompt. The native macOS
# "Last login" banner is suppressed via ~/.hushlogin (stowed from zsh/).
typeset -gi _zsh_startup_shown=0

_cmd_startup_banner() {
  (( _zsh_start_epoch > 0 )) || return 0
  local -F2 startup=$(( EPOCHREALTIME - _zsh_start_epoch ))
  local line="startup ${startup}s"
  if [[ -r "$HOME/.lastlogin" ]]; then
    local last=$(strftime '%a %b %e %H:%M:%S' "$(<$HOME/.lastlogin)")
    line="Last login: $last on ${TTY:t}  ·  $line"
  fi
  print -P "%F{240}$line%f"
  echo "$EPOCHSECONDS" > "$HOME/.lastlogin"
}

# Prompt & Git (native vcs_info)
autoload -Uz vcs_info
precmd() {
  vcs_info
  # First prompt: print the startup banner (last login + startup time).
  if (( _zsh_startup_shown == 0 )); then
    _zsh_startup_shown=1
    _cmd_startup_banner
  fi
  # Show execution time only if a command actually ran (preexec fired).
  if (( _cmd_start_time > 0 )); then
    local elapsed=$(( EPOCHREALTIME - _cmd_start_time ))
    RPROMPT="%F{240}$(_cmd_format_elapsed "$elapsed")%f"
    _cmd_start_time=0
  else
    RPROMPT=""
  fi
}

zstyle ':vcs_info:git:*' formats ' %F{yellow}(%b%u%c)%f'
zstyle ':vcs_info:git:*' actionformats ' %F{yellow}(%b|%a%u%c)%f'
zstyle ':vcs_info:git:*' unstagedstr '%F{red}*%f'      # * = unstaged changes
zstyle ':vcs_info:git:*' stagedstr '%F{green}+%f'      # + = staged changes
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' check-for-staged-changes true

# PERFORMANCE: the 2 lines above run `git status` on every prompt
# (2 git calls). On large repos this can slow down the prompt.
# If you notice lag, uncomment the 2 lines below
# (you'll lose the * = unstaged / + = staged indicators):
# zstyle ':vcs_info:git:*' check-for-changes false
# zstyle ':vcs_info:git:*' check-for-staged-changes false

# Prompt: directory + git branch
PROMPT='%F{blue}%~%f${vcs_info_msg_0_} %# '
