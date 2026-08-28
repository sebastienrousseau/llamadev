# syntax=docker/dockerfile:1.9
# llamadev Containerfile — OCI, builds with Docker AND Podman.
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
# An Ollama LLM development environment built on the shared langdev core:
# non-root, all-caps-dropped, read-only-rootfs friendly, multi-arch
# (linux/amd64 + linux/arm64), every input pinned and checksum-verified.
#
# The developer environment (shell, editor, tmux) IS the USER'S OWN
# chezmoi-managed dotfiles, cloned + applied at build time (latest by
# default; pin with DOTFILES_REF). langdev provides only the hardened base
# + toolchain + the single nvim/plugins.local/lang.lua LSP drop-in.
#
# Stages:
#   toolchain  — Python dev toolchain (uv + hash-locked venv) + Ollama binary
#   env-build  — clone + chezmoi-apply the dotfiles, bake the nvim plugin set
#   base       — the shared langdev runtime (COMMON — kept in sync)
#   final      — copies the toolchain artifacts + Ollama onto the base
#
# Base is pinned BY DIGEST. Update via `make bump-base`.
ARG ALPINE_VERSION=3.22
# renovate: datasource=docker depName=alpine
ARG ALPINE_DIGEST=sha256:14358309a308569c32bdc37e2e0e9694be33a9d99e68afb0f5ff33cc1f695dce

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

# Dotfiles source — "always the latest" by default; pin a tag/commit for
# reproducible builds.
ARG DOTFILES_REPO=https://github.com/sebastienrousseau/dotfiles.git
ARG DOTFILES_REF=main

###############################################################################
# Stage: toolchain  (LANGUAGE-SPECIFIC)
#   Builds a relocatable /opt tree the final stage copies in wholesale:
#     /opt/venv    — Python dev tools, installed from a hash-pinned lockfile
#     /opt/ollama  — the pinned, checksum-verified Ollama runtime (CPU)
###############################################################################
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS toolchain

# Build deps are discarded with this stage; only /opt is copied forward.
# python3-dev/build-base/libffi-dev/yaml-dev let uv build any package that
# lacks a musllinux wheel from its (also hash-pinned) sdist.
# hadolint ignore=DL3018
RUN apk add --no-cache \
      ca-certificates curl tar zstd \
      python3 python3-dev \
      build-base libffi-dev yaml-dev \
 && update-ca-certificates

# --- uv (checksum-verified release binary; NOT `curl | sh`) ------------------
ARG UV_VERSION=0.12.7
ARG UV_SHA256_AMD64=3d64d44ed67da7908dc7f5c4d64ebb44bad326fa17f8a0a52fc9a7793017bbe1
ARG UV_SHA256_ARM64=6dcf60e3c085de88ace3671b949ca99f0652be561ff5627f0d21394140f041db
RUN set -eux; \
    arch="$(uname -m)"; \
    case "$arch" in \
      x86_64)  triple=x86_64-unknown-linux-musl;  sha="$UV_SHA256_AMD64" ;; \
      aarch64) triple=aarch64-unknown-linux-musl; sha="$UV_SHA256_ARM64" ;; \
      *) echo "unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    curl -fsSL -o /tmp/uv.tar.gz \
      "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-${triple}.tar.gz"; \
    printf '%s  %s\n' "$sha" /tmp/uv.tar.gz > /tmp/uv.sha256; \
    sha256sum -c /tmp/uv.sha256; \
    tar -xzf /tmp/uv.tar.gz -C /tmp; \
    install -m 0755 "/tmp/uv-${triple}/uv" /usr/local/bin/uv; \
    rm -rf /tmp/uv.tar.gz /tmp/uv.sha256 "/tmp/uv-${triple}"

# --- Python dev tools from a fully hash-pinned lockfile ----------------------
COPY requirements.lock /tmp/requirements.lock
RUN set -eux; \
    uv venv --python python3 /opt/venv; \
    uv pip install --python /opt/venv/bin/python \
      --require-hashes --no-cache -r /tmp/requirements.lock; \
    rm -f /tmp/requirements.lock; \
    find /opt/venv -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true

# --- Ollama runtime (pinned + checksum-verified; CPU runners only) -----------
ARG OLLAMA_VERSION=0.33.1
ARG OLLAMA_SHA256_AMD64=88e0d36bd90121595e5516c84f6ab61b546368fbd2d825b4aae70999c949649d
ARG OLLAMA_SHA256_ARM64=869b98629bf4a438d1c11669331c8214e8317cdfd7ec3fe4efd44fb929602f57
RUN set -eux; \
    arch="$(uname -m)"; \
    case "$arch" in \
      x86_64)  oarch=amd64; sha="$OLLAMA_SHA256_AMD64" ;; \
      aarch64) oarch=arm64; sha="$OLLAMA_SHA256_ARM64" ;; \
      *) echo "unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    curl -fsSL -o /tmp/ollama.tar.zst \
      "https://github.com/ollama/ollama/releases/download/v${OLLAMA_VERSION}/ollama-linux-${oarch}.tar.zst"; \
    printf '%s  %s\n' "$sha" /tmp/ollama.tar.zst > /tmp/ollama.sha256; \
    sha256sum -c /tmp/ollama.sha256; \
    mkdir -p /opt/ollama; \
    tar --use-compress-program=unzstd -xf /tmp/ollama.tar.zst -C /opt/ollama; \
    rm -f /tmp/ollama.tar.zst /tmp/ollama.sha256; \
    # CPU-only image: drop the multi-GB GPU (CUDA/ROCm) runner libraries.
    rm -rf /opt/ollama/lib/ollama/cuda_v* /opt/ollama/lib/ollama/rocm* \
           /opt/ollama/lib/ollama/cuda* 2>/dev/null || true; \
    /opt/ollama/bin/ollama --version >/dev/null 2>&1 || true

###############################################################################
# Stage: env-build  (COMMON — apply the user's dotfiles + bake nvim plugins)
###############################################################################
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS env-build
ARG USERNAME USER_UID USER_GID DOTFILES_REPO DOTFILES_REF
# Tools needed to clone+apply dotfiles and compile/install nvim plugins.
# hadolint ignore=DL3018
RUN apk add --no-cache \
      bash ca-certificates chezmoi curl git \
      neovim ripgrep fd fzf bat \
      build-base cmake
RUN addgroup -g "${USER_GID}" "${USERNAME}" \
 && adduser -D -u "${USER_UID}" -G "${USERNAME}" -s /bin/bash "${USERNAME}"
COPY --chown=${USER_UID}:${USER_GID} common/bootstrap-dotfiles.sh /usr/local/bin/langdev-bootstrap-dotfiles
RUN chmod 0755 /usr/local/bin/langdev-bootstrap-dotfiles
USER ${USERNAME}
ENV HOME=/home/${USERNAME}
# 1) Clone + chezmoi-apply the user's dotfiles (brings bashrc, tmux, nvim…).
RUN DOTFILES_REPO="${DOTFILES_REPO}" DOTFILES_REF="${DOTFILES_REF}" \
      langdev-bootstrap-dotfiles
# 2) Drop the language LSP spec into the dotfiles' nvim (auto-imported via
#    the config's `plugins.local`), then bake the full plugin set headless
#    so the runtime needs no network on first launch.
COPY --chown=${USER_UID}:${USER_GID} nvim/plugins.local/ /home/${USERNAME}/.config/nvim/lua/plugins.local/
RUN nvim --headless "+Lazy! restore" +qa 2>&1 | tail -n 5 || true \
 && nvim --headless "+Lazy! sync"    +qa 2>&1 | tail -n 5 || true \
 && nvim --headless "+TSUpdateSync"  +qa 2>&1 | tail -n 5 || true

###############################################################################
#                              COMMON BASE
###############################################################################
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS base
ARG USERNAME USER_UID USER_GID

LABEL org.opencontainers.image.title="llamadev" \
      org.opencontainers.image.description="Ollama LLM + Python dev environment on the langdev core" \
      org.opencontainers.image.licenses="Apache-2.0 OR MIT" \
      org.opencontainers.image.vendor="Sebastien Rousseau"

# Runtime deps: editor, multiplexer (tmux — available by default), and the
# CLI tools the dotfiles expect. `tini` is PID 1 (compose sets init:true).
# hadolint ignore=DL3018
RUN apk add --no-cache \
      bash \
      bat \
      ca-certificates \
      chezmoi \
      curl \
      fd \
      fzf \
      git \
      less \
      neovim \
      ripgrep \
      tini \
      tmux \
      tzdata \
      zoxide \
 && update-ca-certificates

RUN addgroup -g "${USER_GID}" "${USERNAME}" \
 && adduser -D -u "${USER_UID}" -G "${USERNAME}" -s /bin/bash "${USERNAME}"

# Bring in the fully-populated home from env-build: the applied dotfiles
# (~/.bashrc, ~/.config/tmux, ~/.config/nvim, ~/.config/shell/*, …) plus the
# baked nvim plugin set. One COPY captures everything chezmoi wrote.
COPY --from=env-build --chown=${USER_UID}:${USER_GID} /home/${USERNAME} /home/${USERNAME}

# Entrypoint (tmux-loading, strict-mode).
COPY common/entrypoint.sh /usr/local/bin/langdev-entrypoint
RUN chmod 0755 /usr/local/bin/langdev-entrypoint \
 && mkdir -p /usr/local/lib/langdev

# --- Hardening ---------------------------------------------------------------
# Sticky bit preserved (1777, NOT 777). Strip any setuid/setgid bits.
RUN chmod 1777 /tmp \
 && find / -xdev -type f \( -perm -4000 -o -perm -2000 \) -exec chmod -s {} + 2>/dev/null || true

USER ${USERNAME}
WORKDIR /work
ENV HOME=/home/${USERNAME} \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    EDITOR=nvim \
    XDG_CONFIG_HOME=/home/${USERNAME}/.config \
    XDG_DATA_HOME=/home/${USERNAME}/.local/share \
    XDG_STATE_HOME=/home/${USERNAME}/.local/state \
    XDG_CACHE_HOME=/home/${USERNAME}/.cache

# Cheap, honest liveness probe (no full-FS scans).
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD nvim --version >/dev/null 2>&1 || exit 1

ENTRYPOINT ["/usr/local/bin/langdev-entrypoint"]

###############################################################################
# Stage: final  (llamadev = base + Python toolchain + Ollama)
###############################################################################
FROM base AS final

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

USER root

# Runtime deps: Python for the venv interpreter; libstdc++/libgcc/libgomp for
# Ollama's llama.cpp runners; gcompat is the glibc shim the (glibc-built)
# Ollama binary needs on musl. (`curl`, used by the runtime hook to probe the
# API, already comes from the base stage.)
# hadolint ignore=DL3018
RUN apk add --no-cache \
      python3 \
      libstdc++ libgcc libgomp \
      gcompat \
 && update-ca-certificates

# Python dev toolchain (hash-locked venv) and the Ollama runtime.
COPY --from=toolchain --chown=${USER_UID}:${USER_GID} /opt/venv   /opt/venv
COPY --from=toolchain --chown=${USER_UID}:${USER_GID} /opt/ollama /opt/ollama

# Language PATH/env for LOGIN shells (sourced via /etc/profile → profile.d).
# Root-owned, 0644. Kept OUT of the user's chezmoi dotfiles so those stay
# pristine and langdev-agnostic. This is IN ADDITION to the container ENV
# below (needed by the non-login entrypoint/runtime-hook) and the compose env.
COPY dotfiles.d/llamadev.sh /etc/profile.d/llamadev.sh
RUN chmod 0644 /etc/profile.d/llamadev.sh

# Runtime hook: the common entrypoint SOURCES this (before it execs tmux/shell)
# to start Ollama on loopback. It stays installed under /usr/local/lib/langdev.
COPY runtime-hook.sh /usr/local/lib/langdev/runtime-hook.sh
RUN chmod 0755 /usr/local/lib/langdev/runtime-hook.sh \
 # Model store lives on a named volume at runtime (read-only rootfs); create
 # the mount point up front, owned by the non-root user.
 && mkdir -p /home/${USERNAME}/.ollama \
 && chown ${USER_UID}:${USER_GID} /home/${USERNAME}/.ollama

USER ${USERNAME}
WORKDIR /work

# Toolchain on PATH; loopback-only, unauthenticated Ollama bound to localhost.
# PATH is set here (not only in profile.d) so the non-login entrypoint and its
# runtime-hook can find `ollama` before the login shell/tmux is exec'd.
ENV VIRTUAL_ENV=/opt/venv \
    PATH="/opt/venv/bin:/opt/ollama/bin:/home/dev/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    OLLAMA_HOST=127.0.0.1:11434 \
    OLLAMA_MODELS=/home/dev/.ollama \
    OLLAMA_DEFAULT_MODEL=qwen2.5-coder \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
