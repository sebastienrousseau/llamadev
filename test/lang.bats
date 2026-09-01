#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0 OR MIT
# Unit tests for llamadev's language layer:
#   * dotfiles.d/llamadev.sh — the profile fragment sourced by login shells:
#     puts the venv + Ollama on PATH and sets the loopback-only Ollama env.
#   * runtime-hook.sh — sourced by the common entrypoint under `set -euo
#     pipefail`; must NEVER let a failure escape. It starts a loopback-only
#     Ollama server and degrades gracefully when Ollama or the network is
#     unavailable.
#
# Both are exercised hermetically: ollama/curl/setsid/sleep are test doubles on
# a closed PATH (see helpers/bin/), so the no-ollama, no-network, ready, and
# model-pull branches are all deterministic — no real server, no network.
load helpers/common

setup() { common_setup; }

# ── dotfiles.d/llamadev.sh ────────────────────────────────────────────

@test "llamadev.sh: puts the venv + Ollama on PATH and sets loopback env" {
  run bash -c '
    set -euo pipefail
    export PATH="/langdev-base"
    # shellcheck source=/dev/null
    source "$1"
    printf "PATHVAL=%s\n" "$PATH"
    printf "VIRTUAL_ENV=%s\n" "$VIRTUAL_ENV"
    printf "OLLAMA_HOST=%s\n" "$OLLAMA_HOST"
    printf "OLLAMA_MODELS=%s\n" "$OLLAMA_MODELS"
    printf "OLLAMA_DEFAULT_MODEL=%s\n" "$OLLAMA_DEFAULT_MODEL"
  ' _ "$REPO_ROOT/dotfiles.d/llamadev.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"PATHVAL=/opt/venv/bin:/opt/ollama/bin:/langdev-base"* ]]
  [[ "$output" == *"VIRTUAL_ENV=/opt/venv"* ]]
  [[ "$output" == *"OLLAMA_HOST=127.0.0.1:11434"* ]]
  [[ "$output" == *"OLLAMA_MODELS=$HOME/.ollama"* ]]
  [[ "$output" == *"OLLAMA_DEFAULT_MODEL=qwen2.5-coder"* ]]
}

@test "llamadev.sh: is idempotent — re-sourcing does not duplicate PATH" {
  run bash -c '
    set -euo pipefail
    export PATH="/langdev-base"
    source "$1"; source "$1"
    printf "PATHVAL=%s" "$PATH"
  ' _ "$REPO_ROOT/dotfiles.d/llamadev.sh"
  [ "$status" -eq 0 ]
  pathval="${output#PATHVAL=}"
  n="$(printf '%s' "$pathval" | grep -oF '/opt/venv/bin' | wc -l)"
  [ "$n" -eq 1 ]
}

# ── runtime-hook.sh ───────────────────────────────────────────────────

@test "runtime-hook: no ollama on PATH → warns, forces loopback, returns 0" {
  hermetic_path   # deliberately NO ollama stub
  run bash -c '
    set -euo pipefail
    export OLLAMA_HOST="0.0.0.0:11434"   # hostile inherited value
    source "$1"
    printf "OLLAMA_HOST=%s\n" "$OLLAMA_HOST"
  ' _ "$REPO_ROOT/runtime-hook.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ollama not found on PATH"* ]]
  # Loopback binding is asserted BEFORE the ollama check, so it still holds.
  [[ "$output" == *"OLLAMA_HOST=127.0.0.1:11434"* ]]
}

@test "runtime-hook: reuses an already-responding server; no auto-pull by default" {
  hermetic_path ollama curl setsid sleep
  run bash -c '
    set -euo pipefail
    source "$1"
  ' _ "$REPO_ROOT/runtime-hook.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already responding"* ]]
  [[ "$output" == *"not auto-pulled"* ]]
  # No second server spawned.
  run grep -c "setsid ollama serve" "$STUB_LOG"
  [ "$output" -eq 0 ]
}

@test "runtime-hook: starts Ollama and waits until the API is ready" {
  hermetic_path ollama curl setsid sleep
  export STUB_CURL_FAIL_UNTIL=1
  export STUB_CURL_COUNTER="$SANDBOX/curl.count"
  run bash -c '
    set -euo pipefail
    source "$1"
  ' _ "$REPO_ROOT/runtime-hook.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"starting Ollama on 127.0.0.1:11434"* ]]
  [[ "$output" == *"Ollama API is ready"* ]]
  stublog_has "setsid ollama serve"
}

@test "runtime-hook: no network — gives up gracefully after the bounded wait" {
  hermetic_path ollama curl setsid sleep
  export STUB_CURL_ALWAYS_FAIL=1
  run bash -c '
    set -euo pipefail
    source "$1"
  ' _ "$REPO_ROOT/runtime-hook.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"starting Ollama on 127.0.0.1:11434"* ]]
  [[ "$output" == *"did not become ready in time"* ]]
}

@test "runtime-hook: auto-pull fetches a missing model in the background" {
  hermetic_path ollama curl setsid sleep
  export LLAMADEV_AUTO_PULL=1
  run bash -c '
    set -euo pipefail
    source "$1"
  ' _ "$REPO_ROOT/runtime-hook.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already responding"* ]]
  [[ "$output" == *"pulling default model"* ]]
  stublog_has "setsid ollama pull qwen2.5-coder"
}

@test "runtime-hook: auto-pull skips a model that is already installed" {
  hermetic_path ollama curl setsid sleep
  export LLAMADEV_AUTO_PULL=1
  export STUB_OLLAMA_HAS_MODEL=1
  run bash -c '
    set -euo pipefail
    source "$1"
  ' _ "$REPO_ROOT/runtime-hook.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already responding"* ]]
  [[ "$output" != *"pulling default model"* ]]
}
