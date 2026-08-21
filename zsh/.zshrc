# ~/.zshrc - entry point for the zsh modules

# This file only defines the ORDER and sources the modules from
# ~/.zshrc.d/ (same stow package folder). Order is given by the
# numeric prefix:
#   10-env          environment variables and PATH
#   20-options      history and shell options
#   30-plugins      Sheldon (plugins) + compinit
#   40-prompt       git prompt (vcs_info) + command exec time
#   50-aliases      aliases (and ls colors)
#   55-integrations CLI tool hooks (zoxide, fzf, eza, bat)
#   60-functions    utility functions

# To add a new module: create ~/.zshrc.d/70-*.zsh

setopt EXTENDED_GLOB

# Measure shell startup time (from zsh start to first prompt).
zmodload zsh/datetime
typeset -gF _zsh_start_epoch=$EPOCHREALTIME

for _f in "$HOME/.zshrc.d/"*.zsh(N); do
    source "$_f"
done

# Machine-local overrides
[[ -f "$HOME/.zshrc_local" ]] && source "$HOME/.zshrc_local"
