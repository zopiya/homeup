# Homeup Linux

[English](README.md)

Homeup 为 Debian/Ubuntu 提供统一、可锁定版本的开发环境：物理机、VM、cloud-init、Dev Container 与 GitHub Codespaces 使用同一套层和命令。

## 快速开始

在已安装 Git 的 Debian/Ubuntu 开发环境执行：

```sh
curl -fsSL https://get.zopiya.dev/dev | bash
```

入口会把仓库维护在 `~/.local/share/homeup-linux`，安装锁定版本的 `just`，并运行 `just bootstrap auto`。可用 root 或非交互 sudo 时会安装全部层；没有 sudo 时只跳过系统层，语言层和用户层仍可运行。

已 clone 仓库时，等价命令为：

```sh
just bootstrap          # 自动选择允许的层
just bootstrap full     # 必须具备系统权限
just bootstrap user     # 只运行语言层与用户层，绝不调用 sudo
just doctor             # 检查精确锁定版本
```

主机初始化与开发环境分离，SSH 加固永远需要人工单独执行：

```sh
NEW_USER=dev SSH_PUBKEY="ssh-ed25519 AAAA..." just host::provision
just host::ssh-harden
```

完整约束见 [v1 开发环境契约](docs/dev-environment-v1.md)，具体命令见 [命令手册](docs/commands.md)。
