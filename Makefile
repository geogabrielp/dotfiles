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

# claude is special: it needs claude-prep before stowing and claude-settings
# after (settings.json is copied, not symlinked). See those targets below.
PACKAGES := claude eza ghostty git homebrew lazygit nanorc sheldon zprofile zsh

# Targets
.PHONY: help install unstow refresh adopt check macos print-packages \
        claude-prep claude-settings
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
	@echo "  make claude-prep  -> create real ~/.claude dirs (run by install)"
	@echo "  make claude-settings -> merge settings.json (run by install)"

# install: stow all packages (idempotent)
install: claude-prep
	@test -n "$(PACKAGES)" || { echo "No packages found."; exit 1; }
	@for pkg in $(PACKAGES); do \
		echo "→ stow $$pkg"; \
		$(STOW) --target="$(TARGET)" --verbose $$pkg || exit 1; \
	done
	@$(MAKE) --no-print-directory claude-settings
	@echo "✅ Packages installed in $(TARGET)"

# claude-prep: create the ~/.claude subdirectories as REAL directories before
# stow runs.
claude-prep:
	@mkdir -p "$(TARGET)/.claude/skills" "$(TARGET)/.claude/rules" \
		"$(TARGET)/.claude/themes"

# The jq merge makes the repo the source of truth, the repo wins on every key
# it defines, while keeping keys that exist only in the live file. Put a
# machine-local choice in the live file only; never define it here.
claude-settings:
	@live="$(TARGET)/.claude/settings.json"; \
	if [ -f "$$live" ]; then \
		tmp=$$(mktemp); \
		jq -s '.[1] * .[0]' claude/.claude/settings.json "$$live" > "$$tmp" || { rm -f "$$tmp"; exit 1; }; \
		install -m 600 "$$tmp" "$$live"; \
		rm -f "$$tmp"; \
		echo "→ merged settings.json → $$live (repo wins, local-only keys kept)"; \
	else \
		install -m 600 claude/.claude/settings.json "$$live"; \
		echo "→ installed settings.json → $$live"; \
	fi

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
