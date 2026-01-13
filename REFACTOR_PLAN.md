# Homeup Refactoring Plan

**Target Date:** 2026-01-12  
**Status:** Implementation Complete / Manual Verification Pending  
**Version:** 2.0

This document outlines the comprehensive refactoring plan for the Homeup dotfiles project. The goal is to simplify the profile structure, clarify the role of Linux environments, and create a standalone, lightweight profile for ephemeral environments.

---

## Table of Contents

1. [Architectural Changes](#1-architectural-changes)
2. [Affected Files Inventory](#2-affected-files-inventory)
3. [Implementation Steps](#3-implementation-steps)
4. [Justfile Updates](#4-justfile-updates)
5. [Template Degradation Strategy](#5-template-degradation-strategy)
6. [Verification Checklist](#6-verification-checklist)

---

## 1. Architectural Changes

### 1.1 Profile Redefinition

The previous profile structure (`workstation`, `server`, `codespace`) is being replaced with a platform-centric approach:

| Profile     | Type                  | Inheritance     | Description                                                                                           |
| :---------- | :-------------------- | :-------------- | :---------------------------------------------------------------------------------------------------- |
| **`macos`** | GUI / Main            | Inherits `Core` | Primary workstation. Handles sensitive keys (GPG/YubiKey), GUI apps, and full development stack.      |
| **`linux`** | Headless / SSH        | Inherits `Core` | Remote development hosts, servers, and homelabs which are accessed via SSH. Full toolset (Ops + Dev). |
| **`mini`**  | Ephemeral / Container | **Standalone**  | **Dev-Ready Minimal**. For Docker containers & Codespaces. Includes Runtimes, excludes Ops tools.     |

### 1.2 Core Philosophy Shifts

- **Linux Unification**: No distinction between "Linux Workstation" and "Linux Server". Any Linux machine is treated as a remote headless environment accessed via SSH.
  - **⚠️ BREAKING CHANGE**: Linux Desktop/GUI support is **completely removed**. All GUI applications (previously managed via Flatpak) are no longer supported.
  - **Migration Path for Linux Desktop Users**: Switch to macOS, or manually install GUI apps outside of Homeup management.
- **Mini Independence**: `mini` profile strictly does **not** inherit from `Brewfile.core`. It is a targeted bundle for pure development.
  - **IN**: Runtimes (mise, uv, pnpm), Editors (nvim, tmux), Shell (zsh, starship), Basic Git.
  - **OUT**: Ops tools (k9s, lazydocker, terraform), Heavy monitoring (netdata), Backup (restic).
- **Identity Unification**: Single personal Git identity across all profiles. No multi-persona configuration required.
- **Zero-Touch Bootstrap**: The `bootstrap.sh` script will be hardcoded for personal use. Default behavior is fully automated (install Brew -> chezmoi init & apply from `zopiya/homeup`).

---

## 2. Affected Files Inventory

### 2.1 Files to Delete

| File                          | Reason                                              |
| :---------------------------- | :-------------------------------------------------- |
| `packages/Brewfile.server`    | Profile removed; functionality merged into `linux`. |
| `packages/Brewfile.codespace` | Profile removed; replaced by standalone `mini`.     |
| `packages/flatpak.txt`        | Linux is now headless; no GUI apps needed.          |

### 2.2 Files to Create

| File                     | Purpose                                                        |
| :----------------------- | :------------------------------------------------------------- |
| `packages/Brewfile.mini` | Standalone package bundle for dev containers (incl. Runtimes). |

### 2.3 Files to Modify

| File                                                     | Changes Required                                                              |
| :------------------------------------------------------- | :---------------------------------------------------------------------------- |
| `packages/Brewfile.linux`                                | Rewrite: merge server + workstation(Linux) tools, remove GUI/Flatpak references. |
| `packages/README.md`                                     | Update documentation to reflect new profile structure.                        |
| `bootstrap.sh`                                           | Hardcode repo URL, update profile validation/detection, update help text.     |
| `.chezmoi.toml.tmpl`                                     | Change default profile value and enum validation.                             |
| `.chezmoiignore.tmpl`                                    | Update profile conditions (`workstation` → `macos`, `server` → `linux`, etc). |
| `.chezmoitemplates/profile-guard.tmpl`                   | **[NEW]** Update profile validation logic, variable names, and capability flags. |
| `.chezmoiscripts/run_once_install_brew_packages.sh.tmpl` | Update `case` statement for new profiles; remove Flatpak logic.               |
| `private_dot_ssh/config.tmpl`                            | Replace `$isWorkstation/$isCodespace/$isServer` with new variables.           |
| `private_dot_ssh/authorized_keys.tmpl`                   | **[NEW]** Simplify `$isServer` logic to `$isLinux`.                           |
| `private_dot_gnupg/gpg-agent.conf.tmpl`                  | **[NEW]** Replace `$isWorkstation` with `$isMacos`.                           |
| `dot_config/git/config.tmpl`                             | Replace `$isWorkstation` with `$isMacos`; update profile conditions.          |
| `dot_config/zsh/dot_zshrc.tmpl`                          | Replace `$isWorkstation` with `$isMacos`; update profile variable.            |
| `dot_config/security/gpg.inc.tmpl`                       | **[NEW]** Replace `$isWorkstation` with `$isMacos`.                           |
| `dot_config/security/1password.inc.tmpl`                 | **[NEW]** Replace `profile == "workstation"` with `profile == "macos"`.       |
| `dot_config/security/yubikey.inc.tmpl`                   | **[NEW]** Replace `profile == "workstation"` with `profile == "macos"`.       |
| `justfile`                                               | Update profile tasks and validation loop.                                     |
| `.github/workflows/test.yml`                             | **[NEW]** Update CI test matrix, profile options, validation logic.           |
| `lefthook.yml`                                           | **[NEW]** Update Git hooks validation loop for new profiles.                  |
| `README.md`                                              | Update documentation, profile table, examples, and migration notes.           |

---

## 3. Implementation Steps

### Phase 1: Package Management (`packages/`)

Refactoring the Homebrew bundle definitions.

#### 3.1.1 Cleanup

- Delete `packages/Brewfile.server`.
- Delete `packages/Brewfile.codespace`.
- Delete `packages/flatpak.txt`.

#### 3.1.2 `Brewfile.core` (No Changes)

Remains the foundation for `macos` and `linux`. Current contents are appropriate.

#### 3.1.3 `Brewfile.macos` (No Changes)

GUI apps and macOS-specific tools. Current contents are appropriate.

#### 3.1.4 `Brewfile.linux` (Rewrite)

Inherits `core`. Full-featured headless environment merging former workstation(Linux) and server capabilities.

**Merge Strategy**: Current `Brewfile.linux` (47 packages) + `Brewfile.server` unique tools (glances, bmon, lnav) = **50 packages total**.

**Content Definition (Incremental over Core):**

| Category                | Tools                                                          | Purpose                                   | Source      |
| :---------------------- | :------------------------------------------------------------- | :---------------------------------------- | :---------- |
| **Enhanced CLI**        | `fastfetch`, `zellij`, `bottom`, `choose`                      | System info, multiplexer, monitoring      | Both        |
| **Monitoring (Server)** | `glances`, `bmon`                                              | Enhanced system/network monitoring        | **Server**  |
| **Log Analysis**        | `lnav`                                                         | Log file navigator                        | **Server**  |
| **File Management**     | `yazi`, `watchexec`                                            | File browser, file watcher                | Workstation |
| **AI Development**      | `aider`, `glow`, `vhs`                                         | AI coding assistant, markdown, demos      | Workstation |
| **Container & K8s**     | `lazydocker`, `dive`, `k9s`, `helm`, `kubectx`, `stern`, `kustomize` | Complete K8s ecosystem                    | Workstation |
| **IaC & DevOps**        | `terraform`, `ansible`, `trivy`, `grype`, `syft`               | Infrastructure as Code, security scanning | Workstation |
| **Network & API**       | `httpie`, `xh`, `doggo`, `gping`, `trippy`, `grpcurl`, `evans` | HTTP/gRPC clients, DNS, network tools     | Workstation |
| **Database**            | `usql`, `pgcli`                                                | Universal SQL client, PostgreSQL CLI      | Workstation |
| **Runtimes**            | `mise`, `uv`, `pnpm`                                           | Version manager, Python, Node             | Workstation |
| **Performance**         | `hyperfine`, `tokei`, `bandwhich`                              | Benchmarks, code stats, bandwidth monitor | Workstation |
| **Git Enhancements**    | `git-cliff`, `onefetch`                                        | Changelog generator, repo info            | Workstation |
| **Security**            | `gnupg`, `age`, `ykman`, `1password-cli`, `gitleaks`           | Encryption, hardware keys, secret scanning| Workstation |
| **Backup**              | `restic`                                                       | Backup and disaster recovery              | Both        |

**Note**: GUI apps (previously in `flatpak.txt`) are **completely removed**. No Flatpak installation logic.

#### 3.1.5 `Brewfile.mini` (New Creation)

**Standalone** — Does NOT inherit from `Brewfile.core`.
**Philosophy**: "Just enough to Write Code".

**Content Definition:**

| Category       | Tools                               | Purpose                            |
| :------------- | :---------------------------------- | :--------------------------------- |
| **Shell**      | `zsh`, `starship`, `sheldon`        | Shell, prompt, plugin manager      |
| **Navigation** | `zoxide`, `fzf`                     | Smart cd, fuzzy finder             |
| **Editor**     | `neovim`, `tmux`                    | Editor, multiplexer                |
| **Runtimes**   | `mise`, `uv`, `pnpm`                | **CRITICAL**: needed for Dev       |
| **Git**        | `git`, `lazygit`, `git-delta`       | Version control                    |
| **Utils**      | `bat`, `eza`, `ripgrep`, `fd`, `jq` | Modern CLI replacements            |
| **Dev**        | `direnv`, `just`, `chezmoi`         | Env loading, task runner, dotfiles |
| **Network**    | `curl`                              | HTTP client (system fallback)      |

**Explicitly Excluded from Mini:**

- `k9s`, `lazydocker` (Ops/Container Mgmt)
- `terraform`, `ansible`, `helm` (Infrastructure)
- `gh` (GitHub CLI)
- `topgrade` (System updates)
- `glances`, `btop` (Heavy monitoring)

---

### Phase 2: Bootstrap Script (`bootstrap.sh`)

Updating the entry point logic for Zero-Touch experience.

#### 2.1 Profile Validation (lines 169-175)

Update valid profile list:

```bash
case "$ARG_PROFILE" in
    macos|linux|mini) ;;
    *)
        printf "Valid profiles: macos, linux, mini\n" >&2
        exit 1
        ;;
esac
```

#### 2.2 Profile Auto-Detection (lines 427-473)

Key changes:
- **Codespace/Containers** → `mini` (not `codespace`)
- **CI/SSH headless** → `linux` (not `server`)
- **macOS** → always `macos` (not `workstation`)
- **Linux with GUI** → `linux` (GUI no longer supported)

#### 2.3 Validate Profile Function (lines 475-479)

```bash
validate_profile() {
    case "$profile" in
        macos|linux|mini) return 0 ;;
        *) return 1 ;;
    esac
}
```

#### 2.4 Help Text Updates

Update all profile descriptions:
- Lines 14-24: Short help banner
- Lines 77-89: Detailed help text
- Lines 96-105: Example commands

Replace:
- `workstation` → `macos`
- `codespace` → `mini`
- `server` → `linux`

#### 2.5 Flatpak Installation Removal (lines 650-704)

**DELETE** the entire `install_flatpak_apps()` function.

Reason: Linux no longer supports GUI apps.

#### 2.6 Interactive Prompt (line 523)

```bash
printf "%smacos%s / %slinux%s / %smini%s to override\n" \
    "$C_CYAN" "$C_RESET" "$C_CYAN" "$C_RESET" "$C_CYAN" "$C_RESET"
```

---

### Phase 3: Configuration & Templating

Ensuring dotfiles adapt to the new profiles.

#### 3.3.1 Chezmoi Config (`.chezmoi.toml.tmpl`)

- Update `profile` default from `"workstation"` to `"macos"`.
- Enum validation: `macos | linux | mini`.

#### 3.3.2 Profile Guard Template (`.chezmoitemplates/profile-guard.tmpl`)

**Critical:** This is a core template used by other templates. Must be updated first.

**Changes Required:**

1. **Update valid profiles list** (line 25):
   ```go-template
   # Before
   {{- $validProfiles := list "workstation" "codespace" "server" -}}

   # After
   {{- $validProfiles := list "macos" "linux" "mini" -}}
   ```

2. **Update default profile** (line 24):
   ```go-template
   # Before
   {{- $profile := .profile | default "workstation" -}}

   # After
   {{- $profile := .profile | default "macos" -}}
   ```

3. **Replace boolean variables** (lines 31-33):
   ```go-template
   # Before
   {{- $isWorkstation := eq $profile "workstation" -}}
   {{- $isCodespace := eq $profile "codespace" -}}
   {{- $isServer := eq $profile "server" -}}

   # After
   {{- $isMacos := eq $profile "macos" -}}
   {{- $isLinux := eq $profile "linux" -}}
   {{- $isMini := eq $profile "mini" -}}
   ```

4. **Update capability flags** (lines 36-39):
   ```go-template
   # Before
   {{- $hasGUI := $isWorkstation -}}
   {{- $hasGPG := $isWorkstation -}}
   {{- $hasPrivateKey := $isWorkstation -}}
   {{- $hasAgentForward := or $isWorkstation $isCodespace -}}

   # After
   {{- $hasGUI := $isMacos -}}
   {{- $hasGPG := $isMacos -}}
   {{- $hasPrivateKey := $isMacos -}}
   {{- $hasAgentForward := or $isMacos $isLinux -}}
   ```

5. **Update documentation comments** (lines 8-11):
   ```go-template
   # Before
   - $profile:      Current profile ("workstation", "codespace", or "server")
   - $isWorkstation: true if profile == "workstation"
   - $isCodespace:   true if profile == "codespace"
   - $isServer:      true if profile == "server"

   # After
   - $profile:  Current profile ("macos", "linux", or "mini")
   - $isMacos:  true if profile == "macos"
   - $isLinux:  true if profile == "linux"
   - $isMini:   true if profile == "mini"
   ```

#### 3.3.3 Chezmoi Ignore (`.chezmoiignore.tmpl`)

- Replace `{{ if ne $profile "workstation" }}` with `{{ if ne $profile "macos" }}`.
- Replace `{{ if eq $profile "server" }}` with `{{ if eq $profile "linux" }}`.
- Replace `{{ if eq $profile "codespace" }}` with `{{ if eq $profile "mini" }}`.

#### 3.3.4 Installation Script (`.chezmoiscripts/run_once_install_brew_packages.sh.tmpl`)

**Changes Required:**

1. **Update profile variable** (line 12):
   ```bash
   readonly PROFILE="{{ .profile | default "macos" }}"
   ```

2. **Update case statement** (lines 112-129):
   ```bash
   case "$PROFILE" in
       macos)
           brewfiles+=("$source_dir/packages/Brewfile.macos")
           ;;
       linux)
           brewfiles+=("$source_dir/packages/Brewfile.linux")
           ;;
       mini)
           # Mini is standalone - replace core, don't add to it
           brewfiles=("$source_dir/packages/Brewfile.mini")
           ;;
       *)
           msg_fail "Unknown profile: $PROFILE"
           ;;
   esac
   ```

3. **Remove Flatpak installation logic** (lines 158-162):
   - **DELETE** the entire Flatpak installation section
   - Reason: Linux no longer supports GUI apps

4. **Update GPG agent check** (line 219):
   ```bash
   if [[ "$PROFILE" != "macos" ]]; then
   ```

#### 3.3.5 SSH Configuration (`private_dot_ssh/config.tmpl`)

- Replace `$isWorkstation` with `$isMacos`.
- Replace `$isCodespace` with `$isMini`.
- Replace `$isServer` with `$isLinux`.
- The `Host *.hs` block with `ForwardAgent yes` already exists — **verify it remains intact**.

#### 3.3.6 SSH Authorized Keys (`private_dot_ssh/authorized_keys.tmpl`)

**Simplify logic:**

```go-template
# Before
{{- if or $isLinux $isServer }}

# After
{{- if $isLinux }}
```

Reason: In new architecture, all Linux machines need CA trust (both former workstation and server).

#### 3.3.7 GPG Agent Configuration (`private_dot_gnupg/gpg-agent.conf.tmpl`)

- Replace `$isWorkstation` with `$isMacos` (line 8)
- Update profile comments in disabled section (line 46)

#### 3.3.8 Git Configuration (`dot_config/git/config.tmpl`)

- Replace `$isWorkstation` with `$isMacos` (line 10)
- Update credential helper conditions:
  ```go-template
  # Line 46: Linux workstation condition
  {{- else if $isMacos }}

  # Lines 49-54: Update profile checks
  {{- else if eq $profile "mini" }}
  ```

#### 3.3.9 Security Modules

**GPG Integration** (`dot_config/security/gpg.inc.tmpl`):
- Replace `$isWorkstation` with `$isMacos` (lines 3, 6)
- Update profile comments (line 19)

**1Password CLI** (`dot_config/security/1password.inc.tmpl`):
- Replace `profile == "workstation"` with `profile == "macos"` (line 5)
- Update disabled profile comment (line 24)

**YubiKey Integration** (`dot_config/security/yubikey.inc.tmpl`):
- Replace `profile == "workstation"` with `profile == "macos"` (line 5)
- Update disabled profile comment (line 22)

#### 3.3.10 Shell Configuration (`dot_config/zsh/dot_zshrc.tmpl`)

- Replace `$isWorkstation` with `$isMacos` (line 8)
- Security modules (GPG, 1Password, YubiKey) only load when `$isMacos` (line 68)

---

## 4. Justfile Updates

Update task runner to reflect new profile structure.

### 4.1 Profile Tasks

Replace old profile tasks:

```just
# Show current profile
profile:
    @echo "Current profile: ${HOMEUP_PROFILE:-macos}"

# Set profile to macos
profile-macos:
    @echo "export HOMEUP_PROFILE=macos"

# Set profile to linux
profile-linux:
    @echo "export HOMEUP_PROFILE=linux"

# Set profile to mini
profile-mini:
    @echo "export HOMEUP_PROFILE=mini"
```

### 4.2 Validation Task

Update the validation loop:

```just
validate:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Validating templates for all profiles..."
    for profile in macos linux mini; do
        echo "--- Profile: $profile ---"
        export HOMEUP_PROFILE=$profile
        chezmoi init --source . --destination /tmp/chezmoi-test-$profile --dry-run 2>/dev/null && echo "OK" || echo "FAIL"
    done
```

### 4.3 Package Installation Task

Update the install logic:

```just
install-packages:
    @echo "Installing packages..."
    @if [ "${HOMEUP_PROFILE:-macos}" = "mini" ]; then \
        brew bundle --file=packages/Brewfile.mini; \
    else \
        brew bundle --file=packages/Brewfile.core; \
        if [ "$(uname)" = "Darwin" ]; then \
            brew bundle --file=packages/Brewfile.macos; \
        else \
            brew bundle --file=packages/Brewfile.linux; \
        fi; \
    fi
```

---

## 5. Template Degradation Strategy

For tools that exist in `Core` but not in `Mini`, use **Runtime Detection** in shell configs.

### 5.1 Strategy: Runtime Detection (Preferred)

Use `command -v` to check tool availability before initializing:

```bash
# Example: Atuin (exists in Core, not in Mini)
if command -v atuin &> /dev/null; then
    eval "$(atuin init zsh)"
fi
```

**Rationale:**

- Templates remain simple (no complex `{{ if }}` nesting).
- If user manually installs a tool in Mini, it automatically works.
- Negligible performance impact (microseconds per check).

### 5.2 Current Status

The existing `dot_zshrc.tmpl` **already uses this pattern** for most tools:

```bash
if command -v sheldon &> /dev/null; then
    eval "$(sheldon source)"
fi
```

**No additional changes needed** for basic shell loading. The current implementation is robust.

### 5.3 Alias Safety

In `aliases.zsh`, aliases like `alias cat="bat"` will fail silently if `bat` is not installed. This is acceptable behavior — the alias simply won't be available, and the user can use the original `cat`.

---

### Phase 4: CI/CD & Git Hooks

#### 4.1 GitHub Actions Workflow (`.github/workflows/test.yml`)

**Extensive changes required** (71 profile references across 605 lines):

1. **Update workflow dispatch inputs** (lines 28-36):
   ```yaml
   options:
     - ""
     - macos
     - linux
     - mini
   ```

2. **Update job names and conditions:**
   - Line 54: `macOS / workstation` → keep as `macOS / macos`
   - Line 56: `github.event.inputs.profile == 'workstation'` → `== 'macos'`
   - Lines 145, 345: `Debian / ${{ matrix.profile }}`, `Fedora / ${{ matrix.profile }}` (no change)

3. **Update test matrices** (lines 155, 355):
   ```yaml
   matrix:
     profile: [macos, linux, mini]
   ```

4. **Update cache keys** (lines 187, 387):
   ```yaml
   key: debian-homebrew-${{ matrix.profile }}-${{ hashFiles('bootstrap.sh') }}
   ```

5. **Update bootstrap commands** (lines 86, 210, 410):
   ```bash
   ./bootstrap.sh -p macos -y  # for macOS job
   ./bootstrap.sh -p ${{ matrix.profile }} -y  # for matrix jobs
   ```

6. **Update environment variables** (lines 88, 107, 230, 430):
   ```yaml
   HOMEUP_PROFILE: macos  # or ${{ matrix.profile }}
   ```

7. **Update profile verification conditions** (lines 264, 292, 314, 464, 492, 514):
   ```yaml
   if: ${{ matrix.profile == 'macos' && steps.verify_core.outcome == 'success' }}
   if: ${{ matrix.profile == 'linux' && steps.verify_core.outcome == 'success' }}
   if: ${{ matrix.profile == 'mini' && steps.verify_core.outcome == 'success' }}
   ```

8. **Update template validation loop** (lines 562-572):
   ```bash
   for profile in macos linux mini; do
     echo "--- Testing profile: $profile ---"
     export HOMEUP_PROFILE=$profile
     chezmoi init --source . --destination /tmp/chezmoi-test-$profile --dry-run
   done
   ```

#### 4.2 Lefthook Git Hooks (`lefthook.yml`)

**Update template validation loop** (lines 91-99):

```yaml
template-validate:
  run: |
    echo "Validating all templates..."
    for profile in macos linux mini; do
      export HOMEUP_PROFILE=$profile
      if command -v chezmoi &> /dev/null; then
        chezmoi init --source . --destination /tmp/chezmoi-validate-$profile --dry-run 2>/dev/null || {
          echo "Template validation failed for profile: $profile"
          exit 1
        }
      fi
    done
    echo "All templates valid"
```

---

### Phase 5: Documentation Updates

#### 5.1 Project README (`README.md`)

**Major updates required:**

1. **Update profile table** (lines 33-35):
   ```markdown
   | Profile | Trust Model | Use On | Highlights |
   |---------|-------------|--------|------------|
   | **macos** | Full | Personal macOS laptop/desktop | GPG signing, YubiKey, GUI apps, full package set |
   | **linux** | Headless | Remote Linux hosts, servers, homelabs | SSH-only access, full dev+ops toolset, no GUI |
   | **mini** | Minimal | Dev containers, Codespaces | Lightweight, runtimes included, no ops tools |
   ```

2. **Add breaking change notice:**
   ```markdown
   ## ⚠️ Breaking Changes in v2.0

   - **Linux Desktop support removed**: The `linux` profile no longer installs GUI applications.
     - Former Linux Desktop users should either:
       1. Switch to macOS, or
       2. Manually manage GUI apps outside Homeup
     - Flatpak integration has been completely removed
   ```

3. **Update usage examples** (lines 38-42, 59-62):
   ```bash
   export HOMEUP_PROFILE=macos
   ./bootstrap.sh -p linux
   ./bootstrap.sh -p mini -r zopiya/homeup -a
   ```

4. **Update profile descriptions** throughout the document

#### 5.2 Package Documentation (`packages/README.md`)

1. **Update Brewfile list:**
   - Remove references to `Brewfile.server` and `Brewfile.codespace`
   - Add `Brewfile.mini`
   - Update `Brewfile.linux` description

2. **Update package counts and distribution table**

3. **Update installation examples**

---

## 6. Verification Checklist

### 6.1 Mini Profile

- [ ] `bootstrap.sh -p mini` completes in < 5 minutes on fresh Ubuntu container
- [ ] `zsh` starts without errors; `starship` prompt renders correctly
- [ ] `z` (zoxide) and `Ctrl+R` (fzf) work as expected
- [ ] `nvim` opens and basic editing works
- [ ] `tmux` starts new session successfully
- [ ] `lazygit` runs without errors
- [ ] `just` command is available and lists tasks
- [ ] `chezmoi status` runs without errors
- [ ] No "command not found" errors for missing tools (atuin, btop, etc.)

### 6.2 Linux Profile

- [ ] `bootstrap.sh -p linux` completes successfully
- [ ] `chezmoi apply` runs without errors
- [ ] `ssh -A myserver.hs` followed by `ssh -T git@github.com` returns authentication success
- [ ] `git commit -S` on remote triggers YubiKey prompt on local macOS
- [ ] `topgrade` runs and updates system components
- [ ] `lazydocker` connects to Docker daemon
- [ ] Monitoring tools (`btop`, `glances`) run correctly

### 6.3 macOS Profile

- [ ] `bootstrap.sh -p macos` completes successfully (or auto-detects)
- [ ] All GUI apps (Ghostty, VS Code, etc.) install via Homebrew Cask
- [ ] `gpg --card-status` recognizes YubiKey
- [ ] `1password-cli` authenticates successfully
- [ ] All aliases in `aliases.zsh` resolve correctly
- [ ] Security modules load without errors (check `source ~/.zshrc` output)
- [ ] `chezmoi diff` shows no unexpected changes after fresh apply

### 6.4 Cross-Profile Consistency

- [ ] Git identity (`git config user.email`) is consistent across all profiles
- [ ] Shell prompt (starship) looks identical across all profiles
- [ ] Core aliases (`ls`, `cat`, `grep` replacements) behave the same
- [ ] `lazygit` keybindings and theme are consistent

---

## 7. Implementation Order & Risk Assessment

### 7.1 Recommended Execution Sequence

Execute phases in strict order to minimize errors and enable incremental testing:

```
Phase 1: Package Management (Low Risk, Isolated)
  ├─ 3.1.1: Delete old Brewfiles ✓ Reversible
  ├─ 3.1.4: Rewrite Brewfile.linux
  └─ 3.1.5: Create Brewfile.mini

Phase 2: Bootstrap Script (Medium Risk, High Impact)
  └─ Update profile validation, detection, and help text

Phase 3: Configuration & Templating (High Risk, Wide Impact)
  ├─ 3.3.1: .chezmoi.toml.tmpl (default profile)
  ├─ 3.3.2: .chezmoitemplates/profile-guard.tmpl ⚠️ CRITICAL
  ├─ 3.3.3: .chezmoiignore.tmpl
  ├─ 3.3.4: Installation script (case statement + Flatpak removal)
  ├─ 3.3.5-3.3.10: All application config templates
  └─ Run `just validate` after each template change

Phase 4: CI/CD & Git Hooks (Automation)
  ├─ .github/workflows/test.yml (71 changes)
  └─ lefthook.yml (validation loop)

Phase 5: Documentation (No Code Impact)
  ├─ README.md (breaking change notice)
  ├─ packages/README.md
  └─ justfile

Phase 6: Verification & Testing
  └─ Run full test matrix on all profiles
```

### 7.2 Critical Dependencies

**Must be updated FIRST:**
- `.chezmoitemplates/profile-guard.tmpl` - Used by all other templates
- `.chezmoi.toml.tmpl` - Defines default profile

**Blocked until Phase 3 complete:**
- CI workflows (will fail on invalid templates)
- Documentation (examples must match code)

### 7.3 Risk Matrix

| Component | Risk Level | Impact if Failed | Mitigation |
|-----------|-----------|------------------|------------|
| **profile-guard.tmpl** | 🔴 **CRITICAL** | All templates break | Update first, validate immediately |
| **Brewfile.linux merge** | 🟡 Medium | Package conflicts | Review diff carefully, test in container |
| **Flatpak removal** | 🟢 Low | No impact (Linux Desktop unsupported) | Document breaking change |
| **CI workflow updates** | 🟡 Medium | Tests fail, block merges | Update matrix carefully, test manually first |
| **Bootstrap auto-detection** | 🟡 Medium | Wrong profile selected | Keep manual `-p` override |

### 7.4 Rollback Strategy

**If issues arise:**

1. **Template errors**: Revert `.chezmoitemplates/profile-guard.tmpl` first
2. **Bootstrap failures**: Use `-p` flag to force correct profile
3. **Package conflicts**: `brew bundle cleanup` to remove orphaned packages
4. **Complete rollback**: Revert entire branch, keep data in `~/.local/share/chezmoi`

### 7.5 File Change Summary

**Total files affected: 21**

| Change Type | Count | Files |
|-------------|-------|-------|
| **Delete** | 3 | Brewfile.server, Brewfile.codespace, flatpak.txt |
| **Create** | 1 | Brewfile.mini |
| **Modify** | 18 | Templates, configs, scripts, docs, CI |

**Lines of code changed: ~400+ across all files**

---

## 8. Post-Refactor Cleanup

After successful verification:

1. **Update CHANGELOG.md:**
   - Document breaking changes
   - List new profile names
   - Provide migration guide

2. **Tag release:**
   ```bash
   git tag -a v2.0.0 -m "Major refactor: Unified Linux profiles, new mini profile"
   git push origin v2.0.0
   ```

3. **Archive old documentation:**
   - Move v1.x profile docs to `docs/legacy/`
   - Keep for reference but mark as deprecated

4. **Communication:**
   - Announce breaking changes in README
   - Update any external references (blog posts, gists, etc.)
