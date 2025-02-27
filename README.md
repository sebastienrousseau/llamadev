# LlamaDev (llamadev)

<!-- markdownlint-disable MD033 MD041 -->
<img src="https://kura.pro/llamadev/images/logos/llamadev.svg"
alt="LlamaDev logo" height="66" align="right" />
<!-- markdownlint-enable MD033 MD041 -->

An opinionated, secure, Debian-based container providing a complete Python development environment with NeoVim configuration and Ollama for local AI assistance. Engineered for safety, efficiency, and developer productivity. **This is not an official Python project** and is not affiliated with or supported by the Python Software Foundation.

<!-- markdownlint-disable MD033 MD041 -->
<center>
<!-- markdownlint-enable MD033 MD041 -->

[![Made with Debian][debian-badge]][08] [![Container][container-badge]][03] [![Python][python-badge]][01] [![NeoVim][neovim-badge]][04] [![Ollama][ollama-badge]][09] [![Security][security-badge]][06] [![Build Status][build-badge]][07]

• [Features](#key-features) • [Prerequisites](#prerequisites) • [Installation](#installation) • [Configuration](#configuration) • [Security](#security)

<!-- markdownlint-disable MD033 MD041 -->
</center>
<!-- markdownlint-enable MD033 MD041 -->

## Disclaimer

This is an opinionated development environment that reflects specific preferences for tooling, configuration, and workflow. It is:

- Not an official Python project
- Not affiliated with or supported by the Python Software Foundation or its contributors
- Not intended to be a one-size-fits-all solution
- Maintained independently and based on open-source projects
- Provided as-is with no warranties (see [License](#license))

## Overview

**LlamaDev** is a containerized Python development environment that prioritizes security, performance, and developer convenience. Built on Debian for reliability, it includes a pre-configured NeoVim setup with LazyVim, Python-specific tooling, intelligent code completion, Ollama for local AI assistance, and Git integration.

## Key Features

- **Security Standards**
  - Multi-stage build with secret scanning
  - OCI container verification and trust
  - Base image digest verification
  - Content trust enforcement
  - SECCOMP profile implementation
  - Enhanced security labels
  - Regular vulnerability scanning

- **Secure by Design**
  - Debian slim base with minimal attack surface
  - Non-root user operation (UID 1000)
  - Comprehensive security hardening
  - PAM security implementation
  - Container isolation and resource limits
  - Core dump protection
  - SUID/SGID binary removal
  - System file immutability

- **Python Development Tools**
  - Python 3.13.2 with virtual environment
  - UV package installer for faster dependency management
  - Virtual environment configuration
  - Optimized Python build
  - Complete stdlib verification
  - Path isolation and environment control

- **Enhanced Development Experience**
  - NeoVim with LazyVim configuration
  - Ollama integration for local AI assistance
  - Intelligent code completion
  - Syntax highlighting
  - Git integration
  - Terminal integration
  - Fuzzy finding

## Prerequisites

- Docker 24.0+ or Podman 4.0+
- Minimum 4GB RAM (8GB recommended)
- At least 10GB free disk space
- Git 2.40 or newer
- Terminal with SSH support

## Installation

1. **Clone the repository:**

```bash
git clone <https://github.com/sebastienrousseau/llamadev.git>
cd llamadev
```

2. **Configure the environment (optional):**
   Default values are provided, but you can customize in `.env`:

```bash
LANG="C.UTF-8"
NAME="LlamaDev"
OS="debian"
PYTHON_VERSION="3.13.2"
SHELL="/bin/bash"
TZ="UTC"
USER_HOME="/home/llamadev"
USERNAME="llamadev"
VERSION="0.0.1"
```

3. **Build and start the development environment:**

*Using Docker:*

```bash
# Build and start with Docker Compose
docker-compose up --build -d

# Or build and run manually
docker build -t llamadev -f Dockerfile .
docker run -it --security-opt=no-new-privileges:true \
           --cap-drop=ALL --cap-add=NET_BIND_SERVICE \
           -p 11434:11434 -p 8080:8080 \
           -v "$(pwd):/home/llamadev/code" \
           -v ollama_models:/home/llamadev/.ollama \
           llamadev
```

*Using Podman:*

```bash
# Build and start with Podman Compose
podman-compose up --build -d

# Build and start with Podman
podman build -t llamadev -f Containerfile .
podman run -it --security-opt=no-new-privileges:true \
           --cap-drop=ALL --cap-add=NET_BIND_SERVICE \
           -p 11434:11434 -p 8080:8080 \
           -v "$(pwd):/home/llamadev/code" \
           -v ollama_models:/home/llamadev/.ollama \
           llamadev
```

4. **Access the container:**

*Using Docker:*

```bash
# New shell in running container
docker exec -it llamadev bash

# Reattach to stopped container
docker start -ai llamadev
```

*Using Podman:*

```bash
# New shell in running container
podman exec -it llamadev bash

# Reattach to stopped container
podman start -ai llamadev
```

## Configuration

### Docker commands

```bash
docker ps                   # List running containers
docker stop llamadev       # Stop the container
docker start llamadev      # Start the container
docker rm llamadev         # Remove the container
docker volume ls            # List volumes
```

### Podman equivalent

```bash
podman ps                   # List running containers
podman stop llamadev       # Stop the container
podman start llamadev      # Start the container
podman rm llamadev         # Remove the container
podman volume ls            # List volumes
```

### Environment Variables

The container uses pre-configured environment variables with sensible defaults:

```bash
DOCKER_CONTENT_TRUST=1       # Enable Docker content trust
SECCOMP_PROFILE=default      # Security computing mode profile
PYTHONHOME=/opt/venv         # Python installation directory
PYTHONPATH=/opt/venv/lib/python3.13/site-packages
PYTHONDONTWRITEBYTECODE=1    # Prevent Python from writing pyc files
PYTHONUNBUFFERED=1           # Prevent Python from buffering stdout/stderr
NO_NEW_PRIVILEGES=true       # Ensure no process can gain additional privileges
```

### Docker Configuration

Example `docker-compose.yml`:

```yaml
services:
  llamadev:
    image: llamadev
    container_name: llamadev

    build:
      context: .
      args:
        PYTHON_VERSION: "${PYTHON_VERSION}"
        USERNAME: "${USERNAME}"
        USER_HOME: "${USER_HOME}"

    env_file:
      - .env

    environment:
      PATH: "/opt/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
      LANG: "C.UTF-8"
      LC_ALL: "C.UTF-8"
      PYTHON_VERSION: "${PYTHON_VERSION}"
      USERNAME: "${USERNAME}"
      USER_HOME: "${USER_HOME}"
      OLLAMA_HOST: "0.0.0.0:11434"

    user: "1000:1000"
    working_dir: "/home/llamadev/code"
    stdin_open: true
    tty: true
    restart: unless-stopped

    ports:
      - "11434:11434"

    volumes:
      - llamadev:/home/llamadev/.ollama
      - ./start.sh:/start.sh

    command: ["/bin/bash", "-c", "source /opt/venv/bin/activate && exec /start.sh"]

volumes:
  llamadev: {}
```

### Podman Configuration

Example `podman-compose.yml`:

```yaml
services:
  llamadev:
    image: llamadev
    container_name: llamadev

    build:
      context: .
      args:
        PYTHON_VERSION: "${PYTHON_VERSION}"
        USERNAME: "${USERNAME}"
        USER_HOME: "${USER_HOME}"

    env_file:
      - .env

    environment:
      PATH: "/opt/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
      LANG: "C.UTF-8"
      LC_ALL: "C.UTF-8"
      PYTHON_VERSION: "${PYTHON_VERSION}"
      USERNAME: "${USERNAME}"
      USER_HOME: "${USER_HOME}"
      OLLAMA_HOST: "0.0.0.0:11434"

    user: "1000:1000"
    working_dir: "/home/llamadev/code"
    stdin_open: true
    tty: true
    restart: unless-stopped

    ports:
      - "11434:11434"

    volumes:
      - llamadev:/home/llamadev/.ollama
      - ./start.sh:/start.sh

    command: ["/bin/bash", "-c", "source /opt/venv/bin/activate && exec /start.sh"]

volumes:
  llamadev: {}
```

## Development Workflow

1. **Mount your code directory:**

   ```bash
   # Docker
   docker run -it -v "$(pwd):/home/llamadev/code" llamadev

   # Podman
   podman run -it -v "$(pwd):/home/llamadev/code" llamadev
   ```

2. **For web development, expose ports:**

   ```bash
   # Docker
   docker run -it -v "$(pwd):/home/llamadev/code" -p 8080:8080 llamadev

   # Podman
   podman run -it -v "$(pwd):/home/llamadev/code" -p 8080:8080 llamadev
   ```

3. **Using Ollama for local AI assistance:**

   ```bash
   # Inside the container
   ollama pull llama3
   ollama run llama3
   ```

## Security

The container implements multiple layers of security:

- Multi-stage build with secret scanning
- Non-root user operation (UID 1000)
- Minimal Debian slim base image
- Content trust verification
- SECCOMP profile implementation
- Resource limitations
- Regular security updates
- System hardening
- Core dump protection
- SUID/SGID removal
- File system restrictions
- Process isolation
- User access control
- Enhanced healthchecks
- No-new-privileges enforcement
- Capability dropping (principle of least privilege)

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

[debian-badge]: https://img.shields.io/badge/Debian-A81D33?style=for-the-badge&logo=debian&logoColor=white
[container-badge]: https://img.shields.io/badge/Container-2496ED?style=for-the-badge&logo=docker&logoColor=white
[python-badge]: https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white
[neovim-badge]: https://img.shields.io/badge/NeoVim-57A143?style=for-the-badge&logo=neovim&logoColor=white
[ollama-badge]: https://img.shields.io/badge/Ollama-AI-orange?style=for-the-badge
[security-badge]: https://img.shields.io/badge/Security-Hardened-success?style=for-the-badge
[build-badge]: https://img.shields.io/badge/Build-Passing-success?style=for-the-badge

[01]: https://www.python.org
[03]: https://www.docker.com
[04]: https://neovim.io
[06]: #security
[07]: https://github.com/sebastienrousseau/llamadev/actions
[08]: https://www.debian.org
[09]: https://ollama.ai
