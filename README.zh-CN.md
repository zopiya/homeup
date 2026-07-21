# Homeup Linux

[English](README.md)

## 快速开始

```bash
curl -fsSL https://get.zopiya.dev/init | sudo -E bash
```

建好用户、开防火墙、clone 仓库、装好 `just`/`chezmoi`，然后停在关闭 root/密码登录之前 ——
另开个终端 `ssh zopiya@<ip>` 确认能登录，再手动跑它打印出来的那条命令。

登录那个用户，跑完剩下的安装：

```bash
just bootstrap
```

（不想用 just 也可以：`curl -fsSL https://get.zopiya.dev/install | bash`）

之后更新 / 重新 apply：

```bash
just update
```

## 常用命令

```sh
just diff      # 预览
just apply     # 应用
just update    # 拉最新 + 应用
just doctor    # 健康检查
```

`just` 看完整菜单 · [docs/architecture.md](docs/architecture.md) 架构 · [docs/installation.md](docs/installation.md) 安装
· [docs/commands.md](docs/commands.md) 命令手册 · [docs/linux-ops.md](docs/linux-ops.md) 运维工具箱用法（均为英文，除本文件外）
