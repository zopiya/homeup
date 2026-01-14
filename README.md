# Homeup

> 现代化、安全、智能的 Dotfiles 管理系统

<div align="center">

[![CI](https://github.com/zopiya/homeup/actions/workflows/ci.yml/badge.svg)](https://github.com/zopiya/homeup/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

[快速开始](#-快速开始) • [特性](#-特性) • [文档](#-文档) • [场景](#-适用场景)

</div>

---

## 简介

Homeup 是一套面向独立开发者和技术团队的生产级 Dotfiles 管理方案，通过三层架构设计实现**一套配置，多种环境**无缝切换。

### 核心亮点

- 🎯 **三种场景，统一管理** - macOS 个人开发机 / Linux 服务器 / 容器临时环境
- 🔒 **分层安全设计** - 根据环境信任级别自动调整安全策略
- 📦 **102 个精选工具** - 经过筛选的现代化 CLI 工具链
- 🤖 **全流程自动化** - 从安装到日常维护的完整自动化
- ✅ **生产级质量** - 8 个并行 CI 测试，全平台验证

---

## 🚀 快速开始

### 一键安装

```bash
# 默认安装 Mini Profile（安全模式），如需完整环境请参阅下方手动安装
curl -fsSL https://raw.githubusercontent.com/zopiya/homeup/main/bootstrap.sh | bash
```

### 手动安装

```bash
# 1. 克隆仓库
git clone https://github.com/zopiya/homeup.git
cd homeup

# 2. 运行 bootstrap
# 默认安装 Mini Profile
./bootstrap.sh

# 或指定 Profile 安装完整环境
# ./bootstrap.sh -p macos
# ./bootstrap.sh -p linux

# 3. 查看变化
just diff

# 4. 应用配置
just apply

# 5. 安装包
just install-packages

# 6. 验证安装
just doctor
```

**详细步骤**: 查看 [使用手册 - 快速开始](docs/guide.md#快速开始)

---

## 🎯 Profiles

| Profile | 适用场景 | 包数量 | 核心特性 |
|---------|---------|--------|---------|
| **macOS** | 个人开发机 | 99 | GUI 应用 + GPG 签名 + 硬件密钥 |
| **Linux** | 服务器 / SSH 开发 | 79 | 无头模式 + 服务器监控 |
| **Mini** | 容器 / Codespaces | 23 | 轻量快速 + 独立配置 |

**了解更多**: [架构设计 - Profile 隔离策略](docs/architecture.md#profile-隔离策略)

---

## ✨ 特性

### 分层架构

```
Core 层 (64 包)
├─ macOS Profile (+35 包)
├─ Linux Profile (+15 包)
└─ Mini Profile (23 包，独立)
```

- **Core**: 跨平台通用工具（zsh, neovim, git, tmux 等）
- **macOS**: GUI 应用 + 安全工具（1Password, GPG, YubiKey）
- **Linux**: 服务器监控工具（glances, lnav, bmon）
- **Mini**: 容器最小化配置（快速启动）

**详细说明**: [架构设计 - 三层继承模型](docs/architecture.md#三层继承模型)

### 安全策略

| Profile | GPG 签名 | 硬件密钥 | 密码管理 |
|---------|---------|---------|---------|
| macOS | ✅ 本地启用 | ✅ YubiKey | ✅ 1Password |
| Linux | ❌ Forwarding | ❌ 无 | ❌ 无 |
| Mini | ❌ 禁用 | ❌ 无 | ❌ 无 |

**原则**: 敏感密钥仅保存在个人设备，远程环境通过 SSH Agent Forwarding 使用。

### 自动化

- **环境检测**: 自动识别 OS、架构、容器环境
- **包管理**: 验证、安装、更新、清理
- **配置应用**: 模板渲染、权限设置
- **健康检查**: doctor, debug, rescue

---

## 📚 文档

| 文档 | 说明 | 适合人群 |
|------|------|---------|
| [架构设计](docs/architecture.md) | 项目设计理念和技术栈 | 想深入了解的用户 |
| [工具介绍](docs/tools.md) | 102 个工具简要说明 | 想了解工具作用 |
| [最佳实践](docs/best-practices.md) | Dev/Ops 场景工具组合 | 想优化工作流程 |
| [使用手册](docs/guide.md) | 完整命令参考和 FAQ | 日常使用和问题排查 |

**文档中心**: [docs/README.md](docs/README.md)

---

## 💼 适用场景

### Dev 场景

- [前端开发](docs/best-practices.md#前端开发) - React/Vue + Node.js + pnpm
- [后端开发](docs/best-practices.md#后端开发) - Go/Python + Docker + API 工具
- [全栈开发](docs/best-practices.md#全栈开发) - Monorepo + 容器化
- [数据科学](docs/best-practices.md#数据科学ml) - Python + Jupyter + 数据工具
- [系统编程](docs/best-practices.md#系统编程) - Rust/C++ + 性能分析
- [Web3 开发](docs/best-practices.md#web3区块链开发) - Hardhat/Foundry

### Ops 场景

- [容器化部署](docs/best-practices.md#容器化部署) - Docker/K8s + k9s + helm
- [CI/CD 流水线](docs/best-practices.md#cicd-流水线) - GitHub Actions + just
- [基础设施即代码](docs/best-practices.md#基础设施即代码) - Terraform + Ansible
- [监控和可观测性](docs/best-practices.md#监控和可观测性) - btop + lnav + gping
- [安全和合规](docs/best-practices.md#安全和合规) - trivy + gitleaks + age
- [数据库管理](docs/best-practices.md#数据库管理) - pgcli + DBeaver + restic

---

## 🛠️ 常用命令

```bash
# 日常使用
just apply          # 应用配置
just diff           # 查看变化
just status         # 检查状态

# 包管理
just install-packages   # 安装包
just packages-info      # 包统计
just packages-outdated  # 检查更新
just upgrade            # 更新所有

# 诊断
just doctor         # 健康检查
just debug          # 调试信息
just rescue         # 自动修复

# Profile 管理
just profile        # 查看当前 Profile
just profile-diff macos linux  # 对比 Profiles
```

**完整命令列表**: [使用手册 - 命令参考](docs/guide.md#命令参考)

---

## 🏗️ 项目结构

```
homeup/
├── bootstrap.sh           # 引导安装脚本
├── justfile               # 80+ 自动化任务
├── packages/              # Brewfile 配置
│   ├── Brewfile.core      # 64 个通用工具
│   ├── Brewfile.macos     # 35 个 macOS 工具
│   ├── Brewfile.linux     # 15 个 Linux 工具
│   └── Brewfile.mini      # 23 个容器工具
├── dot_config/            # Dotfiles
│   ├── zsh/
│   ├── git/
│   ├── nvim/
│   └── ...
├── private_dot_ssh/       # SSH 配置（模板）
├── .github/workflows/     # CI/CD 工作流
└── docs/                  # 完整文档
    ├── architecture.md    # 架构设计
    ├── tools.md           # 工具介绍
    ├── best-practices.md  # 最佳实践
    └── guide.md           # 使用手册
```

---

## 🧪 CI/CD

每次提交都经过 **8 个测试任务** 验证：

- ✅ macOS 完整测试（GPG + YubiKey）
- ✅ Debian 测试（mini + linux）
- ✅ Fedora 测试（mini + linux）
- ✅ 模板语法验证
- ✅ Shell 脚本 Lint
- ✅ Justfile 功能测试
- ✅ 包可用性验证
- ✅ Just + Chezmoi 集成测试

**CI 状态**: [![CI](https://github.com/zopiya/homeup/actions/workflows/ci.yml/badge.svg)](https://github.com/zopiya/homeup/actions/workflows/ci.yml)

---

## 🤝 贡献

欢迎贡献！方式包括：

- 🐛 [提交 Issue](https://github.com/zopiya/homeup/issues) - 报告问题
- 💡 [功能建议](https://github.com/zopiya/homeup/discussions) - 分享想法
- 🔧 [Pull Request](https://github.com/zopiya/homeup/pulls) - 提交改进
- 📝 [改进文档](docs/) - 完善文档

**贡献指南**: 查看 [CONTRIBUTING.md](CONTRIBUTING.md)

---

## 📄 许可证

[MIT License](LICENSE) - 自由使用和修改

---

## 🙏 致谢

本项目基于以下优秀项目：

- [Chezmoi](https://www.chezmoi.io/) - Dotfiles 管理
- [Homebrew](https://brew.sh/) - 包管理器
- [Just](https://github.com/casey/just) - 任务运行器

---

<div align="center">

**Made with ❤️ by [zopiya](https://github.com/zopiya)**

如果这个项目对你有帮助，请给个 ⭐️！

[快速开始](docs/guide.md#快速开始) • [查看文档](docs/README.md) • [提交问题](https://github.com/zopiya/homeup/issues)

</div>
