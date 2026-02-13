# LlamaDev

<!-- markdownlint-disable MD033 MD041 -->
<img src="https://kura.pro/llamadev/images/logos/llamadev.svg"
alt="LlamaDev logo" height="66" align="right" />
<!-- markdownlint-enable MD033 MD041 -->

**A portable, AI-powered Python IDE that runs anywhere.**

LlamaDev is a self-contained development environment combining NeoVim + Ollama in a lightweight container. Think VS Code with Copilot, but faster, more portable, and runs on anything from your laptop to a headless server.

<!-- markdownlint-disable MD033 MD041 -->
<center>
<!-- markdownlint-enable MD033 MD041 -->

[![Made with Debian][debian-badge]][08] [![Container][container-badge]][03] [![Python][python-badge]][01] [![NeoVim][neovim-badge]][04] [![Ollama][ollama-badge]][09] [![Security][security-badge]][06] [![Build Status][build-badge]][07]

• [Why LlamaDev](#why-llamadev) • [Quick Start](#quick-start) • [Features](#features) • [Configuration](#configuration) • [Security](#security)

<!-- markdownlint-disable MD033 MD041 -->
</center>
<!-- markdownlint-enable MD033 MD041 -->

## Why LlamaDev?

| Problem | LlamaDev Solution |
|---------|-------------------|
| VS Code/PyCharm are heavy and slow to start | NeoVim starts instantly, even in containers |
| AI assistants require cloud APIs and subscriptions | Ollama runs locally - no API keys, no costs, full privacy |
| Setting up a dev environment takes hours | Single `docker run` command, ready in seconds |
| Can't run your IDE on a remote server | Works anywhere - laptops, servers, cloud VMs, CI/CD |
| Different environments = different setups | Same container = identical experience everywhere |

### Key Benefits

- **Instant startup** - NeoVim launches in milliseconds, not minutes
- **Truly portable** - One container runs on macOS, Linux, Windows (WSL), ARM, x86
- **Local AI assistance** - Ollama provides code completion and chat without internet
- **Memory efficient** - Runs comfortably in 4GB RAM (vs 8GB+ for Electron-based IDEs)
- **Server-friendly** - SSH into any machine, pull the container, start coding
- **Self-contained** - Python, linting, formatting, testing, debugging - all included

## Quick Start

### Using Docker

```bash
# Start LlamaDev with your project mounted
docker run -it --rm \
  -v "$(pwd):/home/llamadev/code" \
  -p 11434:11434 \
  ghcr.io/sebastienrousseau/llamadev:latest

# Or build from source
cd docker && docker-compose up --build -d
docker exec -it llamadev bash
```

### Using Podman

```bash
# Start LlamaDev with your project mounted
podman run -it --rm \
  -v "$(pwd):/home/llamadev/code" \
  -p 11434:11434 \
  ghcr.io/sebastienrousseau/llamadev:latest

# Or build from source
cd podman && podman-compose up --build -d
podman exec -it llamadev bash
```

### First Steps Inside the Container

```bash
# Start NeoVim
nvim .

# Pull an AI model (one-time setup)
ollama pull codellama

# Start coding with AI assistance
# Use <leader>ai for AI completions (default leader is space)
```

## Features

### AI-Powered Development

- **Ollama Integration** - Local LLM for code completion, explanation, and generation
- **No API Keys Required** - Everything runs on your machine
- **Privacy First** - Your code never leaves your system
- **Multiple Models** - Use CodeLlama, Llama 3, Mistral, or any Ollama-compatible model

### Modern Python IDE

- **Python 3.13** with virtual environment and UV package manager
- **LSP Support** - Full language server with go-to-definition, references, hover docs
- **Intelligent Completion** - Context-aware suggestions via nvim-cmp
- **Syntax Highlighting** - Treesitter-powered highlighting for Python, YAML, JSON, Markdown
- **Integrated Testing** - Run pytest with `<leader>pt`, see results inline
- **Debugging** - Full DAP support with breakpoints, stepping, variable inspection

### NeoVim with LazyVim

Pre-configured with sensible defaults:

| Keymap | Action |
|--------|--------|
| `<leader>ff` | Find files (Telescope) |
| `<leader>fg` | Live grep across project |
| `<leader>pr` | Run current Python file |
| `<leader>pt` | Run pytest |
| `<leader>ca` | Code actions (LSP) |
| `<leader>cf` | Format code |
| `<leader>tt` | Toggle terminal |
| `<F5>` | Start/continue debugging |

### Developer Tools Included

**Linting & Formatting:**
- ruff (fast Python linter)
- bandit (security linter)
- codespell (spell checker)

**Type Checking:**
- mypy
- pyright

**Testing:**
- pytest with coverage, async, mock, and hypothesis support
- pytest-xdist for parallel testing

**Security:**
- pip-audit for dependency vulnerability scanning
- Pre-commit hooks configured

## Installation

### Prerequisites

- Docker 24.0+ or Podman 4.0+
- 4GB RAM minimum (8GB recommended for larger AI models)
- 10GB disk space

### Option 1: Pull Pre-built Image

```bash
docker pull ghcr.io/sebastienrousseau/llamadev:latest
```

### Option 2: Build from Source

```bash
git clone https://github.com/sebastienrousseau/llamadev.git
cd llamadev/docker  # or cd llamadev/podman
docker-compose up --build -d
```

### Option 3: Development Setup

For contributors working on LlamaDev itself:

```bash
git clone https://github.com/sebastienrousseau/llamadev.git
cd llamadev
make install    # Install Lua dev dependencies
make test       # Run test suite
make ci-local   # Full CI pipeline
```

## Configuration

### Environment Variables

Create a `.env` file or set these variables:

```bash
PYTHON_VERSION="3.13.2"    # Python version to use
USERNAME="llamadev"         # Container username
USER_HOME="/home/llamadev"  # Home directory
OLLAMA_HOST="0.0.0.0:11434" # Ollama API endpoint
```

### Mounting Your Code

```bash
# Mount current directory
docker run -it -v "$(pwd):/home/llamadev/code" llamadev

# Mount specific project
docker run -it -v "/path/to/project:/home/llamadev/code" llamadev

# Persist Ollama models between sessions
docker run -it \
  -v "$(pwd):/home/llamadev/code" \
  -v ollama_models:/home/llamadev/.ollama \
  llamadev
```

### Exposing Ports

```bash
# Ollama API (for external tools)
docker run -it -p 11434:11434 llamadev

# Web development
docker run -it -p 8080:8080 -p 11434:11434 llamadev
```

### Using docker-compose.yml

```yaml
services:
  llamadev:
    image: llamadev
    container_name: llamadev
    build:
      context: .
    environment:
      OLLAMA_HOST: "0.0.0.0:11434"
    user: "1000:1000"
    working_dir: "/home/llamadev/code"
    stdin_open: true
    tty: true
    ports:
      - "11434:11434"
      - "8080:8080"
    volumes:
      - ./:/home/llamadev/code
      - ollama_models:/home/llamadev/.ollama

volumes:
  ollama_models: {}
```

## Using Ollama for AI Assistance

### Download a Model

```bash
# Inside the container
ollama pull codellama      # Best for code completion
ollama pull llama3         # General purpose
ollama pull mistral        # Fast and capable
```

### Interactive Chat

```bash
ollama run codellama "Explain this Python function: $(cat myfile.py)"
```

### In NeoVim

The configuration includes AI integration. Use:
- `<leader>ai` - Get AI suggestions for current context
- `<leader>ae` - Explain selected code
- `<leader>ar` - Refactor selected code

## Security

LlamaDev is built with security as a priority:

### Container Hardening

- **Non-root user** - Runs as UID 1000, never as root
- **Minimal base image** - Debian slim with only essential packages
- **Capability dropping** - Only NET_BIND_SERVICE capability retained
- **No new privileges** - Prevents privilege escalation
- **SECCOMP profile** - System call filtering enabled
- **Core dump protection** - Prevents sensitive data leakage

### Build Security

- **Secret scanning** - gitleaks runs during build to catch leaked credentials
- **Dependency audit** - pip-audit checks for known vulnerabilities
- **Multi-stage build** - Build tools don't ship in final image
- **Base image verification** - Content trust enforced

### Runtime Security

- **Read-only where possible** - System directories are immutable
- **Resource limits** - Memory and CPU constraints applied
- **Network isolation** - Only necessary ports exposed
- **SUID/SGID removal** - Dangerous permission bits stripped

## Project Structure

```
llamadev/
├── docker/                 # Docker configuration
│   ├── Dockerfile          # Multi-stage secure build
│   ├── docker-compose.yml  # Compose configuration
│   ├── plugins/            # NeoVim plugin configs
│   │   ├── coding.lua      # LSP, completion, treesitter
│   │   ├── ui.lua          # Dashboard and UI
│   │   ├── keymaps.lua     # Key bindings
│   │   └── toggleterm.lua  # Terminal integration
│   └── requirements.txt    # Python dependencies
├── podman/                 # Podman configuration (mirrors docker/)
├── tests/                  # Test suite
│   └── unit/               # Unit tests for plugins
├── Makefile                # Development commands
└── README.md               # This file
```

## Development

### Make Commands

```bash
make help          # Show all commands
make install       # Install dev dependencies
make lint          # Run luacheck
make format        # Format with StyLua
make test          # Run test suite
make coverage      # Tests with coverage (100% required)
make security      # Security audit
make ci-local      # Full CI pipeline
```

### Running Tests

```bash
# All tests
make test

# With coverage
make coverage

# Specific test file
busted tests/unit/keymaps_spec.lua
```

## Troubleshooting

### Container won't start

```bash
# Check logs
docker logs llamadev

# Verify image built correctly
docker images | grep llamadev
```

### Ollama not responding

```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# Restart Ollama inside container
ollama serve &
```

### NeoVim plugins not loading

```bash
# Inside container, sync plugins
nvim --headless "+Lazy! sync" +qa

# Check plugin status
nvim "+Lazy"
```

### Permission issues with mounted volumes

```bash
# Ensure your user matches container user (UID 1000)
id -u  # Should output 1000

# Or run with your user ID
docker run -it --user "$(id -u):$(id -g)" -v "$(pwd):/home/llamadev/code" llamadev
```

## Disclaimer

This is an opinionated development environment. It is:

- Not an official Python project
- Not affiliated with or supported by the Python Software Foundation
- Maintained independently based on open-source projects
- Provided as-is under the MIT License

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Run `make ci-local` to verify changes
4. Submit a pull request

---

**LlamaDev** - Your portable Python IDE. Code anywhere.

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
