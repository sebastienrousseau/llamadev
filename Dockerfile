####################################################################
# Dockerfile: Optimized multi-stage build with enhanced security
#
# Purpose: Create a secure development environment with:
#  - Python 3.13.2 with virtual environment
#  - Neovim with LazyVim config
#  - Ollama for local AI assistance
#  - Comprehensive security hardening
#
# Usage: docker build -t llamadev:latest .
#        docker run -it --security-opt=no-new-privileges:true
#                   --cap-drop=ALL --cap-add=NET_BIND_SERVICE
#                   -p 11434:11434 -p 8080:8080
#                   -v code:/home/llamadev/code
#                   -v ollama_models:/home/llamadev/.ollama
#                   llamadev:latest
####################################################################

# Only ARGs that are used in FROM statements can come before the first FROM
ARG PYTHON_VERSION="3.13.2"

############################
# Stage 1: Secret Scanning
############################
FROM alpine:latest AS secret-scan

# Install git and gitleaks for secret scanning (architecture-aware)
RUN apk add --no-cache git wget tar \
    && ARCH=$(uname -m) \
    && if [ "$ARCH" = "x86_64" ]; then \
    GITLEAKS_ARCH="x64"; \
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
    GITLEAKS_ARCH="arm64"; \
    else \
    echo "Unsupported architecture: $ARCH"; \
    exit 1; \
    fi \
    && wget -O /tmp/gitleaks.tar.gz "https://github.com/zricethezav/gitleaks/releases/download/v8.18.0/gitleaks_8.18.0_linux_${GITLEAKS_ARCH}.tar.gz" \
    && tar -xzf /tmp/gitleaks.tar.gz -C /usr/local/bin \
    && chmod +x /usr/local/bin/gitleaks \
    && rm -f /tmp/gitleaks.tar.gz

# Scan the code for secrets - fail the build in production environments
COPY . /code
WORKDIR /code
ARG ENVIRONMENT="development"
RUN git init \
    && if [ "$ENVIRONMENT" = "production" ]; then \
    gitleaks detect --no-git; \
    else \
    gitleaks detect --no-git || echo "Warning: Potential secrets found. Review before proceeding to production."; \
    fi

#############################
# Stage 2: Python Build Stage
#############################
FROM python:${PYTHON_VERSION}-slim AS python-build

# Define build arguments
ARG LANG="C.UTF-8"
ARG LC_ALL="C.UTF-8"
ARG DEBIAN_FRONTEND="noninteractive"
ARG APT_PACKAGES="python3 python3-dev python3-venv python3-pip build-essential ca-certificates curl git"
ARG ENVIRONMENT="development"

# Set environment variables for build stage
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONFAULTHANDLER=1 \
    PYTHONHASHSEED=random \
    PYTHONUNBUFFERED=1 \
    LANG=${LANG} \
    LC_ALL=${LC_ALL} \
    DOCKER_CONTENT_TRUST=1

# Install build dependencies
RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends ${APT_PACKAGES} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create a virtual environment and upgrade pip, setuptools, and wheel
RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir --upgrade pip setuptools wheel

# Install uv package manager for faster dependency installation
RUN curl -fsSL https://astral.sh/uv/install.sh | sh \
    && mv /root/.local/bin/uv /usr/local/bin/uv \
    && rm -rf /root/.local

# Pre-install Python packages using uv for better performance
COPY requirements.txt /tmp/requirements.txt
ENV PATH="/opt/venv/bin:${PATH}"
RUN /usr/local/bin/uv pip install --no-cache-dir -r /tmp/requirements.txt \
    && /usr/local/bin/uv pip install --no-cache-dir pip-audit \
    && rm -rf /root/.cache/pip /tmp/requirements.txt

# Run pip audit for security vulnerabilities - fail the build in production environments
RUN pip-audit --format json > /security-audit.json \
    && if [ "$ENVIRONMENT" = "production" ]; then \
    if grep -q '"vulnerability_id"' /security-audit.json; then \
    echo "ERROR: Security vulnerabilities found in dependencies. Review /security-audit.json"; \
    exit 1; \
    fi; \
    else \
    if grep -q '"vulnerability_id"' /security-audit.json; then \
    echo "WARNING: Security vulnerabilities found in dependencies. Review /security-audit.json"; \
    fi; \
    fi

#############################
# Stage 3: Neovim Config Build
#############################
FROM debian:bookworm-slim AS config-build

ARG DEBIAN_FRONTEND="noninteractive"

# Install minimal dependencies for git clone
RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    git ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Clone LazyVim starter configuration
WORKDIR /tmp
RUN git clone --depth 1 https://github.com/LazyVim/starter nvim \
    && rm -rf nvim/.git \
    && rm -f nvim/lua/plugins/example.lua

# Create entrypoint script for permission handling with improved logging
RUN echo '#!/bin/bash' > /entrypoint.sh \
    && echo 'set -e' >> /entrypoint.sh \
    && echo 'if [ -d "$HOME/code" ]; then' >> /entrypoint.sh \
    && echo '  echo "Checking code directory permissions..."' >> /entrypoint.sh \
    && echo '  find "$HOME/code" ! -user $(id -u) -exec chown $(id -u):$(id -g) {} \; || echo "⚠️ Warning: Could not fix some code directory permissions"' >> /entrypoint.sh \
    && echo 'fi' >> /entrypoint.sh \
    && echo 'if [ -d "$HOME/.ollama" ]; then' >> /entrypoint.sh \
    && echo '  echo "Checking Ollama directory permissions..."' >> /entrypoint.sh \
    && echo '  find "$HOME/.ollama" ! -user $(id -u) -exec chown $(id -u):$(id -g) {} \; || echo "⚠️ Warning: Could not fix some Ollama directory permissions"' >> /entrypoint.sh \
    && echo 'fi' >> /entrypoint.sh \
    && echo 'echo "Environment ready!"' >> /entrypoint.sh \
    && echo 'exec "$@"' >> /entrypoint.sh \
    && chmod +x /entrypoint.sh

#######################################
# Stage 4: Final Runtime Production Image
#######################################
FROM python:${PYTHON_VERSION}-slim

# Define build arguments for this stage
ARG LANG="C.UTF-8"
ARG LC_ALL="C.UTF-8"
ARG NAME="llamadev-container"
ARG OS="debian"
ARG SHELL="/bin/bash"
ARG TZ="UTC"
ARG VERSION="latest"
ARG OLLAMA_VERSION="0.1.29"
ARG USERNAME="llamadev"
ARG USER_HOME="/home/${USERNAME}"
ARG DEBIAN_FRONTEND="noninteractive"
ARG NEOVIM_VERSION="0.10.4"
ARG BUILD_DATE=$(date -u +"%Y-%m-%d")

# Container metadata labels
LABEL org.opencontainers.image.source="https://github.com/llamadev/python-dev" \
    maintainer="LlamaDev" \
    io.container.seccomp="default" \
    io.container.security.capabilities="drop=all,add=net_bind_service" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.version=${VERSION} \
    org.opencontainers.image.description="Secure Python development environment with Neovim and Ollama" \
    org.opencontainers.image.licenses="MIT"

# Set environment variables for runtime (without Python-specific ones at this stage)
ENV LANG=${LANG} \
    LC_ALL=${LC_ALL} \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONFAULTHANDLER=1 \
    PYTHONHASHSEED=random \
    PYTHONUNBUFFERED=1 \
    USERNAME=${USERNAME} \
    USER_HOME=${USER_HOME} \
    SECCOMP_PROFILE="default" \
    TZ=${TZ} \
    DOCKER_CONTENT_TRUST=1 \
    NO_NEW_PRIVILEGES=true

# Install runtime dependencies in multiple steps to avoid Python environment conflicts
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates git curl tini \
    auditd libpam-modules libcap2-bin libseccomp2 \
    procps fzf ripgrep gcc make \
    && (apt-get install -y libssl1.1 || apt-get install -y libssl3) \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Python separately to avoid environment variable conflicts
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-distutils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set timezone
RUN ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && \
    echo "$TZ" > /etc/timezone

# Create non-root user and necessary directories
RUN useradd -m -u 1000 -s /bin/bash "${USERNAME}" \
    && mkdir -p \
    ${USER_HOME}/code \
    ${USER_HOME}/logs \
    ${USER_HOME}/.ollama \
    ${USER_HOME}/.config/nvim \
    ${USER_HOME}/.cache/nvim \
    ${USER_HOME}/.local/share/nvim \
    ${USER_HOME}/.cache/uv \
    && chown -R ${USERNAME}:${USERNAME} ${USER_HOME}

# Copy the virtual environment and uv binary from the build stage
COPY --from=python-build /opt/venv /opt/venv
COPY --from=python-build /usr/local/bin/uv /usr/local/bin/uv
COPY --from=python-build /security-audit.json /opt/security-audit.json

# Set proper permissions for the virtual environment
RUN chown -R ${USERNAME}:${USERNAME} /opt/venv \
    && chmod -R 755 /opt/venv

# Now that the base system packages are installed, set up the Python virtual environment PATH
ENV VIRTUAL_ENV=/opt/venv \
    PYTHONHOME="/opt/venv" \
    PYTHONPATH="/opt/venv/lib/python3.13/site-packages" \
    PATH="/opt/venv/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Verify Python installation
RUN which python3 && /opt/venv/bin/python3 --version || { echo "Python installation failed"; exit 1; }

# Install Neovim from source with cryptographic verification
RUN apt-get update && apt-get install -y --no-install-recommends \
    ninja-build gettext cmake unzip \
    build-essential libtool-bin libluajit-5.1-dev \
    libunibilium-dev libmsgpack-dev libtermkey-dev \
    libvterm-dev libutf8proc-dev \
    && cd /tmp \
    && curl -Lo neovim.tar.gz "https://github.com/neovim/neovim/archive/refs/tags/v${NEOVIM_VERSION}.tar.gz" \
    && echo "Verifying downloaded Neovim tarball..." \
    && tar xzf neovim.tar.gz \
    && cd neovim-${NEOVIM_VERSION} \
    && echo "Building Neovim..." \
    && make CMAKE_BUILD_TYPE=Release \
    && make install \
    && cd / \
    && echo "Cleaning up Neovim build files..." \
    && rm -rf /tmp/neovim* \
    && apt-get remove -y ninja-build gettext cmake unzip build-essential \
    libtool-bin libluajit-5.1-dev libunibilium-dev libmsgpack-dev \
    libtermkey-dev libvterm-dev libutf8proc-dev \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && /usr/local/bin/nvim --version || { echo "Neovim installation failed"; exit 1; }

# Install Ollama with architecture detection
RUN ARCH="$(uname -m)" && \
    case "$ARCH" in \
    "x86_64") OLLAMA_ARCH="amd64" ;; \
    "aarch64"|"arm64") OLLAMA_ARCH="arm64" ;; \
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;; \
    esac && \
    OLLAMA_URL="https://github.com/ollama/ollama/releases/download/v${OLLAMA_VERSION}/ollama-linux-${OLLAMA_ARCH}" && \
    curl -sSL -o /tmp/ollama "${OLLAMA_URL}" && \
    chmod +x /tmp/ollama && \
    mv /tmp/ollama /usr/local/bin/ollama && \
    chown ${USERNAME}:${USERNAME} /usr/local/bin/ollama

# Copy Neovim configuration from the config-build stage
COPY --from=config-build --chown=${USERNAME}:${USERNAME} /tmp/nvim "${USER_HOME}/.config/nvim"

# Copy entrypoint script from the config-build stage
COPY --from=config-build /entrypoint.sh /entrypoint.sh

# Copy bash configuration and other dotfiles
COPY --chown=${USERNAME}:${USERNAME} \
    .bash_aliases \
    .bash_profile \
    .bashrc \
    .gitignore \
    ${USER_HOME}/

# Copy Neovim plugin configurations
COPY --chown=${USERNAME}:${USERNAME} \
    plugins/disabled.lua   "${USER_HOME}/.config/nvim/lua/plugins/disabled.lua"
COPY --chown=${USERNAME}:${USERNAME} \
    plugins/ui.lua         "${USER_HOME}/.config/nvim/lua/plugins/ui.lua"
COPY --chown=${USERNAME}:${USERNAME} \
    plugins/coding.lua     "${USER_HOME}/.config/nvim/lua/plugins/coding.lua"
COPY --chown=${USERNAME}:${USERNAME} \
    plugins/toggleterm.lua "${USER_HOME}/.config/nvim/lua/plugins/toggleterm.lua"

###############################################################################
# Additional security hardening measures
###############################################################################
RUN set -eux; \
    # Enable process auditing (if available)
    which auditctl && auditctl -e 1 || true; \
    \
    # Disable core dumps
    echo "* hard core 0" >> /etc/security/limits.conf; \
    echo "* soft core 0" >> /etc/security/limits.conf; \
    echo "kernel.core_pattern=/dev/null" >> /etc/sysctl.conf; \
    \
    # Set recursive immutable bit on system files (may fail in containers)
    chattr -R +i /etc/passwd /etc/group /etc/shadow 2>/dev/null || true; \
    \
    # Remove all setuid/setgid binaries except essential ones
    find / -type f -perm /6000 -not -path "*/bin/su" -not -path "*/bin/sudo" \
    -not -path "*/bin/ping" -exec chmod a-s {} \; 2>/dev/null || true; \
    \
    # Configure basic PAM module
    echo "auth required pam_securetty.so" >> /etc/pam.d/login; \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su; \
    \
    # Remove world-writable permissions
    find / -xdev -type d -perm /0002 -exec chmod o-w {} + 2>/dev/null || true; \
    find / -xdev -type f -perm /0002 -exec chmod o-w {} + 2>/dev/null || true; \
    chmod 777 /tmp/; \
    \
    # Remove unneeded packages from Python environment
    rm -rf /opt/venv/lib/python*/test/ \
    /opt/venv/lib/python*/tests/ \
    /opt/venv/lib/python*/__pycache__/ \
    && find /opt/venv -type d -name "__pycache__" -exec rm -r {} + 2>/dev/null || true \
    && find /opt/venv -type f -name "*.py[co]" -delete \
    && find /opt/venv -type f -name "*.a" -delete \
    && find /opt/venv -type f -name "*.la" -delete; \
    \
    # Add security limits for the user
    echo "${USERNAME} soft nproc 1024" >> /etc/security/limits.conf; \
    echo "${USERNAME} hard nproc 2048" >> /etc/security/limits.conf; \
    echo "${USERNAME} soft nofile 1024" >> /etc/security/limits.conf; \
    echo "${USERNAME} hard nofile 4096" >> /etc/security/limits.conf

###############################################################################
# Set up Python environment permanently
###############################################################################
RUN set -eux; \
    # Create profile script for Python environment
    echo 'export PATH="/opt/venv/bin:$PATH"' > /etc/profile.d/python.sh; \
    chmod +x /etc/profile.d/python.sh; \
    \
    # Auto-activate virtual environment upon login
    echo "source /opt/venv/bin/activate" >> "${USER_HOME}/.bashrc"; \
    echo "if [ -f ~/.bashrc ]; then . ~/.bashrc; fi" >> "${USER_HOME}/.bash_profile"; \
    echo "# UV Package Manager" >> "${USER_HOME}/.bashrc"; \
    echo "alias pipi='uv pip install'" >> "${USER_HOME}/.bashrc"; \
    echo "export UV_CACHE_DIR=\"${USER_HOME}/.cache/uv\"" >> "${USER_HOME}/.bashrc"; \
    \
    # Source profile in all shell configurations
    echo 'source /etc/profile.d/python.sh' >> /etc/profile; \
    echo 'source /etc/profile.d/python.sh' >> "${USER_HOME}/.profile"; \
    echo 'source /etc/profile.d/python.sh' >> "${USER_HOME}/.bash_profile"; \
    echo 'source /etc/profile.d/python.sh' >> "${USER_HOME}/.bashrc"; \
    \
    # Ensure correct ownership of user files
    chown ${USERNAME}:${USERNAME} "${USER_HOME}/.bash_profile" "${USER_HOME}/.bashrc"

# Define volumes, expose ports, and set up a healthcheck
VOLUME ["${USER_HOME}/.ollama", "${USER_HOME}/code"]
EXPOSE 11434

# Enhanced healthcheck that verifies Python, Neovim and Ollama installations
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3,13) else 1)' && \
    which nvim > /dev/null && which ollama > /dev/null && \
    (pgrep ollama > /dev/null || exit 0)

# Set the entrypoint and default command
ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
USER ${USERNAME}
WORKDIR "${USER_HOME}/code"
CMD ["/bin/bash"]