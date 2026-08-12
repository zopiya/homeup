# syntax=docker/dockerfile:1.7
# Debian 13-slim digest, pinned on 2026-08-12 for linux/amd64.
FROM debian:13-slim@sha256:3a39a0592364683e6bab97937b72cad5a8fa6dcbbee90edb3bb48c7f8e94f258

# PATH must be kept in sync with the HOMEUP_PREFIX/HOMEUP_BIN_DIR passed to
# language.sh/core-cli.sh below — Docker can't source their shared defaults.
ENV DEBIAN_FRONTEND=noninteractive \
    PATH=/usr/local/bin:/usr/local/sbin:/usr/local/lib/homeup/rust/bin:/usr/local/lib/homeup/node/bin:${PATH}

COPY packages/ /opt/homeup/packages/
COPY toolchain/ /opt/homeup/toolchain/
COPY scripts/bootstrap/ /opt/homeup/scripts/bootstrap/

RUN /opt/homeup/scripts/bootstrap/system.sh \
    && HOMEUP_INSTALL_SCOPE=system HOMEUP_PREFIX=/usr/local/lib/homeup HOMEUP_BIN_DIR=/usr/local/bin /opt/homeup/scripts/bootstrap/language.sh \
    && HOMEUP_BIN_DIR=/usr/local/bin /opt/homeup/scripts/bootstrap/core-cli.sh \
    && useradd --create-home --shell /usr/bin/zsh --groups sudo dev \
    && printf 'dev ALL=(ALL) NOPASSWD:ALL\n' >/etc/sudoers.d/dev \
    && chmod 0440 /etc/sudoers.d/dev \
    && rm -rf /var/lib/apt/lists/* /root/.cache

USER dev
WORKDIR /workspaces/homeup
