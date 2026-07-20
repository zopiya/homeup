# Homeup Linux

[中文](README.zh-CN.md)

## Quick start

```bash
curl -fsSL https://get.zopiya.dev/init | sudo -E bash
```

Stops before disabling root/password SSH login — verify `ssh zopiya@<ip>` works from another
terminal, then run the follow-up command it prints.

Update / re-apply later:

```bash
curl -fsSL https://get.zopiya.dev/install | bash
```

## Common commands

```sh
just diff      # preview
just apply     # apply
just update    # pull + apply
just doctor    # health check
```

`just` for the full menu · [docs/architecture.md](docs/architecture.md) · [docs/installation.md](docs/installation.md) · [docs/commands.md](docs/commands.md) · [docs/linux-ops.md](docs/linux-ops.md)
