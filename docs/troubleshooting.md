# 故障排查

## 先看环境报告

任何问题排查都从这条命令开始（在 checkout 根目录，或 curl 安装的默认目录
`~/.local/share/homeup` 下执行）：

```sh
just doctor
```

它会报告载体、权限级别，以及每个锁定运行时/CLI 是否和 `toolchain/lock.sh`
一致。下面按具体症状分节，先定位属于哪一类再往下看。

## 系统层被跳过了

`just bootstrap auto` 在当前用户既没有 root、也没有免交互 sudo 时会跳过
系统层——这是**预期行为**，语言层和用户层仍会正常安装完。如果确实需要装
系统包，换一个有权限的账号，或者：

```sh
just bootstrap full
```

`full` 模式在拿不到 root/免交互 sudo 时会直接失败退出，且不会对机器做任何
改动，绝不会"装一半"。

## 下载或校验和失败

Homeup 拒绝安装任何 SHA-256 摘要不匹配的产物——**不要绕过这个检查**。先检查
网络连接后重试；如果持续失败，检查 `toolchain/lock.sh` 里对应组件的锁定 URL
和摘要是否仍然有效，只能通过[工具链更新流程](usage-guide.md#8-工具链版本升级)
去修改，不要手工编辑锁文件里的校验和。

清空下载缓存后重试（只会删除这个用户自有的缓存目录）：

```sh
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/homeup/downloads"
```

## 现有 checkout 无法更新

curl 入口点拒绝覆盖一个"非它自己创建"的目录，对已有的 Git checkout 使用
`git pull --ff-only`。如果 fast-forward 失败，先保护好本地修改，再手动处理：

```sh
git -C ~/.local/share/homeup status
git -C ~/.local/share/homeup pull --ff-only
```

如果这个 checkout 是故意做了本地定制，换一个 `HOMEUP_DIR` 而不是覆盖它。

如果 checkout 是通过"无 Git"路径（源码归档）创建的，目录里会有一个
`.homeup-archive-checkout` 标记文件；有这个标记时才允许被 entrypoint 自动
替换，否则会拒绝覆盖并报错。

## dotfiles 没有按预期生效

先预览会改动什么，再决定要不要应用：

```sh
just diff
just user::apply
```

Git 身份默认是空的——只有在跑 `user::apply` 之前设置了 `HOMEUP_GIT_NAME` 和
`HOMEUP_GIT_EMAIL`，chezmoi 模板才会写入对应配置。这是故意的，避免容器或
Codespace 意外继承你的个人身份。

## SSH 加固相关

`just host::ssh-harden` 在你**用另一个 SSH 会话确认新用户和公钥可以正常登录
之前**，不要执行。它要求真实终端并且必须手动输入 `yes` 才会生效，绝不会被
bootstrap、cloud-init 或镜像自动调用。如果不小心把自己锁在外面，需要通过
云厂商的控制台/救援模式访问磁盘，恢复 `/etc/ssh/sshd_config` 的备份——
`ssh-harden.sh` 会在修改前把原文件备份为
`/etc/ssh/sshd_config.bak.<timestamp>`。

## cloud-init 渲染或校验失败

`cloud-init/homeup.yaml.tmpl` 使用 `${VAR}` 占位符，必须用 `envsubst`
渲染，而不是直接上传模板本身。渲染后先本地校验语法再上传：

```sh
envsubst < cloud-init/homeup.yaml.tmpl > /tmp/homeup-cloud-init.yaml
cloud-init schema --config-file /tmp/homeup-cloud-init.yaml
```

如果报告缺变量，检查是否遗漏了 `HOMEUP_USER`、`HOMEUP_SSH_PUBLIC_KEY`、
`HOMEUP_REPO_URL` 这几个必填值（见[场景 5](usage-guide.md#5-cloud-init-云主机)）。

## Docker 镜像构建或容器内命令失败

先确认 `toolchain/lock.sh` 里的所有产物在当前网络下可下载（镜像构建期同样
会做 SHA-256 校验，摘要不匹配会直接构建失败）。本地复现：

```sh
docker build --file containers/dev/Dockerfile --tag homeup-dev:local .
docker run --rm --user dev homeup-dev:local bash -lc 'just doctor'
```

如果只有非 root 用户能复现问题，多半和 `HOMEUP_INSTALL_SCOPE`/
`HOMEUP_BIN_DIR` 默认值（用户自有路径）有关，见
[命令参考](commands.md#语言层安装位置一般不需要手动设置)。

## Dev Container / Codespaces 创建后环境不完整

镜像里应当已经包含系统层和语言层；创建后只会自动跑
`postCreateCommand: just user::apply`。如果某个 CLI 或运行时缺失：

```sh
just doctor   # 确认到底缺什么
just diff     # 确认 dotfiles 状态
just user::apply  # 重新跑一遍用户层，幂等，可以放心重复执行
```

不要在容器里跑 `host::provision` 或 `host::ssh-harden`——它们假设的是一台
长期主机，容器场景里没有意义，也不会生效。

## 工具链更新失败

`scripts/ci/update-toolchain.py` 依赖各项目官方 API/元数据的可用性；如果某个
上游临时不可用，更新会直接失败退出，不会写入部分更新的锁文件。本地排查：

```sh
python3 scripts/ci/update-toolchain.py
bash scripts/ci/validate-lock.sh
```

`validate-lock.sh` 报错时，说明生成的 URL/摘要格式不满足契约要求（必须是
`https://`、不含 `latest`、SHA-256 必须是 64 位十六进制），检查对应上游的
release 资产命名是否发生了变化。
