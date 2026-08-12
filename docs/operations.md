# Homeup Linux 操作手册

本文面向日常使用与维护。设计边界和实现约束请阅读
[v1 开发环境契约](dev-environment-v1.md)；所有命令默认在 Homeup checkout
根目录执行。

## 1. 首次安装与验证

在 Debian/Ubuntu `amd64` 环境执行：

```sh
curl -fsSL https://raw.githubusercontent.com/zopiya/homeup/main/scripts/bootstrap/entrypoint.sh | bash
```

完成后立即检查：

```sh
cd ~/.local/share/homeup-linux
just doctor
```

`doctor` 会显示环境类型、权限级别，以及 `just`、chezmoi、Sheldon、Node.js、
Bun、Python、Rust 和 TPM 是否与锁文件一致。若系统层因无 sudo 被跳过，这是预期
行为；语言层和用户层仍会完成。

## 2. 根据权限选择安装方式

| 场景 | 命令 | 结果 |
| --- | --- | --- |
| 不确定是否有 sudo | `just bootstrap` | 自动选择；无权限时跳过系统层 |
| 必须安装系统包 | `just bootstrap full` | 没有 root/免交互 sudo 时会先失败 |
| 共享主机或无 sudo | `just bootstrap user` | 只安装语言层与用户层，不调用 sudo |
| 仅补装一层 | `just system::install` / `just language::install` / `just user::apply` | 适合故障恢复或调试 |

所有层均可重复运行。正常更新不需要删除现有安装目录。

## 3. 日常更新与检查

先查看 dotfiles 会发生什么变化：

```sh
just diff
```

更新 chezmoi 源但不立即应用：

```sh
just update
```

重新应用用户层并确认结果：

```sh
just user::apply
just doctor
```

运行时和核心 CLI 的版本由 `toolchain/lock.sh` 控制。不要手工将 `latest` 下载
覆盖到 `~/.local/bin`；需要升级时应更新锁文件并通过 CI 验证。

## 4. 新建长期主机

主机初始化与开发环境分离。先创建用户、写入 SSH 公钥，并按需配置防火墙、主机名
和时区：

```sh
NEW_USER=dev \
SSH_PUBKEY="$(cat ~/.ssh/id_ed25519.pub)" \
NEW_HOSTNAME=homeup-dev \
TIMEZONE=UTC \
just host::provision
```

从另一个终端确认该用户可以 SSH 登录之后，才可以执行：

```sh
just host::ssh-harden
```

该命令要求真实终端和输入 `yes`，会禁用 root 登录与密码认证。它绝不会由
bootstrap、cloud-init 或镜像自动执行。

## 5. cloud-init

使用模板前必须在可信机器渲染并审查：

```sh
export HOMEUP_USER=dev
export HOMEUP_SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)"
export HOMEUP_REPO_URL=https://github.com/zopiya/homeup.git
export HOMEUP_HOSTNAME=homeup-cloud
export HOMEUP_TIMEZONE=UTC
export HOMEUP_ENABLE_UFW=false
envsubst < cloud-init/homeup.yaml.tmpl >homeup-cloud-init.yaml
```

上传 `homeup-cloud-init.yaml` 前确认其中没有 token、私钥或其他秘密。实例首次启动
会先完成系统层，再以目标用户运行语言层和用户层。

## 6. Dev Container 与 Codespaces

仓库的 Dev Container 已使用 GHCR 的不可变镜像 digest。创建后会自动运行
`just user::apply`；镜像内已有系统层和语言层。若要排查容器环境：

```sh
just doctor
just diff
```

不要在 Dev Container 内运行 `host::provision` 或 `host::ssh-harden`，它们只适用于
长期主机或 VM。

## 7. 失败恢复

- `doctor` 报版本不匹配：重新运行对应层；不要绕过校验和验证。
- 下载校验失败：检查网络后重试；必要时删除
  `${XDG_CACHE_HOME:-$HOME/.cache}/homeup/downloads` 再执行。
- Git checkout 无法 fast-forward：先保留本地修改，再手动解决 Git 历史。
- dotfiles 异常：先执行 `chezmoi diff`，确认后再执行 `just user::apply`。

更完整的症状与恢复路径见 [故障排查](troubleshooting.md)。
