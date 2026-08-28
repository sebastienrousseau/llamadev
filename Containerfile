# syntax=docker/dockerfile:1.9
# llamadev Containerfile — OCI, builds with Docker AND Podman.
# SPDX-License-Identifier: MIT
#
# An Ollama LLM development environment built on the shared langdev core:
# non-root, all-caps-dropped, read-only-rootfs friendly, multi-arch
# (linux/amd64 + linux/arm64), every input pinned and checksum-verified.
#
# Stages:
#   toolchain  — Python dev toolchain (uv + hash-locked venv) + Ollama binary
#   nvim-build — bakes Neovim + the pinned plugin set (no network at runtime)
#   base       — the shared langdev runtime (COMMON — kept in sync)
#   final      — copies the toolchain artifacts onto the base
#
# Base is pinned BY DIGEST. Update via `make bump-base`.
ARG ALPINE_VERSION=3.22
# renovate: datasource=docker depName=alpine
ARG ALPINE_DIGEST=sha256:14358309a308569c32bdc37e2e0e9694be33a9d99e68afb0f5ff33cc1f695dce

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
# Stage: nvim-build  (COMMON — bakes the editor + plugins into the image)
###############################################################################
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS nvim-build
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000
# hadolint ignore=DL3018
RUN apk add --no-cache \
      bash ca-certificates curl git \
      neovim ripgrep fd \
      build-base cmake
# LazyVim starter pinned to a commit (reproducible); overridable at build.
ARG LAZYVIM_STARTER_REF=c31e5cc9f77b16d20a693c30f28fdf907f1caf95
ENV XDG_CONFIG_HOME=/root/.config \
    XDG_DATA_HOME=/root/.local/share \
    XDG_STATE_HOME=/root/.local/state \
    XDG_CACHE_HOME=/root/.cache
RUN git clone --filter=blob:none https://github.com/LazyVim/starter /root/.config/nvim \
 && git -C /root/.config/nvim checkout "${LAZYVIM_STARTER_REF}" \
 && rm -rf /root/.config/nvim/.git
# Common + language plugin specs.
COPY common/nvim/plugins/ /root/.config/nvim/lua/plugins/
COPY nvim/plugins/ /root/.config/nvim/lua/plugins/
# Reproducible plugin set: restore from committed lockfile, then sync.
COPY nvim/lazy-lock.json /root/.config/nvim/lazy-lock.json
RUN nvim --headless "+Lazy! restore" +qa 2>&1 | tail -n 5 || true \
 && nvim --headless "+TSUpdateSync" +qa 2>&1 | tail -n 5 || true

###############################################################################
#                              COMMON BASE
###############################################################################
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS base

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

LABEL org.opencontainers.image.title="llamadev" \
      org.opencontainers.image.description="Ollama LLM + Python dev environment on the langdev core" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.vendor="Sebastien Rousseau"

# Minimal, pinned runtime. `tini` is the init (compose sets init:true, but
# shipping it keeps `docker run` correct too).
# hadolint ignore=DL3018
RUN apk add --no-cache \
      bash \
      ca-certificates \
      curl \
      git \
      less \
      neovim \
      ripgrep \
      fd \
      tini \
      tzdata \
 && update-ca-certificates

# Non-root user with a real home.
RUN addgroup -g "${USER_GID}" "${USERNAME}" \
 && adduser -D -u "${USER_UID}" -G "${USERNAME}" -s /bin/bash "${USERNAME}"

# Portable dotfiles.
COPY --chown=${USER_UID}:${USER_GID} common/dotfiles/bashrc        /home/${USERNAME}/.bashrc
COPY --chown=${USER_UID}:${USER_GID} common/dotfiles/bash_profile  /home/${USERNAME}/.bash_profile
COPY --chown=${USER_UID}:${USER_GID} common/dotfiles/bash_aliases  /home/${USERNAME}/.bash_aliases

# Editor + baked-in plugins from the nvim-build stage.
COPY --from=nvim-build --chown=${USER_UID}:${USER_GID} /root/.config/nvim /home/${USERNAME}/.config/nvim
COPY --from=nvim-build --chown=${USER_UID}:${USER_GID} /root/.local/share/nvim /home/${USERNAME}/.local/share/nvim

# Entrypoint.
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

# Runtime hook: the common entrypoint sources this to start Ollama on loopback.
COPY runtime-hook.sh /usr/local/lib/langdev/runtime-hook.sh
RUN chmod 0755 /usr/local/lib/langdev/runtime-hook.sh \
 # Model store lives on a named volume at runtime (read-only rootfs); create
 # the mount point up front, owned by the non-root user.
 && mkdir -p /home/${USERNAME}/.ollama \
 && chown ${USER_UID}:${USER_GID} /home/${USERNAME}/.ollama

USER ${USERNAME}
WORKDIR /work

# Toolchain on PATH; loopback-only, unauthenticated Ollama bound to localhost.
ENV VIRTUAL_ENV=/opt/venv \
    PATH="/opt/venv/bin:/opt/ollama/bin:/home/dev/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    OLLAMA_HOST=127.0.0.1:11434 \
    OLLAMA_MODELS=/home/dev/.ollama \
    OLLAMA_DEFAULT_MODEL=qwen2.5-coder \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
