# llamadev — language PATH/env for login shells.
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
# Installed to /etc/profile.d/llamadev.sh (root-owned, 0644) by the
# Containerfile's final stage, so LOGIN shells (the tmux/bash session the
# entrypoint execs, and `bash -lc` one-shots) see the Python venv + Ollama
# on PATH and the Ollama env. Kept OUT of the user's chezmoi dotfiles so
# those stay pristine and langdev-agnostic.
#
# This is IN ADDITION to the container ENV (set in the Containerfile so the
# non-login entrypoint/runtime-hook can find `ollama`) and the compose env.
# Ollama is unauthenticated: it stays bound to loopback. Never 0.0.0.0.

# Python dev toolchain + Ollama runtime on PATH.
case ":${PATH}:" in
  *:/opt/venv/bin:*) : ;;
  *) PATH="/opt/venv/bin:/opt/ollama/bin:${PATH}" ;;
esac
export PATH
export VIRTUAL_ENV="/opt/venv"

# Loopback-only, unauthenticated Ollama. Do NOT change to 0.0.0.0.
export OLLAMA_HOST="${OLLAMA_HOST:-127.0.0.1:11434}"
export OLLAMA_MODELS="${OLLAMA_MODELS:-$HOME/.ollama}"
export OLLAMA_DEFAULT_MODEL="${OLLAMA_DEFAULT_MODEL:-qwen2.5-coder}"
