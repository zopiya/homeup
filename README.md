# Homeup Linux

[中文](README.zh-CN.md)

Homeup provides one pinned Debian/Ubuntu development environment for a host,
VM, cloud-init instance, Development Container, or GitHub Codespaces.

## Quick start

On a Debian/Ubuntu development machine with Git:

```sh
curl -fsSL https://get.zopiya.dev/dev | bash
```

The entry point keeps a checkout in `~/.local/share/homeup-linux`, installs a
locked `just`, and runs `just bootstrap auto`. With root or non-interactive
sudo it installs all layers; without it, it safely skips only the system layer.

From a checkout, the equivalent commands are:

```sh
just bootstrap          # automatic privilege selection
just bootstrap full     # require system access
just bootstrap user     # language + user layers only; never sudo
just doctor             # exact lock-version report
```

Host provisioning is intentionally separate and SSH hardening is always a
manual follow-up:

```sh
NEW_USER=dev SSH_PUBKEY="ssh-ed25519 AAAA..." just host::provision
just host::ssh-harden
```

See the accepted [v1 environment contract](docs/dev-environment-v1.md), the
[command reference](docs/commands.md), and [installation guide](docs/installation.md).
