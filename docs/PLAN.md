# PLAN.md - Homeup Multi-Profile Architecture Refactoring

> **Maintainer:** Loop X (Metacognitive Supervisor)
> **Status:** Execution Phase
> **Last Updated:** 2026-01-06
> **Confidence Level:** 0.95 (All blocking points resolved)

---

## Executive Summary

将 `homeup` 从当前的「OS-centric」条件逻辑重构为「Profile-centric」架构，实现 **Single Repo, Multi-Profile** 的目标。三个 Profile（Workstation / Codespace / Server）将成为所有配置决策的第一公民。

---

## 1. Architecture Design (架构设计)

### 1.1 Profile Definitions

| Profile | 描述 | 信任模型 | 私钥 | GUI | 典型场景 |
|---------|------|----------|------|-----|----------|
| **workstation** | 主力开发机 | Trust Anchor | YubiKey + GPG | Full | MacBook, Linux Desktop |
| **codespace** | 云端临时环境 | Borrowed Trust | None (Agent Forwarding) | CLI Only | GitHub Codespaces, DevContainers |
| **server** | 生产/受控端 | CA-Based Trust | None | CLI Only | VPS, Production Servers |

### 1.2 Profile Detection Strategy (置信度: 0.9)

```
                    ┌─────────────────┐
                    │ .chezmoi.toml   │
                    │ [data]          │
                    │ profile = ?     │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
        "workstation"   "codespace"    "server"
              │              │              │
              │              │              │
    ┌─────────┴─────────┐    │    ┌────────┴────────┐
    │ Full Trust        │    │    │ Zero Trust      │
    │ • YubiKey Access  │    │    │ • CA Public Key │
    │ • GPG Signing     │    │    │ • Minimal Tools │
    │ • Full Toolchain  │    │    │ • No Forwarding │
    └───────────────────┘    │    └─────────────────┘
                             │
                   ┌─────────┴─────────┐
                   │ Borrowed Trust    │
                   │ • SSH Forwarding  │
                   │ • CLI Tools Only  │
                   │ • Ephemeral       │
                   └───────────────────┘
```

### 1.3 Configuration Matrix

| Component | Workstation | Codespace | Server |
|-----------|-------------|-----------|--------|
| **SSH Private Keys** | YubiKey / Local + CA Cert | None (Forwarded) | None |
| **SSH Agent Forward** | Yes (to remotes) | Yes (from host) | No |
| **GPG Signing** | Local YubiKey | **Skip** (manual if needed) | Skip |
| **Git Credential** | osxkeychain/cache | cache (short) | cache (minimal) |
| **Packages** | Full (Core + Workstation) | Core + Dev CLI | Core only |
| **GUI Apps** | Yes | No | No |
| **Shell Plugins** | Full | Full (consistent UX) | Full (consistent UX) |
| **Neovim/Tmux** | Full config | Full config | Full config |
| **1Password CLI** | Yes | Optional | No |

### 1.4 Data Flow

```
chezmoi init
    │
    ▼
┌──────────────────────────────────────────────────────────┐
│ .chezmoi.toml.tmpl                                       │
│ ┌──────────────────────────────────────────────────────┐ │
│ │ [data]                                               │ │
│ │   profile = "workstation"  # or codespace/server    │ │
│ │   name = "zopiya"                                   │ │
│ │   email = "i@zopiya.com"                            │ │
│ │   signingkey = "4520C731F79D0C82"                   │ │
│ └──────────────────────────────────────────────────────┘ │
└───────────────────────────┬──────────────────────────────┘
                            │
                            ▼
              ┌─────────────────────────────┐
              │ Template Resolution Order: │
              │ 1. {{ .profile }}          │
              │ 2. {{ .chezmoi.os }}       │
              │ 3. {{ .chezmoi.arch }}     │
              └─────────────────────────────┘
```

---

## 2. Task Breakdown (任务拆解)

### Phase 0: Foundation (基础设施) — COMPLETED

| # | Task | Status | Confidence | Notes |
|---|------|--------|------------|-------|
| 0.1 | Define profile schema in `.chezmoi.toml.tmpl` | [x] Done | 0.95 | Added `profile` with env override |
| 0.2 | Create `.chezmoitemplates/profile-guard.tmpl` | [x] Done | 0.85 | Reusable validation + capability flags |
| 0.3 | Update `.chezmoiignore.tmpl` for profile-based exclusion | [x] Done | 0.8 | Excludes GUI/security per profile |
| 0.4 | Create `PROFILES.md` documentation | [x] Done | 0.9 | Full user guide created |

### Phase 1: Gatekeeper Layer (守门人) — COMPLETED

| # | Task | Status | Confidence | Notes |
|---|------|--------|------------|-------|
| 1.1 | Refactor `bootstrap.sh` with profile detection | [x] Done | 0.95 | 3-in-1: env + auto + interactive |
| 1.2 | Add profile validation in install script | [x] Done | 0.95 | validate_profile() function |
| 1.3 | Create profile-specific package lists | [ ] Pending | 0.9 | → Moved to Phase 6 |

### Phase 2: SSH Configuration — COMPLETED

| # | Task | Status | Confidence | Notes |
|---|------|--------|------------|-------|
| 2.1 | Expand `private_dot_ssh/config.tmpl` profile logic | [x] Done | 0.95 | Full 3-profile support |
| 2.2 | Add Codespace-specific SSH settings | [x] Done | 0.95 | No agent forward, borrowed trust |
| 2.3 | Implement CA-based trust for Server profile | [x] Done | 0.9 | Minimal config, CA on sshd side |

### Phase 3: GPG Configuration — COMPLETED

| # | Task | Status | Confidence | Notes |
|---|------|--------|------------|-------|
| 3.1 | Profile-aware `gpg-agent.conf.tmpl` | [x] Done | 0.95 | Workstation: full, others: minimal stub |
| 3.2 | Update `gpg.conf` for profile | [x] Skip | - | Static config OK for all profiles |
| 3.3 | Conditional `security/gpg.inc.tmpl` | [x] Done | 0.95 | Agent only launched on workstation |
| 3.4 | Handle Codespace GPG forwarding | [x] Done | 0.95 | Disabled by design (user decision) |

### Phase 4: Git Configuration — COMPLETED

| # | Task | Status | Confidence | Notes |
|---|------|--------|------------|-------|
| 4.1 | Profile-based signing in `config.tmpl` | [x] Done | 0.95 | Workstation: GPG, others: disabled |
| 4.2 | Credential helper per profile | [x] Done | 0.95 | macOS: keychain, others: timed cache |
| 4.3 | Identity management | [x] Done | - | Same identity file for all profiles |

### Phase 5: Shell Configuration — COMPLETED

| # | Task | Status | Confidence | Notes |
|---|------|--------|------------|-------|
| 5.1 | Profile-aware `exports.zsh.tmpl` | [x] Skip | - | No changes needed |
| 5.2 | Conditional plugin loading in `sheldon/plugins.toml` | [x] Skip | - | Same plugins, graceful degradation |
| 5.3 | Profile-specific aliases | [x] Skip | - | Consistent UX per decision |
| 5.4 | Security module conditional loading | [x] Done | 0.95 | GPG/1Password/YubiKey workstation only |

### Phase 6: Package Management — COMPLETED

| # | Task | Status | Confidence | Notes |
|---|------|--------|------------|-------|
| 6.1 | Create `packages/Brewfile.core` (shared) | [x] Done | 0.95 | Essential CLI for all profiles |
| 6.2 | Keep `packages/Brewfile.macos/linux` | [x] Done | 0.95 | Full workstation toolchain |
| 6.3 | Create `packages/Brewfile.codespace` | [x] Done | 0.95 | Dev tools, no GUI/security HW |
| 6.4 | Create `packages/Brewfile.server` | [x] Done | 0.95 | Minimal additions to core |

### Phase 7: Validation & Testing — COMPLETED

| # | Task | Status | Confidence | Notes |
|---|------|--------|------------|-------|
| 7.1 | Create `chezmoi doctor` integration | [x] Skip | - | Manual validation preferred |
| 7.2 | Verify template syntax | [x] Done | 0.95 | All templates validated |
| 7.3 | Document rollback procedure | [x] Done | 0.95 | In PROFILES.md |

---

## 3. Resolved Decisions (已决策)

### [x] Decision 1.1: Profile Detection — 3-in-1 Strategy

**Final Decision:** 自动检测 + 环境变量覆盖 + 延迟交互确认

```bash
# Priority Order:
# 1. HOMEUP_PROFILE environment variable (highest priority)
# 2. Auto-detection based on environment signals
# 3. Interactive prompt with timeout (fallback, allows override)

detect_profile() {
    # Explicit override takes precedence
    if [[ -n "${HOMEUP_PROFILE:-}" ]]; then
        echo "$HOMEUP_PROFILE"
        return
    fi

    # Auto-detection
    if [[ -n "${CODESPACES:-}" || -n "${REMOTE_CONTAINERS:-}" ]]; then
        detected="codespace"
    elif [[ -n "${SSH_CONNECTION:-}" && -z "${DISPLAY:-}" ]]; then
        detected="server"
    else
        detected="workstation"
    fi

    # Interactive confirmation with timeout (3 seconds)
    echo "Detected profile: $detected (press Enter to confirm, or type override)"
    read -t 3 -r override || true
    echo "${override:-$detected}"
}
```

---

### [x] Decision 2.3: SSH CA Configuration

**Final Decision:** Workstation 配置 CA 证书认证，Loop X 负责最佳实践

**SSH CA Best Practice (Loop X Recommendation):**

```
┌─────────────────────────────────────────────────────────────┐
│                    SSH CA Architecture                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Workstation (Trust Anchor)                                 │
│  ├── ~/.ssh/id_ed25519           # Private key              │
│  ├── ~/.ssh/id_ed25519-cert.pub  # CA-signed certificate    │
│  └── ~/.ssh/config               # Host configurations      │
│                                                             │
│  Server (Trusting Party)                                    │
│  └── /etc/ssh/sshd_config                                   │
│      └── TrustedUserCAKeys /etc/ssh/ca.pub                  │
│                                                             │
│  Certificate contains:                                      │
│  └── principals: [zopiya, deploy, admin]  # Allowed users   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**SSH Config Strategy:**

| Scenario | Configuration |
|----------|---------------|
| **Global Default** | `User zopiya` (most common login) |
| **Specific Host Override** | `Host prod-*` → `User deploy` |
| **Certificate Auto-Discovery** | SSH auto-finds `*-cert.pub` next to private key |

**Implementation:**
- 不在 SSH config 中硬编码所有用户，而是：
  - 设置合理的 `User` 默认值
  - 证书的 `principals` 字段控制可用用户名
  - 特定 Host 块按需覆盖

---

### [x] Decision 3.4: Codespace GPG — Skip by Default

**Final Decision:** Codespace 默认禁用 GPG 签名

```toml
# Codespace profile: ~/.config/git/config
[commit]
    gpgsign = false

[tag]
    gpgsign = false
```

**Rationale:**
- 避免临时环境的签名配置复杂度
- 需要时用户可手动开启
- 保持 Codespace 的轻量和即用性

---

### [x] Decision 5.2: Shell Experience — Consistent Across Profiles

**Final Decision:** 所有 Profile 使用相同的 Shell 插件集

**Rationale:**
- 核心 CLI 体验必须一致（用户要求）
- Sheldon plugins.toml 不模板化
- 差异通过 packages 层面控制（工具是否安装）
- 插件即使依赖工具不存在也会 graceful degradation

---

## 4. Proposed Implementation Order

```
Phase 0 (Foundation)     ████████████████████  [Week 1]
    │
    ▼
Phase 1 (Gatekeeper)     ██████████████        [After Block 1.1 resolved]
    │
    ├──────────────┬──────────────┐
    │              │              │
    ▼              ▼              ▼
Phase 2         Phase 3        Phase 4
(SSH)           (GPG)          (Git)
████████        ████████       ████████  [Parallel execution possible]
    │              │              │
    └──────────────┴──────────────┘
                   │
                   ▼
Phase 5 (Shell)          ████████████████████
    │
    ▼
Phase 6 (Packages)       ████████████████████
    │
    ▼
Phase 7 (Validation)     ██████████
```

---

## 5. Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Profile 误判 | Medium | High | 显式配置 + 验证脚本 |
| GPG Forwarding 复杂 | High | Medium | Codespace 可降级为无签名 |
| Sheldon 不兼容 | Low | Low | 使用模板生成 |
| 现有配置回归 | Medium | High | 增量修改 + chezmoi diff |
| Bootstrap 破坏 | Low | Critical | 保留原脚本作为 fallback |

---

## 6. Success Criteria

- [ ] `chezmoi init --apply` 在三种 profile 下均能成功
- [ ] Workstation: GPG 签名正常，SSH Agent 可用
- [ ] Codespace: SSH Forwarding 正常，可访问私有仓库
- [ ] Server: 最小化安装，无敏感数据残留
- [ ] 切换 profile 只需修改 `.chezmoi.toml` 中的一个值
- [ ] 所有配置文件有清晰的 profile 注释

---

## 7. Rollback Plan

如果重构失败：
1. Git: `git checkout HEAD~N` 回退到重构前
2. Chezmoi: `chezmoi apply --force` 重新应用
3. 手动: 保留原始 `config.tmpl` 备份

---

## Appendix A: File Change Summary

| File | Action | Profile Logic |
|------|--------|---------------|
| `.chezmoi.toml.tmpl` | Modify | Add `profile` field |
| `.chezmoitemplates/profile-guard.tmpl` | Create | Validation snippet |
| `.chezmoiignore.tmpl` | Modify | Profile-based ignore |
| `bootstrap.sh` | Modify | Profile detection |
| `private_dot_ssh/config.tmpl` | Modify | Expand profile logic |
| `private_dot_gnupg/gpg-agent.conf.tmpl` | Modify | Profile conditionals |
| `private_dot_gnupg/gpg.conf` | Modify → Template | Profile conditionals |
| `dot_config/git/config.tmpl` | Modify | Signing per profile |
| `dot_config/zsh/exports.zsh.tmpl` | Modify | Path adjustments |
| `dot_config/security/*.tmpl` | Modify | Conditional loading |
| `packages/Brewfile.*` | Restructure | Split by profile |

---

**End of PLAN.md**

---

## Loop X Status

**Current State:** IMPLEMENTATION COMPLETE

**All Phases Completed:**
- [x] Phase 0: Foundation (Profile schema, templates, documentation)
- [x] Phase 1: Gatekeeper (3-in-1 profile detection in bootstrap.sh)
- [x] Phase 2: SSH Configuration (CA support, profile-aware agent forwarding)
- [x] Phase 3: GPG Configuration (Workstation-only agent)
- [x] Phase 4: Git Configuration (Profile-based signing)
- [x] Phase 5: Shell Configuration (Consistent UX, conditional security modules)
- [x] Phase 6: Package Management (Core + Profile-specific Brewfiles)
- [x] Phase 7: Validation (Template syntax verified)

**Files Modified/Created:**
```
Modified:
  .chezmoi.toml.tmpl              - Added profile field
  .chezmoiignore.tmpl             - Profile-based exclusions
  bootstrap.sh                     - CLI args + one-liner support (v6.0.0)
  private_dot_ssh/config.tmpl     - Full 3-profile SSH support
  private_dot_gnupg/gpg-agent.conf.tmpl - Profile-aware agent
  dot_config/git/config.tmpl      - Profile-based signing
  dot_config/zsh/dot_zshrc.tmpl   - Conditional security modules
  dot_config/security/*.tmpl       - Profile guards added
  .chezmoiscripts/run_once_*.tmpl - Profile-based installation

Created:
  .chezmoitemplates/profile-guard.tmpl - Reusable profile helper
  packages/Brewfile.core          - Shared CLI tools
  packages/Brewfile.codespace     - Dev tools (no GUI/HW)
  packages/Brewfile.server        - Minimal additions
  PROFILES.md                     - User documentation
  PLAN.md                         - This file
```

**Bootstrap CLI (v6.0.0):**
```bash
# One-liner for new machine
./bootstrap.sh -p workstation -r zopiya/homeup -a

# Options:
#   -p, --profile <name>   workstation | codespace | server
#   -r, --repo <repo>      Dotfiles repo (user/repo or full URL)
#   -a, --apply            Auto-apply chezmoi
#   -y, --yes              Non-interactive mode
```

**Next Steps for User:**
1. Run `chezmoi diff` to preview changes
2. Run `chezmoi apply` to apply configuration
3. Or test with different profile: `./bootstrap.sh -p codespace --dry-run`
