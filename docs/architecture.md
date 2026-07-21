# Architecture

## Two phases, two users

Cloud servers start out completely fresh, so getting to a working shell takes two stages, run as
two different users:

1. **Day 0 — machine setup (`scripts/system/*.sh`, root, once)**: creates the sudo user, installs
   the SSH public key, sets hostname/timezone, opens ufw, and — as a separate, deliberately manual
   step, only after confirming the new login works — disables root/password SSH login. Five
   independent scripts (`create-user.sh`, `ufw.sh`, `hostname.sh`, `timezone.sh`, `ssh-harden.sh`),
   composed by whatever calls them rather than sourcing each other. Stays plain, dependency-free
   bash: it runs before `just`/chezmoi exist on the box.
2. **Day 1 — dotfiles (the new user)**: `scripts/packages/apt-packages.txt` +
   `scripts/packages/install-tools.sh` install tools, then chezmoi applies `dot_config/` — mirrors
   homeup's own bootstrap shape.

`scripts/init.sh` / `scripts/install.sh` are curl-pipeable entry points, not a third phase.
`init.sh` composes `create-user.sh` → `ufw.sh` → `hostname.sh` → `timezone.sh`, installs just
enough (`just`/`chezmoi`) to hand off, then **stops** — it does not automatically run Day 1, and it
never touches `ssh-harden.sh` (that one's only ever run manually, see below). See
[installation.md](installation.md) for the full chain and [commands.md](commands.md) for the
command reference.

### SSH hardening is always separate, always manual

`ssh-harden.sh` disables root/password SSH login — the one genuinely irreversible step here (a
wrong key means a full lockout, recoverable only via out-of-band console access). Unlike the other
four `scripts/system/*.sh` scripts, nothing ever calls it automatically: not `scripts/init.sh`, not
`just provision`. You run it yourself, after confirming from a separate session that the new user
can log in: `just scripts::ssh-harden`.

## Directory layout

```
homeup-linux/
├── scripts/
│   ├── init.sh                            # Day 0 entry: machine setup + minimal just/chezmoi, then stops (curl | bash)
│   ├── install.sh                          # Day 1 entry: minimal just/chezmoi, then delegates to `just bootstrap` (curl | bash)
│   ├── justfile                             # just module (mod scripts) — one recipe per script, see commands.md
│   ├── system/                              # attribute: machine-level config (not tied to any software)
│   │   ├── create-user.sh                      # user + SSH key + passwordless sudo
│   │   ├── ufw.sh                               # firewall
│   │   ├── hostname.sh                           # hostname + /etc/hosts
│   │   ├── timezone.sh                            # timezone
│   │   └── ssh-harden.sh                           # disables root/password login — manual only, never composed automatically
│   └── packages/                            # attribute: software/tool installation
│       ├── apt-packages.txt                     # Day 1: flat apt package list
│       └── install-tools.sh                      # Day 1: upstream installers apt lacks/undershoots
├── run_once_after_sheldon-lock.sh          # chezmoi hook: sheldon lock, after apply writes plugins.toml
├── run_once_after_reload-gpg-agent.sh       # chezmoi hook: restart gpg-agent, after apply
├── justfile                    # Task runner (macro recipes only) — see commands.md
├── lefthook.yml                 # Git hooks: pre-commit + pre-push
├── .chezmoi.toml.tmpl             # Chezmoi config (user identity)
├── dot_zshenv                       # Zsh entry point
├── dot_config/                        # chezmoi-managed ~/.config/
│   ├── zsh/                             # path -> options -> exports -> tools -> aliases -> functions -> local
│   ├── git/                              # Git config + identity/alias templates
│   ├── nvim/                              # Neovim Lua config (copied from homeup, unchanged)
│   └── tmux/  zellij/  starship.toml  sheldon/  atuin/  lazygit/  topgrade.toml
├── private_dot_ssh/                    # SSH config (chezmoi private_ prefix -> 0700/0600)
└── docs/
    ├── architecture.md                      # this file
    ├── installation.md                       # manual walkthrough + caveats
    ├── commands.md                            # just / script command reference
    └── linux-ops.md                            # ops toolbelt usage notes
```

`scripts/` groups everything by **what it acts on**, not by which day it runs — `system/` is
machine-level config (one script per concern, none of them source each other), `packages/` is
software installation. Future scripts (e.g. a `docker/` or `kvm/` setup) get their own sibling
directory under `scripts/` on the same logic; only some of them will also get a public
`get.zopiya.dev` mapping like `init.sh`/`install.sh` do, the rest stay internal and get wrapped as
`just` recipes in `scripts/justfile`.

The root `justfile` only holds macro/orchestration recipes (`bootstrap`, `provision`, `install`,
`setup`, ...); `scripts/justfile` is a just module (`mod scripts 'scripts/justfile'`) holding one
recipe per script, called as `just scripts::<name>`. Macro recipes depend on module recipes
directly, e.g. `provision: scripts::create-user scripts::ufw scripts::hostname scripts::timezone`.

The two `run_once_after_*.sh` files at the repo root are chezmoi's own hook mechanism (chezmoi's
sourceDir is the repo root, so no separate `chezmoi/` subdirectory is needed) — they replace what
used to be a `just setup` step, and are guaranteed to run only after `chezmoi apply` has already
written the files they depend on.

## apt-first packaging

Packages are split by **whether apt is good enough**, not by install-order tier:

- `scripts/packages/apt-packages.txt` — flat list, anything apt packages at a version this config needs.
- `scripts/packages/install-tools.sh` — upstream installers/GitHub releases for anything apt lacks or ships
  too old (notably neovim — Debian/Ubuntu's apt version is well below the 0.10+ this nvim config
  needs — plus chezmoi, just, starship, atuin, zoxide, sheldon, zellij, uv, bun, gh, lazygit,
  git-delta, shfmt, age, gitleaks, eza, fastfetch, terraform, ollama, fava).

Everything `install-tools.sh` installs lands in `~/.local/bin`, which `dot_config/zsh/path.zsh`
already puts first on `PATH`.

`bat`/`fd` are packaged by Debian/Ubuntu as `batcat`/`fdfind`; `install-tools.sh` symlinks them to
the names this config's aliases expect.

`install-tools.sh` only supports `x86_64`/`amd64` — it exits with a clear error on other
architectures instead of silently installing binaries that won't run.

## Zsh module load order

`dot_zshrc` sources `dot_config/zsh/` modules in a fixed order: `path.zsh` (PATH, must be first) →
`options.zsh` → `exports.zsh` → `tools.zsh` (starship, zoxide, sheldon, compinit) → `aliases.zsh` →
`functions.zsh` → `local.zsh` (untracked, machine-local overrides).

## No GUI, ever

No Ghostty/terminal config, no VS Code profiles, no `defaults write`-style scripts. Anything that
needs a display belongs in `homeup`, not here.
