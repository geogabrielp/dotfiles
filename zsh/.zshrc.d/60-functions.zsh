# ~/.zshrc.d/60-functions.zsh — utility functions

# Update Homebrew: formulae, casks (incl. auto-update) and cleanup
brewup() {
    command -v brew >/dev/null || { echo "brewup: brew not installed" >&2; return 1; }
    brew update && \
    brew upgrade && \
    brew upgrade --cask --greedy && \
    brew cleanup --prune=all
}

# Clean & optimize the system
#   macOS: Mole (`mo clean` + `mo optimize`) - safe, has dry-run/whitelist
#   Linux: native cleanup (apt + linuxbrew + docker)
sysoptimize() {
    if [[ "$(uname)" == "Darwin" ]]; then
        if command -v mo >/dev/null 2>&1; then
            mo clean && mo optimize
        else
            echo "sysoptimize: Mole ('mo') not installed -> brew install mole" >&2
            return 1
        fi
    else
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update -qq
            sudo apt-get autoremove -y
            sudo apt-get autoclean
        fi
        command -v brew >/dev/null 2>&1 && brew cleanup --prune=all
        command -v docker >/dev/null 2>&1 && docker system prune -f
    fi
}

# Create a directory and cd into it: take my_project
take() { mkdir -p "$1" && cd "$1"; }

# Show public IP + geolocation
unalias myip 2>/dev/null   # clear stale alias from older versions
myip() {
  local url="http://ip-api.com/json/?fields=status,message,query,country,regionName,city,timezone,isp,org,lat,lon"
  local data
  data="$(curl -s --max-time 8 "$url")" || { echo "myip: network error" >&2; return 1; }
  if command -v jq >/dev/null 2>&1; then
    print -r -- "$data" | jq -r 'if .status == "success" then
        "IP:        \(.query)",
        "Location:  \(.city), \(.regionName) - \(.country)",
        "Timezone:  \(.timezone)",
        "Coords:    \(.lat), \(.lon)",
        "ISP:       \(.isp)",
        "Provider:  \(.org)"
      else "Error: \(.message)" end'
  else
    echo "myip: jq not installed; raw response:" >&2
    print -r -- "$data"
  fi
}

# Extract any archive, detecting the format: extract app.tar.gz  (alias: x)
extract() {
  [[ -f "$1" ]] || { echo "extract: '$1' is not a file" >&2; return 1; }
  case "$1" in
    *.tar.gz|*.tgz)   tar xzf "$1" ;;
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.xz|*.txz)   tar xJf "$1" ;;
    *.tar.zst)        tar --zstd -xf "$1" 2>/dev/null || tar -xf "$1" ;;
    *.tar)            tar xf "$1" ;;
    *.gz)             gunzip "$1" ;;
    *.bz2)            bunzip2 "$1" ;;
    *.xz)             unxz "$1" ;;
    *.zip)            unzip "$1" ;;
    *.7z)             7z x "$1" ;;
    *.rar)            unrar x "$1" ;;
    *) echo "extract: unsupported format: $1" >&2; return 1 ;;
  esac
}

# Top directories by size in the current folder: dsize [count]
# Size is colored by magnitude (red=GB, yellow=MB, green=KB).
dsize() {
  du -sh ./*(N/) 2>/dev/null | sort -rh | head -n "${1:-10}" \
    | awk -F'\t' '{
        sub(/^\.\//,"",$2)
        s = $1
        c = (s ~ /G$/) ? "\033[31m" : (s ~ /M$/) ? "\033[33m" : "\033[32m"
        printf "%s%-7s\033[0m \033[1m%s\033[0m\n", c, s, $2
      }'
}

# Interactive history search via fzf (falls back to grep): hist [query]
hist() {
  if command -v fzf >/dev/null 2>&1; then
    local sel
    sel="$(fc -l 1 | fzf --tac --no-sort --query="$1" \
      | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//')"
    [[ -n "$sel" ]] && print -z -- "$sel"
  else
    grep -i --color=always "${1:-.}" "${HISTFILE:-$HOME/.zsh_history}" | tail -n 50
  fi
}

# Colorized --help via bat (falls back to plain if bat/its help syntax is missing)
bathelp() {
  local out
  out="$("$@" --help 2>&1)" || return
  if command -v bat >/dev/null 2>&1; then
    print -r -- "$out" | bat --plain --language=help 2>/dev/null || print -r -- "$out"
  else
    print -r -- "$out"
  fi
}
