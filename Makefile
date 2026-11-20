# dotfiles - Makefile (idempotent dotfiles management)
#
# Requirements: GNU Stow (see README.md)
# Usage: make help

# Configuration
SHELL  := /bin/bash
STOW   ?= stow
TARGET ?= $(HOME)

# Packages: one top-level folder per package, except the infra dirs below.
# Derived from the filesystem, so a new folder is stowed automatically.
INFRA := bin docs macos .github
PACKAGES := $(filter-out $(INFRA),$(patsubst %/,%,$(dir $(wildcard */))))

# Junk stow would otherwise link (it only ignores VCS files and package docs by
# default). These flags add to that built-in list; a .stow-local-ignore file
# would replace it, which is why the patterns live here instead.
# No trailing `$`: make would eat the `$'` pair, and a literal `$` needs `$$`.
# `--ignore` is unanchored anyway, so the anchor buys nothing.
STOW_IGNORE := --ignore='(^|/)\.DS_Store' --ignore='\.swp' \
               --ignore='\.swo' --ignore='(^|/)Makefile'

.PHONY: help install unstow refresh adopt check macos print-packages \
        print-stow-ignore lint check-brewfile check-home
.DEFAULT_GOAL := help

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  %-18s %s\n", $$1, $$2}'

install: ## Stow every package into the target home
	@test -n "$(PACKAGES)" || { echo "No packages found."; exit 1; }
	@for pkg in $(PACKAGES); do \
		echo "→ stow $$pkg"; \
		$(STOW) --target="$(TARGET)" $(STOW_IGNORE) --verbose $$pkg || exit 1; \
	done
	@echo "✅ Packages installed in $(TARGET)"

unstow: ## Remove every symlink
	@for pkg in $(PACKAGES); do \
		echo "→ stow -D $$pkg"; \
		$(STOW) --target="$(TARGET)" --delete $$pkg || exit 1; \
	done
	@echo "✅ Packages unstowed"

refresh: ## Unstow + install (rebuild all symlinks)
	$(MAKE) unstow
	$(MAKE) install

adopt: ## Pull existing ~ files into the repo (CAREFUL)
	@echo "⚠️  WARNING: '--adopt' overwrites repo files with the ones in ~."
	@echo "    Review with 'git status' and 'git diff' BEFORE committing."
	@read -p "Continue? (y/N) " -n 1 -r; echo; \
	if [[ ! $$REPLY =~ ^[Yy]$$ ]]; then echo "Cancelled."; exit 1; fi
	@for pkg in $(PACKAGES); do \
		echo "→ stow --adopt $$pkg"; \
		$(STOW) --target="$(TARGET)" $(STOW_IGNORE) --adopt $$pkg || exit 1; \
	done

check: ## Dry-run: stow --simulate on every package
	@for pkg in $(PACKAGES); do \
		echo "→ stow --simulate $$pkg"; \
		$(STOW) --target="$(TARGET)" $(STOW_IGNORE) --simulate --verbose $$pkg || exit 1; \
	done
	@echo "✅ All packages valid"

check-home: ## Stow into a throwaway HOME (the real CI check)
	@STOW="$(STOW)" bin/check-stow.sh

print-packages: ## One package per line (used by check-stow)
	@printf '%s\n' $(PACKAGES)

print-stow-ignore: ## One stow --ignore flag per line (used by check-stow)
	@for opt in $(STOW_IGNORE); do echo "$$opt"; done

lint: ## shellcheck + zsh -n (same as CI)
	@for tool in shellcheck zsh; do \
		command -v $$tool >/dev/null || { echo "Missing $$tool - install it first (brew/apt install $$tool)."; exit 1; }; \
	done
	@echo "→ shellcheck"
	@shellcheck bin/*.sh macos/bin/*.sh
	@echo "→ zsh -n"
	@# one file at a time: `zsh -n a b` parses only `a` and treats the rest as $1 $2
	@for f in zsh/.zshrc zsh/.zshrc.d/*.zsh zprofile/.zprofile; do \
		zsh -n "$$f" || exit 1; \
	done
	@echo "✅ Lint OK"

# Catches a formula dropped from Homebrew (e.g. `tldr`), which breaks
# `brew bundle` on a fresh machine. Needs macOS or Linuxbrew.
check-brewfile: ## Check every formula/cask still exists upstream
	@command -v brew >/dev/null || { echo "❌ brew not found - this check needs macOS or Linuxbrew."; exit 1; }
	@missing=0; \
	for f in $$(sed -n 's/^brew "\([^"]*\)".*/\1/p' homebrew/Formulae.brewfile); do \
		brew info --json=v2 "$$f" >/dev/null 2>&1 \
			|| { echo "❌ formula not available: $$f"; missing=1; }; \
	done; \
	for c in $$(sed -n 's/^cask "\([^"]*\)".*/\1/p' homebrew/Casks.brewfile); do \
		brew info --cask --json=v2 "$$c" >/dev/null 2>&1 \
			|| { echo "❌ cask not available: $$c"; missing=1; }; \
	done; \
	[ "$$missing" -eq 0 ] || exit 1; \
	echo "✅ All formulae and casks in the Brewfiles resolve"

# macOS only: the script itself guards on Darwin and no-ops elsewhere.
macos: ## Apply macOS system defaults
	@bash macos/bin/set-defaults.sh
