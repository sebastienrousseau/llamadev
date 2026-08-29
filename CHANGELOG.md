<!-- SPDX-License-Identifier: Apache-2.0 OR MIT -->

# Changelog

All notable changes to this project are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

llamadev is a member of the
[`langdev`](https://github.com/sebastienrousseau/langdev) suite: a
portable, disposable development container pairing a local Ollama runtime
with a hardened, hash-locked Python LLM toolchain, inside the developer's
own chezmoi-managed dotfiles, that builds with **both** Docker and Podman.

### Security

- **Ollama is now bound to loopback only.** The unauthenticated Ollama
  HTTP API was previously published on `0.0.0.0:11434`, exposing it on
  every interface. It is now bound to `127.0.0.1:11434` inside the
  container and published only to host loopback (`127.0.0.1`) by compose
  and `make`. The bind address is enforced in the container `ENV`, the
  runtime hook, and the publish rule so no inherited variable can widen
  the exposure.

### Changed

- **Bumped Ollama 0.1.29 → 0.33.1**, pinned and checksum-verified for
  both `amd64` and `arm64`.
- Consolidated the previously duplicated `docker/` and `podman/` trees
  into a single OCI `Containerfile` that builds with both engines and
  both architectures; every input is pinned and checksum-verified.

### Added

- **Adopted the noyalib-style OSS scaffolding** shared across the langdev
  suite: `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `SECURITY.md`,
  `SUPPORT.md`, `GOVERNANCE.md`, and `.github/` templates (`CODEOWNERS`,
  `FUNDING.yml`, `dependabot.yml`, a pull-request template, and issue
  forms).
- Python dev toolchain installed from a fully hash-pinned
  `requirements.lock` with `uv --require-hashes`, wiring the Neovim LSP
  to **basedpyright + `ruff server`**.
- Named-volume model store at `/home/dev/.ollama` so multi-GB weights
  persist across a read-only, disposable container's lifetime.

### Licensing

- Relicensed from single MIT to **dual `Apache-2.0 OR MIT`**. Added
  `LICENSE-APACHE` and `LICENSE-MIT`, removed the single `LICENSE` file,
  and applied `SPDX-License-Identifier: Apache-2.0 OR MIT` headers across
  the repo.

[Unreleased]: https://github.com/sebastienrousseau/llamadev/commits/main
