#!/usr/bin/env bash

# bootstrap.sh - Bootstrap a fresh machine from my dotfiles repo

#   1. Install dependencies   git · zsh · Homebrew (skipped if present)
#   2. Clone the repo         → $DOTFILES_DIR (HTTPS by default, no keys needed)
#   3. Install CLI tools      brew bundle (Formulae.brewfile)
#   4. Link dotfiles          make install (GNU Stow)
#   5. Create *_local files   ~/.gitconfig_local · ~/.zshrc_local · ~/.zprofile_local

# Idempotent - safe to re-run as many times as you like.

# Usage:
#   curl -fsSL https://raw.githubusercontent.com/geogabrielp/dotfiles/main/bin/bootstrap.sh | bash

set -euo pipefail

# Configuration
REPO_URL="${DOTFILES_REPO_URL:-https://github.com/geogabrielp/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

# Colors (auto-disabled when not a TTY; force off with NO_COLOR=1)
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  readonly C_RESET=$'\033[0m'   C_BOLD=$'\033[1m'   C_DIM=$'\033[2m'
  readonly C_RED=$'\033[31m'    C_GREEN=$'\033[32m' C_YELLOW=$'\033[33m'
  readonly C_MAGENTA=$'\033[35m' C_CYAN=$'\033[36m'
else
  readonly C_RESET='' C_BOLD='' C_DIM=''
  readonly C_RED='' C_GREEN='' C_YELLOW='' C_MAGENTA='' C_CYAN=''
fi

# Logging helpers
info()    { printf '%s▸%s %s\n'   "$C_CYAN"   "$C_RESET" "$*"; }
ok()      { printf '%s✔%s %s\n'   "$C_GREEN"  "$C_RESET" "$*"; }
warn()    { printf '%s⚠%s %s\n'   "$C_YELLOW" "$C_RESET" "$*"; }
err()     { printf '%s✖%s %s\n'   "$C_RED"    "$C_RESET" "$*" >&2; }
die()     { err "$@"; exit 1; }
section() { printf '\n%s── %s ──%s\n' "$C_MAGENTA$C_BOLD" "$*" "$C_RESET"; }

have() { command -v "$1" >/dev/null 2>&1; }

# Banner
banner() {
  printf '%s\n' "$C_MAGENTA"
  cat <<'EOF'
  ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
  ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝
  ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
  ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
  ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
  ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝ ╚═════╝

EOF
  # my signature - dim (inherits magenta), centered under the art
  printf '%s%40s%s\n' "$C_DIM" "by @geogabrielp" "$C_RESET"
}

# OS detection
detect_os() {
  case "$(uname -s)" in
    Darwin) echo macos ;;
    Linux)  echo linux ;;
    *)      die "Unsupported OS: $(uname -s)" ;;
  esac
}

# Install packages with the distro's native package manager (Linux only).
install_linux_pkgs() {
  local pkgmgr
  if have apt-get; then
    pkgmgr=apt
  elif have dnf; then
    pkgmgr=dnf
  elif have pacman; then
    pkgmgr=pacman
  elif have zypper; then
    pkgmgr=zypper
  elif have apk; then
    pkgmgr=apk
  else
    die "No supported package manager found (apt/dnf/pacman/zypper/apk)."
  fi

  case "$pkgmgr" in
    apt)    sudo apt-get update -y && sudo apt-get install -y "$@" ;;
    dnf)    sudo dnf install -y "$@" ;;
    pacman) sudo pacman -S --noconfirm --needed "$@" ;;
    zypper) sudo zypper --non-interactive install "$@" ;;
    apk)    sudo apk add "$@" ;;
  esac
}

# Load Homebrew into PATH for this script's shell (cross-platform prefix).
eval_brew() {
  local prefix
  for prefix in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew; do
    if [ -x "$prefix/bin/brew" ]; then
      eval "$("$prefix/bin/brew" shellenv)"
      return 0
    fi
  done
  return 1
}

# Dependencies
ensure_xcode_clt() {
  xcode-select -p >/dev/null 2>&1 && return 0
  warn "Xcode Command Line Tools are not installed."
  info "Run 'xcode-select --install', complete the dialog, then re-run this script."
  die "Xcode CLT is required on macOS."
}

ensure_git() {
  if have git; then
    ok "git already installed: $(git --version)"
    return
  fi
  info "Installing git..."
  if [ "$OS" = macos ]; then
    brew install git
  else
    install_linux_pkgs git
  fi
  have git || die "Failed to install git."
  ok "git installed: $(git --version)"
}

ensure_zsh() {
  if have zsh; then
    ok "zsh already installed: $(zsh --version)"
    return
  fi
  info "Installing zsh..."
  if [ "$OS" = macos ]; then
    die "zsh is bundled with macOS; it should already be present."
  else
    install_linux_pkgs zsh
  fi
  have zsh || die "Failed to install zsh."
  ok "zsh installed: $(zsh --version)"
}

ensure_make() {
  have make && { ok "make already installed."; return; }
  info "Installing make..."
  if [ "$OS" = macos ]; then
    die "make is bundled with Xcode CLT; it should already be present."
  else
    install_linux_pkgs make
  fi
  have make || die "Failed to install make."
  ok "make installed."
}

ensure_homebrew() {
  if have brew; then
    eval_brew || true
    ok "Homebrew already installed: $(brew --version | head -n1)"
    return
  fi

  info "Installing Homebrew..."
  if [ "$OS" = linux ] && ! have curl; then
    install_linux_pkgs curl
  fi
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
    || die "Homebrew installation failed — see the output above."
  eval_brew || die "Homebrew was installed but could not be loaded into PATH."
  have brew || die "Homebrew installation failed."
  ok "Homebrew installed: $(brew --version | head -n1)"
}

install_dependencies() {
  section "Dependencies (git · zsh · Homebrew)"
  case "$OS" in
    macos)
      ensure_xcode_clt
      ensure_homebrew
      ensure_git
      ensure_zsh
      ;;
    linux)
      ensure_git
      ensure_zsh
      ensure_make
      ensure_homebrew
      ;;
  esac
}

# Repository
clone_repo() {
  section "Repository"
  if [ -d "$DOTFILES_DIR/.git" ]; then
    info "Updating existing repo at $DOTFILES_DIR..."
    git -C "$DOTFILES_DIR" pull --ff-only || warn "Could not pull latest changes."
    ok "Repository up to date."
  else
    info "Cloning $REPO_URL → $DOTFILES_DIR"
    git clone "$REPO_URL" "$DOTFILES_DIR" \
      || die "Clone failed. Check the URL / network, or set DOTFILES_REPO_URL."
    ok "Repository cloned."
  fi
}

# Homebrew formulae
install_formulae() {
  section "Homebrew formulae"
  local brewfile="$DOTFILES_DIR/homebrew/Formulae.brewfile"
  if [ ! -f "$brewfile" ]; then
    warn "No Formulae.brewfile found in the repo — skipping."
    return
  fi
  info "Running 'brew bundle' with $brewfile ..."
  brew bundle --file="$brewfile" || warn "brew bundle finished with warnings."
  ok "CLI tools installed."
}

# Link dotfiles
link_dotfiles() {
  section "Link dotfiles"
  info "Running 'make install' (stow all packages) into $HOME ..."
  ( cd "$DOTFILES_DIR" && make install ) \
    || die "make install failed. Existing files? See: make adopt"
  ok "All packages linked into $HOME."
}

# Resolve sheldon plugins once the config is linked (best-effort).
sheldon_lock() {
  have sheldon || return 0
  [ -f "$HOME/.config/sheldon/plugins.toml" ] || return 0
  info "Resolving sheldon plugins (sheldon lock)..."
  sheldon lock || warn "sheldon lock failed — run 'sheldon lock' later."
  ok "Sheldon plugins resolved."
}

# Create machine-local config files with boilerplate.
# Idempotent: only creates files that don't exist yet - NEVER overwrites.
ensure_local_configs() {
  section "Local configs (*_local)"

  # ~/.gitconfig_local
  if [ -f "$HOME/.gitconfig_local" ]; then
    ok "$HOME/.gitconfig_local already exists"
  else
    info "Creating ~/.gitconfig_local (set your identity)..."
    cat > "$HOME/.gitconfig_local" <<'EOF'
# ~/.gitconfig_local - machine-specific git config (NEVER commit this file)
# Set your identity once per machine:
#   git config --file ~/.gitconfig_local user.name "Your Name"
#   git config --file ~/.gitconfig_local user.email "you@example.com"
#
# Personal tweaks that should NOT be shared across machines go here.
#   [core]
#       sshCommand = ssh -F ~/.ssh/config-work   # only if you use custom SSH
EOF
    ok "Created ~/.gitconfig_local"
  fi

  # ~/.zshrc_local
  if [ -f "$HOME/.zshrc_local" ]; then
    ok "$HOME/.zshrc_local already exists"
  else
    info "Creating ~/.zshrc_local..."
    cat > "$HOME/.zshrc_local" <<'EOF'
# ~/.zshrc_local - machine-specific zsh config (NEVER commit this file)
# Sourced automatically at the end of ~/.zshrc.
# Examples:
#   export PROJECTS_DIR="$HOME/Work"
#   alias work="cd $PROJECTS_DIR"
#   # add machine-specific PATHs, secrets, tool init, etc.
EOF
    ok "Created ~/.zshrc_local"
  fi

  # ~/.zprofile_local
  if [ -f "$HOME/.zprofile_local" ]; then
    ok "$HOME/.zprofile_local already exists"
  else
    info "Creating ~/.zprofile_local..."
    cat > "$HOME/.zprofile_local" <<'EOF'
# ~/.zprofile_local - machine-specific login env (NEVER commit this file)
# Sourced automatically at the end of ~/.zprofile (login shells).
# Examples:
#   # OrbStack
#   # [ -f ~/.orbstack/... ] && ...
#   export SOME_LOGIN_ONLY_VAR="value"
EOF
    ok "Created ~/.zprofile_local"
  fi
}

# Main
main() {
  OS="$(detect_os)"
  banner

  info "OS:       $OS"
  info "Repo:     $REPO_URL"
  info "Target:   $DOTFILES_DIR"

  install_dependencies
  clone_repo
  install_formulae
  link_dotfiles
  ensure_local_configs
  sheldon_lock

  section "Done"
  ok "Bootstrap finished. Your dotfiles are installed and linked."

  section "Next steps"
  info "${C_BOLD}1.${C_RESET} Reload your shell:         ${C_YELLOW}exec $SHELL${C_RESET}"
  info "${C_BOLD}2.${C_RESET} Authenticate with GitHub:  ${C_YELLOW}gh auth login && gh auth setup-git${C_RESET}"
  info "${C_BOLD}3.${C_RESET} Set your git name:         ${C_YELLOW}git config --file ~/.gitconfig_local user.name \"Your Name\"${C_RESET}"
  info "${C_BOLD}3.${C_RESET} Set your git email:        ${C_YELLOW}git config --file ~/.gitconfig_local user.email \"you@example.com\"${C_RESET}"
  info "${C_BOLD}4.${C_RESET} Verify git config:         ${C_YELLOW}gh auth status${C_RESET} or ${C_YELLOW}git config user.name${C_RESET}"
  info "${C_BOLD}5.${C_RESET} Make zsh your shell:       ${C_YELLOW}chsh -s \"$(command -v zsh)\"${C_RESET}"
  info "${C_BOLD}6.${C_RESET} GUI apps (macOS only):     ${C_YELLOW}brew bundle --file=~/Casks.brewfile${C_RESET}"
  info "${C_BOLD}7.${C_RESET} Manage packages/dotfiles:  ${C_YELLOW}cd $DOTFILES_DIR && make help${C_RESET}"
}

main "$@"
