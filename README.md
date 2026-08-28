<!-- SPDX-License-Identifier: Apache-2.0 OR MIT -->

<p align="center">
  <img src="https://cloudcdn.pro/llamadev/v1/logos/llamadev.svg" alt="llamadev logo" width="128" />
</p>

<h1 align="center">llamadev</h1>

<p align="center">
  A portable, disposable development container that pairs a
  loopback-only <b>Ollama</b> runtime with a hardened, hash-locked
  <b>Python</b> LLM toolchain and boots the developer's own dotfiles.
</p>

<p align="center">
  <a href="https://github.com/sebastienrousseau/llamadev/actions"><img src="https://img.shields.io/github/actions/workflow/status/sebastienrousseau/llamadev/ci.yml?style=for-the-badge&logo=github" alt="Build" /></a>
  <a href="#license"><img src="https://img.shields.io/badge/license-Apache--2.0%20OR%20MIT-blue?style=for-the-badge" alt="License: Apache-2.0 OR MIT" /></a>
  <a href="https://scorecard.dev/viewer/?uri=github.com/sebastienrousseau/llamadev"><img src="https://img.shields.io/ossf-scorecard/github.com/sebastienrousseau/llamadev?style=for-the-badge&label=OpenSSF%20Scorecard&logo=openssf" alt="OpenSSF Scorecard" /></a>
  <a href="#portability"><img src="https://img.shields.io/badge/engines-docker%20%7C%20podman-1d63ed?style=for-the-badge&logo=docker" alt="Engines: Docker or Podman" /></a>
  <a href="#portability"><img src="https://img.shields.io/badge/arch-amd64%20%C2%B7%20arm64-555?style=for-the-badge" alt="Architectures: amd64, arm64" /></a>
</p>

---

## Contents

**Getting started**

- [Quick start](#quick-start) — clone, `make up`, pull a model
- [Why this approach?](#why-this-approach) — the choices that shape the image

**What's inside**

- [What's inside](#whats-inside) — Ollama, the Python toolchain, the editor
- [The developer environment IS your dotfiles](#the-developer-environment-is-your-dotfiles) — no synthetic config
- [Model store](#model-store) — where the weights live

**Operational**

- [Security model](#security-model) — hardening, and the loopback-only Ollama
- [Portability](#portability) — engines, architectures, host assumptions
- [When not to use llamadev](#when-not-to-use-llamadev) — limitations, stated plainly
- [Development](#development) — `make` targets, lint, scan, SBOM, CI
- [Documentation](#documentation) — community docs and the house style
- [License](#license)

---

## Quick start

`llamadev` is a member of the
[`langdev`](https://github.com/sebastienrousseau/langdev) suite. Clone
it, and one command builds the image and drops you into an interactive,
hardened tmux shell in a fresh container:

```sh
git clone https://github.com/sebastienrousseau/llamadev.git
cd llamadev
make up            # build + interactive tmux dev shell (Docker or Podman)
```

The `Makefile` auto-detects `docker` or `podman` and runs the container
non-root, read-only, with all capabilities dropped (see
[Security model](#security-model)). The entrypoint's runtime hook starts
Ollama on `127.0.0.1:11434` **before** the tmux/shell is exec'd, so the
API is ready when the prompt appears. Pull the default model on first
run (it is multi-GB):

```sh
ollama pull qwen2.5-coder
ollama run  qwen2.5-coder
```

Or have it pulled automatically, in the background, at start:

```sh
LLAMADEV_AUTO_PULL=1 make up     # pulls qwen2.5-coder in the background
```

Other lifecycle targets:

```sh
make run CMD="ruff check ."   # one-shot command in a fresh container
make lint                     # hadolint + shellcheck
make scan                     # Trivy image scan (fail on HIGH/CRITICAL)
make trash                    # remove the image + dangling build cache
```

Compose works the same way:

```sh
docker compose up -d          # or: podman compose up -d
docker compose exec dev bash
```

No registry pull and no base-image dependency: the image is built
entirely from the repo you cloned, and needs no network on first launch
apart from the model download itself.

---

## Why this approach?

Running a local LLM for development usually means one of two things: a
root-running, everything-exposed container you would not put on a shared
network, or a hand-assembled mix of a runtime, an editor, and Python
tooling you rebuild every time. llamadev refuses both. Four choices, in
priority order, shape the image:

1. **Loopback by default, not by afterthought.** Ollama serves an
   **unauthenticated** HTTP API. llamadev binds it to
   `127.0.0.1:11434` inside the container and publishes it only to host
   loopback — never `0.0.0.0`. The bind address is enforced in three
   independent places (the container `ENV`, the runtime hook that
   re-exports `OLLAMA_HOST` before launch, and the compose/`make`
   publish rule), so no single inherited variable can widen the
   exposure. See [Security model](#security-model).

2. **Secure by default, not by opt-in.** The container runs as a
   non-root `dev` user (UID/GID 1000) with **all Linux capabilities
   dropped**, `no-new-privileges`, and a **read-only root filesystem**;
   writable state is confined to explicit `tmpfs` mounts, and the model
   store to a named volume. This is the default `make up` posture, not a
   hardened variant you have to remember to select.

3. **Reliable and reproducible.** Everything is pinned: the Alpine base
   **by digest**, the Ollama runtime and the `uv` binary
   **checksum-verified**, and every Python dependency installed from a
   fully hash-locked lockfile with `uv --require-hashes`. There is no
   `curl | sh` anywhere in the build, and no fake "Verifying…" echo. Pin
   `DOTFILES_REF` to a tag or commit and the environment layer is
   reproducible too.

4. **Portable and disposable.** One OCI `Containerfile` builds with
   Docker and Podman, for `linux/amd64` and `linux/arm64`. The only bind
   mount is your project at `/work`; `make trash` leaves nothing behind
   but the named model volume you can delete when you are done.

---

## What's inside

| Component | Detail |
|---|---|
| **Ollama** | Version **0.33.1**, a pinned and checksum-verified release binary (CPU runners; the multi-GB CUDA/ROCm libraries are stripped). Bound to **loopback only**, `127.0.0.1:11434`. Default model `qwen2.5-coder`. |
| **Python dev toolchain** | Installed from a fully hash-pinned `requirements.lock` with `uv --require-hashes` into a relocatable `/opt/venv`: `ruff` (incl. `ruff server` LSP), `basedpyright`, `mypy`, `bandit`, `pip-audit`, `pytest` (+ `asyncio`/`cov`/`mock`/`xdist`), `hypothesis`, `debugpy`, `pre-commit`, `rich`, `typer`, `structlog`, `codespell`, `mdformat`. |
| **Editor** | Neovim, driven by your dotfiles' config, with a single language drop-in wiring the Python LSP to **basedpyright + `ruff server`**. Plugins are baked headless at build time. |
| **Shell + multiplexer** | tmux, loaded by default; `bash`, `zoxide`, `fzf`, `fd`, `ripgrep`, `bat`, `git`, and the rest of the dotfiles' CLI expectations. |
| **Base** | Alpine 3.22, pinned **by digest**. `tini` is PID 1 (compose sets `init: true`) for clean signal handling. |

### The developer environment IS your dotfiles

llamadev does **not** ship a synthetic shell or editor config. At build
time the image clones your chezmoi-managed **dotfiles repo** and runs
`chezmoi apply`, so the container has the *real* bashrc, aliases, tmux
config, and Neovim setup — **latest by default**. Pin `DOTFILES_REF` to
a tag or commit for reproducible builds.

- **tmux** is installed and **loaded by default**: the entrypoint
  attaches to (or creates) a persistent `langdev` session for
  interactive shells. Opt out with `LANGDEV_NO_TMUX=1`.
- The dotfiles' Neovim config is authoritative. llamadev drops **one**
  `nvim/plugins.local/lang.lua` spec into the dotfiles' nvim
  (auto-imported via its `plugins.local` convention) to wire
  basedpyright and `ruff server`. Because the LSP binaries already live
  on `PATH` in the image, Mason is not relied upon, and the plugin set
  is baked headless at build time — **no network on first launch**.

### Model store

The root filesystem is **read-only**, so downloaded models are kept on a
**named volume** mounted at `/home/dev/.ollama` (env `OLLAMA_MODELS`).
Models persist across container restarts and re-creations, and are
removed only when you delete the volume. A named volume — not `tmpfs` —
is used deliberately, because model weights are multi-GB and must
survive a disposable container's lifetime.

---

## Security model

llamadev inherits the full `langdev` hardening posture. The full threat
model and the private disclosure process are in
[`SECURITY.md`](SECURITY.md).

- **Non-root.** Runs as `dev` (UID/GID 1000); no `sudo`, no setuid
  binaries in the image.
- **Least privilege at runtime.** Compose enforces `cap_drop: [ALL]`,
  `security_opt: [no-new-privileges:true]`, `read_only: true` (with
  `tmpfs` for `/tmp`, `~/.cache`, and `~/.local/state`), `pids_limit`,
  and a realistic `mem_limit` of **8g** — LLM inference is
  memory-hungry, so raise it for larger models; lower it and Ollama may
  OOM mid-inference. `make up` applies the same flags on the CLI.
- **Pinned, checksummed inputs.** Base image pinned **by digest**
  (Alpine 3.22); the Ollama binary, the `uv` binary, and every Python
  dependency are **checksum-verified** — no `curl | sh`, no unpinned
  downloads, no fake "Verifying…" echo.
- **Hash-locked dependencies.** The Python toolchain installs from
  `requirements.lock` with `uv --require-hashes`.
- **No committed secrets.** No `.env` is committed or `COPY`'d into an
  image — secrets are runtime-only via `env_file`. `.dockerignore` and
  `.gitignore` block `.env` from both the build context and git.
- **CI gates every change.** `hadolint`, `shellcheck`, `gitleaks` secret
  scanning (single pinned version), and a Trivy image scan (fail on
  HIGH/CRITICAL) run on every push; a CycloneDX SBOM is generated on
  build.

### Ollama is loopback-only (important)

Ollama exposes an **unauthenticated** HTTP API: anyone who can reach the
port can run inference, read loaded models, and enumerate the host.
Earlier revisions of this repo published it on `0.0.0.0:11434`, exposing
it on every interface. That is **fixed**: the API is now bound to
`127.0.0.1:11434` inside the container and published only to host
loopback (`127.0.0.1`) by compose and `make`. Do not change the publish
address to `0.0.0.0` unless you add authentication in front of it and
understand exactly what you are exposing.

Report a vulnerability privately — see [`SECURITY.md`](SECURITY.md). Do
not open a public issue.

---

## Portability

- **One `Containerfile` (OCI).** `docker build`, `podman build`,
  `buildah`, and `nerdctl` all work from the same file.
- **Engine autodetection.** The `Makefile` detects `docker` or `podman`
  and adjusts flags (SELinux `:Z` mounts) accordingly.
- **Multi-arch.** Images build for `linux/amd64` and `linux/arm64` via
  `docker buildx` / `podman --platform`. The Ollama image is CPU-only;
  the GPU runner libraries are stripped from the build.
- **No host assumptions.** The only bind mount is your project directory
  at `/work`; the model store is a self-contained named volume.

---

## When not to use llamadev

Stated plainly, so you can rule it out fast:

- **You need GPU-accelerated inference.** The image ships the CPU
  runners only — the CUDA/ROCm libraries are stripped to keep it small,
  and the default posture drops all capabilities and forbids privilege
  escalation. Device passthrough runs against the grain of the design.
- **You need to expose the model API to other hosts.** llamadev binds
  Ollama to loopback on purpose; serving it on a network requires
  authentication llamadev does not provide, and a deliberate,
  documented relaxation of the publish rule.
- **You want a production inference server.** This is a *development*
  environment — editor, LSP, test tooling, a shell. Ship a separate,
  slimmer, authenticated image for a real serving workload.
- **You do not use chezmoi-managed dotfiles.** The environment *is* the
  user's dotfiles. Without a chezmoi dotfiles repo you lose the main
  point, though the hardening and toolchain layers still stand on their
  own.
- **You are on a platform without Docker or Podman.** There is no
  VM-less fallback; the suite targets an OCI engine on Linux, macOS, or
  Windows/WSL2.

---

## Development

The per-repo `Makefile` exposes the whole lifecycle:

```sh
make up          # build + interactive tmux dev shell (alias: make shell)
make run CMD=… # one-shot command in a fresh container
make build       # build the image for the host arch
make buildx      # multi-arch build (linux/amd64, linux/arm64)
make lint        # hadolint the Containerfile + shellcheck the scripts
make scan        # Trivy vulnerability scan (fail on HIGH/CRITICAL)
make sbom        # CycloneDX SBOM via syft
make trash       # remove the image and dangling build cache
make sync-common # refresh common/ from the langdev source
```

Language-agnostic files live under `common/` and are vendored from
`langdev`; refresh them with `make sync-common LANGDEV=../langdev`.

CI (`.github/workflows/ci.yml`) runs the lint, secret-scan, and
build/scan jobs on every push and pull request. Contributions require
signed commits and Conventional Commit messages — see
[`CONTRIBUTING.md`](CONTRIBUTING.md).

---

## Documentation

| Document | What it covers |
|---|---|
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | The container workflow: build/lint/scan/sbom, signed commits, Conventional Commits. |
| [`SECURITY.md`](SECURITY.md) | The container threat model and the private disclosure process. |
| [`GOVERNANCE.md`](GOVERNANCE.md) | Who decides what, and how the maintainer base is meant to grow. |
| [`SUPPORT.md`](SUPPORT.md) | Where to go for questions, bugs, and feature requests. |
| [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) | Community standards and enforcement. |
| [`CHANGELOG.md`](CHANGELOG.md) | Notable changes, Keep a Changelog format. |

The house style every suite README follows lives in the `langdev` repo's
[`STYLE.md`](https://github.com/sebastienrousseau/langdev/blob/main/STYLE.md).

---

## License

Licensed under either of

- Apache License, Version 2.0 ([`LICENSE-APACHE`](LICENSE-APACHE))
- MIT license ([`LICENSE-MIT`](LICENSE-MIT))

at your option. The suite is dual-licensed `Apache-2.0 OR MIT`; every
file carries an `SPDX-License-Identifier: Apache-2.0 OR MIT` header.

Unless you explicitly state otherwise, any contribution intentionally
submitted for inclusion in the work by you, as defined in the Apache-2.0
license, shall be dual licensed as above, without any additional terms
or conditions.
