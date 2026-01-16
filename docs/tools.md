# Home Up 工具清单

本文档介绍 Home Up 项目中包含的所有工具，共计 102 个。这些工具根据不同的使用场景（macos、linux、mini）分布在不同的 Brewfile 中。

## 目录

- [Shell 工具](#shell-工具)
- [现代化替代工具](#现代化替代工具)
- [开发工具](#开发工具)
- [网络工具](#网络工具)
- [容器和 Kubernetes](#容器和-kubernetes)
- [数据处理工具](#数据处理工具)
- [监控工具](#监控工具)
- [Git 增强工具](#git-增强工具)
- [安全工具](#安全工具)
- [macOS 专属工具](#macos-专属工具)
- [Linux 专属工具](#linux-专属工具)
- [Mini Profile 工具](#mini-profile-工具)

---

## Shell 工具

### zsh

Zsh shell，功能强大的命令行解释器，具有丰富的自动补全和插件系统。

```bash
chsh -s $(which zsh)  # 设置为默认 shell
```

配置位置: `~/.zshrc`

### starship

跨 shell 的现代化提示符，快速且高度可定制，支持 Git 状态、语言版本显示。

```bash
eval "$(starship init zsh)"
```

配置位置: `~/.config/starship.toml`

### sheldon

快速、可配置的 shell 插件管理器，支持延迟加载和并行下载。

```bash
eval "$(sheldon source)"
```

配置位置: `~/.config/sheldon/plugins.toml`

### zoxide

智能目录跳转工具，根据使用频率快速跳转到常用目录。

```bash
z project    # 跳转到包含 project 的目录
zi           # 交互式选择目录
```

配置位置: Shell 初始化脚本

### fzf

命令行模糊查找器，可用于历史命令、文件、进程等的交互式搜索。

```bash
Ctrl+R       # 搜索历史命令
Ctrl+T       # 搜索文件
Alt+C        # 跳转目录
```

配置位置: `~/.fzf.zsh`

### atuin

Shell 历史记录同步工具，提供加密的历史记录同步和强大的搜索功能。

```bash
atuin search  # 搜索历史
atuin sync    # 同步历史记录
```

配置位置: `~/.config/atuin/config.toml`

### tmux

终端复用器，允许在单个终端窗口中管理多个会话和窗格。

```bash
tmux new -s session_name  # 创建新会话
tmux attach -t session    # 附加到会话
```

配置位置: `~/.tmux.conf`

### zellij

现代化的终端工作空间，具有直观的 UI 和会话管理功能。

```bash
zellij        # 启动默认会话
zellij attach # 附加到会话
```

配置位置: `~/.config/zellij/`

---

## 现代化替代工具

### bat

增强版 cat，支持语法高亮、Git 集成和自动分页。

```bash
bat file.txt        # 查看文件
bat -l python code  # 指定语言高亮
```

配置位置: `~/.config/bat/config`

### eza

现代化的 ls 替代品，支持图标、Git 状态和树形视图。

```bash
eza -la              # 详细列表
eza --tree --level=2 # 树形视图
```

配置位置: Shell 别名

### fd

简单快速的 find 替代品，默认忽略 .gitignore 中的文件。

```bash
fd pattern          # 查找文件
fd -e py            # 按扩展名查找
```

配置位置: 无需配置

### ripgrep

极快的递归搜索工具，尊重 .gitignore 规则。

```bash
rg pattern          # 搜索内容
rg -i pattern       # 忽略大小写
```

配置位置: `~/.ripgreprc`

### sd

直观的查找和替换工具，比 sed 更易用。

```bash
sd 'old' 'new' file.txt  # 替换文本
sd -s 'old' 'new'        # 字符串字面量模式
```

配置位置: 无需配置

### dust

更直观的 du 替代品，以树形图展示磁盘使用情况。

```bash
dust              # 当前目录磁盘使用
dust -d 2         # 限制深度
```

配置位置: 无需配置

### duf

用户友好的 df 替代品，彩色输出磁盘使用统计。

```bash
duf               # 显示所有挂载点
duf /home         # 显示特定路径
```

配置位置: 无需配置

### procs

现代化的 ps 替代品，彩色输出和更好的默认格式。

```bash
procs             # 列出所有进程
procs nginx       # 搜索特定进程
```

配置位置: 无需配置

### btop

资源监控器，显示 CPU、内存、磁盘和网络使用情况。

```bash
btop              # 启动监控器
```

配置位置: `~/.config/btop/btop.conf`

### bottom

跨平台的系统监控工具，类似 gtop/gotop。

```bash
btm               # 启动监控器
btm --battery     # 显示电池信息
```

配置位置: `~/.config/bottom/bottom.toml`

### choose

更好的 cut/awk 替代品，用于处理结构化数据。

```bash
echo 'a b c' | choose 0 2  # 选择第 0 和第 2 列
```

配置位置: 无需配置

---

## 开发工具

### neovim

现代化的 Vim 编辑器，支持异步插件和 LSP。

```bash
nvim file.txt     # 编辑文件
nvim +PlugInstall # 安装插件
```

配置位置: `~/.config/nvim/`

### direnv

自动加载和卸载目录特定的环境变量。

```bash
direnv allow .    # 允许加载 .envrc
```

配置位置: `~/.config/direnv/`, `.envrc`

### just

现代化的命令运行器，比 make 更简单直观。

```bash
just              # 运行默认任务
just build        # 运行特定任务
```

配置位置: `justfile`

### lefthook

快速的 Git hooks 管理器，支持并行执行。

```bash
lefthook install  # 安装 hooks
lefthook run pre-commit
```

配置位置: `lefthook.yml`

### entr

文件监控工具，当文件变化时执行命令。

```bash
ls *.py | entr pytest  # 文件变化时运行测试
```

配置位置: 无需配置

### watchexec

执行文件变化监控，比 entr 更强大。

```bash
watchexec -e py pytest  # 监控 Python 文件
```

配置位置: 无需配置

### mise

通用版本管理器，替代 asdf、nvm、pyenv 等工具。

```bash
mise install node@20  # 安装 Node.js
mise use python@3.11  # 使用特定版本
```

配置位置: `~/.config/mise/config.toml`, `.mise.toml`

### uv

极快的 Python 包管理器和项目管理工具。

```bash
uv pip install requests  # 安装包
uv venv                  # 创建虚拟环境
```

配置位置: `pyproject.toml`

### pnpm

高效的 Node.js 包管理器，节省磁盘空间。

```bash
pnpm install      # 安装依赖
pnpm add package  # 添加包
```

配置位置: `pnpm-workspace.yaml`

### aider

AI 结对编程工具，通过命令行与 AI 协作编码。

```bash
aider file.py     # 使用 AI 编辑文件
aider --model gpt-4
```

配置位置: `.aider.conf.yml`

### vhs

终端会话录制工具，生成 GIF 演示。

```bash
vhs demo.tape     # 录制演示
```

配置位置: `.tape` 文件

### hyperfine

命令行基准测试工具，精确测量命令执行时间。

```bash
hyperfine 'command1' 'command2'  # 对比性能
```

配置位置: 无需配置

### tokei

代码统计工具，快速显示项目的代码行数和语言分布。

```bash
tokei             # 统计当前目录
tokei --sort lines
```

配置位置: 无需配置

---

## 网络工具

### curl

数据传输工具，支持多种协议的命令行 HTTP 客户端。

```bash
curl https://api.example.com  # GET 请求
curl -X POST -d 'data' url    # POST 请求
```

配置位置: `~/.curlrc`

### wget

文件下载工具，支持断点续传和递归下载。

```bash
wget url          # 下载文件
wget -c url       # 断点续传
```

配置位置: `~/.wgetrc`

### httpie

人性化的 HTTP 客户端，语法简单直观。

```bash
http GET api.example.com      # GET 请求
http POST api.example.com key=value
```

配置位置: `~/.config/httpie/config.json`

### xh

快速的 HTTP 客户端（Rust 实现），类似 httpie。

```bash
xh GET api.example.com  # GET 请求
xh :3000/api            # 本地请求简写
```

配置位置: 无需配置

### doggo

现代化的 DNS 客户端，彩色输出和多种格式支持。

```bash
doggo example.com     # DNS 查询
doggo example.com MX  # 查询 MX 记录
```

配置位置: 无需配置

### gping

带图形的 ping 工具，实时显示延迟图表。

```bash
gping google.com  # Ping 并显示图表
```

配置位置: 无需配置

### trippy

网络诊断工具，结合 ping 和 traceroute 功能。

```bash
trip google.com   # 网络诊断
```

配置位置: 无需配置

### grpcurl

gRPC 的 curl，用于测试 gRPC 服务。

```bash
grpcurl localhost:9000 list  # 列出服务
```

配置位置: 无需配置

### evans

gRPC 交互式客户端，支持 REPL 模式。

```bash
evans -r repl     # REPL 模式
```

配置位置: `.evans.toml`

### bandwhich

按进程显示带宽使用情况的网络监控工具。

```bash
bandwhich         # 监控网络使用
```

配置位置: 无需配置

---

## 容器和 Kubernetes

### lazydocker

Docker 的终端 UI，简化容器和镜像管理。

```bash
lazydocker        # 启动 TUI
```

配置位置: `~/.config/lazydocker/config.yml`

### dive

Docker 镜像分析工具，探索镜像层内容和优化空间。

```bash
dive image:tag    # 分析镜像
```

配置位置: 无需配置

### k9s

Kubernetes 终端 UI，管理集群资源。

```bash
k9s               # 启动 TUI
k9s -n namespace  # 指定命名空间
```

配置位置: `~/.config/k9s/config.yml`

### helm

Kubernetes 包管理器，用于部署和管理应用。

```bash
helm install release chart  # 安装应用
helm upgrade release chart  # 升级应用
```

配置位置: `~/.config/helm/`

### kubectx

快速切换 Kubernetes 上下文和命名空间。

```bash
kubectx           # 列出上下文
kubens            # 切换命名空间
```

配置位置: 无需配置

### stern

多 pod 日志聚合工具，彩色输出。

```bash
stern pod-prefix  # 查看日志
stern --tail 50 app
```

配置位置: 无需配置

### kustomize

Kubernetes 配置管理工具，无模板的配置定制。

```bash
kustomize build dir  # 构建配置
kubectl apply -k dir # 应用配置
```

配置位置: `kustomization.yaml`

---

## 数据处理工具

### jq

JSON 处理器，查询和操作 JSON 数据。

```bash
jq '.key' file.json       # 提取字段
echo '{}' | jq '.a = 1'   # 修改数据
```

配置位置: 无需配置

### yq

YAML/XML/TOML 处理器，类似 jq。

```bash
yq '.key' file.yaml  # 提取字段
yq -i '.a = 1' file  # 原地修改
```

配置位置: 无需配置

### miller

处理 CSV、TSV、JSON 等格式的数据工具。

```bash
mlr --csv cut -f name file.csv  # 提取列
mlr --json filter '$age > 30'   # 过滤数据
```

配置位置: 无需配置

### gron

将 JSON 转换为可 grep 的格式。

```bash
gron file.json     # 展平 JSON
gron file.json | grep pattern | gron -u
```

配置位置: 无需配置

### ouch

压缩和解压缩工具，自动检测格式。

```bash
ouch compress file.txt file.tar.gz  # 压缩
ouch decompress file.tar.gz          # 解压
```

配置位置: 无需配置

### zstd

高压缩比的压缩算法和工具。

```bash
zstd file         # 压缩文件
zstd -d file.zst  # 解压文件
```

配置位置: 无需配置

---

## 监控工具

### fastfetch

快速的系统信息显示工具，类似 neofetch。

```bash
fastfetch         # 显示系统信息
```

配置位置: `~/.config/fastfetch/config.jsonc`

### btop

（见现代化替代工具部分）

### bottom

（见现代化替代工具部分）

### glances

高级系统监控工具（Linux），提供详细的系统统计信息。

```bash
glances           # 启动监控
glances -w        # Web 模式
```

配置位置: `~/.config/glances/glances.conf`

### bmon

带宽监控工具（Linux），实时显示网络接口统计。

```bash
bmon              # 监控网络
```

配置位置: 无需配置

### lnav

日志文件导航器（Linux），智能合并和高亮日志。

```bash
lnav /var/log/*   # 查看日志
```

配置位置: `~/.lnav/`

---

## Git 增强工具

### git

分布式版本控制系统。

```bash
git clone url     # 克隆仓库
git commit -m msg # 提交更改
```

配置位置: `~/.gitconfig`

### gh

GitHub 官方 CLI，管理仓库、PR、issue 等。

```bash
gh repo create    # 创建仓库
gh pr create      # 创建 PR
```

配置位置: `~/.config/gh/config.yml`

### lazygit

Git 的终端 UI，简化 Git 操作流程。

```bash
lazygit           # 启动 TUI
```

配置位置: `~/.config/lazygit/config.yml`

### git-delta

Git 的语法高亮分页器，改善 diff 输出。

```bash
git diff          # 自动使用 delta
```

配置位置: `~/.gitconfig` (设置为 pager)

### git-cliff

自动生成 changelog 的工具，基于 conventional commits。

```bash
git cliff         # 生成 changelog
git cliff --tag v1.0.0
```

配置位置: `cliff.toml`

### onefetch

Git 仓库信息摘要工具，显示项目统计。

```bash
onefetch          # 显示仓库信息
```

配置位置: `~/.config/onefetch/config.yaml`

### gitleaks

Git 仓库密钥扫描工具，防止敏感信息泄露。

```bash
gitleaks detect   # 扫描当前仓库
gitleaks protect  # 作为 pre-commit hook
```

配置位置: `.gitleaks.toml`

---

## 安全工具

### age

现代化的文件加密工具，简单易用。

```bash
age -r public-key file > file.age  # 加密
age -d -i key file.age > file      # 解密
```

配置位置: 无需配置

### gnupg (macOS)

GPG 加密和签名工具，支持 PGP 协议。

```bash
gpg --gen-key     # 生成密钥
gpg -e file       # 加密文件
```

配置位置: `~/.gnupg/gpg.conf`

### ykman (macOS)

YubiKey 管理工具，配置硬件安全密钥。

```bash
ykman info        # 查看设备信息
ykman oath list   # 列出 OTP
```

配置位置: 无需配置

### pinentry-mac (macOS)

macOS 原生的 GPG PIN 输入工具。

```bash
# 在 gpg-agent.conf 中配置
pinentry-program /opt/homebrew/bin/pinentry-mac
```

配置位置: `~/.gnupg/gpg-agent.conf`

### trivy

容器和文件系统漏洞扫描工具。

```bash
trivy image nginx:latest  # 扫描镜像
trivy fs .                # 扫描文件系统
```

配置位置: 无需配置

### grype

容器镜像和文件系统漏洞扫描器。

```bash
grype image:tag   # 扫描镜像
grype dir:.       # 扫描目录
```

配置位置: `.grype.yaml`

### syft

生成软件物料清单（SBOM）的工具。

```bash
syft image:tag    # 生成 SBOM
syft dir:.        # 扫描目录
```

配置位置: 无需配置

---

## macOS 专属工具

### GUI 应用 (Casks)

#### 浏览器

- **google-chrome**: Google Chrome 浏览器
- **firefox**: Mozilla Firefox 浏览器

#### 终端

- **ghostty**: 现代化的 GPU 加速终端模拟器
- **warp**: AI 驱动的现代终端，支持协作功能

#### 通信和文件同步

- **localsend**: 跨平台本地文件传输工具
- **nextcloud**: 自托管的文件同步和共享平台

#### 开发工具

- **visual-studio-code**: 微软的代码编辑器
- **dbeaver-community**: 通用数据库管理工具
- **bruno**: API 测试工具（Postman 替代）

#### 生产力工具

- **obsidian**: 知识管理和笔记应用
- **typora**: Markdown 编辑器

#### 系统工具

- **stats**: macOS 菜单栏系统监控工具
- **keka**: 压缩和解压工具
- **vlc**: 多媒体播放器

### Nerd Fonts

- **font-jetbrains-mono-nerd-font**: JetBrains Mono 编程字体
- **font-hack-nerd-font**: Hack 编程字体
- **font-noto-sans**: Google Noto Sans 字体
- **font-source-han-serif**: 思源宋体

---

## Linux 专属工具

### glances

（见监控工具部分）

### bmon

（见监控工具部分）

### lnav

（见监控工具部分）

说明: Linux 配置主要继承 Brewfile.core，额外添加了专注于无头服务器监控和日志分析的工具。

---

## Mini Profile 工具

Mini Profile 是为短暂开发环境（GitHub Codespaces、Dev Containers 等）设计的精简配置，包含约 23 个核心开发工具。

### 包含的工具

- **Shell 基础**: zsh, starship, sheldon, zoxide, fzf
- **编辑器**: neovim, tmux
- **运行时**: mise, uv, pnpm
- **Git**: git, lazygit, git-delta
- **现代 CLI**: bat, eza, ripgrep, fd, jq, sd
- **开发工具**: direnv, just, chezmoi
- **网络**: curl

### 设计原则

- 独立配置，不继承 Brewfile.core
- 快速启动（5 分钟内完成安装）
- 仅包含编码必需的工具
- 排除重型运维工具（k9s、lazydocker 等）

---

## 基础设施和运维工具

### terraform

基础设施即代码工具，用于管理云资源。

```bash
terraform init    # 初始化项目
terraform apply   # 应用配置
```

配置位置: `*.tf` 文件

### ansible

自动化配置管理和应用部署工具。

```bash
ansible-playbook playbook.yml  # 运行 playbook
```

配置位置: `ansible.cfg`, `playbook.yml`

---

## 其他工具

### chezmoi

跨机器的 dotfiles 管理工具，支持模板和加密。

```bash
chezmoi init      # 初始化
chezmoi apply     # 应用配置
```

配置位置: `~/.local/share/chezmoi/`

### topgrade

一键更新所有包管理器和工具的工具。

```bash
topgrade          # 更新所有工具
```

配置位置: `~/.config/topgrade.toml`

### tldr

简化的 man 页面，提供实用命令示例。

```bash
tldr command      # 查看简化文档
```

配置位置: `~/.config/tldr/`

### yazi

终端文件管理器，支持预览和批量操作。

```bash
yazi              # 启动文件管理器
```

配置位置: `~/.config/yazi/`

### glow

终端 Markdown 渲染器，优雅显示 Markdown 文件。

```bash
glow README.md    # 渲染 Markdown
glow -p .         # 查找并渲染
```

配置位置: 无需配置

### pgcli

PostgreSQL 的 CLI 客户端，支持自动补全和语法高亮。

```bash
pgcli -h localhost -U user dbname  # 连接数据库
```

配置位置: `~/.config/pgcli/config`

### restic

快速、安全的备份程序，支持加密和去重。

```bash
restic init       # 初始化仓库
restic backup dir # 备份目录
```

配置位置: 环境变量和配置文件

---

## 工具总数统计

- **Brewfile.core**: 64 个包（所有环境通用）
- **Brewfile.macos**: 16 个 formulae + 19 个 casks（macOS 独有）
- **Brewfile.linux**: 15 个包（Linux 独有）
- **Brewfile.mini**: 23 个包（容器环境独立配置）

**总计**: 约 102 个工具（去重后）

---

## 配置层级结构

```
Brewfile.core (64)        # 基础工具
    ├─ Brewfile.macos (16+19)  # macOS 扩展
    └─ Brewfile.linux (15)     # Linux 扩展

Brewfile.mini (23)        # 独立的精简配置
```

---

## 快速参考

### 按使用场景选择配置

1. **macOS 开发工作站**: 使用 `macos` profile

   - 完整 GUI 应用
   - Kubernetes 和容器工具
   - 安全硬件支持（YubiKey、GPG）

2. **Linux 服务器/Homelab**: 使用 `linux` profile

   - 无头环境优化
   - 系统监控工具（glances、bmon、lnav）
   - 完整容器和 K8s 支持

3. **临时开发容器**: 使用 `mini` profile
   - 最小化工具集
   - 快速启动
   - 仅核心开发工具

---

## 获取更多帮助

大多数工具都支持以下命令查看帮助：

```bash
tool --help       # 查看帮助
man tool          # 查看手册页
tldr tool         # 查看简化文档
```

Home Up 项目地址: https://github.com/zopieux/homeup
