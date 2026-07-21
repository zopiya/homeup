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
bad `scripts/system/*.sh` change can lock someone out of a box entirely.

## Two phases — don't conflate them

1. **Day 0 (`scripts/system/*.sh`, run as root, once)**: creates the sudo user, installs their SSH
   public key, sets hostname/timezone, opens ufw, and — only after the operator confirms the new
   login works, as a deliberately separate manual step — disables root/password SSH login. These
   scripts must stay plain, dependency-free bash (`#!/usr/bin/env bash` + coreutils/`apt`/`ufw`/
   `ssh` only) because they run **before** `just`/`chezmoi` exist on the box.
2. **Day 1 (everything else, run as the new user)**: `scripts/packages/apt-packages.txt` +
   `scripts/packages/install-tools.sh` install tools, then chezmoi applies dotfiles — mirrors
   homeup's own `install` → `setup` → `apply` shape.

Never merge these into one script or one recipe — they run as different users with very different
blast radii (Day 0 mistakes can be irreversible without out-of-band console access).

Scripts are grouped under `scripts/` by **what they act on**, not by which day they run: `system/`
holds machine-level config (users, firewall, hostname — independent of what software ends up
installed), `packages/` holds software/tool installation. Future categories (e.g. a `docker/` or
`kvm/` setup script) get their own sibling directory under `scripts/` following the same
by-attribute logic, rather than being wedged into a Day 0/Day 1 numbering scheme.

### `scripts/system/` — one script, one concern, no cross-sourcing

`scripts/system/` is five independent scripts, not one monolith: `create-user.sh`, `ufw.sh`,
`hostname.sh`, `timezone.sh`, `ssh-harden.sh`. Each does exactly one thing, reads only the env vars
it needs, and never sources another script in this directory — they're composed by whatever calls
them (`scripts/init.sh` for the curl-pipe path, `scripts/justfile`'s `scripts::*` recipes for the
manual/`just` path), not by calling each other. This costs a little duplicated boilerplate (each
carries its own `log`/`non_interactive`/validation helpers) in exchange for genuine independence —
the same trade this repo already made for `scripts/init.sh`/`scripts/install.sh` not sourcing each
other. When adding a new system-level concern, add a new sibling script here, don't grow an
existing one past its one concern.

`ssh-harden.sh` is the odd one out on purpose: it's the only genuinely irreversible step (a wrong
key means a full lockout, recoverable only via out-of-band console access), so it's the only script
in this directory that **no composed recipe ever calls automatically** — not `scripts/init.sh`, not
`just provision`. It's always a separate, deliberate `just scripts::ssh-harden` (or
`sudo bash scripts/system/ssh-harden.sh`) you run yourself after confirming the new login works.
Don't fold it back into `provision`/`init.sh`'s automatic sequence — that isolation is the point.

### `scripts/init.sh` / `scripts/install.sh` — curl-pipeable entry points

These two scripts are thin bootstrappers, not a third phase, and neither duplicates the actual
install sequence — that sequence lives in exactly one place, the root `justfile`:

- **`scripts/init.sh`** (Day 0, run as root, `curl -fsSL <url> | sudo -E bash`): clones the repo,
  runs `scripts/system/create-user.sh` → `ufw.sh` → `hostname.sh` → `timezone.sh` in sequence
  (composing the independent scripts described above), hands the checkout off (`chown -R`) to the
  new user, then installs only `just`/`chezmoi` for that user (not the full `install-tools.sh` run)
  and **stops** — it deliberately does not cascade into `scripts/install.sh` or `just bootstrap`.
  Installing packages and applying dotfiles is a manual choice you make afterwards, logged in as the
  new user. Don't reintroduce that cascade — root doing the new user's package/dotfile choices for
  them was the thing this was deliberately simplified away from.
- **`scripts/install.sh`** (Day 1, run as the non-root user, same curl-pipeable shape): clones/pulls
  the repo into `/opt/homeup` (or `$HOMEUP_DIR`), installs only `just`/`chezmoi` (same minimal
  install as `init.sh`, duplicated rather than shared — see below), then delegates everything else
  to `just bootstrap`. It does not itself know about `apt-packages.txt`/`install-tools.sh`/
  `chezmoi apply`/`just setup` — that knowledge lives only in the justfile now. Re-running
  `install.sh` is the update path.

Both scripts duplicate the same two `install_minimal_tools` one-liners (chezmoi's and just's
official installers) rather than one sourcing the other or either sourcing
`install-tools.sh` — consistent with `scripts/system/`'s no-cross-sourcing rule above. Piped
through `curl | bash`, stdin is the script itself, not a terminal — neither script may prompt via
`read`; where a prompt is genuinely unavoidable (sudo in `install.sh`), it's read from `/dev/tty`
explicitly instead.

**The one rule that still holds across all of this: SSH hardening (disabling root/password login)
never runs unattended, no matter which entry point is used.** It's not just "skipped in
non-interactive mode" anymore — `ssh-harden.sh` is a fully separate script that no composed
recipe or entry script ever calls for you (see above). Don't add an env-var opt-in to auto-confirm
it, and don't have `init.sh`/`provision` call it automatically — a wrong or mistyped key here means
a lockout recoverable only via out-of-band console access, so it stays a human-in-the-loop,
separately-invoked step by design.

`create-user.sh` also grants `$NEW_USER` passwordless sudo via a dedicated, `visudo`-validated
`/etc/sudoers.d/$NEW_USER` (the account has no password at all — `adduser --disabled-password` — so
without this, sudo would be unusable for that user in any context, including the apt/sudo calls
`install.sh`/`install-tools.sh`/the other `scripts/system/*.sh` scripts make).

**Repo hosting**: canonical remote is self-hosted Forgejo (`git.zopiya.dev/infra/homeup-linux`,
login required by default), not GitHub. Both entry scripts' `HOMEUP_REPO_URL` default embeds a
read-only deploy token (`https://<token>@git.zopiya.dev/...`) specifically so the anonymous
`curl | bash` flow can still `git clone` despite the instance requiring auth — that token is
intentionally read-only, so don't expect it to work for anything beyond cloning. Docs/README show
the plain (tokenless) URL for people using their own credentials; only the two scripts' defaults
carry the token. The `get.zopiya.dev/init`/`/install` redirect that actually serves these scripts'
raw bytes to `curl` is a separate, external system with no config in this repo — out of scope here.

## Commands

```sh
./scripts/init.sh    # Day 0: machine setup + minimal just/chezmoi install, then stops (root only, curl-pipeable, no SSH hardening)
./scripts/install.sh # Day 1 alone, or the update path (non-root, curl-pipeable, re-run to update)
just provision   # Day 0 macro: scripts::create-user → scripts::ufw → scripts::hostname → scripts::timezone
just bootstrap   # Day 1: install → setup → apply (needs just/chezmoi already installed)
just install     # macro: scripts::apt + scripts::tools
just apply       # Apply dotfiles via chezmoi
just diff        # Preview pending dotfile changes (dry run)
just update      # Pull latest changes and apply
just doctor      # Health check (required + optional tools)
just validate    # Validate chezmoi templates
just lint        # Shellcheck all *.sh files
just fmt         # shfmt -i 4 all *.sh files
just upgrade     # apt update && upgrade
just clean       # apt autoremove/clean + remove temp chezmoi-test dirs

just scripts::create-user  # scripts/system/create-user.sh
just scripts::ufw          # scripts/system/ufw.sh
just scripts::hostname     # scripts/system/hostname.sh
just scripts::timezone     # scripts/system/timezone.sh
just scripts::ssh-harden   # scripts/system/ssh-harden.sh — never automatic, see above
just scripts::apt          # scripts/packages/apt-packages.txt
just scripts::tools        # scripts/packages/install-tools.sh
```

`just` with no args prints the macro recipe menu; `just --list` shows everything, including the
`scripts::*` module recipes. The root `justfile` only holds macro/orchestration recipes; `scripts/
justfile` (loaded via `mod scripts 'scripts/justfile'`) holds the one-recipe-per-script
implementation details — see "`scripts/` layout and the justfile module" below. Both files
together are the source of truth for commands.

There is no test suite in the conventional sense; `just validate` (dry-run chezmoi init) is the
closest equivalent to "tests" and should be run after touching any `.tmpl` file or the two
`run_once_after_*.sh` chezmoi hooks. `just lint`/`just fmt` are the lint/format pass for any `.sh`
file. There's no CI and no real Debian/Ubuntu box to test against from this environment — the only
reliable way to validate `scripts/system/*.sh` or `install-tools.sh` end-to-end is a throwaway
VM/container, per the plan that created this repo.

## Architecture

### apt-first packaging (`scripts/packages/`)
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

### `scripts/` layout and the justfile module
The root `justfile` is macro-level only: `bootstrap`/`provision`/`install`/`setup`/`apply`/`doctor`/
etc — recipes that describe *what happens*, not *how a specific script gets invoked*. Anything
that's really "run this one script" detail lives in `scripts/justfile` instead, wired in via
`mod scripts 'scripts/justfile'` and called as `just scripts::<name>` (e.g. `just scripts::ufw`).
Macro recipes depend on module recipes directly (`provision: scripts::create-user scripts::ufw ...`)
rather than shelling out to `just` again recursively — that's the idiomatic way to compose across a
just module. When adding a new script anywhere under `scripts/`, add its one-line invocation to
`scripts/justfile`, not to the root `justfile`.

### chezmoi `run_once_after_` hooks, not justfile recipes, for apply-time setup
`run_once_after_sheldon-lock.sh` and `run_once_after_reload-gpg-agent.sh` (repo root, alongside
`dot_config/` — chezmoi's sourceDir is the repo root, no separate `chezmoi/` subdirectory needed)
replace what used to be a `just setup`-driven `_setup-tools` recipe. This isn't just a relocation:
`run_once_after_` scripts are guaranteed by chezmoi to run *after* the corresponding apply pass
writes files to disk, even on the very first `chezmoi apply` — the old justfile-recipe version ran
`setup` *before* `apply` in the `bootstrap` chain, so on a brand-new machine
`~/.config/sheldon/plugins.toml` didn't exist yet and the sheldon-lock step silently no-opped (only
a *second* `just setup` ever actually locked anything). If you add another "needs to run right
after chezmoi writes some config" step, add another `run_once_after_<name>.sh` here — one script,
one concern, same as `scripts/system/` — don't grow one of these two or resurrect a
`_setup-tools`-style combined recipe.

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
- Any change to `scripts/system/ssh-harden.sh` needs extra care: preserve its requirement of a real
  controlling terminal and an explicit typed `yes` before disabling root/password auth — don't add
  a way to skip that confirmation, and don't have any other script or recipe call it automatically.

## Git Workflow

- Commit format: `<type>(<scope>): <description>` — types: feat, fix, docs, chore, refactor, test,
  ci, perf; subject ≤72 chars, imperative mood, no trailing period
- Language: match the user's language in conversation (Chinese or English); code identifiers,
  commit messages, and comments stay in English regardless
