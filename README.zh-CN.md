# Homeup Linux

[English](README.md)

一套面向**无图形界面的 Debian/Ubuntu 服务器**的 dotfiles 方案，基于 chezmoi + apt + just —— 是
`homeup`（macOS 工作站版）的姊妹仓库。同样的 shell/工具体验，为刚开好的、没有桌面环境的云服务器
做了适配。

本仓库运行时**不依赖** homeup —— 可移植的部分（zsh 模块、nvim、tmux、zellij、starship、git
别名……）当初是复制过来一次，此后在这里独立维护。

为"SSH 进去用，而不是坐在它面前用"的日常运维/开发场景调优过：
- 每次登录自动 attach 一个持久化的 tmux 会话（`main`）——连接断了也不会丢工作现场，
  `tmux-resurrect`/`tmux-continuum`（已配置好，TPM 会自动安装）连重启都能扛住。第一次真正创建
  会话时还会顺带展示一次 `fastfetch` 系统信息横幅。
- 提示符里 SSH 登录时始终显示 `user@hostname`——否则很容易搞不清当前终端连的是哪台服务器。
- 基础 shell 之外还带一套小型运维/开发工具箱：`yq`（YAML）、`bottom`/`glances`/`htop`（资源监控）、
  `xh`（HTTP 客户端）、`watchexec`（开发循环自动化）、`mtr`/`dnsutils`/`tcpdump`（网络排查）、
  `rclone`（备份/同步）。容器/编排相关工具（Docker、k8s）故意没放进来——真正需要的服务器上手动装，
  不把某个团队的技术栈焊死在每台机器里。

## 两个阶段

云服务器通常是一台全新的机器，所以要走到能用的 shell，需要分两个阶段、由两个不同的用户来跑：

1. **Day 0 —— 初始化配置（root，只跑一次）**：创建非 root 的 sudo 用户，装好你的 SSH 公钥，设置
   hostname/timezone，打开防火墙，最后关闭 root/密码 SSH 登录。
2. **Day 1 —— dotfiles（你的用户）**：apt 包 + 上游工具安装器，然后 chezmoi 应用 dotfiles ——
   跟 homeup 自己的 bootstrap 流程同构。

## 前置条件

- 一台全新的 Debian 12+ 或 Ubuntu 22.04+ 服务器，有 root/sudo 权限
- 你的 SSH 公钥（比如在你自己的机器上 `cat ~/.ssh/id_ed25519.pub`）
- Git —— 跑 `root-install.sh`/`install.sh` 不需要（没有的话它们会自己装），只有下面的纯手动流程
  才需要你自己先有

## 快速开始

### 全自动 —— 一条命令，从 root 直达可用 shell

```bash
export NEW_USER=zopiya SSH_PUBKEY="ssh-ed25519 AAAA... you@laptop"
curl -fsSL https://get.zopiya.dev/init | sudo -E bash
```

（已经是以字面意义上的 root 登录、不是走 sudo 的普通用户？把 `sudo -E` 去掉，直接 pipe 给
`bash` 就行。）

`root-install.sh` 会把仓库 clone 到 `/opt/homeup-linux`，非交互式地跑完 Day 0 初始化配置
（创建 `$NEW_USER`、装好 `$SSH_PUBKEY`、打开防火墙、设置 hostname/timezone），把这份 checkout
的所有权交给 `$NEW_USER`，然后直接级联跑进他们的 Day 1 —— apt 包、上游工具、`chezmoi apply`、
`just setup`。

**SSH 加固（关闭 root/密码登录）故意不包含在这个自动流程里。** 这是这里唯一真正不可逆的一步——
公钥填错或者贴错了，就是彻底锁死在门外，只能靠你云服务商的带外 console 救。脚本总是会在这一步
之前停下来，打印出确切的后续命令；等你在另一个终端验证过 `ssh $NEW_USER@<服务器IP>` 确实能登录
之后，自己手动跑那条命令。

root 只做 root 该做的事（建用户、开防火墙、移交所有权）；Day 1 全程以 `$NEW_USER` 身份跑，
绝不会是 root。

### 之后的更新，或者单独跑 Day 1

Day 0 完成之后（不管是用哪种方式），以你的用户身份登录后，Day 1 用的这同一个脚本也是更新用的——
重新跑一遍，它会拉最新的 commit、重新应用 dotfiles、重新跑一遍安装器（已经装好的会自动跳过）：

```bash
curl -fsSL https://get.zopiya.dev/install | bash
```

用 `HOMEUP_REPO_URL`/`HOMEUP_DIR` 环境变量（两个脚本都支持）可以指向 fork 或者别的 checkout
路径。

### 纯手动 —— 自己一步步跑

```bash
# ── Day 0（以 root 身份）──────────────────────────────────────────────────
git clone https://github.com/zopiya/homeup-linux.git /tmp/homeup-linux && cd /tmp/homeup-linux
sudo bash packages/server-init.sh
# 按提示操作。脚本会在关闭 root/密码登录之前停下来，
# 要求你在另一个终端验证新用户能登录成功——
# 别跳过这一步，否则可能把自己锁在门外。

# ── Day 1（重新登录后，以你的新用户身份）──────────────────────────────────
sudo mkdir -p /opt/homeup-linux && sudo chown "$(id -u):$(id -g)" /opt/homeup-linux
git clone https://github.com/zopiya/homeup-linux.git /opt/homeup-linux
cd /opt/homeup-linux

# just/chezmoi 还没装，所以先直接装包：
sudo apt-get update && xargs -a packages/apt-packages.txt sudo apt-get install -y
bash packages/install-tools.sh   # 装 chezmoi、just、starship、neovim……

# 现在 chezmoi/just 都有了 —— 应用 dotfiles（先 --dry-run 预览一下）
chezmoi init --source /opt/homeup-linux --apply --dry-run
chezmoi init --source /opt/homeup-linux --apply

# 收尾（默认 shell、sheldon lock、gpg-agent）
just setup
```

以后在别的服务器上，只要 `just` 已经存在了（比如先重新跑一遍 `packages/install-tools.sh`），
`just bootstrap` 就能把上面手动的三步一次跑完。

## 用法

不带参数跑 `just` 可以看到帮助菜单。

### Day 0 —— 服务器初始化配置

```sh
just provision   # sudo bash packages/server-init.sh（只有 root 身份跑才有意义）
```

### Day 1 —— 日常工作流

```sh
just diff      # 预览待应用的改动
just apply     # 把改动应用到系统
just update    # 拉最新 + 应用
```

### 维护

```sh
just doctor      # 健康检查（必需 + 可选工具）
just upgrade     # apt update && upgrade
just clean       # apt autoremove/clean
```

### 开发

```sh
just validate    # 校验 chezmoi 模板
just lint        # 对所有 .sh 文件跑 shellcheck
just fmt         # 用 shfmt 格式化所有 .sh 文件
```

## 项目结构

```
homeup-linux/
├── root-install.sh              # 一条龙 Day 0 + Day 1（root，curl | bash 友好，不含 SSH 加固）
├── install.sh                   # 一条龙 Day 1 引导（curl | bash 友好，重跑即更新）
├── justfile                   # 任务运行器
├── lefthook.yml                # Git hooks：pre-commit + pre-push
├── .chezmoi.toml.tmpl          # Chezmoi 配置（用户身份）
├── dot_zshenv                  # Zsh 入口
├── dot_config/                 # chezmoi 管理的 ~/.config/
│   ├── zsh/                    # 模块化 zsh 配置（path、options、exports、tools、aliases、functions）
│   ├── git/                    # Git 配置 + 身份/别名模板
│   ├── nvim/                   # Neovim Lua 配置（从 homeup 复制过来，未改动）
│   ├── tmux/  zellij/  starship.toml  sheldon/  atuin/  lazygit/  topgrade.toml
├── private_dot_ssh/            # SSH 配置（chezmoi 的 private_ 前缀 → 部署为 0700/0600）
├── packages/
│   ├── server-init.sh          # Day 0：用户/hostname/timezone/SSH 加固/防火墙（root）
│   ├── apt-packages.txt        # Day 1：apt 包扁平列表
│   └── install-tools.sh        # Day 1：apt 里没有或版本太旧的工具的上游安装器
└── docs/
    └── linux-ops.md            # glances/bmon/lnav/mosh 用法笔记
```

## 配置

### 环境变量

| 变量 | 默认值 | 说明 |
|----------|---------|--------------|
| `CI` | false | 在 CI/容器里跳过 shell 相关改动 |
| `NEW_USER` | `zopiya` | `server-init.sh` / `root-install.sh`：要创建的用户名 |
| `SSH_PUBKEY` | （交互式提示；非交互模式下必填） | `server-init.sh`：要给 `NEW_USER` 装的公钥 |
| `NEW_HOSTNAME` | （交互式提示；非交互模式下留空不改） | `server-init.sh`：要设置的 hostname |
| `TIMEZONE` | `Asia/Shanghai` | `server-init.sh`：要设置的时区 |
| `EXTRA_FIREWALL_PORTS` | （空） | `server-init.sh`：SSH 之外要放行的额外端口 |
| `NONINTERACTIVE` | （自动探测） | `server-init.sh`：即使在真终端里也强制走非交互（纯环境变量）模式 |
| `HOMEUP_REPO_URL` | `https://github.com/zopiya/homeup-linux.git` | `install.sh` / `root-install.sh`：要 clone 的仓库（比如指向 fork） |
| `HOMEUP_DIR` | `/opt/homeup-linux` | `install.sh` / `root-install.sh`：clone/更新仓库的位置 |

### 已知注意事项

- **免密 sudo**：`server-init.sh` 用 `adduser --disabled-password` 创建 `$NEW_USER`（只能用 SSH
  密钥登录，完全没有密码），并通过专属的 `/etc/sudoers.d/$NEW_USER` 给它发了 `NOPASSWD` sudo
  权限。不这么做的话，这个账号在任何场景下（不只是自动化流程）都没法用密码方式 `sudo` 成功——
  因为它压根没有一个 PAM 会认的密码。这不会扩大账号本身能做的事（它本来就在 `sudo` 组里，也就是
  已经等价于完整的 root 权限）；只是去掉了一个永远不可能正确回答的密码提示。如果你更想要密码
  门槛，配置完之后删掉那个文件，再用 `sudo passwd $NEW_USER` 设一个真密码（这跟 SSH
  登录方式无关，SSH 依然只认密钥）。
- **`bat`/`fd`**：Debian/Ubuntu 把这两个包命名成 `batcat`/`fdfind` 以避免和其他包重名冲突。
  `install-tools.sh` 会把 `bat`/`fd` 软链到 `~/.local/bin`，这样本仓库配置里的别名不用改就能用。
- **提交签名**：`dot_config/git/identity.gitconfig.tmpl` 里带的是跟 homeup 一样的 SSH 签名密钥。
  如果这台服务器上没有对应的私钥，`git commit` 签名会失败——要么把签名私钥拷过来，要么本地跑
  `git config commit.gpgsign false` 关掉签名。
- **架构**：`install-tools.sh` 只支持 `x86_64`/`amd64`，在其他架构上会直接报清晰的错误退出，
  而不是悄悄装上跑不了的二进制。在 arm64 服务器上，跑之前要先手动改一下 GitHub-release 的
  匹配规则（换成 `aarch64`/`arm64`）。
- **tmux 插件**：`install-tools.sh` 会 clone TPM，但 TPM 本身只有在你在 tmux 会话里按一次
  `prefix + I` 之后，才会真正装上声明好的插件（`tmux-resurrect`、`tmux-continuum` 等）——第一次
  `chezmoi apply` 之后记得按一下。

## License

MIT License，见 [LICENSE](LICENSE)。
