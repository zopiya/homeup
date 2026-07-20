# Architecture

## Two phases, two users

Cloud servers start out completely fresh, so getting to a working shell takes two stages, run as
two different users:

1. **Day 0 — provisioning (`packages/server-init.sh`, root, once)**: creates the sudo user,
   installs the SSH public key, sets hostname/timezone, opens ufw, and — only after confirming the
   new login works — disables root/password SSH login. Stays plain, dependency-free bash: it runs
   before `just`/chezmoi exist on the box.
2. **Day 1 — dotfiles (the new user)**: `packages/apt-packages.txt` + `packages/install-tools.sh`
   install tools, then chezmoi applies `dot_config/` — mirrors homeup's own bootstrap shape.

`root-install.sh` / `install.sh` are curl-pipeable wrappers around exactly those two phases, not a
third phase — see [installation.md](installation.md) for how they chain together.

## Directory layout

```
homeup-linux/
├── root-install.sh          # Day 0 + Day 1 in one shot (root, curl | bash)
├── install.sh                 # Day 1 alone / update path (curl | bash)
├── justfile                    # Task runner — see commands.md
├── lefthook.yml                 # Git hooks: pre-commit + pre-push
├── .chezmoi.toml.tmpl             # Chezmoi config (user identity)
├── dot_zshenv                       # Zsh entry point
├── dot_config/                        # chezmoi-managed ~/.config/
│   ├── zsh/                             # path -> options -> exports -> tools -> aliases -> functions -> local
│   ├── git/                              # Git config + identity/alias templates
│   ├── nvim/                              # Neovim Lua config (copied from homeup, unchanged)
│   └── tmux/  zellij/  starship.toml  sheldon/  atuin/  lazygit/  topgrade.toml
├── private_dot_ssh/                    # SSH config (chezmoi private_ prefix -> 0700/0600)
├── packages/
│   ├── server-init.sh                    # Day 0
│   ├── apt-packages.txt                   # Day 1: flat apt package list
│   └── install-tools.sh                    # Day 1: upstream installers apt lacks/undershoots
└── docs/
    ├── architecture.md                      # this file
    ├── installation.md                       # manual walkthrough + caveats
    ├── commands.md                            # just / script command reference
    └── linux-ops.md                            # ops toolbelt usage notes
```

## apt-first packaging

Packages are split by **whether apt is good enough**, not by install-order tier:

- `packages/apt-packages.txt` — flat list, anything apt packages at a version this config needs.
- `packages/install-tools.sh` — upstream installers/GitHub releases for anything apt lacks or ships
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
