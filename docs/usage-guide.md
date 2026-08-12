# 场景化使用手册

本文按"我现在处于什么场景"组织，直接给出该场景下要敲的命令和需要注意的点。
设计原理见[架构总览](architecture.md)；命令与环境变量的完整速查表见
[命令参考](commands.md)；出问题时看[故障排查](troubleshooting.md)。

所有命令默认在 Homeup 的 checkout 根目录执行（curl 安装后默认是
`~/.local/share/homeup-linux`）。

## 我该看哪一节？

| 你的情况 | 去哪一节 |
| --- | --- |
| 全新的个人电脑/VM，第一次装 | [1. 全新开发机首次安装](#1-全新开发机首次安装) |
| 公司/公共服务器，没有 sudo | [2. 无 sudo 的共享主机](#2-无-sudo-的共享主机) |
| 已经装过，日常拉更新 | [3. 日常维护](#3-日常维护) |
| 要建一台新的长期主机/VM（含 SSH 加固） | [4. 新建长期主机](#4-新建长期主机) |
| 要用 cloud-init 拉起一台云主机 | [5. cloud-init 云主机](#5-cloud-init-云主机) |
| 要改 Dockerfile 或本地验证镜像 | [6. Docker 镜像本地验证](#6-docker-镜像本地验证) |
| 用 Dev Container / Codespaces 开发 | [7. Dev Container 与 Codespaces](#7-dev-container-与-codespaces) |
| 要升级 Node/Python/Rust/CLI 版本 | [8. 工具链版本升级](#8-工具链版本升级) |
| 要配置 Git 身份/签名 | [9. Git 身份（可选）](#9-git-身份可选) |

---

## 1. 全新开发机首次安装

适用于：一台新的 Debian/Ubuntu `amd64` 机器，你对它有 root 或 sudo 权限。

```sh
curl -fsSL https://raw.githubusercontent.com/zopiya/homeup/main/scripts/bootstrap/entrypoint.sh | bash
```

这一行做的事：把仓库放到 `~/.local/share/homeup-linux`（有 Git 用 Git
checkout，没有则用源码归档），安装锁定版本的 `just`，然后执行
`just bootstrap auto`——即"权限允许就装系统层，语言层和用户层总会装"。

装完立刻验证：

```sh
cd ~/.local/share/homeup-linux
just doctor
```

`doctor` 会报告当前载体、权限级别，以及 `just`、chezmoi、Sheldon、Node.js、
Bun、Python、Rust、TPM 是否与 `toolchain/lock.sh` 完全一致。如果系统层因为
没有 sudo 被跳过，这是预期行为——语言层和用户层依然会完整安装。

## 2. 无 sudo 的共享主机

适用于：公司跳板机、公共开发服务器等你无法/不想要求 sudo 的环境。

```sh
just bootstrap user
```

`user` 模式绝对不会调用 `sudo` 或 `apt`，只运行语言层（装到
`~/.local/opt`）和用户层（装到 `~/.local/bin`，dotfiles 应用到 `$HOME`）。
如果之后拿到了 sudo，可以单独补装系统层：

```sh
just system::install
```

## 3. 日常维护

先看 dotfiles 会发生什么变化，再决定要不要应用：

```sh
just diff      # 预览 chezmoi 会改动哪些文件，不会真的改
just update    # 拉取 chezmoi 源码更新，但不应用
just user::apply  # 重新应用用户层（chezmoi apply + 核心 CLI + TPM）
just doctor    # 确认版本仍然和锁文件一致
```

运行时和核心 CLI 的版本完全由 `toolchain/lock.sh` 控制。**不要**手工把
`latest` 版本的二进制覆盖到 `~/.local/bin`；需要升级时走
[8. 工具链版本升级](#8-工具链版本升级)。

所有层都是幂等的：重复执行不会重新下载已经存在且版本匹配的产物，可以放心
在任何时候重新跑一遍来"修复"环境。

## 4. 新建长期主机

适用于：一台准备长期使用的新主机或物理机，需要建独立用户、配置防火墙/主机名/
时区，并最终做 SSH 加固。**这一整节都是主机初始化操作，和开发环境安装是分开的
两件事**，不会被 `bootstrap` 自动触发。

第一步，创建用户并按需配置：

```sh
NEW_USER=dev \
SSH_PUBKEY="$(cat ~/.ssh/id_ed25519.pub)" \
NEW_HOSTNAME=homeup-dev \
TIMEZONE=UTC \
just host::provision
```

`host::provision` 会创建 `NEW_USER`、写入 `SSH_PUBKEY` 到
`~/.ssh/authorized_keys`、按需启用 UFW（`EXTRA_FIREWALL_PORTS` 可选）、
设置 `NEW_HOSTNAME` 和 `TIMEZONE`。这一步**不会**碰 SSH 加固。

第二步，从**另一个终端**用新用户和新公钥登录，确认能正常 SSH 进去。

第三步，确认无误后，再手动执行 SSH 加固：

```sh
just host::ssh-harden
```

这个命令要求真实终端（拒绝非交互执行），并要求你手动输入 `yes` 确认才会
禁用 root 登录和密码认证。它绝对不会被 bootstrap、cloud-init 或镜像构建
自动调用——这是一个不可逆操作，设计上必须有人在场。

主机初始化完成后，用[场景 1](#1-全新开发机首次安装)的方式装开发环境。

## 5. cloud-init 云主机

适用于：用 cloud-init 拉起一台云主机（如 AWS/DigitalOcean/自建 KVM），让它
开机自动完成用户创建 + 开发环境安装。

`cloud-init/homeup.yaml.tmpl` 是**模板**，不能直接上传。必须先在可信机器上
用具体值渲染它，并人工检查渲染结果里没有 token、私钥或其它密钥：

```sh
export HOMEUP_USER=dev
export HOMEUP_SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)"
export HOMEUP_REPO_URL=https://github.com/zopiya/homeup.git
export HOMEUP_HOSTNAME=homeup-cloud
export HOMEUP_TIMEZONE=UTC
export HOMEUP_ENABLE_UFW=false
envsubst < cloud-init/homeup.yaml.tmpl > homeup-cloud-init.yaml
```

确认无误后，把 `homeup-cloud-init.yaml` 作为该实例的 user-data 上传。实例首次
启动会：通过 cloud-init 原生配置创建 `HOMEUP_USER` 并写入 SSH 公钥；用
`runcmd` 以 root 身份跑系统层；再用 `runuser` 以目标用户身份跑语言层和
用户层。全程没有自动 SSH 加固开关。

## 6. Docker 镜像本地验证

适用于：改动了 `containers/dev/Dockerfile`、`packages/base.apt` 或
`toolchain/lock.sh`，需要在本地确认镜像还能正常构建、跑起来。

```sh
docker build --file containers/dev/Dockerfile --tag homeup-dev:local .
docker run --rm --user dev homeup-dev:local bash -lc 'just doctor'
```

镜像构建期只跑系统层和语言层（`HOMEUP_INSTALL_SCOPE=system`，装到
`/usr/local`），不会跑用户层——镜像里不应该出现任何 Git 身份、SSH 密钥或
dotfiles。真实的 CI（[verify.yml](../.github/workflows/verify.yml)）还会额外
用非 root 的 `dev` 用户跑一遍 `just bootstrap user && just doctor`，验证"无
sudo 主机"这条路径在镜像里同样成立。

## 7. Dev Container 与 Codespaces

适用于：直接用 VS Code Dev Container 或 GitHub Codespaces 打开这个仓库（或
以这个镜像为基础的其它仓库）。

`.devcontainer/devcontainer.json` 已经指向发布在 GHCR 上的不可变镜像摘要，
容器创建后会自动执行：

```sh
just user::apply
```

系统层和语言层已经在镜像里，不需要也不应该在容器里重新触发。如果需要排查
容器内的环境状态：

```sh
just doctor
just diff
```

**不要**在 Dev Container 里跑 `host::provision` 或 `host::ssh-harden`——它们
只对长期主机/VM 有意义，容器场景里没有 SSH、没有防火墙这些概念。

## 8. 工具链版本升级

Homeup 的版本升级不是"手工改个数字"，而是走一条固定的自动化流程：

- 每月 1 日，[toolchain-update.yml](../.github/workflows/toolchain-update.yml)
  自动运行 `scripts/ci/update-toolchain.py`，从各项目的官方 release 元数据
  （GitHub Releases API、`nodejs.org`、`static.rust-lang.org`、
  `astral-sh/python-build-standalone` 等）拉取最新稳定版本和官方校验和，
  直接改写 `toolchain/lock.sh` 并提交到默认分支。
- 想立刻看一眼"当前锁定版本 vs 上游最新版本"的对比，而不实际改锁文件，可以
  本地跑：

  ```sh
  bash scripts/ci/check-toolchain-update.sh
  ```

  它会打印一张 Markdown 表格，逐个组件列出锁定版本和官方最新版本。

- 如果要手动触发一次更新（不用等下个月 1 日），去 Actions 页面手动运行
  `toolchain-update.yml`（`workflow_dispatch`），或在本地跑：

  ```sh
  python3 scripts/ci/update-toolchain.py
  bash scripts/ci/validate-lock.sh
  ```

`validate-lock.sh` 会强制校验：URL 必须是 `https://` 且不含 `latest`，
SHA-256 必须是合法的 64 位十六进制。锁文件更新后，正常走一遍
`just bootstrap`/`just doctor` 就能验证新版本可以正常下载、校验、安装。

## 9. Git 身份（可选）

Homeup 默认**不写入任何 Git 身份信息**，这样公开镜像、全新 Codespace 都不会
意外带上你的个人身份。需要时，在跑 `just user::apply` 之前设置：

```sh
export HOMEUP_GIT_NAME="Your Name"
export HOMEUP_GIT_EMAIL="you@example.com"
# 可选：SSH 签名
export HOMEUP_GIT_SIGNING_KEY="ssh-ed25519 AAAA... you@example.com"
export HOMEUP_GIT_SIGN_COMMITS=true
just user::apply
```

这几个变量只会被 chezmoi 模板（`dot_config/git/identity.gitconfig.tmpl`）
读取；不设置时模板不生成任何 `[user]`/签名配置。变量完整说明见
[命令参考](commands.md#环境变量)。
