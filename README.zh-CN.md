# Homeup Linux

[English](README.md)

Homeup 为 Debian/Ubuntu `amd64` 主机、VM、cloud-init、Docker、Dev Container
和 GitHub Codespaces 提供一致、可复现的开发环境。所有环境共享锁定的运行时、
CLI 工具与 dotfiles，同时将主机运维与开发环境严格分离。

## 快速开始

在 Debian 或 Ubuntu 开发环境执行：

```sh
curl -fsSL https://raw.githubusercontent.com/zopiya/homeup/main/scripts/bootstrap/entrypoint.sh | bash
```

入口会将仓库维护在 `~/.local/share/homeup-linux`，安装锁定版本的 `just`，再执行
`just bootstrap auto`。系统有 Git 时使用 Git checkout；没有 Git 时使用公开源码
归档。具备 root 或免交互 sudo 时会运行全部层；否则只跳过系统层。

已 clone 仓库时，可直接执行：

```sh
just bootstrap          # 自动选择当前允许的层
just bootstrap full     # 必须具备 root 或免交互 sudo
just bootstrap user     # 只运行语言层和用户层，绝不调用 sudo
just doctor             # 报告环境类型与精确锁定版本
```

## 安装内容

| 层 | 内容 | 权限 |
| --- | --- | --- |
| 系统层 | Debian/Ubuntu 软件包 | root 或免交互 sudo |
| 语言层 | 锁定的 Python、Node.js、Bun、Rust | 默认写入用户目录 |
| 用户层 | 锁定 CLI、chezmoi dotfiles、Sheldon 与 TPM | 不需要 sudo |

所有版本敏感的产物均来自 `toolchain/lock.sh`，下载后先校验 SHA-256 再安装。

## 新建长期主机

主机初始化是可选操作，且独立于开发环境：

```sh
NEW_USER=dev SSH_PUBKEY="ssh-ed25519 AAAA..." just host::provision
```

务必在另一个终端确认新用户可以 SSH 登录，之后再手工执行不可逆的加固操作：

```sh
just host::ssh-harden
```

## 文档

- [架构总览](docs/architecture.md)：carrier/layer 模型、组件调用关系与供应链
  信任链路，配图解读。
- [场景化使用手册](docs/usage-guide.md)：按场景给命令——首次安装、无 sudo
  主机、新建长期主机、cloud-init、Docker 镜像、Dev Container/Codespaces、
  工具链升级。
- [命令参考](docs/commands.md)：公开命令与环境变量速查表。
- [故障排查](docs/troubleshooting.md)：常见恢复路径。
- [Linux 运维工具](docs/linux-ops.md)：已安装的服务器工具用法。
- [v1 开发环境契约](docs/dev-environment-v1.md)：已批准的设计契约，实现与
  文档必须与它保持一致。

## 支持边界

Homeup 仅支持 `x86_64` / `amd64` 的 Debian 和 Ubuntu；不配置 GUI、非 Debian
Linux，也不会在没有明确人工确认的情况下执行 SSH 加固。
