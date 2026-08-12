# Homeup Linux Development Environment v1

## Status

**Accepted.** This document is the implementation contract for the v1
cross-carrier development environment. Implementation, documentation, and CI
must follow this document; changes to the contract require updating this
document first.

## 1. Goal

Provide one consistent, personal Linux development environment on supported
Debian and Ubuntu releases, whether it runs on a long-lived host, virtual
machine, cloud-init provisioned instance, local Development Container, or
GitHub Codespaces.

Consistency means the same pinned core CLI and language runtimes, dotfiles,
shell behavior, and public `just` commands. It does not mean treating
containers as hosts: SSH, firewall, hostname, timezone, and login-shell
management remain host-only concerns.

### Supported platform and non-goals

- Supported operating systems: Debian and Ubuntu only.
- Supported architecture: `amd64` / `x86_64`.
- Default language toolchain: Python, Node.js, Bun, and Rust.
- No GUI configuration, no non-Debian/Ubuntu support, and no third-party
  version managers (`mise`, `asdf`, `nvm`, or `pyenv`).
- SSH hardening is never automated. It remains a separately invoked,
  human-confirmed host operation.

## 2. Model: carriers and layers

Every installation is described by one carrier and up to three layers.

| Carrier | System layer | Language layer | User layer |
| --- | --- | --- | --- |
| Host or VM with root/sudo | Install | Install | Install |
| Host or VM without sudo | Report unavailable | Install to user-owned paths | Install |
| cloud-init | Configure through cloud-init, then install | Install for target user | Install for target user |
| Docker image | Install at build time | Install at build time | Not applied |
| Dev Container/Codespaces | Present from image | Present from image | Apply after the target user exists |

### System layer

The system layer is the only layer allowed to use `apt` or otherwise require
root. It installs Debian/Ubuntu packages needed by the environment and may add
the narrow package sources required by pinned tools.

It explicitly excludes host provisioning. Host provisioning is a separate
host-only capability: user creation, SSH public keys, firewall, hostname,
timezone, and optional manual SSH hardening.

### Language layer

The language layer installs the pinned versions of Python, Node.js, Bun, and
Rust plus their required package managers and tooling. It can run either:

- system-wide in a Docker image build; or
- entirely in user-owned locations under `~/.local` (including its private
  `opt` prefix) on a host.

It must not require sudo or compile language runtimes on the target machine.
Every language runtime is downloaded from a locked, checksum-verified
prebuilt archive.

### User layer

The user layer never requires sudo. It installs user-owned core CLI tools,
applies chezmoi dotfiles, initializes user-owned integrations (Sheldon and
TPM), and verifies the resulting environment.

Git identity is opt-in. Chezmoi templates use only these variables when they
are set:

```text
HOMEUP_GIT_NAME
HOMEUP_GIT_EMAIL
HOMEUP_GIT_SIGNING_KEY
HOMEUP_GIT_SIGN_COMMITS
```

By default, no Git identity, signing configuration, personal key, or secret is
written. Credentials are never embedded in the repository, image, generated
cloud-init, or published logs.

## 3. Version and supply-chain policy

### Locked artifacts

`toolchain/lock.sh` is the single source of truth for every non-apt core CLI
and language artifact. It contains an exact version, x86_64 source URL,
expected SHA-256 digest, destination, and any components to install.
`toolchain/checksums.sh` may be split out only if it remains sourced by
`lock.sh`; it is not a second source of version truth.

Installers download only URLs constructed from this lock data, verify the
digest before installation, and never request a `latest` endpoint in the
normal install path.

### Update policy

- Node.js: newest active LTS release at the time of an update.
- Python: newest stable CPython release at the time of an update.
- Bun: newest stable release at the time of an update.
- Rust: newest stable release at the time of an update.
- Core CLI: newest compatible stable release at the time of an update.

A scheduled GitHub Actions workflow checks official upstream metadata monthly
and directly commits updated lock data, checksums, and update metadata to the
default branch. The normal verification and image-publishing workflows then
run from that same commit. This is intentionally optimized for the single-user
repository: GitHub Actions is the audit trail rather than a mandatory PR.

### apt policy

Packages supplied by Debian/Ubuntu apt remain distribution-managed. The
repository maintains two explicit lists:

- `packages/base.apt`: packages necessary on every carrier with system access.
- `packages/host.apt`: host/VM-only operational tooling.

No language runtime or core CLI that is required to be version-consistent may
be supplied by apt unless its version is explicitly accepted into the lock
policy.

## 4. Public command contract

The following commands are the stable v1 public interface.

```sh
# Bootstrap the current user and automatically select the permitted layers.
just bootstrap

# Explicitly choose an installation policy.
just bootstrap auto
just bootstrap full
just bootstrap user

# Execute one layer.
just system::install
just language::install
just user::apply

# Persistent-host-only provisioning.
just host::provision
just host::ssh-harden

# Report installed versions, missing prerequisites, and skipped layers.
just doctor
```

Modes have the following exact meaning:

| Mode | Behavior |
| --- | --- |
| `auto` | Install the system layer only when root/sudo is usable; always run language and user layers. |
| `full` | Require root or non-interactive-capable sudo and fail before making changes if unavailable. |
| `user` | Never call `sudo` or `apt`; run only language and user layers. |

All layers are idempotent. Re-running a command with the same lock data must
converge to the same state. A new lock version is applied only after its normal
checksum verification.

The curl entry point is intentionally thin:

```sh
curl -fsSL https://raw.githubusercontent.com/zopiya/homeup/main/scripts/bootstrap/entrypoint.sh | bash
```

It obtains or updates the checkout, performs carrier and privilege detection,
and invokes `just bootstrap auto`. It must not duplicate package,
language, or user-layer installation logic. `HOMEUP_REPO_URL`, `HOMEUP_REF`,
`HOMEUP_DIR`, and (for non-GitHub sources without Git) `HOMEUP_ARCHIVE_URL`
remain override points; no access token may be compiled into the script.

## 5. Carrier adapters

### Host and VM

`just bootstrap` (equivalent to `just bootstrap auto`) is the standard developer-environment entry
point. `just host::provision` is optional and intended only for a new
persistent VM or physical host. It composes the independent host scripts but
never calls `host::ssh-harden`.

### cloud-init

`cloud-init/homeup.yaml.tmpl` is a user-data template, not an independent
installer. It:

1. declares the target user, its SSH authorized keys, and its sudo policy via
   cloud-init's native configuration;
2. optionally performs safe host provisioning selected in template data;
3. uses `runcmd` to invoke the same bootstrap checkout and commands; and
4. uses `runuser` to execute language and user layers as the target user.

The template accepts only named data values such as `HOMEUP_USER`, SSH key,
hostname, timezone, and whether UFW is requested. It does not place secrets in
user-data and it has no automatic SSH-hardening switch.

### Docker image

`containers/dev/Dockerfile` is the only image build definition. It uses an
explicit Debian/Ubuntu base digest, builds for `linux/amd64`, and runs the
system and language layers during image build. It creates a
non-root `dev` user with passwordless sudo only for interactive development;
the user layer is not executed at build time.

The image must contain the locked toolchain and enough prerequisites for
`just user::apply` to work offline except for explicitly user-owned plugin
downloads. The image build must not include Git identity, SSH material,
GitHub credentials, or user home-directory dotfiles.

### Dev Container and Codespaces

After the first public image is published, `.devcontainer/devcontainer.json`
references the public GHCR image by digest, sets `remoteUser` to `dev`, and
runs the user layer after creation:

```text
just user::apply
```

It may add project-maintenance editor extensions and settings only. It does
not install system packages, language runtimes, or host configuration.

Until that first immutable manifest exists, the checked-in configuration may
use the same `containers/dev/Dockerfile` as a one-time local build fallback.
The release workflow commits the published digest directly to the default
branch before the first public release is declared complete. That digest-only
commit does not trigger another image build. The one-line bootstrap command is
served directly from the public GitHub repository; it falls back to that
repository's source archive when Git is unavailable.

When Codespaces prebuilds are enabled, all costly, secret-free work must be in
the Docker image or `onCreateCommand`/`updateContentCommand`. The user-layer
application stays in `postCreateCommand`, because user secrets and identity
variables are unavailable to prebuilds and must not be baked into snapshots.

## 6. Repository layout

```text
scripts/
  bootstrap/
    entrypoint.sh            # curl entry point implementation
    detect.sh                # carrier, OS, architecture, and privilege checks
    system.sh                # system-layer implementation
    language.sh              # language-layer implementation
    user.sh                  # user-layer implementation
  host/
    create-user.sh
    ufw.sh
    hostname.sh
    timezone.sh
    ssh-harden.sh
packages/
  base.apt
  host.apt
toolchain/
  lock.sh
  checksums.sh
containers/dev/
  Dockerfile
.devcontainer/
  devcontainer.json
cloud-init/
  homeup.yaml.tmpl
.github/workflows/
  image.yml
  verify.yml
  toolchain-update.yml
docs/
  dev-environment-v1.md      # this contract
```

Existing `scripts/system/` and `scripts/packages/` are migrated into these
locations. Compatibility aliases preserve the current commands during the v1
migration, but the new hierarchy is authoritative. Deprecated commands are
documented with their replacements and removed only in a later major release.

## 7. Publishing and provenance

GitHub Actions builds and tests public `linux/amd64` images, then
publishes them to:

```text
ghcr.io/<github-owner>/homeup-linux
```

Each accepted release publishes:

- `dev-<commit-sha>` for traceability;
- a versioned release tag for human consumption;
- `dev` as the current convenience tag; and
- an immutable image digest.

The checked-in Dev Container configuration uses the immutable digest. The
image package is public and linked to its GitHub repository. CI uses GitHub's
token with the minimum package permission required; no long-lived registry
credential is committed.

## 8. CI and acceptance criteria

Every change to bootstrap, toolchain, Docker, Dev Container, cloud-init, or
dotfiles must run the applicable checks:

1. shell formatting, ShellCheck, and shell syntax checks;
2. chezmoi template validation;
3. lock-file schema and checksum-reference validation;
4. Docker amd64 image build validation;
5. container smoke test as a non-root user running `just bootstrap user`;
6. Debian and Ubuntu system-layer smoke tests;
7. `cloud-init schema --config-file` validation of rendered user-data; and
8. `just doctor` assertions for required tools and exact locked versions.

The final acceptance test is a clean Dev Container/Codespaces creation from
the published image. It must yield a working non-root Zsh environment, all
locked language runtimes, the configured CLI suite, and no Git identity unless
explicit variables were supplied.

## 9. Delivery sequence

Implementation proceeds in these independently reviewable stages:

1. Add the contract, lock format, carrier detection, and doctor output without
   removing the existing workflow.
2. Implement idempotent system, language, and user layers; preserve current
   commands as compatibility aliases.
3. Migrate chezmoi templates to opt-in Git identity and remove embedded
   repository credentials from bootstrap defaults.
4. Add Dockerfile, amd64 smoke tests, GHCR publishing, and
   provenance metadata.
5. Add Dev Container/Codespaces configuration and verify prebuild-safe
   lifecycle placement.
6. Add the cloud-init template, renderer/validation workflow, and host
   provisioning migration.
7. Update all public documentation; mark old entry points deprecated after
   successful end-to-end validation.

At the end of every stage, existing users must retain a functioning migration
path. No stage may weaken the manual SSH-hardening guarantee.
