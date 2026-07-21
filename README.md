# Homeup Linux

[中文](README.zh-CN.md)

## Quick start

Fresh cloud server, logged in as `root` (the normal case):

```bash
curl -fsSL https://get.zopiya.dev/init | bash
```

Already on the box as a non-root sudo user instead? Use `sudo -E bash` in place of `bash` (plain
`sudo bash` drops your environment, so `-E` matters if you're overriding `NEW_USER`/`SSH_PUBKEY`).

Creates your user, opens the firewall, clones the repo, and installs `just`/`chezmoi` — then stops
before disabling root/password SSH login. Verify `ssh zopiya@<ip>` works from another terminal,
then run the follow-up command it prints.

Log in as that user and finish setup:

```bash
just bootstrap
```

(or, without `just`: `curl -fsSL https://get.zopiya.dev/install | bash`)

Update / re-apply later:

```bash
just update
```

## Common commands

```sh
just diff      # preview
just apply     # apply
just update    # pull + apply
just doctor    # health check
```

`just` for the full menu · [docs/architecture.md](docs/architecture.md) · [docs/installation.md](docs/installation.md) · [docs/commands.md](docs/commands.md) · [docs/linux-ops.md](docs/linux-ops.md)
