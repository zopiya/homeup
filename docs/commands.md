# Command reference

## `just`

```sh
just provision   # Day 0: sudo bash packages/server-init.sh (root only)
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

`just` with no arguments prints this same menu — `justfile` is the source of truth.

## Entry-point scripts

```bash
curl -fsSL https://get.zopiya.dev/init | sudo -E bash     # root-install.sh: Day 0 + Day 1
curl -fsSL https://get.zopiya.dev/install | bash            # install.sh: Day 1 alone / update
```

| Variable | Default | Used by |
|----------|---------|---------|
| `NEW_USER` | `zopiya` | `server-init.sh` / `root-install.sh` — username to create |
| `SSH_PUBKEY` | zopiya's own key | `server-init.sh` — public key to install for `NEW_USER`; override for a different user |
| `NEW_HOSTNAME` | (prompted; unchanged if non-interactive) | `server-init.sh` — hostname to set |
| `TIMEZONE` | `Asia/Shanghai` | `server-init.sh` — timezone to set |
| `EXTRA_FIREWALL_PORTS` | (empty) | `server-init.sh` — extra ufw ports beyond SSH |
| `NONINTERACTIVE` | (auto-detected) | `server-init.sh` — force non-interactive mode even from a real terminal |
| `HOMEUP_REPO_URL` | `https://github.com/zopiya/homeup-linux.git` | `install.sh` / `root-install.sh` — repo to clone |
| `HOMEUP_DIR` | `/opt/homeup-linux` | `install.sh` / `root-install.sh` — where to clone/update the repo |
| `CI` | false | `just setup` — skip shell changes in CI/containers |

Example override (`export` matters — env vars only reach `sudo -E bash` on the right side of the
pipe if they're exported into the shell first, not just prefixed on the `curl` command):

```bash
export NEW_USER=other SSH_PUBKEY="ssh-ed25519 AAAA... other@laptop"
curl -fsSL https://get.zopiya.dev/init | sudo -E bash
```
