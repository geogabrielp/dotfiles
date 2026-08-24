# Quick Reference

> Back to [README](../README.md) · My personal cheat sheet. The README holds the
> public/generic stuff (setup flow, prerequisites, what's included). This is
> the "for me" quick lookup.

---

## 🖥️ Environment

| Setting | Value |
| --- | --- |
| **Primary OS** | macOS Apple Silicon (Homebrew `/opt/homebrew`) |
| **Secondary** | Linux / WSL — same dotfiles via `make install` |
| **Shell** | native zsh (no oh-my-zsh / p10k / heavy frameworks) |
| **Terminal** | Ghostty (EmberSlate custom theme) |
| **Editor** | nano (Homebrew) |

## 🐚 zsh

`~/.zshrc` is a thin entry point that sources numbered modules from `~/.zshrc.d/`:

| Module | Purpose |
| --- | --- |
| `10-env` | environment vars & PATH |
| `20-options` | history & shell options |
| `30-plugins` | Sheldon + compinit (must run before the prompt) |
| `40-prompt` | prompt with git (`vcs_info`) + exit code |
| `50-aliases` | aliases & ls colors |
| `55-integrations` | CLI hooks (zoxide, fzf, direnv, eza, bat) |
| `60-functions` | utility functions |
| `70-*` | ➕ your new module |

**Plugins** (via `sheldon/.config/sheldon/plugins.toml`):

- zsh-autosuggestions
- zsh-completions
- zsh-syntax-highlighting

After editing the file: `sheldon lock && exec $SHELL`.

**Key aliases:**

| Alias | What it does |
| --- | --- |
| `zconfig` | edit zsh config |
| `reload` | reload zsh |
| `lgit` | lazygit |
| `ldocker` | lazydocker |
| `take()` | `mkdir` + `cd` |

**Per-machine:** `~/.zshrc_local` (auto-sourced last).

## 🌿 Git

| Setting | Value |
| --- | --- |
| **Transport** | HTTPS by default using `gh` as credential helper (baked into `git/.gitconfig`) |
| **Auth once** | `gh auth login` (`gh auth setup-git` only if a GUI app can't find `gh` in PATH) |

**Identity** — never `--global` (`~/.gitconfig` is a stow symlink → would leak
into the repo):

```bash
git config --file ~/.gitconfig_local user.name "Your Name"
git config --file ~/.gitconfig_local user.email "you@example.com"
```

**Aliases** (in `git/.gitconfig`):

| Alias | Expands to |
| --- | --- |
| `st` | `status -sb` |
| `co` / `sw` / `cb` | `checkout` / `switch` / `switch -c` |
| `br` | `branch` |
| `ci` / `cim` | `commit` / `commit -m` |
| `amend` | `commit --amend --no-edit` |
| `undo` / `uncommit` / `unstage` | `reset --soft HEAD~1` / `reset --mixed HEAD~1` / `restore --staged` |
| `sync` | `pull --rebase --autostash && push` |
| `pf` | `push --force-with-lease` |
| `last` | `log -1 HEAD --stat` |
| `lg` / `ls` | colored graph log / `log --oneline --decorate -20` |
| `stat` / `root` / `rv` | `diff --stat` / `rev-parse --show-toplevel` / `remote -v` |
| `tags` | `tag -l` |

**Per-machine:** `~/.gitconfig_local` (auto-included via `[include]`).

**SSH (optional)** via `gh auth login` (it generates and uploads your key):

```bash
gh auth login --git-protocol ssh
# choose GitHub.com → SSH → "Generate a new SSH key" (gh uploads it for you)
ssh -T git@github.com
```

## 🍺 Homebrew

| Command | What it does |
| --- | --- |
| `brew bundle --file ~/Formulae.brewfile` | install CLI tools/formulae (required) |
| `brew bundle --file=~/Casks.brewfile` | install GUI apps/casks (optional) |
| `brew bundle cleanup` | remove anything not listed |

## 🔗 Stow

| Command | What it does |
| --- | --- |
| `stow zsh` | install package `zsh` (symlinks in `~`) |
| `stow -D zsh` | uninstall package (remove symlinks) |
| `stow -R zsh` | restow (uninstall + install) |
| `stow --adopt zsh` | adopt existing `~` files into the repo (careful!) |
| `stow -n -v zsh` | dry-run: simulate only |

Useful flags: `--dotfiles` (`dot-*` → `.*`), `--no-folding`, `--ignore`.

## 📄 Per-machine overrides

The `*_local` files hold machine-specific stuff — the bootstrap creates them
with boilerplate on a fresh machine. **Edit, never commit** (they're git-ignored).

| File | Purpose |
| --- | --- |
| `~/.zshrc_local` | machine zsh (paths, secrets, hostname) |
| `~/.gitconfig_local` | git identity + personal settings |
| `~/.zprofile_local` | login env (e.g. OrbStack) |

## 💡 Tips

| Problem | Fix |
| --- | --- |
| Stow: *"existing target is not owned by stow"* | `make adopt` (review with `git status` / `git diff` first) |
| `compinit`/`compaudit` error on `/opt/homebrew/share` | `chmod g-w /opt/homebrew/share` |
| Edited `plugins.toml` | `sheldon lock && exec $SHELL` |
| Changed zsh config | `reload` |
