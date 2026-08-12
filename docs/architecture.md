# Architecture

The authoritative design is [the v1 development-environment contract](dev-environment-v1.md).

Homeup has three convergent layers:

1. **System** — Debian/Ubuntu packages only; requires root or non-interactive sudo.
2. **Language** — pinned Python, Node.js, Bun, and Rust; writes to user-owned
   paths except while building the development image.
3. **User** — locked CLI tools, chezmoi dotfiles, Sheldon, and pinned TPM; it
   never calls `sudo`.

Host provisioning is deliberately outside these layers. It may create a user,
configure UFW, hostname, and timezone, but SSH hardening always remains an
interactive, separately invoked operation.

```text
Host / VM       bootstrap auto  -> system? + language + user
cloud-init      native host config -> system -> runuser(language + user)
Docker image    system + language + locked core CLI at build time
Dev Container   image -> postCreate(user)
```

All non-apt version-sensitive artifacts derive from `toolchain/lock.sh`; the
curl entry point only obtains a checkout and delegates to `just bootstrap auto`.
