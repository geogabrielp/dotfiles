#!/usr/bin/env bash

# check-stow.sh - stow every package into a throwaway HOME.
#
# Shared by `make check-home` and CI, so the check that runs on the runners is
# exactly the one you can run locally. Catches a broken package (wrong layout,
# missing file, name clash) before it touches the real $HOME.
#
# Usage: check-stow.sh [destination]   (default: $TMPDIR/dotfiles-check-home)

set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
STOW="${STOW:-stow}"
TMP_BASE="${TMPDIR:-/tmp}"
DEST="${1:-${TMP_BASE%/}/dotfiles-check-home}"

command -v make >/dev/null 2>&1 || { echo "make not found (brew/apt install make)" >&2; exit 1; }
command -v "$STOW" >/dev/null 2>&1 || { echo "$STOW not found (brew install stow)" >&2; exit 1; }

case "${DEST%/}" in
  ""|/|.|"$HOME") echo "refusing to wipe '$DEST': pass a throwaway directory" >&2; exit 1 ;;
esac
DEST="${DEST%/}"

rm -rf "$DEST"
mkdir -p "$DEST"

packages=()
while IFS= read -r pkg; do
  packages+=("$pkg")
done < <(cd "$REPO" && make -s print-packages)

ignore=()
while IFS= read -r opt; do
  ignore+=("$opt")
done < <(cd "$REPO" && make -s print-stow-ignore)

if [ "${#packages[@]}" -eq 0 ]; then
  echo "no packages found (see PACKAGES in the Makefile)" >&2
  exit 1
fi

if [ "${#ignore[@]}" -eq 0 ]; then
  echo "no --ignore flags from 'make print-stow-ignore'" >&2
  exit 1
fi

# Regression guard: the ignore flags must actually drop junk, otherwise a
# broken pattern silently links .DS_Store / swap files into $HOME.
probe="$(mktemp -d)"
mkdir -p "$probe/pkg" "$probe/home"
: > "$probe/pkg/a.swp"
: > "$probe/pkg/keep"
(cd "$probe" && "$STOW" --target="$probe/home" "${ignore[@]}" pkg) >/dev/null
if [ -e "$probe/home/a.swp" ] || [ ! -e "$probe/home/keep" ]; then
  echo "the Makefile's --ignore flags do not ignore junk files" >&2
  rm -rf "$probe"
  exit 1
fi
rm -rf "$probe"

echo "Packages: ${packages[*]}"

fail=0
for pkg in "${packages[@]}"; do
  echo "→ stow $pkg"
  (cd "$REPO" && "$STOW" --target="$DEST" "${ignore[@]}" --verbose "$pkg") || fail=1
done

if [ "$fail" -ne 0 ]; then
  echo "one or more packages failed to stow" >&2
  exit 1
fi

echo "✅ All packages stowed into $DEST"
