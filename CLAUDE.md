# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**homeup-linux** is a dotfiles setup for **headless Debian/Ubuntu cloud servers**, built on chezmoi
(templating) + apt (packages) + just (task runner). It is the sibling of
[homeup](../homeup) (macOS workstation) — same shell/tooling experience, adapted for a freshly
provisioned server with no GUI. It does not depend on homeup at runtime: the portable config
(zsh modules, nvim, tmux, zellij, starship, git aliases, ...) was copied over once and is
maintained independently here. Don't try to symlink/submodule the two repos back together — that
was an explicit decision (see homeup's own CLAUDE.md for why it stayed a separate repo instead of
reintroducing profile branching).

There is no application code here — this repo *is* the configuration. Changes take effect on a
server via `chezmoi apply`, so correctness matters: a bad template breaks someone's shell, and a
bad `server-init.sh` change can lock someone out of a box entirely.

## Two phases — don't conflate them

1. **Day 0 (`packages/server-init.sh`, run as root, once)**: creates the sudo user, installs their
   SSH public key, sets hostname/timezone, opens ufw, and — only after the operator confirms the
   new login works — disables root/password SSH login. This script must stay plain, dependency-free
   bash (`#!/usr/bin/env bash` + coreutils/`apt`/`ufw`/`ssh` only) because it runs **before**
   `just`/`chezmoi` exist on the box.
2. **Day 1 (everything else, run as the new user)**: `packages/apt-packages.txt` +
   `packages/install-tools.sh` install tools, then chezmoi applies dotfiles — mirrors homeup's own
   `install` → `setup` → `apply` shape.

Never merge these into one script or one recipe — they run as different users with very different
blast radii (Day 0 mistakes can be irreversible without out-of-band console access).

## Commands

```sh
just provision   # Day 0: sudo bash packages/server-init.sh (root only)
just bootstrap   # Day 1: install → setup → apply (needs just/chezmoi already installed)
just install     # apt-packages.txt + install-tools.sh
just apply       # Apply dotfiles via chezmoi
just diff        # Preview pending dotfile changes (dry run)
just update      # Pull latest changes and apply
just doctor      # Health check (required + optional tools)
just validate    # Validate chezmoi templates
just lint        # Shellcheck all *.sh files
just fmt         # shfmt -i 4 all *.sh files
just upgrade     # apt update && upgrade
just clean       # apt autoremove/clean + remove temp chezmoi-test dirs
```

`just` with no args prints the recipe menu. `justfile` is the source of truth for commands.

There is no test suite in the conventional sense; `just validate` (dry-run chezmoi init) is the
closest equivalent to "tests" and should be run after touching any `.tmpl` file. `just lint`/
`just fmt` are the lint/format pass for any `.sh` file. There's no CI and no real Debian/Ubuntu box
to test against from this environment — the only reliable way to validate `server-init.sh` or
`install-tools.sh` end-to-end is a throwaway VM/container, per the plan that created this repo.

## Architecture

### apt-first packaging (`packages/`)
Unlike homeup's layered Brewfiles, this repo splits packages by **whether apt is good enough**, not
by install-order tier:
- `apt-packages.txt` — flat list, anything apt packages at a version this config actually needs.
- `install-tools.sh` — upstream installers/GitHub releases for anything apt lacks or ships too old
  (notably **neovim** — Debian/Ubuntu's apt version is well below the 0.10+ this config's nvim
  config needs — plus chezmoi, just, starship, atuin, zoxide, sheldon, zellij, uv, bun, gh,
  lazygit, git-delta, shfmt, age, gitleaks, eza, fastfetch, terraform, ollama, fava).

Everything install-tools.sh installs lands in `~/.local/bin`, which `dot_config/zsh/path.zsh`
already puts first on `PATH`. Don't add a Homebrew-style tool-isolation layer — there's no
Homebrew here at all.

`bat`/`fd` are packaged by Debian/Ubuntu as `batcat`/`fdfind`; `install-tools.sh`'s
`link_apt_renamed_tools` symlinks them to the names this config's aliases/exports expect. If a
future tool has the same renaming problem, extend that function rather than hand-patching every
place that calls the tool.

The GitHub-release asset-name patterns in `install-tools.sh` were written from memory and can
drift when a project changes its release tooling — if `install_from_github` fails to match, check
the project's actual latest-release page and fix the pattern, don't just widen the regex blindly.

### Zsh module load order (`dot_config/zsh/`)
`dot_zshrc` sources modules in a fixed, load-bearing order — respect it when adding to any module:
1. `path.zsh` (PATH/tool env — must be first; homeup's equivalent is `brew.zsh`, there's no
   Homebrew concept here)
2. `options.zsh` (setopt, affects history/globbing/completion)
3. `exports.zsh` (env vars)
4. `tools.zsh` (starship, zoxide, sheldon plugins, compinit)
5. `aliases.zsh`
6. `functions.zsh`
7. `local.zsh` (untracked, machine-local overrides — never add this to chezmoi)

`dot_zshenv` sets XDG dirs and `ZDOTDIR` before any of the above run.

### No GUI, ever
This repo intentionally excludes anything GUI/desktop: no Ghostty/Otty terminal config, no VS Code
profiles, no `defaults write`-style OS preference scripts. If a change needs a display or a desktop
app, it belongs in homeup, not here.

### Templating conventions
Same as homeup: `.tmpl` only where a file genuinely needs a computed value
(`.chezmoi.toml.tmpl`, `dot_config/git/identity.gitconfig.tmpl`). Don't add profile/OS branching
to templates — this repo is Debian/Ubuntu-only by design, same reasoning homeup uses to stay
macOS-only.

## Code Style

- Functions: single responsibility, ≤40 lines (>60 is a signal to split)
- Self-documenting names, no magic numbers, no dead code (rely on git history instead)
- No trailing whitespace; files end with a single newline
- **Shell**: `set -euo pipefail` at script top, quote all variables, `snake_case` function names,
  `shellcheck`-clean, `shfmt -i 4` formatted
- Any change to `packages/server-init.sh` needs extra care: preserve the "verify new login works
  before disabling root/password auth" ordering in `main()` — don't collapse it into one
  unconfirmed pass.

## Git Workflow

- Commit format: `<type>(<scope>): <description>` — types: feat, fix, docs, chore, refactor, test,
  ci, perf; subject ≤72 chars, imperative mood, no trailing period
- Language: match the user's language in conversation (Chinese or English); code identifiers,
  commit messages, and comments stay in English regardless
