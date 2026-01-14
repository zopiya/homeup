# Homeup 使用手册

全面的命令参考、常见问题和故障排除指南。

---

## 快速开始

### 5 分钟快速设置

完整的安装流程，从克隆到可用：

#### 步骤 1：克隆仓库

```bash
# 克隆 Homeup 仓库
git clone https://github.com/zopiya/homeup.git
cd homeup
```

或使用一键安装（自动检测环境）：

```bash
curl -fsSL https://raw.githubusercontent.com/zopiya/homeup/main/bootstrap.sh | bash
```

#### 步骤 2：运行 Bootstrap（自动检测环境）

Bootstrap 脚本会自动检测你的环境。默认情况下（无参数），它会安装 **Mini Profile**（安全模式），这非常适合首次尝试或容器环境。

```bash
# 默认安装 Mini Profile（推荐首次使用，安全快速）
./bootstrap.sh

# 指定 Profile 安装完整环境
./bootstrap.sh -p macos        # macOS 完整工作站（含 GUI 应用）
./bootstrap.sh -p linux        # Linux 服务器（无头模式）
./bootstrap.sh -p mini         # 显式指定 Mini Profile

# 非交互式自动应用
./bootstrap.sh -p macos -a

# 完全自动化（适合 CI/自动化）
./bootstrap.sh -p linux -y -a
```

**Bootstrap 会做什么：**
1. 检测操作系统和架构
2. 安装 Homebrew（如果尚未安装）
3. 安装 Chezmoi 和 Just
4. 初始化 Chezmoi 配置
5. 可选：自动应用配置（使用 `-a` 标志）

#### 步骤 3：查看变化（使用 `just diff`）

在应用配置前，先预览将要发生的变化：

```bash
just diff               # 显示所有即将发生的变化
just diff-full          # 显示完整 diff（无分页）
```

**示例输出：**
```diff
diff --git a/dot_zshrc b/.zshrc
--- a/dot_zshrc
+++ b/.zshrc
@@ -1,0 +1,10 @@
+# Homeup Zsh Configuration
+export HOMEUP_PROFILE=macos
```

#### 步骤 4：应用配置（使用 `just apply`）

确认变化后，应用配置：

```bash
just apply                    # 应用所有配置文件
just apply-verbose            # 详细输出模式
just apply-interactive        # 逐个确认每个更改
```

**注意事项：**
- 第一次运行时可能需要几分钟
- 某些配置可能需要重启 Shell 才能生效
- 使用 `apply-interactive` 可以精细控制每个文件

#### 步骤 5：安装包（使用 `just install-packages`）

根据你的 Profile 安装相应的包：

```bash
just install-packages                # 安装当前 Profile 的所有包
just install-packages-no-upgrade     # 安装但不升级现有包
```

**按 Profile 安装：**
- **macOS**: Brewfile.core + Brewfile.macos（~100+ 包）
- **Linux**: Brewfile.core + Brewfile.linux（~60+ 包）
- **Mini**: Brewfile.mini（~20 个基础包）

**安装时间估计：**
- Mini Profile: ~5 分钟
- Linux Profile: ~10-15 分钟
- macOS Profile: ~15-20 分钟（包含 GUI 应用）

#### 步骤 6：验证安装（使用 `just doctor`）

运行健康检查确保一切正常：

```bash
just doctor                  # 全面健康检查
just info                    # 显示系统信息
just validate                # 验证所有 Profile 模板
```

**Doctor 检查项：**
- ✅ 必需工具已安装（brew、chezmoi、git）
- ✅ 文件结构完整
- ✅ Profile 配置有效
- ✅ SSH 密钥存在
- ✅ GPG 配置（仅 macOS）

---

### 首次使用检查清单

完成安装后，使用以下清单确保设置正确：

- [ ] **Bootstrap 成功完成**
  ```bash
  just doctor  # 应该显示 "✅ All checks passed!"
  ```

- [ ] **Profile 设置正确**
  ```bash
  just profile  # 验证你的 Profile
  echo $HOMEUP_PROFILE  # 应该显示: macos/linux/mini
  ```

- [ ] **包已安装**
  ```bash
  just packages-info  # 查看包统计
  brew list --formula | wc -l  # 确认已安装的包数量
  ```

- [ ] **Shell 配置已加载**
  ```bash
  # 重启 Shell 或执行
  source ~/.zshrc

  # 测试工具
  command -v starship  # 应该找到 starship
  command -v fzf       # 应该找到 fzf
  ```

- [ ] **Git 配置正确**
  ```bash
  git config --global user.name   # 检查姓名
  git config --global user.email  # 检查邮箱
  git config --list               # 查看所有配置
  ```

- [ ] **SSH 配置生效**
  ```bash
  cat ~/.ssh/config  # 检查 SSH 配置
  ssh -T git@github.com  # 测试 GitHub 连接
  ```

- [ ] **GPG 配置（仅 macOS）**
  ```bash
  gpg --list-keys  # 列出 GPG 密钥
  git config --global user.signingkey  # 验证签名密钥
  ```

- [ ] **Git Hooks 已安装**
  ```bash
  just install-hooks  # 安装 lefthook
  lefthook --version  # 验证安装
  ```

- [ ] **编辑器配置正确**
  ```bash
  nvim --version  # 测试 Neovim
  echo $EDITOR    # 应该显示 nvim 或你的首选编辑器
  ```

---

## 命令参考

Homeup 使用 `just` 作为任务运行器。所有命令都可以通过 `just <命令>` 执行。

### 帮助与信息

#### `just help` - 显示详细帮助

显示常用命令和示例。

```bash
just help
```

**输出示例：**
```
━━━ Homeup Task Runner ━━━

🎯 Quick Start:
  just apply              # Apply dotfiles
  just diff               # Show changes before applying
  just install-packages   # Install Homebrew packages
```

#### `just info` - 显示系统信息

显示操作系统、架构、Profile 和工具版本信息。

```bash
just info
```

**输出示例：**
```
━━━ System Information ━━━

OS: Darwin 23.6.0
Architecture: arm64
Profile: macos
Chezmoi version: chezmoi version 2.47.0
Homebrew version: Homebrew 4.2.0
Shell: /bin/zsh
Git version: git version 2.43.0

📂 Paths:
  Source: /Users/zopiya/workspace/homeup
  Config: /Users/zopiya/.config/chezmoi
  Data: /Users/zopiya/.local/share/chezmoi
```

#### `just --list` - 列出所有可用命令

查看所有可用的 just 命令。

```bash
just --list
just -l  # 简写
```

#### `just --choose` - 交互式选择命令

使用交互式菜单选择要运行的命令（需要支持 TTY）。

```bash
just --choose
just  # 默认行为
```

---

### Chezmoi 操作

管理配置文件和模板。

#### `just apply` - 应用配置文件

将 Chezmoi 管理的所有配置应用到你的系统。

```bash
just apply
```

**使用场景：**
- 首次设置后应用配置
- 从远程仓库拉取更新后
- 修改模板后应用更改

#### `just apply-verbose` - 详细输出模式应用

显示详细的应用过程输出。

```bash
just apply-verbose
```

**输出示例：**
```
Applying dotfiles (verbose)...
copying /Users/zopiya/.zshrc
copying /Users/zopiya/.gitconfig
...
```

#### `just apply-interactive` - 交互式应用

逐个文件确认每个更改。

```bash
just apply-interactive
```

**使用场景：**
- 首次应用时谨慎操作
- 只想应用部分更改
- 不确定某些更改的影响

#### `just diff` - 查看配置差异

显示当前系统状态与 Chezmoi 目标状态之间的差异。

```bash
just diff
```

**输出示例：**
```diff
diff --git a/dot_zshrc b/.zshrc
--- a/dot_zshrc
+++ b/.zshrc
@@ -10,0 +11 @@
+export PATH="$HOME/.local/bin:$PATH"
```

#### `just diff-full` - 完整差异（无分页）

显示完整差异输出，不使用分页器。

```bash
just diff-full
```

**使用场景：**
- 需要复制完整 diff 输出
- 在脚本中使用
- 将 diff 重定向到文件

#### `just edit <文件>` - 编辑受管理的文件

通过 Chezmoi 编辑受管理的文件。

```bash
just edit ~/.zshrc              # 编辑 zsh 配置
just edit ~/.config/git/config  # 编辑 git 配置
just edit ~/.ssh/config         # 编辑 SSH 配置
```

**重要提示：**
- 始终使用 `just edit` 而不是直接编辑文件
- 编辑会自动更新 Chezmoi 源代码
- 使用 `just apply` 应用更改

#### `just add <文件>` - 添加新文件到 Chezmoi

将新文件添加到 Chezmoi 管理。

```bash
just add ~/.new-config-file
just add ~/.config/newtool/config.toml
```

**使用场景：**
- 添加新的配置文件到版本控制
- 跨机器同步新配置
- 备份重要配置

#### `just update` - 从远程更新并应用

从远程 Git 仓库拉取最新更改并应用。

```bash
just update
```

**相当于：**
```bash
git pull
chezmoi update
```

#### `just status` - 查看 Chezmoi 状态

显示 Chezmoi 管理的文件状态。

```bash
just status
```

**输出示例：**
```
 M .zshrc
 A .config/new-app/config.yaml
```

#### `just verify` - 验证配置

验证所有受管理的文件与 Chezmoi 源代码一致。

```bash
just verify
```

#### `just data` - 显示 Chezmoi 数据

显示 Chezmoi 使用的所有变量和数据。

```bash
just data
```

**输出示例：**
```json
{
  "profile": "macos",
  "os": "darwin",
  "arch": "arm64",
  "hostname": "macbook-pro"
}
```

#### `just execute-dry` - 模拟执行脚本

在 dry-run 模式下执行 Chezmoi 脚本（不实际修改系统）。

```bash
just execute-dry
```

#### `just find-template <文件>` - 查找文件的源模板

查找生成特定文件的模板。

```bash
just find-template ~/.zshrc
just find-template ~/.gitconfig
```

---

### Package 管理

使用 Homebrew 管理包和应用程序。

#### `just install-packages` - 安装当前 Profile 的包

根据当前 Profile 安装所有定义的包。

```bash
just install-packages
```

**安装逻辑：**
- **mini**: 只安装 `Brewfile.mini`
- **macos**: 安装 `Brewfile.core` + `Brewfile.macos`
- **linux**: 安装 `Brewfile.core` + `Brewfile.linux`

#### `just install-packages-no-upgrade` - 安装包但不升级

安装缺失的包但不升级已安装的包。

```bash
just install-packages-no-upgrade
```

**使用场景：**
- 快速安装缺失的工具
- 避免意外升级可能破坏的包
- CI 环境中

#### `just packages-verify` - 验证包可用性

验证所有定义的包在 Homebrew 中都可用。

```bash
just packages-verify
```

**输出示例：**
```
━━━ Homebrew Package Verification ━━━

Checking Brewfile.core...
  ✓ git
  ✓ neovim
  ✓ tmux
  ...
  ✗ fake-package - NOT FOUND

❌ Some packages are not available
```

#### `just packages-check-duplicates` - 检查重复包

检查 Brewfiles 之间的重复包。

```bash
just packages-check-duplicates
```

**输出示例：**
```
━━━ Checking for Duplicate Packages ━━━

### Core vs macOS duplicates:
  ✓ No duplicates

### Package counts:
  Core:  45 packages
  macOS: 35 formulae + 25 casks
  Linux: 28 packages
  Mini:  20 packages
```

#### `just packages-info` - 显示包统计

显示包数量和分布统计。

```bash
just packages-info
```

**输出示例：**
```
━━━ Package Statistics ━━━

📊 Package Distribution:
  Core:  45 formulae
  macOS: 35 formulae + 25 casks = 60 total
  Linux: 28 formulae
  Mini:  20 formulae

  Total unique packages: 102

📦 Current profile (macos):
  Would install: 105 packages

💾 Installed packages:
  98 formulae
  23 casks
```

#### `just packages-list` - 列出已安装的包

显示所有已安装的 formulae 和 casks。

```bash
just packages-list
```

#### `just packages-outdated` - 检查过时的包

显示所有可更新的包。

```bash
just packages-outdated
```

**输出示例：**
```
━━━ Outdated Packages ━━━

git (2.42.0) < 2.43.0
neovim (0.9.4) < 0.9.5
```

#### `just packages-dump` - 导出当前安装的包

生成包含所有已安装包的 Brewfile。

```bash
just packages-dump
```

**输出：**
- 创建 `Brewfile.dump`
- 可用于审查和合并到正式 Brewfiles

**使用场景：**
- 记录当前系统状态
- 迁移到新 Brewfile 结构
- 备份包列表

#### `just packages-cleanup` - 清理未使用的包

清理 Homebrew 缓存和未使用的包。

```bash
just packages-cleanup
```

**执行：**
```bash
brew cleanup --prune=all
brew autoremove
```

#### `just packages-deps <包名>` - 显示包依赖

显示包的依赖树。

```bash
just packages-deps neovim
just packages-deps git
```

**输出示例：**
```
Dependencies for neovim:
├── gettext
├── libuv
├── luajit
└── tree-sitter
```

#### `just packages-search <查询>` - 搜索包

在 Homebrew 中搜索包。

```bash
just packages-search python
just packages-search "text editor"
```

#### `just update-brew` - 更新 Homebrew 和包

更新 Homebrew 本身并升级所有已安装的包。

```bash
just update-brew
```

**执行：**
```bash
brew update
brew upgrade
brew cleanup
```

#### `just brew-size` - 显示 Homebrew 磁盘使用

显示 Homebrew 安装和缓存占用的磁盘空间。

```bash
just brew-size
```

**输出示例：**
```
Homebrew disk usage:
2.5G    /opt/homebrew

Cache size:
1.2G    /Users/zopiya/Library/Caches/Homebrew
```

---

### Profile 管理

管理和切换环境 Profile。

#### `just profile` - 显示当前 Profile

显示当前 Profile 和可用 Profile 列表。

```bash
just profile
```

**输出示例：**
```
Current profile: macos

Available profiles:
  • macos - Full macOS workstation (GPG, YubiKey, GUI apps)
  • linux - Headless Linux server (SSH-only, no GUI)
  • mini  - Minimal ephemeral (containers, Codespaces)

To change: export HOMEUP_PROFILE=<profile>
```

#### `just profile-macos` - 切换到 macOS Profile

显示切换到 macOS Profile 的命令。

```bash
just profile-macos
```

**输出：**
```
export HOMEUP_PROFILE=macos
Run: source ~/.zshrc or restart shell
```

**实际切换：**
```bash
export HOMEUP_PROFILE=macos
source ~/.zshrc
```

#### `just profile-linux` - 切换到 Linux Profile

显示切换到 Linux Profile 的命令。

```bash
just profile-linux
```

#### `just profile-mini` - 切换到 Mini Profile

显示切换到 Mini Profile 的命令。

```bash
just profile-mini
```

#### `just profile-diff <from> <to>` - 对比 Profile 差异

对比两个 Profile 之间的包差异。

```bash
just profile-diff macos linux
just profile-diff core mini
```

**输出示例：**
```
Comparing profiles: macos vs linux

=== Packages in macos but not in linux ===
1password-cli
alfred
iterm2
```

---

### 诊断调试

诊断问题和调试配置。

#### `just doctor` - 运行健康检查

运行全面的系统健康检查。

```bash
just doctor
```

**检查项：**
- ✅ 必需工具（brew、chezmoi、git）
- ✅ 文件结构
- ✅ Profile 配置
- ✅ SSH 密钥
- ✅ GPG 配置（macOS）

**输出示例：**
```
━━━ Homeup Health Check ━━━

🔧 Checking required tools...
  ✓ brew
  ✓ chezmoi
  ✓ git

📂 Checking file structure...
  ✓ bootstrap.sh
  ✓ packages/Brewfile.core
  ...

✅ All checks passed!
```

#### `just debug` - 调试 Chezmoi 配置

显示 Chezmoi 调试信息。

```bash
just debug
```

**输出示例：**
```
━━━ Chezmoi Debug Information ━━━

Data:
{
  "profile": "macos",
  "os": "darwin"
}

Managed files:
.zshrc
.gitconfig
...

Source path: /Users/zopiya/.local/share/chezmoi
```

#### `just security-check` - 安全检查

检查仓库中的安全问题和敏感信息。

```bash
just security-check
```

**检查项：**
- Git 历史中的密钥泄露（使用 gitleaks）
- 文件权限问题

---

### Git 操作

Git 相关的快捷命令。

#### `just st` - Git 状态

显示简短的 Git 状态。

```bash
just st
```

**相当于：**
```bash
git status -sb
```

#### `just log [数量]` - Git 日志

显示美化的 Git 日志。

```bash
just log        # 默认显示 20 条
just log 50     # 显示 50 条
```

**相当于：**
```bash
git log --oneline -20 --graph --decorate
```

#### `just branch <名称>` - 创建分支

创建并切换到新分支。

```bash
just branch feature-new-config
```

**相当于：**
```bash
git checkout -b feature-new-config
```

#### `just commit <消息>` - 快速提交

添加所有更改并提交。

```bash
just commit "feat: add new configuration"
```

**相当于：**
```bash
git add -A
git commit -m "feat: add new configuration"
```

#### `just amend` - 修改最后一次提交

修改最后一次提交（不编辑消息）。

```bash
just amend
```

**相当于：**
```bash
git commit --amend --no-edit
```

#### `just push` - 推送到远程

推送到远程仓库。

```bash
just push
```

#### `just pull` - 从远程拉取

从远程拉取并 rebase。

```bash
just pull
```

**相当于：**
```bash
git pull --rebase
```

#### `just install-hooks` - 安装 Git Hooks

安装 lefthook Git hooks。

```bash
just install-hooks
```

**安装的 hooks：**
- pre-commit: 运行 linters 和验证
- pre-push: 运行测试

#### `just uninstall-hooks` - 卸载 Git Hooks

卸载 lefthook Git hooks。

```bash
just uninstall-hooks
```

#### `just pre-commit` - 手动运行 pre-commit

手动运行 pre-commit hooks。

```bash
just pre-commit
```

**使用场景：**
- 测试 hooks
- 在提交前验证更改
- 调试 hook 问题

---

### CI/CD

持续集成和部署相关命令。

#### `just ci` - 运行所有 CI 检查

运行完整的 CI 测试套件。

```bash
just ci
```

**运行的检查：**
1. Linting（shellcheck）
2. 包验证
3. 重复包检查
4. 模板验证
5. 健康检查

**输出示例：**
```
━━━ Running CI Checks ━━━

1/5: Linting...
2/5: Package verification...
3/5: Duplicate check...
4/5: Template validation...
5/5: Health check...

✅ All CI checks passed!
```

#### `just check` - 快速检查

运行快速检查（CI 的子集）。

```bash
just check
```

**运行的检查：**
- 模板验证
- 重复包检查

#### `just ci-trigger` - 触发 GitHub Actions

触发 GitHub Actions 工作流。

```bash
just ci-trigger
```

**需要：**
- GitHub CLI (`gh`)
- 适当的权限

#### `just ci-status` - 查看 CI 状态

显示最近的工作流运行状态。

```bash
just ci-status
```

#### `just ci-logs` - 查看 CI 日志

查看最新工作流运行的日志。

```bash
just ci-logs
```

---

### 维护清理

系统维护和清理命令。

#### `just upgrade` - 完整系统升级

使用 topgrade 运行完整系统升级。

```bash
just upgrade
```

**升级内容：**
- Homebrew 包
- 系统工具
- 运行时（mise）
- 其他包管理器

#### `just clean` - 清理缓存

清理 Chezmoi 缓存和临时文件。

```bash
just clean
```

**清理内容：**
- Chezmoi 缓存
- 临时测试目录

#### `just clean-all` - 深度清理

清理所有缓存（Chezmoi + Homebrew）。

```bash
just clean-all
```

**执行：**
```bash
just clean
just packages-cleanup
```

#### `just reset` - 重置 Chezmoi 状态

完全清除 Chezmoi 状态（危险操作！）。

```bash
just reset
```

**警告：**
- 会删除所有 Chezmoi 状态
- 需要确认
- 不会删除实际配置文件

#### `just backup` - 备份配置文件

创建当前配置文件的备份。

```bash
just backup
```

**备份内容：**
- .zshrc
- .gitconfig
- .ssh/config
- .config/nvim
- .config/starship.toml

**备份位置：**
```
$HOME/dotfiles-backup-<时间戳>/
```

---

### 学习与文档

学习资源和文档命令。

#### `just help` - 详细帮助

显示详细的帮助信息和示例。

```bash
just help
```

#### `just examples` - 常见用法示例

显示常见使用场景的示例。

```bash
just examples
```

**示例类别：**
- 🏁 初始设置
- 📝 日常使用
- 🔄 更新
- 🧹 维护
- 🧪 提交前检查

#### `just shortcuts` - 快捷键和别名

显示有用的快捷键和别名。

```bash
just shortcuts
```

#### `just docs` - 打开文档

在终端中查看 README。

```bash
just docs
```

**使用工具（按优先级）：**
1. `glow`（如果可用）
2. `bat`（如果可用）
3. `cat`（回退）

---

### 高级操作

高级系统操作。

#### `just init` - 初始化新机器

在新机器上初始化 Homeup。

```bash
just init
```

**执行：**
1. 运行 bootstrap
2. 提示下一步操作

**需要确认！**

#### `just reinstall` - 重新运行安装脚本

重新运行所有 Chezmoi 安装脚本。

```bash
just reinstall
```

**警告：**
- 强制重新应用所有配置
- 可能覆盖手动更改

#### `just export` - 导出配置备份

导出当前配置为 tar.gz 归档。

```bash
just export
```

**导出内容：**
- packages/
- bootstrap.sh
- justfile
- README.md

**输出：**
```
homeup-export-<时间戳>.tar.gz
```

---

### 测试与验证

测试和验证命令。

#### `just validate` - 验证所有 Profile

验证所有 Profile 的模板语法。

```bash
just validate
```

**测试的 Profile：**
- macos
- linux
- mini

**输出示例：**
```
━━━ Validating Templates ━━━

Testing profile: macos
  ✅ macos: OK
Testing profile: linux
  ✅ linux: OK
Testing profile: mini
  ✅ mini: OK

✅ All profiles validated successfully!
```

#### `just test [profile]` - 测试特定 Profile

测试特定 Profile 的配置。

```bash
just test macos
just test linux
just test mini
```

**检查项：**
1. 模板验证
2. Brewfile 存在性
3. Profile 一致性

#### `just lint` - 运行 Linters

运行所有 linters。

```bash
just lint
```

**运行的 linters：**
- ShellCheck（Shell 脚本）
- 模板验证

#### `just fmt` - 格式化脚本

格式化所有 shell 脚本（需要 shfmt）。

```bash
just fmt
```

---

### 统计与报告

生成统计和报告。

#### `just stats` - 显示综合统计

显示 Homeup 的综合统计信息。

```bash
just stats
```

**统计内容：**
- 包统计
- 受管理的文件数
- Git 信息
- 代码统计（如果有 tokei）

#### `just report` - 生成设置报告

生成详细的设置报告（Markdown 格式）。

```bash
just report
```

**输出：**
```
homeup-report-<时间戳>.md
```

**报告内容：**
- 系统信息
- 包统计
- 受管理的文件
- Git 状态

---

## 常见问题

### Q1: 如何切换 Profile?

**问题：** 我想在不同的环境中使用不同的 Profile。

**解答：**

Homeup 支持三种 Profile：**macos**、**linux** 和 **mini**。切换 Profile 的步骤：

1. **设置环境变量：**
   ```bash
   export HOMEUP_PROFILE=linux  # 或 macos、mini
   ```

2. **持久化设置（推荐）：**

   将以下内容添加到 `~/.zshrc` 或 `~/.bashrc`：
   ```bash
   export HOMEUP_PROFILE=linux
   ```

3. **重新加载 Shell：**
   ```bash
   source ~/.zshrc
   # 或重启终端
   ```

4. **验证切换：**
   ```bash
   just profile  # 应该显示新的 Profile
   echo $HOMEUP_PROFILE
   ```

5. **重新应用配置：**
   ```bash
   just apply
   just install-packages  # 如果需要安装新包
   ```

**Profile 选择建议：**
- **macOS** → 个人 MacBook/iMac（需要 GPG、GUI 应用）
- **Linux** → 服务器、VPS、Homelab（无头环境）
- **Mini** → Docker 容器、GitHub Codespaces、临时虚拟机

---

### Q2: 如何添加新包?

**问题：** 我想添加一个新的工具到我的环境中。

**解答：**

1. **确定目标 Profile：**

   决定包应该安装到哪个 Profile：
   - 所有 Profile（除 mini）→ `Brewfile.core`
   - 仅 macOS → `Brewfile.macos`
   - 仅 Linux → `Brewfile.linux`
   - 仅 Mini → `Brewfile.mini`

2. **编辑相应的 Brewfile：**
   ```bash
   # 编辑 core（所有 Profile 共享）
   chezmoi edit packages/Brewfile.core

   # 或 macOS 专属
   chezmoi edit packages/Brewfile.macos
   ```

3. **添加包定义：**

   **Formula（命令行工具）：**
   ```ruby
   brew "package-name"
   ```

   **Cask（macOS GUI 应用）：**
   ```ruby
   cask "application-name"
   ```

4. **验证包存在：**
   ```bash
   brew search package-name  # 确认包名正确
   ```

5. **应用更改：**
   ```bash
   just apply                 # 应用 Brewfile 更改
   just install-packages      # 安装新包
   ```

6. **验证安装：**
   ```bash
   brew list | grep package-name
   command -v package-name
   ```

**示例：添加 `ripgrep` 到 core：**

```bash
# 1. 编辑 Brewfile.core
chezmoi edit packages/Brewfile.core

# 2. 添加行
brew "ripgrep"

# 3. 应用
just apply
just install-packages

# 4. 验证
rg --version
```

---

### Q3: 如何自定义配置?

**问题：** 我想修改 Zsh、Git 或其他工具的配置。

**解答：**

**1. 修改现有配置：**

使用 `chezmoi edit` 编辑配置文件（**切勿直接编辑**）：

```bash
# Zsh 配置
chezmoi edit ~/.config/zsh/.zshrc.tmpl

# Git 配置
chezmoi edit ~/.config/git/config.tmpl

# SSH 配置
chezmoi edit ~/.ssh/config.tmpl

# Starship 提示符
chezmoi edit ~/.config/starship/starship.toml
```

**2. 预览更改：**

```bash
just diff  # 查看将要发生的变化
```

**3. 应用更改：**

```bash
just apply
```

**4. 立即生效：**

对于 Shell 配置：
```bash
source ~/.zshrc
```

对于其他配置可能需要重启应用或终端。

**添加自定义配置文件：**

如果要添加全新的配置文件：

```bash
# 1. 将文件添加到 Chezmoi
just add ~/.my-custom-config

# 2. 编辑它
chezmoi edit ~/.my-custom-config

# 3. 现在它已在所有机器上同步
```

**Profile 特定的配置：**

如果配置只在某些 Profile 中需要，使用模板：

```bash
# 在模板中使用条件
{{- if eq .profile "macos" }}
# macOS 专属配置
{{- end }}
```

---

### Q4: GPG 签名失败怎么办?

**问题：** Git 提交时 GPG 签名失败。

**解答：**

**诊断步骤：**

1. **检查 GPG 是否安装（仅 macOS Profile）：**
   ```bash
   gpg --version
   ```

2. **列出 GPG 密钥：**
   ```bash
   gpg --list-secret-keys --keyid-format=long
   ```

3. **检查 Git GPG 配置：**
   ```bash
   git config --global user.signingkey
   git config --global commit.gpgsign
   ```

**常见问题和解决方案：**

**问题 1：没有 GPG 密钥**

生成新的 GPG 密钥：
```bash
gpg --full-generate-key
# 选择 RSA and RSA, 4096 bits
# 永不过期（或根据需求设置）
```

配置 Git 使用密钥：
```bash
# 获取密钥 ID
gpg --list-secret-keys --keyid-format=long
# 示例输出: sec   rsa4096/ABCD1234EFGH5678

# 配置 Git
git config --global user.signingkey ABCD1234EFGH5678
git config --global commit.gpgsign true
```

**问题 2：GPG agent 未运行**

启动 GPG agent：
```bash
gpgconf --kill gpg-agent
gpg-agent --daemon
```

**问题 3：TTY 问题**

设置 GPG TTY：
```bash
export GPG_TTY=$(tty)
# 添加到 ~/.zshrc
echo 'export GPG_TTY=$(tty)' >> ~/.zshrc
```

**问题 4：密码提示不显示**

安装 pinentry-mac（macOS）：
```bash
brew install pinentry-mac
echo "pinentry-program $(which pinentry-mac)" >> ~/.gnupg/gpg-agent.conf
gpgconf --kill gpg-agent
```

**测试 GPG 签名：**

```bash
echo "test" | gpg --clearsign
git commit --allow-empty -m "test gpg" -S
```

**禁用 GPG 签名（临时）：**

如果急需提交但 GPG 有问题：
```bash
git config --global commit.gpgsign false
git commit -m "message"
git config --global commit.gpgsign true
```

---

### Q5: SSH Agent Forwarding 如何配置?

**问题：** 我想在远程服务器上使用本地 SSH 密钥。

**解答：**

Homeup 已经为不同 Profile 配置了 SSH agent forwarding：

**macOS Profile（谨慎模式）：**

SSH 会在每次连接时询问是否转发：
```
ForwardAgent ask
```

**Linux Profile（自动转发到受信任域）：**

自动转发到 `*.hs` 域：
```
Host *.hs
    ForwardAgent yes
```

**自定义配置：**

1. **编辑 SSH 配置：**
   ```bash
   chezmoi edit ~/.ssh/config.tmpl
   ```

2. **添加受信任主机：**
   ```
   Host trusted-server
       HostName server.example.com
       ForwardAgent yes
   ```

3. **应用配置：**
   ```bash
   just apply
   ```

**测试 Agent Forwarding：**

1. **本地检查 agent：**
   ```bash
   ssh-add -l  # 列出已加载的密钥
   ```

2. **连接到远程服务器：**
   ```bash
   ssh user@server
   ```

3. **在远程服务器上测试：**
   ```bash
   ssh-add -l  # 应该显示相同的密钥
   echo $SSH_AUTH_SOCK  # 应该有值
   ```

4. **测试 Git 操作：**
   ```bash
   ssh -T git@github.com  # 在远程服务器上
   ```

**安全建议：**

- ✅ **DO**: 仅转发到受信任的服务器
- ✅ **DO**: 使用 `ForwardAgent ask` 进行交互式确认
- ❌ **DON'T**: 对所有主机使用 `ForwardAgent yes`
- ❌ **DON'T**: 在不受信任的环境中转发

**故障排除：**

如果转发不工作：

1. **检查本地 agent 是否运行：**
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
   ```

2. **检查远程 sshd 配置：**
   ```bash
   # 在远程服务器上
   grep AllowAgentForwarding /etc/ssh/sshd_config
   # 应该是 yes
   ```

3. **使用 verbose 模式调试：**
   ```bash
   ssh -v user@server
   # 查找 "agent forwarding" 相关信息
   ```

---

### Q6: 如何在多台机器间同步?

**问题：** 我想在多台机器上保持配置同步。

**解答：**

**初始设置：**

1. **在第一台机器上设置 Homeup：**
   ```bash
   cd ~/workspace/homeup
   # 进行你的自定义配置
   chezmoi edit ~/.zshrc
   just apply
   ```

2. **提交并推送更改：**
   ```bash
   just commit "feat: customize zsh config"
   just push
   ```

**在新机器上：**

1. **运行 bootstrap：**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/yourusername/homeup/main/bootstrap.sh | bash -s -- -p macos -a
   ```

2. **或手动克隆：**
   ```bash
   git clone https://github.com/yourusername/homeup.git
   cd homeup
   ./bootstrap.sh -p macos -a
   ```

**日常同步工作流：**

**在机器 A 上更改：**
```bash
chezmoi edit ~/.gitconfig  # 修改配置
just diff                  # 预览更改
just apply                 # 应用更改
just commit "update: git config"
just push
```

**在机器 B 上同步：**
```bash
just update                # 拉取并应用更改
# 或分步骤
just pull
just apply
```

**处理冲突：**

如果在两台机器上都进行了更改：

```bash
# 拉取远程更改
just pull
# 如果有冲突，手动解决
cd ~/.local/share/chezmoi
git status
# 解决冲突后
git add .
git commit
just push
```

**机器特定的配置：**

如果某些配置需要因机器而异（如主机名）：

1. **使用模板变量：**
   ```bash
   # 在 .chezmoi.toml.tmpl 中
   [data]
       hostname = "{{ .chezmoi.hostname }}"
   ```

2. **在配置中使用：**
   ```bash
   # 在 .zshrc.tmpl 中
   {{- if eq .chezmoi.hostname "work-laptop" }}
   export WORK_ENV=true
   {{- end }}
   ```

**最佳实践：**

- ✅ 经常提交和推送小更改
- ✅ 在应用前使用 `just diff` 预览更改
- ✅ 为不同环境使用适当的 Profile
- ✅ 使用模板处理机器特定的配置
- ❌ 不要提交敏感信息（使用 `.chezmoiignore`）

---

### Q7: 如何回滚配置?

**问题：** 我应用了错误的配置，想回滚。

**解答：**

**方法 1：使用 Git 回滚（推荐）**

1. **查看最近的提交：**
   ```bash
   just log 10
   ```

2. **回滚到特定提交：**
   ```bash
   cd ~/.local/share/chezmoi
   git reset --hard <commit-hash>
   just apply
   ```

3. **回滚最后一次提交：**
   ```bash
   cd ~/.local/share/chezmoi
   git reset --hard HEAD~1
   just apply
   ```

**方法 2：使用备份恢复**

如果你之前运行了 `just backup`：

```bash
# 列出备份
ls -la ~/dotfiles-backup-*

# 恢复特定文件
cp ~/dotfiles-backup-20260113-100000/.zshrc ~/.zshrc

# 或恢复所有文件
cp -r ~/dotfiles-backup-20260113-100000/* ~/
```

**方法 3：手动编辑修复**

如果只是小错误：

```bash
chezmoi edit ~/.zshrc       # 修复错误
just diff                   # 验证修复
just apply                  # 应用修复
```

**方法 4：重新初始化（核选项）**

如果一切都乱了，完全重置：

```bash
# 备份当前状态
just backup

# 清除 Chezmoi 状态
just reset

# 重新初始化
./bootstrap.sh -p macos -a
```

**预防措施：**

- ✅ 应用前始终运行 `just diff`
- ✅ 定期运行 `just backup`
- ✅ 经常提交到 Git
- ✅ 在测试环境中先测试大更改

---

### Q8: 包安装失败怎么办?

**问题：** 运行 `just install-packages` 时某些包安装失败。

**解答：**

**诊断步骤：**

1. **检查 Homebrew 健康状态：**
   ```bash
   brew doctor
   brew update
   ```

2. **验证包是否存在：**
   ```bash
   just packages-verify
   ```

3. **检查具体包：**
   ```bash
   brew info package-name
   brew search package-name
   ```

**常见问题和解决方案：**

**问题 1：包不存在或已重命名**

```bash
# 搜索正确的包名
brew search similar-name

# 更新 Brewfile
chezmoi edit packages/Brewfile.core
# 替换为正确的包名

just apply
just install-packages
```

**问题 2：Cask 在 Linux 上安装失败**

Casks 只在 macOS 上可用：

```bash
# 确保 casks 只在 Brewfile.macos 中
chezmoi edit packages/Brewfile.macos  # ✅ 正确
chezmoi edit packages/Brewfile.linux  # ❌ 不要在这里放 casks
```

**问题 3：权限问题**

```bash
# 修复 Homebrew 权限
sudo chown -R $(whoami) $(brew --prefix)/*

# 或重新安装 Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**问题 4：依赖冲突**

```bash
# 查看冲突详情
brew install package-name --verbose

# 强制覆盖链接
brew link --overwrite package-name
```

**问题 5：网络问题**

```bash
# 清理并重试
brew cleanup
brew update

# 使用 HTTPS 代替 Git（中国用户）
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
brew update
```

**跳过失败的包并继续：**

如果某个包一直失败但你想继续：

1. **临时注释掉包：**
   ```bash
   chezmoi edit packages/Brewfile.core
   # 添加 # 注释掉问题包
   # brew "problematic-package"
   ```

2. **安装其余包：**
   ```bash
   just apply
   just install-packages
   ```

3. **稍后手动安装：**
   ```bash
   brew install problematic-package
   ```

**查看详细错误信息：**

```bash
brew install package-name --verbose --debug
```

**完全重置 Homebrew（终极方案）：**

```bash
# 警告：会删除所有已安装的包！
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
just install-packages
```

---

## 故障排除

### 问题: Bootstrap 卡住

**症状：**
- Bootstrap 脚本运行时无响应
- 长时间停留在某个步骤
- 进度指示器不动

**可能原因和解决方案：**

**1. 网络连接问题**

Bootstrap 脚本现在包含超时控制。如果它因网络慢而失败，请检查你的连接或代理设置。

**2. Homebrew 安装卡住**

Bootstrap 会重试 Homebrew 安装 3 次。如果仍然失败：

```bash
# 手动安装 Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 然后继续 bootstrap
./bootstrap.sh -p macos
```

**3. 查看详细日志**

Bootstrap 现在会将详细日志写入文件。检查日志以获取更多线索：

```bash
tail -f ~/.homeup/logs/bootstrap.log
```
# 测试网络连接
curl -I https://github.com
ping -c 3 github.com

# 如果在中国，使用镜像
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
```

**3. Git 克隆超时**

```bash
# 增加 Git 超时时间
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999

# 使用 SSH 代替 HTTPS
git config --global url."git@github.com:".insteadOf "https://github.com/"
```

**4. 交互式提示等待输入**

```bash
# 使用非交互模式
./bootstrap.sh -p macos -y -a
```

**5. 脚本权限问题**

```bash
# 确保脚本可执行
chmod +x bootstrap.sh
./bootstrap.sh
```

**调试模式：**

```bash
# 启用 bash 调试
bash -x bootstrap.sh -p macos

# 查看完整输出
./bootstrap.sh -p macos 2>&1 | tee bootstrap.log
```

**手动分步执行：**

如果 bootstrap 持续失败，手动执行步骤：

```bash
# 1. 安装 Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. 安装 chezmoi
brew install chezmoi

# 3. 初始化
export HOMEUP_PROFILE=macos
chezmoi init https://github.com/zopiya/homeup.git

# 4. 应用
chezmoi apply

# 5. 安装包
just install-packages
```

---

### 问题: 包安装失败

**症状：**
- `brew install` 报错
- 某些包找不到
- 依赖冲突

**解决步骤：**

**1. 更新 Homebrew**

```bash
brew update
brew doctor
```

修复 `brew doctor` 报告的所有问题。

**2. 验证包名称**

```bash
# 搜索正确的包名
brew search package-name

# 验证所有包
just packages-verify
```

**3. 检查包可用性**

某些包可能：
- 已重命名
- 已弃用
- 仅在特定平台可用

```bash
brew info package-name  # 查看包信息
```

**4. 解决依赖冲突**

```bash
# 查看依赖树
just packages-deps package-name

# 强制重新安装
brew reinstall package-name

# 解除链接冲突
brew unlink conflicting-package
brew link --overwrite package-name
```

**5. 清理和重试**

```bash
# 清理 Homebrew
just packages-cleanup

# 清理特定包
brew cleanup package-name

# 重新安装
brew install package-name
```

**6. 平台特定问题**

**macOS Casks 问题：**
```bash
# 更新 cask 列表
brew update

# 重新安装 cask
brew reinstall --cask application-name
```

**Linux 问题：**
```bash
# 确保 build-essential 已安装
sudo apt-get install build-essential  # Debian/Ubuntu
sudo dnf groupinstall "Development Tools"  # Fedora
```

**7. 跳过问题包**

如果某个包持续失败：

```bash
# 从 Brewfile 中临时移除
chezmoi edit packages/Brewfile.core
# 注释掉: # brew "problematic-package"

just apply
just install-packages

# 稍后单独调试
brew install problematic-package --verbose
```

---

### 问题: Chezmoi diff 显示大量差异

**症状：**
- `just diff` 显示意外的大量差异
- 文件内容不符合预期
- 模板渲染错误

**解决步骤：**

**1. 检查 Profile 设置**

```bash
just profile
echo $HOMEUP_PROFILE

# 确保 Profile 正确
export HOMEUP_PROFILE=macos  # 或 linux, mini
source ~/.zshrc
```

**2. 验证 Chezmoi 数据**

```bash
just data  # 查看 Chezmoi 使用的变量

# 应该包含：
# - profile: macos/linux/mini
# - os: darwin/linux
# - arch: arm64/amd64
```

**3. 检查模板语法错误**

```bash
# 验证所有模板
just validate

# 调试特定文件
chezmoi execute-template < ~/.local/share/chezmoi/dot_zshrc.tmpl
```

**4. 忽略预期的差异**

某些差异是正常的：
- 时间戳
- 机器特定的设置
- 本地自定义

添加到 `.chezmoiignore`：
```bash
chezmoi edit ~/.local/share/chezmoi/.chezmoiignore.tmpl

# 添加
.config/local/*
*.local
```

**5. 重置到已知状态**

```bash
# 备份当前状态
just backup

# 重新应用所有配置
chezmoi init --apply --force
```

**6. 逐文件检查差异**

```bash
# 查看特定文件的 diff
chezmoi diff ~/.zshrc
chezmoi diff ~/.gitconfig

# 查看模板源
chezmoi cat ~/.zshrc  # 查看渲染后的内容
```

**7. 手动解决冲突**

```bash
# 如果本地修改是正确的，重新添加
chezmoi add ~/.zshrc

# 如果模板是正确的，强制应用
chezmoi apply --force
```

---

### 问题: GPG 签名不工作

**症状：**
- Git 提交时 GPG 错误
- "gpg failed to sign the data"
- 密码提示不显示

**解决步骤：**

**1. 验证 GPG 安装（仅 macOS Profile）**

```bash
which gpg
gpg --version

# 如果未安装
brew install gnupg
```

**2. 检查 GPG 密钥**

```bash
# 列出所有密钥
gpg --list-secret-keys --keyid-format=long

# 如果没有密钥，生成一个
gpg --full-generate-key
```

**3. 配置 Git GPG 密钥**

```bash
# 获取密钥 ID（示例输出中的 ABCD1234）
gpg --list-secret-keys --keyid-format=long
# sec   rsa4096/ABCD1234 2024-01-01 [SC]

# 设置 Git 使用该密钥
git config --global user.signingkey ABCD1234
git config --global commit.gpgsign true
```

**4. 配置 GPG Agent**

```bash
# 设置 GPG_TTY
export GPG_TTY=$(tty)
echo 'export GPG_TTY=$(tty)' >> ~/.zshrc

# 重启 GPG agent
gpgconf --kill gpg-agent
gpg-agent --daemon
```

**5. 配置 Pinentry（macOS）**

```bash
# 安装 pinentry-mac
brew install pinentry-mac

# 配置 GPG 使用它
echo "pinentry-program $(which pinentry-mac)" >> ~/.gnupg/gpg-agent.conf

# 重启 agent
gpgconf --kill gpg-agent
```

**6. 测试 GPG 签名**

```bash
# 测试 GPG 基本功能
echo "test" | gpg --clearsign

# 测试 Git 签名
git commit --allow-empty -m "test gpg signing" -S
```

**7. 权限问题**

```bash
# 修复 .gnupg 目录权限
chmod 700 ~/.gnupg
chmod 600 ~/.gnupg/*
```

**8. 缓存密码**

```bash
# 编辑 gpg-agent.conf
chezmoi edit ~/.gnupg/gpg-agent.conf.tmpl

# 添加（已在 Homeup 中配置）
default-cache-ttl 900
max-cache-ttl 900
```

**临时禁用 GPG 签名：**

如果急需提交：
```bash
git commit --no-gpg-sign -m "message"
# 或临时禁用
git config --global commit.gpgsign false
```

---

### 问题: SSH 配置不生效

**症状：**
- SSH 连接使用错误的密钥
- Agent forwarding 不工作
- 无法连接到 GitHub

**解决步骤：**

**1. 验证 SSH 配置已应用**

```bash
# 检查配置文件
cat ~/.ssh/config

# 重新应用
just apply

# 验证语法
ssh -G github.com | grep -i identityfile
```

**2. 检查 SSH 密钥**

```bash
# 列出已加载的密钥
ssh-add -l

# 如果为空，添加密钥
ssh-add ~/.ssh/id_ed25519

# 生成新密钥（如果需要）
ssh-keygen -t ed25519 -C "your_email@example.com"
```

**3. 测试 SSH 连接**

```bash
# 测试 GitHub
ssh -T git@github.com

# 详细输出调试
ssh -vvv git@github.com
```

**4. SSH Agent 问题**

```bash
# 启动 SSH agent
eval "$(ssh-agent -s)"

# 添加到 shell 配置（已在 Homeup 中）
echo 'eval "$(ssh-agent -s)"' >> ~/.zshrc
```

**5. Agent Forwarding 不工作**

```bash
# 验证本地 agent
echo $SSH_AUTH_SOCK  # 应该有值

# 测试转发
ssh -A user@server 'ssh-add -l'

# 检查服务器 sshd 配置
grep AllowAgentForwarding /etc/ssh/sshd_config  # 应该是 yes
```

**6. 权限问题**

```bash
# 修复 SSH 目录权限
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_*
chmod 644 ~/.ssh/id_*.pub
```

**7. 配置优先级问题**

SSH 配置按以下顺序读取：
1. 命令行选项
2. `~/.ssh/config`
3. `/etc/ssh/ssh_config`

确保你的配置在 `~/.ssh/config` 中：
```bash
chezmoi edit ~/.ssh/config.tmpl
```

**8. 测试特定主机配置**

```bash
# 查看主机配置
ssh -G hostname

# 示例：查看 GitHub 配置
ssh -G github.com
```

---

### 问题: Homebrew 缓存问题

**症状：**
- Homebrew 占用大量磁盘空间
- 安装失败提示缓存错误
- 下载速度慢

**解决步骤：**

**1. 查看缓存大小**

```bash
just brew-size

# 详细查看
du -sh $(brew --cache)
ls -lh $(brew --cache)
```

**2. 清理缓存**

```bash
# 使用 Homeup 命令
just packages-cleanup

# 或手动清理
brew cleanup --prune=all

# 清理特定包的缓存
brew cleanup package-name
```

**3. 删除旧版本**

```bash
# 删除所有旧版本
brew cleanup -s

# 查看可清理的空间
brew cleanup -n
```

**4. 清空整个缓存**

```bash
# 警告：会删除所有缓存文件
rm -rf $(brew --cache)/*
```

**5. 设置缓存清理策略**

```bash
# 自动清理（已在 Homeup 中）
brew cleanup  # 定期运行

# 或添加到 cron
echo "0 0 * * 0 brew cleanup" | crontab -
```

**6. 网络问题导致的缓存失败**

```bash
# 清除失败的下载
brew cleanup

# 重新下载
brew install --force package-name

# 使用镜像（中国用户）
export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles
```

**7. 磁盘空间不足**

```bash
# 检查磁盘空间
df -h

# 清理系统缓存
sudo rm -rf /Library/Caches/Homebrew/*

# 清理用户缓存
rm -rf ~/Library/Caches/Homebrew/*
```

**8. 移动缓存位置**

如果磁盘空间紧张，移动缓存到其他位置：

```bash
# 创建新缓存目录（在大磁盘上）
mkdir -p /path/to/large/disk/homebrew-cache

# 设置环境变量
export HOMEBREW_CACHE=/path/to/large/disk/homebrew-cache
echo 'export HOMEBREW_CACHE=/path/to/large/disk/homebrew-cache' >> ~/.zshrc
```

---

## 高级用法

### 自定义 Profile

如果内置的三个 Profile 不完全满足你的需求，你可以创建自定义 Profile 或扩展现有 Profile。

**方法 1：扩展现有 Profile**

使用模板条件添加自定义逻辑：

```bash
# 编辑 .zshrc 模板
chezmoi edit ~/.config/zsh/.zshrc.tmpl
```

添加基于主机名或其他变量的条件：

```bash
{{- if eq .chezmoi.hostname "work-laptop" }}
# 工作笔记本专属配置
export WORK_MODE=true
source ~/work-specific-config
{{- end }}

{{- if eq .profile "macos" }}
  {{- if eq .chezmoi.hostname "personal-macbook" }}
  # 个人 MacBook 专属配置
  {{- end }}
{{- end }}
```

**方法 2：创建自定义 Brewfile**

为特定场景创建额外的 Brewfile：

```bash
# 创建自定义 Brewfile
touch ~/.local/share/chezmoi/packages/Brewfile.custom

# 编辑它
chezmoi edit packages/Brewfile.custom
```

添加包：
```ruby
# Brewfile.custom - 特定项目工具
brew "terraform"
brew "kubectl"
brew "helm"
```

安装：
```bash
brew bundle --file=packages/Brewfile.custom
```

**方法 3：使用环境变量自定义**

在 `.chezmoi.toml.tmpl` 中添加自定义变量：

```toml
[data]
    profile = "{{ env "HOMEUP_PROFILE" }}"
    custom_env = "{{ env "MY_CUSTOM_ENV" }}"
    is_work = {{ eq (env "WORK_MODE") "true" }}
```

在模板中使用：

```bash
{{- if .is_work }}
# 工作环境配置
{{- end }}
```

**方法 4：创建完全自定义的 Profile**

1. **定义新 Profile：**
   ```bash
   export HOMEUP_PROFILE=myprofile
   ```

2. **创建 Brewfile：**
   ```bash
   cp packages/Brewfile.mini packages/Brewfile.myprofile
   chezmoi edit packages/Brewfile.myprofile
   ```

3. **修改 justfile 支持新 Profile：**
   ```bash
   chezmoi edit justfile
   ```

   添加到 install-packages：
   ```bash
   elif [ "{{PROFILE}}" = "myprofile" ]; then
       brew bundle --file=packages/Brewfile.myprofile
   ```

4. **添加模板条件：**
   ```bash
   {{- if eq .profile "myprofile" }}
   # 自定义 profile 专属配置
   {{- end }}
   ```

---

### 添加私有配置

保护敏感信息的同时保持配置同步。

**方法 1：使用 .chezmoiignore**

忽略包含敏感信息的文件：

```bash
# 编辑 .chezmoiignore
chezmoi edit .chezmoiignore.tmpl
```

添加：
```
.env
.secrets
.config/private/*
.ssh/id_*
.gnupg/private-keys-v1.d/*
```

**方法 2：使用 Chezmoi Template 加密**

使用 age 或 GPG 加密敏感文件：

```bash
# 安装 age
brew install age

# 生成密钥
age-keygen -o ~/.config/chezmoi/key.txt

# 配置 chezmoi 使用 age
chezmoi edit ~/.config/chezmoi/chezmoi.toml
```

添加：
```toml
encryption = "age"
[age]
    identity = "~/.config/chezmoi/key.txt"
    recipient = "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p"
```

添加加密文件：
```bash
chezmoi add --encrypt ~/.secrets
```

**方法 3：使用私有子模块**

将私有配置放在单独的私有仓库：

```bash
# 在 Homeup 中添加子模块
cd ~/.local/share/chezmoi
git submodule add git@github.com:yourusername/private-dotfiles.git private

# 在 .chezmoiignore 中不忽略
# private/
```

**方法 4：使用本地覆盖**

创建本地配置文件覆盖默认值：

```bash
# 在模板中
{{- if stat (joinPath .chezmoi.homeDir ".zshrc.local") }}
source ~/.zshrc.local
{{- end }}
```

在本地创建 `.zshrc.local`（不由 Chezmoi 管理）：
```bash
# ~/.zshrc.local - 本地覆盖，不提交
export SECRET_API_KEY="xxx"
export PRIVATE_CONFIG="yyy"
```

**方法 5：使用 1Password CLI（macOS）**

从 1Password 动态加载密钥：

```bash
# 在模板中
{{- if and (eq .profile "macos") (lookPath "op") }}
export API_KEY="$(op read op://Private/API/credential)"
{{- end }}
```

---

### 集成其他工具

将 Homeup 与其他工具和工作流集成。

**集成 1Password CLI（macOS）**

```bash
# 已在 Brewfile.macos 中
brew "1password-cli"

# 在模板中使用
{{- if lookPath "op" }}
# 从 1Password 加载 SSH 密钥
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
{{- end }}
```

**集成 Mise（运行时管理）**

```bash
# 已在 Brewfile.core 中
brew "mise"

# 配置 Mise
chezmoi edit ~/.config/mise/config.toml
```

示例配置：
```toml
[tools]
node = "20"
python = "3.12"
ruby = "3.3"
```

**集成 Direnv**

自动加载目录特定的环境变量：

```bash
# 添加到 Brewfile
brew "direnv"

# 在 .zshrc 中启用
eval "$(direnv hook zsh)"
```

使用：
```bash
# 在项目目录中
echo "export PROJECT_VAR=value" > .envrc
direnv allow
```

**集成 Docker 和 Kubernetes**

```bash
# 已在相应 Brewfile 中
brew "docker"
brew "kubectl"
brew "k9s"
brew "lazydocker"

# 添加别名
alias k="kubectl"
alias kgp="kubectl get pods"
alias d="docker"
alias dc="docker compose"
```

**集成 Tmux 和 Zellij**

```bash
# 配置 Tmux
chezmoi edit ~/.config/tmux/tmux.conf

# 配置 Zellij
chezmoi edit ~/.config/zellij/config.kdl

# 自动启动会话
if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
    tmux attach || tmux new
fi
```

**集成 Neovim 配置**

```bash
# 添加 Neovim 配置到 Chezmoi
just add ~/.config/nvim

# 或使用 LazyVim/NvChad 等分发版
git clone https://github.com/LazyVim/starter ~/.config/nvim
just add ~/.config/nvim
```

---

### 扩展 Justfile

添加自定义任务到 Justfile。

**添加自定义命令：**

```bash
# 编辑 justfile
chezmoi edit justfile
```

添加你的命令：

```makefile
# ------------------------------------------------------------------------------
# 🎨 Custom Commands
# ------------------------------------------------------------------------------

# Deploy to production server
deploy:
    @echo "Deploying to production..."
    @ssh production "cd /app && git pull && systemctl restart app"

# Sync work projects
sync-work:
    @echo "Syncing work repositories..."
    @rsync -avz ~/work/ work-server:/backup/work/

# Update all development tools
update-dev-tools:
    @echo "Updating dev tools..."
    @mise upgrade
    @npm update -g
    @pip install --upgrade pip

# Start development environment
dev-start:
    @echo "Starting development environment..."
    @tmux new-session -d -s dev
    @tmux send-keys -t dev "cd ~/projects && nvim" C-m
    @tmux split-window -t dev
    @tmux attach -t dev
```

**使用参数：**

```makefile
# Backup specific directory
backup-dir dir:
    @echo "Backing up {{dir}}..."
    @tar -czf ~/backups/{{dir}}-$(date +%Y%m%d).tar.gz {{dir}}

# SSH to server
ssh-to host:
    @echo "Connecting to {{host}}..."
    @ssh user@{{host}}
```

使用：
```bash
just backup-dir ~/important
just ssh-to production.example.com
```

**条件命令：**

```makefile
# macOS specific commands
[macos]
update-macos:
    @echo "Updating macOS..."
    @softwareupdate -ia

# Linux specific commands
[linux]
update-linux:
    @echo "Updating Linux..."
    @sudo apt update && sudo apt upgrade -y
```

**依赖命令：**

```makefile
# Deploy (depends on build and test)
deploy: build test
    @echo "Deploying..."
    @./deploy.sh

build:
    @echo "Building..."
    @npm run build

test:
    @echo "Testing..."
    @npm test
```

---

### 使用 Chezmoi Secrets

管理密钥和敏感配置。

**方法 1：使用模板函数**

```bash
# 从环境变量读取
{{- if env "SECRET_API_KEY" }}
export API_KEY="{{ env "SECRET_API_KEY" }}"
{{- end }}

# 从文件读取
{{- $secret := include "~/.secrets/api-key" }}
export API_KEY="{{ $secret }}"
```

**方法 2：使用 age 加密**

```bash
# 1. 生成 age 密钥对
age-keygen -o ~/.config/chezmoi/key.txt

# 2. 配置 Chezmoi
chezmoi edit ~/.config/chezmoi/chezmoi.toml
```

添加：
```toml
encryption = "age"
[age]
    identity = "~/.config/chezmoi/key.txt"
    recipient = "age1..." # 从 key.txt 复制
```

```bash
# 3. 添加加密文件
chezmoi add --encrypt ~/.secrets.env

# 4. 编辑加密文件
chezmoi edit ~/.secrets.env

# 5. 应用（自动解密）
just apply
```

**方法 3：使用 GPG 加密**

```bash
# 配置 Chezmoi 使用 GPG
chezmoi edit ~/.config/chezmoi/chezmoi.toml
```

添加：
```toml
encryption = "gpg"
[gpg]
    recipient = "your-email@example.com"
```

```bash
# 添加加密文件
chezmoi add --encrypt ~/.secrets

# 编辑（需要 GPG 密钥）
chezmoi edit ~/.secrets
```

**方法 4：使用 1Password**

```bash
# 在模板中使用 op CLI
{{- if lookPath "op" }}
export GITHUB_TOKEN="{{ onepasswordRead "op://Private/GitHub/token" }}"
export AWS_ACCESS_KEY="{{ onepasswordRead "op://Private/AWS/access_key" }}"
{{- end }}
```

**方法 5：使用 Bitwarden**

```bash
# 安装 bw CLI
brew install bitwarden-cli

# 在模板中
{{- if lookPath "bw" }}
{{- $token := output "bw" "get" "password" "github-token" }}
export GITHUB_TOKEN="{{ $token }}"
{{- end }}
```

---

### 多机器配置差异

处理不同机器之间的配置差异。

**方法 1：使用主机名条件**

```bash
# 在模板中
{{- if eq .chezmoi.hostname "work-laptop" }}
# 工作笔记本配置
export WORK_MODE=true
{{- else if eq .chezmoi.hostname "home-desktop" }}
# 家用台式机配置
export PERSONAL_MODE=true
{{- end }}
```

**方法 2：使用自定义数据**

在 `.chezmoi.toml.tmpl` 中定义：

```toml
[data]
    profile = "{{ env "HOMEUP_PROFILE" }}"

    {{- if eq .chezmoi.hostname "work-laptop" }}
    git_email = "work@example.com"
    work_mode = true
    {{- else }}
    git_email = "personal@example.com"
    work_mode = false
    {{- end }}
```

在模板中使用：

```bash
# .gitconfig.tmpl
[user]
    email = {{ .git_email }}

{{- if .work_mode }}
[http]
    proxy = http://proxy.work.com:8080
{{- end }}
```

**方法 3：使用机器特定的文件**

```bash
# 创建机器特定的配置
chezmoi add --template ~/.zshrc.{{ .chezmoi.hostname }}

# 在主配置中 source
{{- $specific := joinPath .chezmoi.homeDir (printf ".zshrc.%s" .chezmoi.hostname) }}
{{- if stat $specific }}
source {{ $specific }}
{{- end }}
```

**方法 4：使用操作系统检测**

```bash
{{- if eq .chezmoi.os "darwin" }}
# macOS 专属
export HOMEBREW_PREFIX="/opt/homebrew"
{{- else if eq .chezmoi.os "linux" }}
# Linux 专属
export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
{{- end }}
```

**方法 5：使用架构检测**

```bash
{{- if eq .chezmoi.arch "arm64" }}
# Apple Silicon 专属配置
{{- else if eq .chezmoi.arch "amd64" }}
# Intel/AMD 专属配置
{{- end }}
```

**方法 6：使用外部配置文件**

创建不由 Chezmoi 管理的本地配置：

```bash
# 在模板中
if [ -f ~/.zshrc.local ]; then
    source ~/.zshrc.local
fi
```

每台机器上手动创建 `~/.zshrc.local`：
```bash
# work-laptop
export WORK_PROXY="http://proxy:8080"

# home-desktop
export PERSONAL_API_KEY="xxx"
```

**最佳实践：**

- ✅ 使用 Profile 处理大的环境差异（macos/linux/mini）
- ✅ 使用主机名处理特定机器的配置
- ✅ 使用本地文件处理敏感/私有配置
- ✅ 保持模板简单，避免过度复杂的条件
- ❌ 不要在模板中硬编码敏感信息

---

## 附录

### 相关资源

- [Chezmoi 官方文档](https://www.chezmoi.io/)
- [Homebrew 文档](https://docs.brew.sh/)
- [Just 手册](https://just.systems/man/en/)
- [Homeup GitHub 仓库](https://github.com/zopiya/homeup)

### 更新日志

参见 [README.md](../README.md) 中的版本历史和 [Git 提交历史](https://github.com/zopiya/homeup/commits/main)。

### 贡献指南

如果你发现本文档有错误或想要添加内容，欢迎：

1. Fork 仓库
2. 编辑 `docs/guide.md`
3. 提交 Pull Request

### 获取帮助

- GitHub Issues: https://github.com/zopiya/homeup/issues
- Discussions: https://github.com/zopiya/homeup/discussions

---

**文档版本**: 1.0
**最后更新**: 2026-01-13
**适用于 Homeup**: v2.0+
