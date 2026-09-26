---
layout: index
title: "llamadev — Portable, Hardened Ollama & Local LLM AI Developer Container"
description: "Hardened local LLM container pairing a loopback-only Ollama runtime with Python LLM toolchain, 4-pane TMUX IDE, and stdio MCP server."
eyebrow: "Local LLM Stack"
author: "Sebastien Rousseau"
name: "llamadev"
headline: "Hardened Ollama & Local LLM Development Container for AI Agents"
lead: "Fast, disposable LLM development container pairing a loopback-only Ollama runtime with a hash-locked Python toolchain, 4-pane TMUX IDE, and stdio Model Context Protocol (MCP) server."
permalink: "/"
language: "en-GB"
date: "2026-09-26"
---

<section id="overview" class="section">
  <div class="container text-center">
    <h2 class="section-title">Engineered for Local LLM Workflows & Terminal AI Agents</h2>
    <p class="section-desc">Run, fine-tune, and evaluate open-weights models entirely offline with zero data leakage.</p>
    <div class="grid-2x2">
      <div class="card">
        <h3>Loopback-Only Ollama Runtime</h3>
        <p>Pre-configured Ollama daemon bound strictly to <code>127.0.0.1:11434</code> with network egress prevention.</p>
      </div>
      <div class="card">
        <h3>4-Pane TMUX IDE (Prefix + i)</h3>
        <p>Instant IDE split layout with File Tree Explorer, Neovim (Treesitter + LSP), bash terminal, and AI Agent pane.</p>
      </div>
      <div class="card">
        <h3>Model Context Protocol (MCP)</h3>
        <p>Stdio JSON-RPC 2.0 interface exposing model inference, tokenization, and diagnostics to Claude Code and Cursor.</p>
      </div>
      <div class="card">
        <h3>Host-Shared Model Store</h3>
        <p>Mount <code>~/.ollama/models</code> or external SSD volume to share quantized GGUF weights across multiple containers.</p>
      </div>
    </div>
  </div>
</section>

<section id="quickstart" class="section">
  <div class="container narrow">
    <h2 class="section-title text-center">Quick Start in 30 Seconds</h2>
    <p class="section-desc text-center">Disposable developer environment running anywhere Docker or Podman runs.</p>
    <pre><code>&#35; 1. Clone the repository
git clone https://github.com/sebastienrousseau/llamadev.git
cd llamadev

&#35; 2. Build and launch 4-pane TMUX IDE
make up

&#35; 3. Run a local quantized model
ollama run llama3.2:3b</code></pre>
  </div>
</section>

<section id="features" class="section">
  <div class="container text-center">
    <h2 class="section-title">Core Developer Capabilities</h2>
    <p class="section-desc">Full terminal-first development experience equipped with modern CLI productivity tools.</p>
    <div class="grid-2x2">
      <div class="card">
        <h3>Python LLM Toolchain</h3>
        <p>Equipped with Python 3.12, uv, pytest, LiteLLM proxy, and Hugging Face Hub CLI.</p>
      </div>
      <div class="card">
        <h3>Deterministic Model Execution</h3>
        <p>Reproducible inference pipelines pinned to SHA256 model digests and hash-locked pip dependencies.</p>
      </div>
      <div class="card">
        <h3>OSC 52 Universal Clipboard</h3>
        <p>Copy text from remote Neovim or TMUX sessions directly to your local system clipboard over SSH, WebTTY, or Mosh.</p>
      </div>
      <div class="card">
        <h3>Parallel AI Task Worktrees</h3>
        <p>Spawn ephemeral git worktrees paired with separate TMUX sessions for concurrent prompt engineering.</p>
      </div>
    </div>
  </div>
</section>

<section id="ai-ide" class="section">
  <div class="container text-center">
    <h2 class="section-title">AI Coding Agent Architecture</h2>
    <p class="section-desc">Designed from first principles to empower local coding agents with standard protocols.</p>
    <div class="grid-2x2">
      <div class="card">
        <h3>Model Context Protocol (MCP) Server</h3>
        <p>Runs a native JSON-RPC 2.0 stdio server providing tools for file reading, file search, shell execution, and diagnostics.</p>
      </div>
      <div class="card">
        <h3>Isolated Git Worktree Workflows</h3>
        <p>Spawn ephemeral worktrees for AI tasks without dirtying your main working tree or breaking active development.</p>
      </div>
      <div class="card">
        <h3>Sub-500ms Cold Start Startup</h3>
        <p>Optimized image layers and pre-compiled configurations ensure instantaneous container boot and shell readiness.</p>
      </div>
      <div class="card">
        <h3>Zero-Trust Capability Drop</h3>
        <p>Runs as unprivileged user (UID 1000) with all root capabilities dropped (<code>cap_drop: [ALL]</code>) and read-only rootfs.</p>
      </div>
    </div>
  </div>
</section>

<section id="suite" class="section">
  <div class="container">
    <h2 class="section-title text-center">Unified Multi-Language Suite</h2>
    <p class="section-desc text-center">Every container shares an identical security baseline, TMUX shortcuts, and MCP interfaces.</p>
    <div class="table-responsive">
      <table>
        <thead>
          <tr>
            <th scope="col">Container</th>
            <th scope="col">Language Stack</th>
            <th scope="col">Built-in Tooling</th>
            <th scope="col">Version</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><a href="https://langdev.hyperbox.run/" class="suite-link"><strong>langdev</strong></a></td>
            <td>Core Foundation</td>
            <td>TMUX IDE, MCP server, ai-pack, WebTTY, OSC 52</td>
            <td>v0.0.4</td>
          </tr>
          <tr>
            <td><a href="https://tsdev.hyperbox.run/" class="suite-link"><strong>tsdev</strong></a></td>
            <td>TypeScript 5.8+</td>
            <td>pnpm, vtsls, Biome, Vitest, TMUX IDE</td>
            <td>v0.0.1</td>
          </tr>
          <tr>
            <td><a href="https://jsdev.hyperbox.run/" class="suite-link"><strong>jsdev</strong></a></td>
            <td>Node.js 22 LTS</td>
            <td>Biome, ESLint, Prettier, Node test runner</td>
            <td>v0.0.1</td>
          </tr>
          <tr>
            <td><a href="https://pythondev.hyperbox.run/" class="suite-link"><strong>pythondev</strong></a></td>
            <td>Python 3.12+</td>
            <td>uv, ruff, mypy, pytest, debugpy, Pyright</td>
            <td>v0.0.4</td>
          </tr>
          <tr>
            <td><a href="https://rustdev.hyperbox.run/" class="suite-link"><strong>rustdev</strong></a></td>
            <td>Rust 1.85+</td>
            <td>rustup, rust-analyzer, clippy, cargo-audit, sccache</td>
            <td>v0.0.4</td>
          </tr>
          <tr>
            <td><a href="https://godev.hyperbox.run/" class="suite-link"><strong>godev</strong></a></td>
            <td>Go 1.24+</td>
            <td>gopls, golangci-lint, delve, Go toolchain</td>
            <td>v0.0.4</td>
          </tr>
          <tr>
            <td><a href="https://javadev.hyperbox.run/" class="suite-link"><strong>javadev</strong></a></td>
            <td>Java 21+</td>
            <td>OpenJDK 21, Maven, Gradle, JDTLS</td>
            <td>v0.0.4</td>
          </tr>
          <tr>
            <td><a href="https://kotlindev.hyperbox.run/" class="suite-link"><strong>kotlindev</strong></a></td>
            <td>Kotlin 2.1+</td>
            <td>kotlinc, OpenJDK 21, Gradle, Maven, KLS</td>
            <td>v0.0.4</td>
          </tr>
          <tr>
            <td><a href="https://swiftdev.hyperbox.run/" class="suite-link"><strong>swiftdev</strong></a></td>
            <td>Swift 6.0+</td>
            <td>Swift toolchain, SourceKit-LSP, swift-format</td>
            <td>v0.0.4</td>
          </tr>
          <tr>
            <td><a href="https://llamadev.hyperbox.run/" class="suite-link"><strong>llamadev</strong></a></td>
            <td>Ollama &amp; Local LLMs</td>
            <td>Ollama, Python 3.12, LiteLLM, HF CLI</td>
            <td>v0.0.1</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</section>

<section id="security" class="section">
  <div class="container text-center">
    <h2 class="section-title">Zero-Trust Hardened Security</h2>
    <p class="section-desc">Strict security guarantees verified in CI and container runtime.</p>
    <div class="grid-2x2">
      <div class="card">
        <h3>Unprivileged Non-Root</h3>
        <p>Runs as unprivileged dev user (UID/GID 1000). Drops all Linux capabilities (<code>cap_drop: [ALL]</code>) with <code>no-new-privileges:true</code>.</p>
      </div>
      <div class="card">
        <h3>Read-Only Root Filesystem</h3>
        <p>Immutable rootfs prevents container modification or persistent malware. Writable state is restricted to explicit tmpfs mounts.</p>
      </div>
      <div class="card">
        <h3>Air-Gapped Privacy</h3>
        <p>Loopback-only binding ensures no telemetry, prompts, or embeddings are transmitted outside your local machine.</p>
      </div>
      <div class="card">
        <h3>Hermetic CI &amp; SAST</h3>
        <p>100% unit tested with Bats, ShellCheck linting, Hadolint OCI auditing, and Trivy CVE vulnerability scans.</p>
      </div>
    </div>
  </div>
</section>

<section id="faq" class="section">
  <div class="container narrow">
    <h2 class="section-title text-center">Frequently Asked Questions</h2>
    <div class="faq-stack">
      <div class="card">
        <h3>Where are model weights stored?</h3>
        <p>Weights are stored on the host filesystem and mounted read-only into the container to avoid duplicating gigabytes of data.</p>
      </div>
      <div class="card">
        <h3>Can I run GPUs with this container?</h3>
        <p>Yes. Pass <code>--gpus all</code> in Docker or <code>--device nvidia.com/gpu=all</code> in Podman for hardware-accelerated inference.</p>
      </div>
      <div class="card">
        <h3>Can I run multiple language containers side by side?</h3>
        <p>Yes. All containers in the suite use non-conflicting port mappings and shared worktree patterns for simultaneous multi-language development.</p>
      </div>
    </div>
  </div>
</section>
