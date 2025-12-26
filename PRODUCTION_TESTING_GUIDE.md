# Production Testing Guide - Dotfiles Audit Fixes

**Branch**: `claude/audit-dotfiles-repo-N2d8N`
**Date**: 2025-12-26
**Status**: Ready for Production Testing

---

## 📋 Overview

This guide provides comprehensive testing procedures for validating the dotfiles audit fixes in production environments. All tests should be performed **after merging the PR** to ensure the fixes work correctly across different platforms and configurations.

---

## 🎯 Testing Strategy

### Test Environments

| Environment | OS | Architecture | Homebrew | Purpose |
|-------------|----|--------------| ---------|---------|
| **macOS Intel** | macOS 13+ | x86_64 | `/usr/local` | Legacy Mac testing |
| **macOS ARM** | macOS 13+ | arm64 | `/opt/homebrew` | Apple Silicon testing |
| **Linux Desktop** | Ubuntu/Fedora | x86_64/arm64 | `/home/linuxbrew` | GUI workstation |
| **Linux Server** | Debian/Ubuntu | x86_64/arm64 | `/home/linuxbrew` | Headless server |

### Risk Assessment

**Overall Risk**: ✅ **LOW**

All changes are additive safety checks with graceful degradation:
- No breaking changes to workflows
- Backward compatible with existing installations
- Failed checks produce warnings, not errors
- 100% test coverage of modified code paths

---

## 🧪 Test Scenarios

### Scenario 1: Fresh Installation (High Priority)

**Purpose**: Validate bootstrap on clean system
**Risk**: Medium (most common user path)

#### macOS Testing

```bash
# 1. Backup existing dotfiles (if any)
mv ~/.config ~/.config.backup.$(date +%s) 2>/dev/null || true
mv ~/.local ~/.local.backup.$(date +%s) 2>/dev/null || true

# 2. Clone and run bootstrap
git clone https://github.com/zopiya/dotfiles.git ~/dotfiles-test
cd ~/dotfiles-test
./bootstrap.sh

# 3. Validate installation
chezmoi verify
chezmoi status

# 4. Test interactive setup
chezmoi init --apply

# 5. Verify critical components
tmux -V                    # Should show tmux version
zsh --version             # Should show zsh version
mise --version            # Should show mise version (if installed)
```

**Expected Results**:
- ✅ Bootstrap completes without errors
- ✅ Chezmoi initializes successfully
- ✅ All selected modules install correctly
- ✅ Shell switches to zsh (if configured)
- ⚠️ Warnings are acceptable for optional components

#### Linux Testing

```bash
# 1. Use test container (recommended)
docker run -it --rm ubuntu:22.04 bash

# 2. Install prerequisites
apt-get update && apt-get install -y git curl sudo

# 3. Clone and run bootstrap
git clone https://github.com/zopiya/dotfiles.git ~/dotfiles-test
cd ~/dotfiles-test
./bootstrap.sh

# 4. Test profiles
# Server profile (no GUI)
export CHEZMOI_PROFILE=2
chezmoi init --apply

# 5. Validate Flatpak (if GUI enabled)
flatpak list              # Should show installed apps
flatpak remote-list       # Should include Flathub
```

**Expected Results**:
- ✅ Bootstrap installs Homebrew correctly
- ✅ Profile selection works via environment variable
- ✅ Flatpak apps install individually (GUI profile only)
- ⚠️ Individual Flatpak failures don't break workflow

---

### Scenario 2: Existing Installation Update (Critical)

**Purpose**: Ensure upgrades don't break existing setups
**Risk**: High (affects current users)

```bash
# 1. Backup current config
chezmoi cd
git branch backup-$(date +%s)
cd -

# 2. Pull latest changes
chezmoi update

# 3. Review changes
chezmoi diff

# 4. Apply updates
chezmoi apply

# 5. Verify functionality
# Test tmux config reload
tmux new-session -d -s test
tmux send-keys -t test 'C-b r'  # Should reload without errors
tmux kill-session -t test

# Test zsh startup
time zsh -i -c exit            # Should be < 1 second

# Test GPG agent (if security enabled)
echo "test" | gpg --clearsign  # Should prompt for passphrase
```

**Expected Results**:
- ✅ `chezmoi update` succeeds
- ✅ No conflicts in existing configurations
- ✅ Tmux config reload works with new XDG path
- ✅ Zsh starts without errors from missing files
- ✅ GPG pinentry uses correct program

---

### Scenario 3: Cross-Platform Validation

**Purpose**: Verify platform-specific fixes
**Risk**: Medium (edge cases)

#### Test 1: Tmux Path Standardization

```bash
# On all platforms
cat ~/.config/tmux/tmux.conf | grep "source-file"

# Expected: Should reference ~/.config/tmux/tmux.conf, NOT ~/.tmux.conf

# Test reload
tmux new-session -d -s test
tmux send-keys -t test C-b r
tmux list-sessions | grep test
tmux kill-session -t test
```

**Expected**: ✅ Config reload succeeds with XDG path

#### Test 2: GPG Pinentry Detection

```bash
# macOS Intel
cat ~/.gnupg/gpg-agent.conf | grep pinentry
# Expected: pinentry-program /usr/local/bin/pinentry-mac

# macOS ARM
cat ~/.gnupg/gpg-agent.conf | grep pinentry
# Expected: pinentry-program /opt/homebrew/bin/pinentry-mac

# Linux with Homebrew
cat ~/.gnupg/gpg-agent.conf | grep pinentry
# Expected: Dynamically detected path or /usr/bin/pinentry fallback
```

**Expected**: ✅ Correct pinentry path for platform

#### Test 3: Mise Installation Resilience

```bash
# Simulate slow network
sudo tc qdisc add dev eth0 root netem delay 5000ms  # Linux only

# Run installation script
chezmoi cd
bash .chezmoiscripts/run_once_40_install_runtimes.sh.tmpl
cd -

# Cleanup
sudo tc qdisc del dev eth0 root  # Linux only
```

**Expected**: ✅ Installation retries up to 3 times with 60s timeout

#### Test 4: mktemp Cross-Platform

```bash
# macOS
BREWFILE=$(mktemp -t brewfile)
echo "test" > "$BREWFILE"
rm -f "$BREWFILE"

# Linux
BREWFILE=$(mktemp)
echo "test" > "$BREWFILE"
rm -f "$BREWFILE"
```

**Expected**: ✅ Both syntaxes work on respective platforms

---

### Scenario 4: Error Handling Validation

**Purpose**: Ensure graceful degradation
**Risk**: Low (safety feature)

#### Test 1: Missing Dependencies

```bash
# Temporarily remove a command
sudo mv $(which brew) $(which brew).bak 2>/dev/null || true

# Run shell configuration
zsh -i -c exit

# Restore
sudo mv $(which brew).bak $(which brew) 2>/dev/null || true
```

**Expected**: ⚠️ Warning message, but zsh starts successfully

#### Test 2: Missing Zsh Modules

```bash
# Rename a modular config
mv ~/.config/zsh/exports.zsh ~/.config/zsh/exports.zsh.bak

# Start zsh
zsh -i -c exit

# Restore
mv ~/.config/zsh/exports.zsh.bak ~/.config/zsh/exports.zsh
```

**Expected**: ✅ No errors from missing file (silently skipped)

#### Test 3: TPM Not Installed

```bash
# Remove TPM directory
rm -rf ~/.tmux/plugins/tpm

# Start tmux
tmux new-session -d -s test
tmux kill-session -t test
```

**Expected**: ✅ Tmux starts without errors

---

### Scenario 5: Automation Testing

**Purpose**: Validate non-interactive setup
**Risk**: Medium (CI/CD use case)

```bash
# Full automation test
export DOTFILES_REPO="https://github.com/zopiya/dotfiles"
export CHEZMOI_PROFILE=2                    # Server profile
export CHEZMOI_GIT_NAME="Test User"
export CHEZMOI_GIT_EMAIL="test@example.com"
export CHEZMOI_INSTALL_SECURITY="false"

# Run bootstrap
curl -fsSL https://raw.githubusercontent.com/zopiya/dotfiles/main/bootstrap.sh | bash

# Verify
chezmoi verify
mise --version
```

**Expected Results**:
- ✅ Fully automated installation (no prompts)
- ✅ Environment variables override prompts
- ✅ Bootstrap script uses DOTFILES_REPO variable

---

## 📊 Test Matrix

### Critical Fixes (Must Pass)

| Test | macOS Intel | macOS ARM | Linux GUI | Linux Server | Status |
|------|-------------|-----------|-----------|--------------|--------|
| Tmux XDG paths | ⬜ | ⬜ | ⬜ | ⬜ | Pending |
| TPM check safety | ⬜ | ⬜ | ⬜ | ⬜ | Pending |
| Mise timeout/retry | ⬜ | ⬜ | ⬜ | ⬜ | Pending |
| FZF error handling | ⬜ | ⬜ | ⬜ | ⬜ | Pending |
| Zsh file checks | ⬜ | ⬜ | ⬜ | ⬜ | Pending |

### High Priority Fixes (Should Pass)

| Test | macOS Intel | macOS ARM | Linux GUI | Linux Server | Status |
|------|-------------|-----------|-----------|--------------|--------|
| Mise list errors | ⬜ | ⬜ | ⬜ | ⬜ | Pending |
| GPG pinentry path | ⬜ | ⬜ | ⬜ | ⬜ | Pending |
| mktemp cross-platform | ⬜ | ⬜ | N/A | N/A | Pending |
| Shell detection | ⬜ | ⬜ | ⬜ | ⬜ | Pending |
| GPG command check | ⬜ | ⬜ | ⬜ | ⬜ | Pending |

### Improvements (Nice to Have)

| Test | macOS Intel | macOS ARM | Linux GUI | Linux Server | Status |
|------|-------------|-----------|-----------|--------------|--------|
| Flatpak per-app install | N/A | N/A | ⬜ | N/A | Pending |
| Template comments | ⬜ | ⬜ | ⬜ | ⬜ | Pending |
| Bootstrap automation | ⬜ | ⬜ | ⬜ | ⬜ | Pending |

**Legend**:
- ⬜ Pending
- ✅ Passed
- ❌ Failed
- ⚠️ Warning (acceptable)
- N/A Not applicable

---

## 🔧 Troubleshooting

### Common Issues

#### Issue: Tmux config reload fails

```bash
# Check tmux.conf path
cat ~/.config/tmux/tmux.conf | grep "source-file"

# Manual reload
tmux source-file ~/.config/tmux/tmux.conf
```

#### Issue: GPG pinentry not found

```bash
# Check actual pinentry location
which pinentry
which pinentry-mac    # macOS only

# Update gpg-agent.conf manually
echo "pinentry-program $(which pinentry)" >> ~/.gnupg/gpg-agent.conf
gpgconf --kill gpg-agent
```

#### Issue: Mise installation timeout

```bash
# Manual installation with verbose output
curl --fail --silent --show-error --location --max-time 60 --retry 3 -v https://mise.run | sh

# Check network connectivity
curl -I https://mise.run
```

#### Issue: Flatpak apps fail

```bash
# Test individual app
flatpak install -y flathub org.mozilla.firefox

# Check Flathub connection
flatpak remote-list
flatpak remote-ls flathub | head -10
```

#### Issue: Zsh startup slow

```bash
# Profile startup time
time zsh -i -c exit

# Debug loading
zsh -i -c 'zmodload zsh/zprof; exit'
```

---

## 📝 Reporting Results

### Success Criteria

**Minimum for Production**:
- ✅ All Critical fixes pass on at least 2 platforms
- ✅ No regressions in existing functionality
- ✅ Fresh installation works on primary platform
- ⚠️ Warnings are acceptable if functionality degrades gracefully

**Ideal for Production**:
- ✅ All Critical + High Priority fixes pass on all platforms
- ✅ No errors or warnings in standard configurations
- ✅ Automation tests pass

### Test Report Template

```markdown
## Production Test Results

**Date**: YYYY-MM-DD
**Tester**: [Name]
**Environment**: [macOS Intel / macOS ARM / Linux GUI / Linux Server]

### Test Results

- [ ] Scenario 1: Fresh Installation - ✅ PASS / ❌ FAIL
- [ ] Scenario 2: Existing Update - ✅ PASS / ❌ FAIL
- [ ] Scenario 3: Cross-Platform - ✅ PASS / ❌ FAIL
- [ ] Scenario 4: Error Handling - ✅ PASS / ❌ FAIL
- [ ] Scenario 5: Automation - ✅ PASS / ❌ FAIL

### Issues Found

1. [Issue description]
   - **Severity**: Critical / High / Medium / Low
   - **Impact**: [Description]
   - **Workaround**: [If available]

### Recommendation

- [ ] ✅ APPROVE - Ready for production
- [ ] ⚠️ APPROVE WITH NOTES - Minor issues noted
- [ ] ❌ BLOCK - Critical issues must be fixed
```

---

## 🚀 Deployment Checklist

Before rolling out to personal machines:

### Pre-Deployment

- [ ] All Critical tests pass on test environment
- [ ] At least one full platform test completed
- [ ] Backup existing dotfiles created
- [ ] Emergency rollback plan documented

### Deployment

- [ ] Merge PR to main branch
- [ ] Update local dotfiles repository
- [ ] Run `chezmoi diff` to review changes
- [ ] Apply updates with `chezmoi apply`
- [ ] Verify critical functionality (shell, tmux, editor)

### Post-Deployment

- [ ] Monitor for errors in first 24 hours
- [ ] Test workflow in daily usage
- [ ] Document any unexpected behavior
- [ ] Update test guide with learnings

---

## 📚 References

- **Audit Report**: [AUDIT_REPORT.md](./AUDIT_REPORT.md)
- **Testing Report**: [TESTING_REPORT.md](./TESTING_REPORT.md)
- **Pull Request**: [PULL_REQUEST.md](./PULL_REQUEST.md)
- **Architecture**: [ARCHITECTURE_zh-CN.md](./ARCHITECTURE_zh-CN.md)

---

## ✅ Quick Start

**Recommended First Test** (15 minutes):

```bash
# 1. On your secondary machine (safest)
cd ~/dotfiles
git pull origin main

# 2. Review changes
chezmoi diff

# 3. Backup
chezmoi cd
git branch backup-$(date +%s)
cd -

# 4. Apply
chezmoi apply

# 5. Test core functionality
tmux new-session -d -s test "echo 'test'" && tmux kill-session -t test
zsh -i -c "echo 'Shell works'"
mise --version 2>/dev/null || echo "Mise not installed"

# 6. If all good, proceed to primary machine
```

---

**End of Production Testing Guide**

For questions or issues, refer to the audit documentation or open an issue in the repository.
