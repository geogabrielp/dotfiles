#!/usr/bin/env bash

# bootstrap.sh - idempotent setup for this dotfiles repo.
#
# Supported: macOS and Ubuntu/WSL (apt-based). Anything else exits early.
#
#   1. base tools   macOS: Xcode CLT · Ubuntu: git zsh make curl stow
#   2. Homebrew     installed on Linux/WSL too, so the same Brewfile works
#   3. repo         cloned (or fast-forwarded) into $DOTFILES_DIR
#   4. CLI tools    brew bundle (Formulae.brewfile, which also installs stow)
#   5. dotfiles     make install (GNU Stow)
#   6. *_local      machine-specific files, created once, never overwritten
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/geogabrielp/dotfiles/main/bin/bootstrap.sh | bash

set -euo pipefail

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

info()    { printf '%s▸%s %s\n'   "$C_CYAN"   "$C_RESET" "$*"; }
ok()      { printf '%s✔%s %s\n'   "$C_GREEN"  "$C_RESET" "$*"; }
warn()    { printf '%s⚠%s %s\n'   "$C_YELLOW" "$C_RESET" "$*"; }
err()     { printf '%s✖%s %s\n'   "$C_RED"    "$C_RESET" "$*" >&2; }
die()     { err "$@"; exit 1; }
section() { printf '\n%s── %s ──%s\n' "$C_MAGENTA$C_BOLD" "$*" "$C_RESET"; }
have()    { command -v "$1" >/dev/null 2>&1; }

# Failed steps are reported in the "Done" section instead of aborting mid-run:
# the remaining steps (clone, stow, local configs) are still worth doing, but
# the script must not exit 0 pretending everything worked.
FAIL_COUNT=0
FAIL_LINES=''
note_failure() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  FAIL_LINES="${FAIL_LINES}  - $*"$'\n'
  warn "$*"
}

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
  printf '%s%40s%s\n' "$C_DIM" "by @geogabrielp" "$C_RESET"
}

detect_os() {
  case "$(uname -s)" in
    Darwin) echo macos ;;
    Linux)
      have apt-get || die "Only Ubuntu/Debian (apt) is supported - use WSL or Ubuntu."
      echo linux ;;
    *) die "Unsupported OS: $(uname -s) - this repo targets macOS and Ubuntu/WSL." ;;
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

ensure_base_tools() {
  if [ "$OS" = macos ]; then
    if ! xcode-select -p >/dev/null 2>&1; then
      # The installer only opens a GUI dialog and returns immediately, so there
      # is nothing to wait for here: stop and let the (idempotent) re-run finish.
      xcode-select --install >/dev/null 2>&1 || true   # exits 1 if already running
      die "Finish the Xcode Command Line Tools dialog (run this from Terminal.app, not over SSH), then re-run this script."
    fi
    ok "Xcode Command Line Tools present (git, zsh, make, curl)."
    return
  fi

  # apt is idempotent, so no need to check tool by tool. The list is the
  # Homebrew-on-Linux requirement (docs.brew.sh/Homebrew-on-Linux) plus what the
  # dotfiles need before brew bundle runs: zsh, stow (make install), unzip
  # (`extract a.zip`) and col (the MANPAGER pipeline - without it `man` prints
  # nothing, and it fails silently).
  info "Installing base packages (apt)..."
  sudo apt-get update
  sudo apt-get install -y build-essential procps file curl git zsh stow unzip bsdextrautils
  ok "Base packages present."
}

# First line of `brew --version`, captured without a pipe: under `pipefail`,
# `| head -n1` can fail with SIGPIPE and look like a broken Homebrew.
brew_first_line() {
  local out
  out="$(brew --version 2>/dev/null)" || return 1
  printf '%s\n' "${out%%$'\n'*}"
}

ensure_homebrew() {
  local brew_version installer

  if have brew; then
    eval_brew || true
    brew_version="$(brew_first_line)" \
      || die "Homebrew is on PATH but 'brew --version' fails. Reinstall Homebrew (https://brew.sh) and re-run."
    ok "Homebrew already installed: $brew_version"
    return
  fi

  info "Installing Homebrew..."
  if [ "$OS" = linux ]; then
    # The installer runs `sudo -n` under NONINTERACTIVE, so the sudo timestamp
    # must be valid; this is the only step that prompts for the password.
    sudo -v || die "sudo is required to install Homebrew on Linux."
  fi
  # Capture the installer first: a failed download inside `bash -c "$(curl ...)"`
  # would run an empty script and exit 0, hiding the real error.
  installer="$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
    || die "Could not download the Homebrew installer - check the network and re-run."
  NONINTERACTIVE=1 /bin/bash -c "$installer" \
    || die "Homebrew installation failed - see the output above."
  eval_brew || die "Homebrew was installed but could not be loaded into PATH."
  have brew || die "Homebrew installation failed."
  brew_version="$(brew_first_line)" \
    || die "Homebrew was installed but 'brew --version' fails. Reinstall Homebrew (https://brew.sh) and re-run."
  ok "Homebrew installed: $brew_version"
}

clone_repo() {
  section "Repository"
  if [ -d "$DOTFILES_DIR/.git" ]; then
    info "Updating existing repo at $DOTFILES_DIR..."
    git -C "$DOTFILES_DIR" pull --ff-only || warn "Could not pull latest changes."
    ok "Repository up to date."
  else
    info "Cloning $REPO_URL -> $DOTFILES_DIR"
    git clone "$REPO_URL" "$DOTFILES_DIR" \
      || die "Clone failed. Check the URL / network, or set DOTFILES_REPO_URL."
    ok "Repository cloned."
  fi
}

install_formulae() {
  section "Homebrew formulae"
  local brewfile="$DOTFILES_DIR/homebrew/Formulae.brewfile"
  [ -f "$brewfile" ] || { warn "No Formulae.brewfile in the repo - skipping."; return; }
  info "Running 'brew bundle' with $brewfile ..."
  if ! brew bundle --file="$brewfile"; then
    note_failure "brew bundle failed - some CLI tools are missing. Re-run: brew bundle --file=$brewfile"
    return
  fi
  ok "CLI tools installed."
}

link_dotfiles() {
  section "Link dotfiles"
  have stow || die "stow is not installed (it comes from 'brew bundle' above) - fix that step, then re-run."
  info "Running 'make install' (stow all packages) into $HOME ..."
  ( cd "$DOTFILES_DIR" && make install ) \
    || die "make install failed. Existing files? See: make adopt"
  ok "All packages linked into $HOME."
}

# Best effort: resolve plugins once the config is linked.
sheldon_lock() {
  have sheldon || return 0
  [ -f "$HOME/.config/sheldon/plugins.toml" ] || return 0
  info "Resolving sheldon plugins (sheldon lock)..."
  sheldon lock || warn "sheldon lock failed - run 'sheldon lock' later."
  ok "Sheldon plugins resolved."
}

# Machine-local overrides. Idempotent: creates missing files only.
ensure_local_configs() {
  section "Local configs (*_local)"

  if [ ! -f "$HOME/.gitconfig_local" ]; then
    info "Creating ~/.gitconfig_local (set your identity)..."
    cat > "$HOME/.gitconfig_local" <<'EOF'
# ~/.gitconfig_local - machine-specific git config (NEVER commit this file)
#   git config --file ~/.gitconfig_local user.name "Your Name"
#   git config --file ~/.gitconfig_local user.email "you@example.com"
EOF
    ok "Created ~/.gitconfig_local"
  fi

  if [ ! -f "$HOME/.zshrc_local" ]; then
    info "Creating ~/.zshrc_local..."
    cat > "$HOME/.zshrc_local" <<'EOF'
# ~/.zshrc_local - machine-specific zsh config (NEVER commit this file)
# Sourced automatically at the end of ~/.zshrc.
#   export PROJECTS_DIR="$HOME/Work"
#   alias work="cd $PROJECTS_DIR"
EOF
    ok "Created ~/.zshrc_local"
  fi

  if [ ! -f "$HOME/.zprofile_local" ]; then
    info "Creating ~/.zprofile_local..."
    cat > "$HOME/.zprofile_local" <<'EOF'
# ~/.zprofile_local - machine-specific login env (NEVER commit this file)
# Sourced automatically at the end of ~/.zprofile (login shells).
EOF
    ok "Created ~/.zprofile_local"
  fi

  ok "Local configs in place."
}

main() {
  OS="$(detect_os)"
  banner

  info "OS:       $OS"
  info "Repo:     $REPO_URL"
  info "Target:   $DOTFILES_DIR"

  ensure_base_tools
  ensure_homebrew
  clone_repo
  install_formulae
  link_dotfiles
  ensure_local_configs
  sheldon_lock

  section "Done"
  if [ "$FAIL_COUNT" -eq 0 ]; then
    ok "Bootstrap finished. Your dotfiles are installed and linked."
  else
    err "Bootstrap finished with $FAIL_COUNT failed step(s):"
    printf '%s' "$FAIL_LINES" >&2
    printf '%sRe-run this script after fixing the step(s) above (it is idempotent).%s\n' \
      "$C_DIM" "$C_RESET" >&2
  fi

  section "Next steps"
  info "1. Make zsh your shell:  ${C_YELLOW}chsh -s \"$(command -v zsh)\"${C_RESET}"
  info "2. Reload the shell:     ${C_YELLOW}exec \$SHELL${C_RESET}"
  info "3. Authenticate GitHub:  ${C_YELLOW}gh auth login${C_RESET} (credential helper is already configured)"
  info "4. Set your identity:    ${C_YELLOW}git config --file ~/.gitconfig_local user.name \"Your Name\"${C_RESET}"
  if [ "$OS" = macos ]; then
    info "5. macOS defaults:       ${C_YELLOW}make -C \"$DOTFILES_DIR\" macos${C_RESET} (Finder, Dock, screenshots...)"
    info "6. Optional GUI apps:    ${C_YELLOW}brew bundle --file=~/Casks.brewfile${C_RESET}"
  fi

  [ "$FAIL_COUNT" -eq 0 ] || exit 1
}

main "$@"
