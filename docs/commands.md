# Command reference

## `just`

```sh
just provision   # Day 0 macro: create-user -> ufw -> hostname -> timezone (root only; SSH hardening is separate, see below)
just bootstrap   # Day 1: install -> setup -> apply, in one shot

just diff        # preview pending dotfile changes (dry run)
just apply       # apply dotfile changes
just update      # pull latest changes and apply

just doctor      # health check (required + optional tools)
just upgrade     # apt update && upgrade
just clean       # apt autoremove/clean + remove temp chezmoi-test dirs

just validate    # validate chezmoi templates
just lint        # shellcheck all *.sh files
just fmt         # shfmt -i 4 all *.sh files
```

`just` with no arguments prints this macro menu — `justfile` is the source of truth for macro
recipes.

## `just scripts::*` — one recipe per script

The root `justfile` only orchestrates; `scripts/justfile` (a just module, `mod scripts
'scripts/justfile'`) holds the one-recipe-per-script details `just provision`/`just install` above
are built from:

```sh
just scripts::create-user  # scripts/system/create-user.sh — user + SSH key + passwordless sudo
just scripts::ufw          # scripts/system/ufw.sh — firewall
just scripts::hostname     # scripts/system/hostname.sh
just scripts::timezone     # scripts/system/timezone.sh
just scripts::ssh-harden   # scripts/system/ssh-harden.sh — disables root/password SSH login

just scripts::apt          # scripts/packages/apt-packages.txt
just scripts::tools        # scripts/packages/install-tools.sh
```

`just --list` shows all of these alongside the macro recipes. **`just scripts::ssh-harden` is never
called automatically by anything** — not `just provision`, not `scripts/init.sh`. Run it yourself,
manually, only after confirming from a separate session that the new user can log in.

## Entry-point scripts

```bash
curl -fsSL https://get.zopiya.dev/init | sudo -E bash     # scripts/init.sh: Day 0 machine setup + minimal just/chezmoi, then stops
curl -fsSL https://get.zopiya.dev/install | bash            # scripts/install.sh: Day 1 alone / update
```

`init.sh` does **not** automatically run `install.sh` — after it finishes, log in as the new user
and run Day 1 yourself (`just bootstrap`, or the `install.sh` curl command above).

| Variable | Default | Used by |
|----------|---------|---------|
| `NEW_USER` | `zopiya` | `create-user.sh` / `init.sh` — username to create |
| `SSH_PUBKEY` | zopiya's own key | `create-user.sh` — public key to install for `NEW_USER`; override for a different user |
| `NEW_HOSTNAME` | (prompted; unchanged if non-interactive) | `hostname.sh` — hostname to set |
| `TIMEZONE` | `Asia/Shanghai` | `timezone.sh` — timezone to set |
| `EXTRA_FIREWALL_PORTS` | (empty) | `ufw.sh` — extra ufw ports beyond SSH |
| `NONINTERACTIVE` | (auto-detected) | `create-user.sh`/`ufw.sh`/`hostname.sh`/`timezone.sh` — force non-interactive mode even from a real terminal |
| `HOMEUP_REPO_URL` | Forgejo URL with an embedded read-only deploy token | `install.sh` / `init.sh` — repo to clone |
| `HOMEUP_DIR` | `/opt/homeup` | `install.sh` / `init.sh` — where to clone/update the repo |
| `CI` | false | `just setup` — skip shell changes in CI/containers |

`ssh-harden.sh` deliberately has no env-var knobs beyond the cosmetic `NEW_USER` (used only in its
confirmation prompt text) — it always requires a real terminal and a typed `yes`, no
non-interactive path exists for it on purpose.

Example override (`export` matters — env vars only reach `sudo -E bash` on the right side of the
pipe if they're exported into the shell first, not just prefixed on the `curl` command):

```bash
export NEW_USER=other SSH_PUBKEY="ssh-ed25519 AAAA... other@laptop"
curl -fsSL https://get.zopiya.dev/init | sudo -E bash
```
