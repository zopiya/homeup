# Homeup Linux

[中文](README.zh-CN.md)

A reproducible development environment for Debian and Ubuntu `amd64` hosts,
VMs, cloud-init instances, Docker, Dev Containers, and GitHub Codespaces.
Homeup installs the same locked runtimes, CLI tools, and dotfiles across every
carrier while keeping host administration separate.

## Start here

On a Debian or Ubuntu development machine, run:

```sh
curl -fsSL https://raw.githubusercontent.com/zopiya/homeup/main/scripts/bootstrap/entrypoint.sh | bash
```

The entry point stores Homeup in `~/.local/share/homeup-linux`, installs the
locked `just` binary, and runs `just bootstrap auto`. Git is used when present;
otherwise Homeup uses the public source archive. With root or passwordless
sudo, all layers run. Without it, only the system layer is skipped.

From an existing checkout:

```sh
just bootstrap          # choose permitted layers automatically
just bootstrap full     # require root or passwordless sudo
just bootstrap user     # language + user layers; never invokes sudo
just doctor             # report carrier and exact locked versions
```

## What gets installed

| Layer | Contents | Privilege |
| --- | --- | --- |
| System | Debian/Ubuntu packages | root or passwordless sudo |
| Language | Locked Python, Node.js, Bun, and Rust archives | user-owned by default |
| User | Locked CLI tools, chezmoi dotfiles, Sheldon, and TPM | no sudo |

All version-sensitive artifacts come from `toolchain/lock.sh` and are verified
with SHA-256 before installation.

## Persistent hosts

Provisioning a new host is optional and separate from the development setup:

```sh
NEW_USER=dev SSH_PUBKEY="ssh-ed25519 AAAA..." just host::provision
```

First verify that the new user can log in from another terminal. Only then run
the deliberately interactive SSH hardening command:

```sh
just host::ssh-harden
```

## Documentation

The full documentation set is maintained in Chinese; each link below is
labeled accordingly.

- [Architecture overview (Chinese)](docs/architecture.md) — the carrier/layer
  model, component call graph, and supply-chain trust path, with diagrams.
- [Usage guide (Chinese)](docs/usage-guide.md) — scenario-by-scenario
  walkthroughs: first install, no-sudo hosts, new persistent hosts,
  cloud-init, Docker images, Dev Containers/Codespaces, and toolchain
  updates.
- [Command reference (Chinese)](docs/commands.md) — public commands and
  environment variables at a glance.
- [Troubleshooting (Chinese)](docs/troubleshooting.md) — common recovery
  paths.
- [Linux operations guide (Chinese)](docs/linux-ops.md) — installed server
  tools.
- [v1 environment contract (Chinese)](docs/dev-environment-v1.md) — the
  accepted design contract; implementation and documentation must stay
  consistent with it.

## Scope

Homeup supports Debian and Ubuntu on `x86_64` / `amd64`. It intentionally does
not configure GUI desktops, non-Debian Linux distributions, or SSH hardening
without an explicit human confirmation.
