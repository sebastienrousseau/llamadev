# LLM Configuration Guide

Optimized configurations for CodeLlama 7B Code Q4_K_M with both Ollama and LM Studio.

## Quick Start

### Ollama Setup

```bash
# 1. Pull the base model
ollama pull codellama:7b-code-q4_K_M

# 2. Create optimized variants
cd config/ollama
ollama create codellama-dev -f Modelfile.codellama-optimized
ollama create codellama-fim -f Modelfile.codellama-fim

# 3. Verify models
ollama list

# 4. Test the model
ollama run codellama-dev "Write a Python function to check if a number is prime"
```

### LM Studio Setup

1. **Download the model** (if not already):
   - Open LM Studio → Search → "codellama 7b code q4_k_m"
   - Download `codellama-7b-code.Q4_K_M.gguf`

2. **Import presets**:
   - Go to Settings → Presets → Import
   - Import `config/lmstudio/codellama-7b-code.preset.json`
   - Import `config/lmstudio/codellama-7b-fim.preset.json`

3. **Start the server**:
   - Load the model
   - Select "CodeLlama 7B Code - Optimized" preset
   - Click "Start Server" (default port: 1234)

4. **Configure LlamaDev**:
   ```bash
   export LLM_PROVIDER=lmstudio
   export LMSTUDIO_HOST=http://localhost:1234
   ```

---

## Configuration Files

### Ollama

| File | Purpose |
|------|---------|
| `ollama.env` | Environment variables for Ollama server |
| `Modelfile.codellama-optimized` | Chat/instruction model with coding system prompt |
| `Modelfile.codellama-fim` | Fill-in-Middle model for code completion |

### LM Studio

| File | Purpose |
|------|---------|
| `codellama-7b-code.preset.json` | Main preset for chat/instructions |
| `codellama-7b-fim.preset.json` | Preset for inline code completion |
| `server-config.json` | Reference server configuration |

---

## Parameter Reference

### Inference Parameters

| Parameter | Chat Value | FIM Value | Description |
|-----------|------------|-----------|-------------|
| `temperature` | 0.15 | 0.1 | Randomness (lower = more deterministic) |
| `top_p` | 0.85 | 0.8 | Nucleus sampling threshold |
| `top_k` | 30 | 20 | Top tokens to consider |
| `repeat_penalty` | 1.15 | 1.2 | Repetition avoidance |
| `max_tokens` | 2048 | 256 | Maximum output length |
| `context_length` | 4096 | 2048 | Context window size |

### Performance Parameters

| Parameter | Recommended | Description |
|-----------|-------------|-------------|
| `gpu_layers` | -1 (all) | Layers to offload to GPU |
| `threads` | 8 | CPU threads for computation |
| `batch_size` | 512 | Tokens processed per batch |
| `flash_attention` | true | Faster attention (requires modern GPU) |
| `mmap` | true | Memory-mapped model loading |

---

## Hardware Requirements

### Minimum (CPU-only)
- 8GB RAM
- Modern x86_64 CPU with AVX2

### Recommended (GPU)
- 6GB+ VRAM (RTX 3060, RX 6700 XT, or better)
- 16GB system RAM
- CUDA 11.7+ or ROCm 5.4+

### Memory Usage (Q4_K_M)
| Context | VRAM Usage | RAM Usage |
|---------|------------|-----------|
| 2048 | ~4.2 GB | ~5.5 GB |
| 4096 | ~4.8 GB | ~6.5 GB |
| 8192 | ~5.8 GB | ~8.0 GB |

---

## Neovim Integration

The models integrate with Neovim via `plugins/ai.lua`:

### Chat Model (codellama-dev)
- Used by: CodeCompanion chat, Ollama prompts
- Best for: Explanations, reviews, complex generation

### FIM Model (codellama-fim)
- Used by: cmp-ai completion source
- Best for: Inline code completion, autocomplete

### Switching Models

```lua
-- In Neovim command mode
:OllamaModel codellama-dev    -- For chat
:OllamaModel codellama-fim    -- For completion
```

---

## Troubleshooting

### Model loads slowly
- Enable `mmap` in settings
- Use GPU offloading (`gpu_layers = -1`)
- Reduce `context_length` if VRAM limited

### Poor code quality
- Lower `temperature` (try 0.1)
- Increase `repeat_penalty` (try 1.2)
- Check system prompt is applied

### Out of memory
- Reduce `context_length` to 2048
- Reduce `gpu_layers` (try 20-28)
- Close other GPU applications

### Slow inference
- Increase `batch_size` to 512-1024
- Enable `flash_attention`
- Use fewer `threads` if hyperthreading

---

## Model Comparison

| Variant | Use Case | Speed | Quality |
|---------|----------|-------|---------|
| `codellama:7b-code-q4_K_M` | Base model | Fast | Good |
| `codellama-dev` (custom) | Chat/coding | Fast | Better |
| `codellama-fim` (custom) | Completion | Fastest | Good |
| `codellama:13b-code-q4_K_M` | Complex tasks | Slower | Best |

---

## Environment Variables

```bash
# Provider selection
LLM_PROVIDER=ollama          # or "lmstudio"
LLM_MODEL=codellama-dev      # Model name

# Ollama
OLLAMA_HOST=http://localhost:11434
OLLAMA_KEEP_ALIVE=300        # Keep model loaded (seconds)
OLLAMA_GPU_LAYERS=-1         # GPU offload (-1 = all)
OLLAMA_FLASH_ATTENTION=true

# LM Studio
LMSTUDIO_HOST=http://localhost:1234
```
