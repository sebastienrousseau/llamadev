<!-- SPDX-License-Identifier: MIT -->

# llamadev — a disposable Ollama + Python LLM dev environment

`llamadev` is a member of the [`langdev`](https://github.com/sebastienrousseau/langdev)
suite: a complete, batteries-included development container you can **spin up
and throw away in seconds**, on any machine with Docker or Podman. It pairs a
local **Ollama** LLM runtime with a hardened **Python** toolchain and a
pre-configured **Neovim** editor.

One **OCI `Containerfile`** builds with both engines and both architectures
(`linux/amd64`, `linux/arm64`). There is no longer a separate `docker/` and
`podman/` tree — that duplication (which had drifted out of sync) has been
consolidated into a single, pinned, checksum-verified image.

## What's inside

- **Ollama** (pinned, checksum-verified release) — a local, private LLM
  runtime. Bound to **loopback only** (see Security).
- **Python dev toolchain**, installed from a **fully hash-pinned lockfile**
  (`requirements.lock`) with `uv --require-hashes`:
  `ruff` (incl. `ruff server` LSP), `basedpyright`, `mypy`, `bandit`,
  `pip-audit`, `pytest` (+ `asyncio`/`cov`/`mock`/`xdist`), `hypothesis`,
  `debugpy`, `pre-commit`, `rich`, `typer`, `structlog`, `codespell`,
  `mdformat`.
- **Neovim** with LazyVim, plugins baked in at build time (no network on
  first launch), Python LSP wired to **basedpyright + ruff server** (Mason is
  intentionally disabled).

## Quick start

```bash
# Docker or Podman — the Makefile auto-detects which you have.
make up            # build + drop into an interactive dev shell
```

Inside the container, Ollama is started automatically on `127.0.0.1:11434`.
Pull the default model (first run only; it is multi-GB):

```bash
ollama pull qwen2.5-coder
ollama run  qwen2.5-coder
```

Or have it pulled automatically on start:

```bash
LLAMADEV_AUTO_PULL=1 make up     # pulls qwen2.5-coder in the background
```

Other lifecycle targets:

```bash
make run CMD="ruff check ."   # one-shot command in a fresh container
make lint                     # hadolint + shellcheck (if installed)
make scan                     # trivy image scan (if installed)
make trash                    # remove the image + dangling cache
```

### compose

```bash
docker compose up -d          # or: podman compose up -d
docker compose exec dev bash
```

## Model store

The root filesystem is **read-only**, so downloaded models are kept on a
**named volume** mounted at `/home/dev/.ollama` (env `OLLAMA_MODELS`). Models
persist across container restarts and re-creations, and are removed only when
you delete the volume. A named volume (not tmpfs) is used deliberately because
models are large.

## Security

`llamadev` inherits the full `langdev` hardening posture:

- Runs as non-root `dev` (UID/GID 1000); no `sudo`, no setuid binaries.
- Compose/`make` enforce `cap_drop: [ALL]`, `no-new-privileges:true`,
  `read_only: true` root filesystem (with tmpfs for `/tmp`, `~/.cache`,
  `~/.local/state`), `pids_limit`, and a realistic `mem_limit` of **8g**
  (LLM inference is memory-hungry — raise it for larger models, lower it and
  Ollama may OOM mid-inference).
- Base image pinned **by digest** (Alpine 3.22); the Ollama binary, the `uv`
  binary, and every Python dependency are **checksum-verified** (no
  `curl | sh`, no unpinned downloads). There is no fake "Verifying…" echo.
- No `.env` is committed or COPY'd into an image — secrets are runtime-only
  via `env_file`. `.dockerignore`/`.gitignore` block `.env` from both the
  build context and git.

### Ollama is loopback-only (important)

Ollama exposes an **unauthenticated** HTTP API. Earlier versions of this repo
published it on `0.0.0.0:11434`, exposing it on every interface. That is
fixed: the API is now bound to **`127.0.0.1:11434` inside the container** and
published only to **host loopback** (`127.0.0.1`) by compose and `make`. Do
not change the publish address to `0.0.0.0` unless you add authentication and
understand the exposure.

## CI

`.github/workflows/ci.yml` gates every change with:

- **hadolint** on the `Containerfile`,
- **shellcheck** on all shell scripts,
- **gitleaks** secret scanning (single pinned version — no in-image no-op
  gate, no per-file version drift),
- a **Trivy** image vulnerability scan (fails on HIGH/CRITICAL),
- **SBOM** (CycloneDX) generation on build.

## Keeping the shared core in sync

Language-agnostic files live under `common/` and are vendored from `langdev`:

```bash
make sync-common LANGDEV=../langdev
```

## License

MIT — see [`LICENSE`](LICENSE).
