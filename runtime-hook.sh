#!/usr/bin/env bash
# llamadev runtime hook — start a loopback-only Ollama server.
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
# This file is SOURCED by the langdev common entrypoint (which runs under
# `set -euo pipefail`). It therefore must NEVER let a failure escape and
# kill the login shell: all work happens inside a function that is invoked
# with a trailing `|| true`, and every fallible step is individually
# guarded. If Ollama or the network is unavailable we warn and continue.
#
# Behaviour:
#   * Binds Ollama to 127.0.0.1:11434 ONLY (never 0.0.0.0). The service is
#     unauthenticated, so it must stay on loopback; compose publishes it to
#     127.0.0.1 on the host as well.
#   * Starts `ollama serve` in the background, detached from the shell.
#   * Waits (bounded) for the HTTP API to answer.
#   * Optionally pulls the default model in the background if enabled AND
#     the model is not already present (opt-in: models are multi-GB).

llamadev_start_ollama() {
  # Never bind to anything but loopback, regardless of inherited env.
  export OLLAMA_HOST="127.0.0.1:11434"
  : "${OLLAMA_MODELS:=$HOME/.ollama}"
  export OLLAMA_MODELS
  local api="http://127.0.0.1:11434/api/version"
  local model="${OLLAMA_DEFAULT_MODEL:-qwen2.5-coder}"
  local auto_pull="${LLAMADEV_AUTO_PULL:-0}"

  if ! command -v ollama >/dev/null 2>&1; then
    echo "llamadev: ollama not found on PATH — skipping LLM startup." >&2
    return 0
  fi

  mkdir -p "$OLLAMA_MODELS" 2>/dev/null || true

  # Already up (e.g. re-sourced)? Then don't spawn a second server.
  if curl -fsS --max-time 2 "$api" >/dev/null 2>&1; then
    echo "llamadev: Ollama already responding on 127.0.0.1:11434." >&2
  else
    echo "llamadev: starting Ollama on 127.0.0.1:11434 ..." >&2
    # Detach fully: own session, no controlling terminal, output discarded.
    ( setsid ollama serve >/tmp/ollama.log 2>&1 & ) || \
      echo "llamadev: failed to launch 'ollama serve' (continuing)." >&2

    # Bounded wait for the API to come up (~15s max); never hangs forever.
    local i=0
    while [ "$i" -lt 30 ]; do
      if curl -fsS --max-time 2 "$api" >/dev/null 2>&1; then
        echo "llamadev: Ollama API is ready." >&2
        break
      fi
      i=$((i + 1))
      sleep 0.5
    done
    if [ "$i" -ge 30 ]; then
      echo "llamadev: Ollama did not become ready in time (see /tmp/ollama.log)." >&2
      return 0
    fi
  fi

  # Optional, opt-in, non-blocking model pull. Multi-GB downloads should
  # never block an interactive shell, so this runs in the background.
  if [ "$auto_pull" = "1" ] || [ "$auto_pull" = "true" ]; then
    if ! ollama list 2>/dev/null | awk '{print $1}' | grep -q "^${model}"; then
      echo "llamadev: pulling default model '${model}' in the background ..." >&2
      ( setsid ollama pull "$model" >/tmp/ollama-pull.log 2>&1 & ) || \
        echo "llamadev: model pull could not be started (continuing)." >&2
    fi
  else
    echo "llamadev: model '${model}' not auto-pulled (set LLAMADEV_AUTO_PULL=1 or run: ollama pull ${model})." >&2
  fi

  return 0
}

# Invoke without ever failing the sourcing shell.
llamadev_start_ollama || true
