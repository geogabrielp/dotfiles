# dotfiles - Makefile (idempotent dotfiles management)

# Usage:
#   make help      list available targets
#   make install   stow all packages (idempotent)
#   make unstow    remove all packages
#   make refresh   unstow + stow (rebuild all symlinks)
#   make adopt     adopt existing ~ files into the repo (CAREFUL!)
#   make check     dry-run: validate all packages

# Requirements: GNU Stow (see README.md to install)

# Configuration
SHELL  := /bin/bash
STOW   ?= stow
TARGET ?= $(HOME)

# Packages
# One top-level folder per package. Add a new package here when you
# create a new dotfiles folder.
# Infra dirs (bin/, docs/, macos/, .github/ are intentionally NOT packages.
PACKAGES := eza ghostty git homebrew lazygit nanorc sheldon zprofile zsh

# Targets
.PHONY: help install unstow refresh adopt check macos print-packages
.DEFAULT_GOAL := help

# help: list available targets
help:
	@echo "Available targets:"
	@echo "  make install      -> stow all packages: $(PACKAGES)"
	@echo "  make unstow       -> remove all symlinks"
	@echo "  make refresh      -> unstow + stow (rebuild symlinks)"
	@echo "  make adopt        -> adopt existing ~ files (CAREFUL!)"
	@echo "  make check        -> dry-run (creates nothing)"
	@echo "  make macos        -> apply macOS defaults (Finder, Dock, ...)"
	@echo "  make print-packages -> list packages (one per line, used by CI)"

# install: stow all packages (idempotent)
install:
	@test -n "$(PACKAGES)" || { echo "No packages found."; exit 1; }
	@for pkg in $(PACKAGES); do \
		echo "→ stow $$pkg"; \
		$(STOW) --target="$(TARGET)" --verbose $$pkg || exit 1; \
	done
	@echo "✅ Packages installed in $(TARGET)"

# unstow: remove all packages
unstow:
	@for pkg in $(PACKAGES); do \
		echo "→ stow -D $$pkg"; \
		$(STOW) --target="$(TARGET)" --delete $$pkg || exit 1; \
	done
	@echo "✅ Packages unstowed"

# refresh: unstow + stow (rebuild all symlinks)
refresh:
	$(MAKE) unstow
	$(MAKE) install

# adopt: pull existing ~ files into the repo (CAREFUL!)
adopt:
	@echo "⚠️  WARNING: '--adopt' overwrites repo files with the ones in ~."
	@echo "    Review with 'git status' and 'git diff' BEFORE committing."
	@read -p "Continue? (y/N) " -n 1 -r; echo; \
	if [[ ! $$REPLY =~ ^[Yy]$$ ]]; then echo "Cancelled."; exit 1; fi
	@for pkg in $(PACKAGES); do \
		echo "→ stow --adopt $$pkg"; \
		$(STOW) --target="$(TARGET)" --adopt $$pkg || exit 1; \
	done

# check: dry-run - validate all packages (creates nothing)
check:
	@for pkg in $(PACKAGES); do \
		echo "→ stow --simulate $$pkg"; \
		$(STOW) --target="$(TARGET)" --simulate --verbose $$pkg || exit 1; \
	done
	@echo "✅ All packages valid"

# print-packages: print the package list, one per line - used by CI
print-packages:
	@printf '%s\n' $(PACKAGES)

# macos: apply macOS system defaults (Finder, Dock, Trackpad, ...)
# Idempotent; macOS only (the script itself guards on Darwin and no-ops elsewhere).
macos:
	@bash macos/bin/set-defaults.sh
