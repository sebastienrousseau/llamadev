#!/bin/bash
# LlamaDev Container Startup Script
# Supports both Ollama and LM Studio backends
#
# Environment Variables:
#   LLM_PROVIDER: "ollama" (default) or "lmstudio"
#   OLLAMA_HOST: Ollama API endpoint (default: http://localhost:11434)
#   LMSTUDIO_HOST: LM Studio API endpoint (default: http://localhost:1234)
#   LLM_MODEL: Model to use (default: codellama-dev)
#   SKIP_MODEL_SETUP: Set to "true" to skip model creation

set -e

LLM_PROVIDER="${LLM_PROVIDER:-ollama}"
LLM_MODEL="${LLM_MODEL:-codellama-dev}"
OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
LMSTUDIO_HOST="${LMSTUDIO_HOST:-http://localhost:1234}"
BASE_MODEL="codellama:7b-code-q4_K_M"
CONFIG_DIR="/home/llamadev/.config/llamadev"

echo "=============================================="
echo "  LlamaDev - AI-Powered Development Environment"
echo "=============================================="
echo "Provider: $LLM_PROVIDER"
echo "Model: $LLM_MODEL"
echo ""

# Function to wait for API endpoint
wait_for_api() {
    local url="$1"
    local max_attempts="${2:-30}"
    local attempt=1

    echo "Waiting for API at $url..."
    while [ $attempt -le $max_attempts ]; do
        if curl -sf "$url" > /dev/null 2>&1; then
            echo "API is ready after ${attempt}s"
            return 0
        fi
        sleep 1
        attempt=$((attempt + 1))
    done

    echo "Warning: API not available after ${max_attempts}s"
    return 1
}

# Function to create optimized Ollama models
create_optimized_models() {
    echo ""
    echo "Setting up optimized models..."

    # Create config directory
    mkdir -p "$CONFIG_DIR"

    # Modelfile for chat/instruction tasks
    cat > "$CONFIG_DIR/Modelfile.codellama-dev" << 'MODELFILE'
FROM codellama:7b-code-q4_K_M

PARAMETER temperature 0.15
PARAMETER top_p 0.85
PARAMETER top_k 30
PARAMETER repeat_penalty 1.15
PARAMETER repeat_last_n 128
PARAMETER num_ctx 4096
PARAMETER num_predict 2048
PARAMETER num_batch 512

PARAMETER stop "<|endoftext|>"
PARAMETER stop "</s>"
PARAMETER stop "<|end|>"
PARAMETER stop "```\n\n"

SYSTEM """You are CodeLlama, an expert AI programming assistant.

CAPABILITIES:
- Write clean, efficient, production-ready code
- Debug, analyze, and fix code issues
- Explain complex algorithms and code patterns
- Generate comprehensive tests
- Refactor and optimize existing code

GUIDELINES:
1. Be concise - provide working code with minimal explanation unless asked
2. Follow language best practices (PEP 8 for Python, etc.)
3. Use type hints for Python functions
4. Include error handling where appropriate
5. Prefer readability over cleverness

OUTPUT FORMAT:
- Use markdown code blocks with language specifier
- When fixing bugs, briefly explain what was wrong"""
MODELFILE

    # Modelfile for FIM (code completion)
    cat > "$CONFIG_DIR/Modelfile.codellama-fim" << 'MODELFILE'
FROM codellama:7b-code-q4_K_M

PARAMETER temperature 0.1
PARAMETER top_p 0.8
PARAMETER top_k 20
PARAMETER repeat_penalty 1.2
PARAMETER repeat_last_n 64
PARAMETER num_ctx 2048
PARAMETER num_predict 256
PARAMETER num_batch 256

PARAMETER stop "<|endoftext|>"
PARAMETER stop "</s>"
PARAMETER stop " <MID>"
PARAMETER stop "<PRE>"
PARAMETER stop "<SUF>"
PARAMETER stop "\n\n"

SYSTEM """Complete the code. Output only the missing code, nothing else."""

TEMPLATE """<PRE> {{ .Prompt }} <SUF>{{ if .Suffix }}{{ .Suffix }}{{ end }} <MID>"""
MODELFILE

    # Create optimized chat model
    if ! ollama list 2>/dev/null | grep -q "codellama-dev"; then
        echo "Creating codellama-dev (optimized chat model)..."
        ollama create codellama-dev -f "$CONFIG_DIR/Modelfile.codellama-dev"
    else
        echo "codellama-dev already exists"
    fi

    # Create optimized FIM model
    if ! ollama list 2>/dev/null | grep -q "codellama-fim"; then
        echo "Creating codellama-fim (optimized completion model)..."
        ollama create codellama-fim -f "$CONFIG_DIR/Modelfile.codellama-fim"
    else
        echo "codellama-fim already exists"
    fi

    echo "Optimized models ready!"
}

if [ "$LLM_PROVIDER" = "ollama" ]; then
    echo "Starting Ollama server..."

    # Set Ollama environment for optimal performance
    export OLLAMA_KEEP_ALIVE=300
    export OLLAMA_FLASH_ATTENTION=true
    export OLLAMA_NUM_PARALLEL=2

    nohup ollama serve > /tmp/ollama.log 2>&1 &
    OLLAMA_PID=$!

    # Wait for Ollama to be ready
    if wait_for_api "http://localhost:11434"; then
        # Pull base model if not exists
        if ! ollama list 2>/dev/null | grep -q "${BASE_MODEL}"; then
            echo "Pulling base model: $BASE_MODEL (this may take a while)..."
            ollama pull "$BASE_MODEL"
        else
            echo "Base model $BASE_MODEL is available"
        fi

        # Create optimized models unless skipped
        if [ "${SKIP_MODEL_SETUP}" != "true" ]; then
            create_optimized_models
        fi

        # Warm up the model (load into memory)
        echo ""
        echo "Warming up model..."
        echo "print('ready')" | timeout 60 ollama run "$LLM_MODEL" > /dev/null 2>&1 &

        echo ""
        echo "Ollama is ready!"
        echo "API endpoint: http://localhost:11434"
        echo "OpenAI-compatible: http://localhost:11434/v1"
        echo ""
        echo "Available models:"
        ollama list 2>/dev/null | head -10
    else
        echo "Error: Ollama failed to start. Check /tmp/ollama.log"
        cat /tmp/ollama.log 2>/dev/null | tail -20 || true
    fi

elif [ "$LLM_PROVIDER" = "lmstudio" ]; then
    echo "LM Studio mode - expecting external LM Studio server"
    echo "Checking connection to LM Studio at ${LMSTUDIO_HOST}..."

    if wait_for_api "${LMSTUDIO_HOST}/v1/models" 10; then
        echo ""
        echo "LM Studio is connected!"
        echo "API endpoint: ${LMSTUDIO_HOST}/v1"
        echo ""
        echo "Available models:"
        curl -s "${LMSTUDIO_HOST}/v1/models" 2>/dev/null | grep -o '"id":"[^"]*"' | head -5 || true
        echo ""
        echo "Recommended: Load codellama-7b-code.Q4_K_M.gguf"
        echo "with the 'CodeLlama 7B Code - Optimized' preset"
    else
        echo ""
        echo "Warning: LM Studio not detected at ${LMSTUDIO_HOST}"
        echo ""
        echo "To use LM Studio:"
        echo "  1. Open LM Studio on your host machine"
        echo "  2. Download: codellama-7b-code.Q4_K_M.gguf"
        echo "  3. Import preset from: config/lmstudio/codellama-7b-code.preset.json"
        echo "  4. Start Local Server on port 1234"
        echo "  5. Ensure 'Serve on Local Network' is enabled"
        echo ""
    fi
else
    echo "Unknown provider: $LLM_PROVIDER"
    echo "Use LLM_PROVIDER=ollama or LLM_PROVIDER=lmstudio"
fi

echo ""
echo "=============================================="
echo "Keybindings (with <leader> = Space):"
echo "=============================================="
echo ""
echo "  AI Chat & Actions:"
echo "    <leader>ac  - Toggle AI Chat"
echo "    <leader>aa  - AI Actions menu"
echo "    <leader>ae  - Inline AI edit (visual)"
echo "    <leader>ap  - Add selection to chat"
echo ""
echo "  Ollama Prompts:"
echo "    <leader>og  - Generate code"
echo "    <leader>oe  - Explain code"
echo "    <leader>or  - Review code"
echo "    <leader>of  - Fix code"
echo "    <leader>ot  - Generate tests"
echo "    <leader>od  - Generate docstring"
echo "    <leader>oR  - Refactor code"
echo "    <leader>oT  - Add type hints"
echo "    <leader>om  - Switch model"
echo ""
echo "  Quick Access:"
echo "    <leader>as  - Show LLM status"
echo "    <leader>al  - List Ollama models"
echo "    <leader>aI  - Terminal AI chat"
echo ""
echo "=============================================="
echo ""

# Start interactive shell
exec /bin/bash --login
