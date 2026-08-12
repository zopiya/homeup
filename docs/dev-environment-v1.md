# Homeup Linux 开发环境 v1

## 状态

**已批准（Accepted）。** 本文档是跨载体（carrier）v1 开发环境的实现契约。实现、
文档与 CI 都必须遵循本文档；契约本身的变更必须先修改本文档，再落地到实现。

## 1. 目标

在受支持的 Debian 与 Ubuntu 发行版上，无论运行在长期存活的主机、虚拟机、
cloud-init 配置的实例、本地 Development Container，还是 GitHub Codespaces，
都提供同一套一致、个人化的 Linux 开发环境。

一致性指的是相同的锁定版本核心 CLI 与语言运行时、相同的 dotfiles、相同的 shell
行为，以及相同的公开 `just` 命令。它不代表把容器当主机对待：SSH、防火墙、主机名、
时区与登录 shell 管理，始终只属于主机层面的职责。

### 支持平台与非目标

- 仅支持操作系统：Debian 与 Ubuntu。
- 仅支持架构：`amd64` / `x86_64`。
- 默认语言工具链：Python、Node.js、Bun、Rust。
- 不做任何 GUI 配置，不支持非 Debian/Ubuntu 系统，也不使用第三方版本管理器
  （`mise`、`asdf`、`nvm`、`pyenv`）。
- SSH 加固永远不会被自动化。它始终是一个单独调用、需要人工确认的主机操作。

## 2. 模型：载体（carrier）与层（layer）

每一次安装都由一个载体和最多三个层描述。

| 载体 | 系统层 | 语言层 | 用户层 |
| --- | --- | --- | --- |
| 有 root/sudo 的主机或 VM | 安装 | 安装 | 安装 |
| 无 sudo 的主机或 VM | 报告不可用 | 安装到用户自有路径 | 安装 |
| cloud-init | 通过 cloud-init 配置，再安装 | 为目标用户安装 | 为目标用户安装 |
| Docker 镜像 | 构建期安装 | 构建期安装 | 不应用 |
| Dev Container / Codespaces | 由镜像预置 | 由镜像预置 | 目标用户存在后应用 |

### 系统层

系统层是唯一允许使用 `apt` 或需要 root 权限的层。它安装环境所需的
Debian/Ubuntu 软件包，并可以按需添加锁定工具所需的少量额外软件源。

它明确不包含主机初始化（host provisioning）。主机初始化是一项独立的、
仅主机可用的能力：创建用户、写入 SSH 公钥、防火墙、主机名、时区，以及
可选的手动 SSH 加固。

### 语言层

语言层安装锁定版本的 Python、Node.js、Bun、Rust，以及它们所需的包管理器和
工具。它可以运行在两种场景之一：

- 在 Docker 镜像构建期以系统范围安装；或
- 完全安装在主机上用户自有的路径下（包括其私有的 `opt` 前缀）。

它不得要求 sudo，也不得在目标机器上编译语言运行时。每一个语言运行时都从
经过校验和验证的锁定预编译归档下载。

### 用户层

用户层永远不需要 sudo。它安装用户自有的核心 CLI 工具，应用 chezmoi 管理的
dotfiles，初始化用户自有的集成（Sheldon 与 TPM），并验证最终环境。

Git 身份信息是可选启用（opt-in）的。chezmoi 模板只在下列变量被设置时才会
使用它们：

```text
HOMEUP_GIT_NAME
HOMEUP_GIT_EMAIL
HOMEUP_GIT_SIGNING_KEY
HOMEUP_GIT_SIGN_COMMITS
```

默认情况下，不会写入任何 Git 身份、签名配置、个人密钥或密钥材料。凭据永远
不会被内嵌进仓库、镜像、生成的 cloud-init 数据或公开发布的日志中。

## 3. 版本与供应链策略

### 锁定产物

`toolchain/lock.sh` 是每一个非 apt 的核心 CLI 与语言产物的唯一版本真源
（single source of truth）。它记录精确版本号、x86_64 源 URL、期望的 SHA-256
摘要、目标位置，以及需要安装的组件。如果校验和数据以后被拆分到另一个文件，
它仍必须由 `lock.sh` 引用；`lock.sh` 是唯一的版本真源，不允许出现第二个。

安装脚本只下载由这些锁定数据拼接出的 URL，安装前先校验摘要，并且在正常安装
路径中永远不会请求 `latest` 端点。

### 更新策略

- Node.js：更新时选择当时最新的活跃 LTS 版本。
- Python：更新时选择当时最新的稳定 CPython 版本。
- Bun：更新时选择当时最新的稳定版本。
- Rust：更新时选择当时最新的稳定版本。
- 核心 CLI：更新时选择当时最新的兼容稳定版本。

一个按月执行的 GitHub Actions 定时工作流会检查官方上游元数据，并直接把更新后的
锁定数据、校验和与更新元数据提交到默认分支。随后常规的验证与镜像发布工作流会
基于同一个提交运行。这个设计是刻意为单人仓库优化的：GitHub Actions 本身就是
审计轨迹，而不强制要求 PR 评审。

### apt 策略

由 Debian/Ubuntu apt 提供的软件包仍由发行版自行管理版本。仓库维护两份明确的
清单：

- `packages/base.apt`：每一个具备系统访问权限的载体都需要的软件包。
- `packages/host.apt`：仅主机/VM 需要的运维工具。

任何需要版本一致性的语言运行时或核心 CLI，都不允许由 apt 提供，除非它的版本
已经被明确纳入锁定策略。

## 4. 公开命令契约

以下命令是稳定的 v1 公开接口。

```sh
# 引导当前用户，自动选择被允许的层。
just bootstrap

# 显式选择安装策略。
just bootstrap auto
just bootstrap full
just bootstrap user

# 执行单个层。
just system::install
just language::install
just user::apply

# 仅限长期主机的初始化。
just host::provision
just host::ssh-harden

# 报告已安装版本、缺失的前置条件与被跳过的层。
just doctor
```

各模式的确切含义如下：

| 模式 | 行为 |
| --- | --- |
| `auto` | 只在 root/sudo 可用时安装系统层；语言层和用户层始终运行。 |
| `full` | 要求 root 或可免交互使用的 sudo，如果不可用则在做任何改动之前失败。 |
| `user` | 永远不调用 `sudo` 或 `apt`；只运行语言层与用户层。 |

所有层都是幂等的。使用相同锁定数据重复执行同一个命令，必须收敛到相同的状态。
只有在通过正常的校验和验证之后，才会应用新的锁定版本。

curl 入口点被刻意设计得很薄：

```sh
curl -fsSL https://raw.githubusercontent.com/zopiya/homeup/main/scripts/bootstrap/entrypoint.sh | bash
```

它负责获取或更新 checkout、执行载体与权限探测，并调用 `just bootstrap auto`。
它不得重复实现软件包、语言或用户层的安装逻辑。`HOMEUP_REPO_URL`、`HOMEUP_REF`、
`HOMEUP_DIR`，以及（在没有 Git 的非 GitHub 源场景下）`HOMEUP_ARCHIVE_URL`，
都是保留的覆盖点；脚本中不得编译进任何访问令牌。

## 5. 载体适配器

### 主机与 VM

`just bootstrap`（等价于 `just bootstrap auto`）是标准的开发环境入口命令。
`just host::provision` 是可选的，只用于全新的长期主机或物理机。它组合了独立的
主机脚本，但永远不会调用 `host::ssh-harden`。

### cloud-init

`cloud-init/homeup.yaml.tmpl` 是一个 user-data 模板，而不是一个独立的安装器。
它会：

1. 通过 cloud-init 原生配置声明目标用户、其 SSH 授权公钥和 sudo 策略；
2. 可选地执行模板数据里指定的安全主机初始化操作；
3. 使用 `runcmd` 调用同一套 bootstrap checkout 和命令；并
4. 使用 `runuser` 以目标用户身份执行语言层和用户层。

模板只接受具名数据值，例如 `HOMEUP_USER`、SSH 公钥、主机名、时区，以及是否
启用 UFW。它不会在 user-data 里放置任何密钥，也没有自动 SSH 加固开关。

### Docker 镜像

`containers/dev/Dockerfile` 是唯一的镜像构建定义。它使用显式的 Debian/Ubuntu
基础镜像摘要，为 `linux/amd64` 构建，并在镜像构建期运行系统层与语言层。它会
创建一个非 root 的 `dev` 用户，并仅为交互式开发赋予免密码 sudo；用户层不会在
构建期执行。

镜像必须包含锁定工具链，并且必须提供足够的前置条件，使 `just user::apply` 能够
离线工作，唯一的例外是显式的用户自有插件下载。镜像构建不得包含 Git 身份、SSH
密钥材料、GitHub 凭据，或用户主目录的 dotfiles。

### Dev Container 与 Codespaces

第一个公开镜像发布之后，`.devcontainer/devcontainer.json` 会通过摘要引用公开的
GHCR 镜像，将 `remoteUser` 设为 `dev`，并在创建之后运行用户层：

```text
just user::apply
```

它只可以添加与项目维护相关的编辑器扩展和设置，不得安装系统软件包、语言运行时，
或进行任何主机配置。

在这个首个不可变清单存在之前，checked-in 的配置可以使用同一份
`containers/dev/Dockerfile` 作为一次性的本地构建兜底方案。发布工作流会在首个
公开发布被宣告完成之前，直接把已发布的镜像摘要提交到默认分支。这次只提交摘要的
commit 不会触发另一次镜像构建。一行式 bootstrap 命令直接由公开的 GitHub 仓库
提供服务；当 Git 不可用时，它会回退到该仓库的源码归档。

启用 Codespaces prebuild 时，所有代价高昂、且不含密钥的工作都必须放在 Docker
镜像或 `onCreateCommand`/`updateContentCommand` 中完成。用户层的应用必须留在
`postCreateCommand` 里，因为用户密钥和身份变量在 prebuild 阶段不可用，也不得被
烘焙进快照。

## 6. 仓库结构

```text
scripts/
  bootstrap/
    entrypoint.sh            # curl 入口点的实现
    detect.sh                # 载体、系统、架构与权限检测
    system.sh                # 系统层实现
    language.sh              # 语言层实现
    user.sh                  # 用户层实现
  host/
    create-user.sh
    ufw.sh
    hostname.sh
    timezone.sh
    ssh-harden.sh
packages/
  base.apt
  host.apt
toolchain/
  lock.sh
containers/dev/
  Dockerfile
.devcontainer/
  devcontainer.json
cloud-init/
  homeup.yaml.tmpl
.github/workflows/
  image.yml
  verify.yml
  toolchain-update.yml
docs/
  dev-environment-v1.md      # 本契约
```

## 7. 发布与来源证明（Provenance）

GitHub Actions 构建并测试公开的 `linux/amd64` 镜像，然后将其发布到：

```text
ghcr.io/<github-owner>/homeup-linux
```

每一次被接受的发布都会推送：

- `dev-<commit-sha>`，用于可追溯性；
- 一个供人阅读的版本发布标签；
- `dev`，作为当前的便捷标签；以及
- 一个不可变的镜像摘要。

checked-in 的 Dev Container 配置使用该不可变摘要。镜像包是公开的，并链接到其
GitHub 仓库。CI 使用 GitHub 提供的、权限最小化的 token 来操作镜像包；仓库中
不会提交任何长期有效的 registry 凭据。

## 8. CI 与验收标准

对 bootstrap、工具链、Docker、Dev Container、cloud-init 或 dotfiles 的每一次
变更，都必须运行相应的检查：

1. shell 格式化、ShellCheck，以及 shell 语法检查；
2. chezmoi 模板校验；
3. 锁文件 schema 与校验和引用校验；
4. Docker amd64 镜像构建校验；
5. 以非 root 用户运行 `just bootstrap user` 的容器冒烟测试；
6. Debian 与 Ubuntu 系统层冒烟测试；
7. 对渲染后的 user-data 执行 `cloud-init schema --config-file` 校验；以及
8. `just doctor` 对所需工具及精确锁定版本的断言。

最终的验收测试是从已发布镜像进行一次干净的 Dev Container/Codespaces 创建。
它必须产出一个可用的非 root Zsh 环境、全部锁定的语言运行时、已配置好的 CLI
套件，并且在没有显式提供变量时不带任何 Git 身份信息。

## 9. 交付状态

**已实现（Implemented）。** v1 契约已经完整体现在 checked-in 的 bootstrap 各层、
主机适配器、cloud-init 模板、Docker 镜像、Dev Container 配置、锁文件更新器和
CI 工作流中。公开接口仅限于第 4 节列出的命令；历史遗留的并行安装器和命令别名
不属于 v1 的一部分。

未来的变更必须保持 carrier/layer 边界与手动 SSH 加固的保证，并在同一次变更中
同步更新本契约与相关的操作文档。
