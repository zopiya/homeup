# 命令参考

这是纯速查表：命令做什么、变量有什么用。想知道"我这个场景该用哪个"，请看
[场景化使用手册](usage-guide.md)；想理解"为什么这样设计"，请看
[架构总览](architecture.md)。

## 公开命令

v1 的公开接口刻意保持很小，不会新增平行的安装器或命令别名。

```sh
just bootstrap [auto]   # 权限允许就装系统层，语言层 + 用户层总会装
just bootstrap full     # 要求 root 或免交互 sudo，做不到就先失败、不改动机器
just bootstrap user     # 绝不调用 sudo/apt，只装语言层 + 用户层
just system::install    # 单独执行系统层（需要 root/sudo）
just language::install  # 单独执行语言层
just user::apply        # 单独执行用户层（chezmoi + 核心 CLI + TPM）
just doctor             # 报告载体、权限级别，以及每个锁定版本是否匹配
just host::provision    # 仅长期主机：建用户 + 防火墙 + 主机名 + 时区
just host::ssh-harden   # 仅长期主机：手动 SSH 加固，需要 TTY + 输入 yes
```

| 命令 | 是否需要权限 | 幂等 |
| --- | --- | --- |
| `just bootstrap` / `bootstrap auto` | 有权限才装系统层 | 是 |
| `just bootstrap full` | 要求 root/免交互 sudo，否则失败退出 | 是 |
| `just bootstrap user` | 绝不使用 sudo | 是 |
| `just system::install` | 需要 root/sudo | 是 |
| `just language::install` | 不需要 sudo | 是 |
| `just user::apply` | 不需要 sudo | 是 |
| `just doctor` | 不需要 sudo，只读 | — |
| `just host::provision` | 需要 root/sudo | 是（已存在用户会跳过创建） |
| `just host::ssh-harden` | 需要 root，需要 TTY 手动确认 | 否——不可逆操作 |

## 日常维护命令

```sh
just diff      # 预览 chezmoi 会改动哪些 dotfiles，不真正改动
just update    # 拉取 chezmoi 源码更新，但不应用
just validate  # 在临时目录里 dry-run 校验 chezmoi 模板，不改动 $HOME
just lint      # ShellCheck + bash/zsh 语法检查
just fmt       # shfmt 格式化所有 shell 脚本
```

## 环境变量

### bootstrap / curl 入口点

| 变量 | 作用 | 默认值 |
| --- | --- | --- |
| `HOMEUP_REPO_URL` | curl 入口点使用的仓库 URL | `https://github.com/zopiya/homeup.git` |
| `HOMEUP_REF` | Git checkout 使用的分支/引用 | `main` |
| `HOMEUP_DIR` | checkout 存放路径 | `~/.local/share/homeup-linux` |
| `HOMEUP_ARCHIVE_URL` | 无 Git 且仓库不是 GitHub HTTPS 地址时的源码归档地址 | 无（此时必填） |

### 语言层安装位置（一般不需要手动设置）

| 变量 | 作用 | 默认值 |
| --- | --- | --- |
| `HOMEUP_INSTALL_SCOPE` | `system`（镜像构建期，系统范围）或 `user`（用户自有路径） | `user` |
| `HOMEUP_PREFIX` | 语言运行时安装前缀 | `user` 模式：`~/.local/opt/homeup`；`system` 模式：`/usr/local/lib/homeup` |
| `HOMEUP_BIN_DIR` | 可执行文件软链接目录 | `user` 模式：`~/.local/bin`；`system` 模式：`/usr/local/bin` |

### Git 身份（可选，详见[场景 9](usage-guide.md#9-git-身份可选)）

| 变量 | 作用 |
| --- | --- |
| `HOMEUP_GIT_NAME` | Git 用户名 |
| `HOMEUP_GIT_EMAIL` | Git 邮箱 |
| `HOMEUP_GIT_SIGNING_KEY` | SSH 签名公钥 |
| `HOMEUP_GIT_SIGN_COMMITS` | 设为 `true` 启用 SSH 提交签名 |

默认全部为空，chezmoi 模板不会写入任何 `[user]`/签名配置。

### 主机初始化（`scripts/host/*`，详见[场景 4](usage-guide.md#4-新建长期主机)）

| 变量 | 作用 | 使用脚本 |
| --- | --- | --- |
| `NEW_USER` | 新建的非 root 用户名 | `create-user.sh` |
| `SSH_PUBKEY` | 该用户的 SSH 公钥 | `create-user.sh` |
| `NEW_HOSTNAME` | 要设置的主机名（留空则不改） | `hostname.sh` |
| `TIMEZONE` | 要设置的时区 | `timezone.sh` |
| `EXTRA_FIREWALL_PORTS` | 除 SSH 外要放行的端口，空格分隔 | `ufw.sh` |
| `NONINTERACTIVE=1` | 跳过交互式提问，直接用上述变量的值 | `create-user.sh` / `ufw.sh` / `hostname.sh` / `timezone.sh` |

### cloud-init 模板渲染（详见[场景 5](usage-guide.md#5-cloud-init-云主机)）

| 变量 | 作用 |
| --- | --- |
| `HOMEUP_USER` | cloud-init 创建的目标用户 |
| `HOMEUP_SSH_PUBLIC_KEY` | 写入该用户 `authorized_keys` 的公钥 |
| `HOMEUP_REPO_URL` | 实例上 `git clone` 使用的仓库地址 |
| `HOMEUP_HOSTNAME` | 实例主机名 |
| `HOMEUP_TIMEZONE` | 实例时区 |
| `HOMEUP_ENABLE_UFW` | `true`/`false`，是否在 `runcmd` 里启用 UFW |

## `just doctor` 检查什么

`doctor` 会依次输出：

1. `detect.sh` 的探测结果——载体（host/container/codespaces）、系统
   （debian/ubuntu）、架构、权限级别（root/sudo/user）；
2. 每一个锁定组件（`just`、`chezmoi`、`sheldon`、`node`、`bun`、`python`、
   `rust`、`tpm`）当前安装的版本，和 `toolchain/lock.sh` 里的锁定版本逐一
   比对，标记 `ok` / `mismatch` / `missing`。

任意一项 `mismatch` 或 `missing` 都会让 `doctor` 以非零状态退出，方便接入
CI 断言。
