-- ai.lua
-- Unified LLM configuration for Ollama and LM Studio
-- Models: codellama-dev (chat), codellama-fim (completion)
--
-- Environment Variables:
--   LLM_PROVIDER: "ollama" (default) or "lmstudio"
--   LLM_MODEL: Override model name (default: codellama-dev)
--   OLLAMA_HOST: Ollama API host (default: http://localhost:11434)
--   LMSTUDIO_HOST: LM Studio API host (default: http://localhost:1234)

-- ============================================================================
-- Provider Detection & Configuration
-- ============================================================================

local function get_provider()
    return vim.fn.getenv("LLM_PROVIDER") or "ollama"
end

local function get_ollama_host()
    local host = vim.fn.getenv("OLLAMA_HOST")
    if host and host ~= "" then
        -- Handle both "0.0.0.0:11434" and "http://localhost:11434" formats
        if not host:match("^https?://") then
            host = "http://localhost:11434"
        end
        return host
    end
    return "http://localhost:11434"
end

local function get_lmstudio_host()
    return vim.fn.getenv("LMSTUDIO_HOST") or "http://localhost:1234"
end

local function get_endpoint()
    local provider = get_provider()
    if provider == "lmstudio" then
        return get_lmstudio_host() .. "/v1"
    end
    return get_ollama_host() .. "/v1"
end

local function get_chat_model()
    local override = vim.fn.getenv("LLM_MODEL")
    if override and override ~= "" then
        return override
    end
    local provider = get_provider()
    if provider == "lmstudio" then
        return "codellama-7b-code-q4_K_M"
    end
    -- Use optimized model if available, fallback to base
    return "codellama-dev"
end

local function get_fim_model()
    local provider = get_provider()
    if provider == "lmstudio" then
        return "codellama-7b-code-q4_K_M"
    end
    return "codellama-fim"
end

-- ============================================================================
-- Optimized Parameters for CodeLlama 7B
-- ============================================================================

local CHAT_PARAMS = {
    temperature = 0.15,
    top_p = 0.85,
    top_k = 30,
    repeat_penalty = 1.15,
    num_ctx = 4096,
    num_predict = 2048,
}

local FIM_PARAMS = {
    temperature = 0.1,
    top_p = 0.8,
    top_k = 20,
    repeat_penalty = 1.2,
    num_ctx = 2048,
    num_predict = 256,
}

local SYSTEM_PROMPT = [[You are CodeLlama, an expert AI programming assistant.

CAPABILITIES:
- Write clean, efficient, production-ready code
- Debug, analyze, and fix code issues
- Explain complex algorithms and code patterns
- Generate comprehensive tests (pytest, unittest)
- Refactor and optimize existing code
- Write documentation and docstrings

GUIDELINES:
1. Be concise - provide working code with minimal explanation unless asked
2. Follow language best practices (PEP 8 for Python, etc.)
3. Use type hints for Python functions
4. Include error handling where appropriate
5. Prefer readability and maintainability over cleverness

OUTPUT FORMAT:
- Use markdown code blocks with language specifier
- For multi-file changes, clearly label each file
- When fixing bugs, briefly explain what was wrong]]

-- ============================================================================
-- Plugin Configurations
-- ============================================================================

return {
    ---------------------------------------------------------------------------
    -- CodeCompanion.nvim - Unified AI Assistant
    ---------------------------------------------------------------------------
    {
        "olimorris/codecompanion.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
            "hrsh7th/nvim-cmp",
        },
        opts = {
            strategies = {
                chat = { adapter = "local_llm" },
                inline = { adapter = "local_llm" },
                agent = { adapter = "local_llm" },
            },
            adapters = {
                local_llm = function()
                    return require("codecompanion.adapters").extend("openai_compatible", {
                        name = "local_llm",
                        env = {
                            url = get_endpoint(),
                            api_key = "NONE",
                        },
                        schema = {
                            model = { default = get_chat_model() },
                            num_ctx = { default = CHAT_PARAMS.num_ctx },
                            temperature = { default = CHAT_PARAMS.temperature },
                            top_p = { default = CHAT_PARAMS.top_p },
                        },
                        handlers = {
                            on_stdout = function(self, data)
                                return require("codecompanion.adapters").openai_compatible.handlers.on_stdout(self, data)
                            end,
                        },
                    })
                end,
            },
            display = {
                diff = { enabled = true, provider = "mini_diff" },
                chat = {
                    window = {
                        layout = "vertical",
                        width = 0.4,
                        height = 0.6,
                    },
                },
            },
            opts = {
                log_level = "ERROR",
                system_prompt = SYSTEM_PROMPT,
            },
        },
        keys = {
            { "<leader>ac", "<cmd>CodeCompanionChat Toggle<CR>", desc = "AI Chat Toggle" },
            { "<leader>aa", "<cmd>CodeCompanionActions<CR>", desc = "AI Actions" },
            { "<leader>ae", "<cmd>CodeCompanion<CR>", desc = "AI Inline Edit", mode = { "n", "v" } },
            { "<leader>ap", "<cmd>CodeCompanionChat Add<CR>", desc = "AI Add to Chat", mode = "v" },
        },
        init = function()
            vim.cmd([[cab cc CodeCompanionChat]])
        end,
    },

    ---------------------------------------------------------------------------
    -- Ollama.nvim - Direct Ollama integration
    ---------------------------------------------------------------------------
    {
        "nomnivore/ollama.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        cmd = { "Ollama", "OllamaModel", "OllamaServe", "OllamaServeStop" },
        opts = function()
            local model = get_chat_model()
            return {
                model = model,
                url = get_ollama_host() .. "/api",
                serve = {
                    on_start = false,
                    command = "ollama",
                    args = { "serve" },
                },
                -- Optimized prompts for CodeLlama
                prompts = {
                    Code = {
                        prompt = [[Generate code based on: $input

Context:
```$ftype
$sel
```

Requirements:
- Follow best practices for $ftype
- Include error handling if appropriate
- Add brief inline comments for complex logic]],
                        input_label = "> ",
                        model = model,
                        action = "display",
                    },
                    Explain = {
                        prompt = [[Explain this code concisely. Cover:
1. What it does (1-2 sentences)
2. Key logic/algorithms used
3. Any potential issues or improvements

```$ftype
$sel
```]],
                        model = model,
                        action = "display",
                    },
                    Review = {
                        prompt = [[Review this code for:
1. Bugs and potential issues
2. Performance improvements
3. Best practices violations
4. Security concerns

```$ftype
$sel
```

Format: List issues with severity (Critical/Warning/Info) and suggested fixes.]],
                        model = model,
                        action = "display",
                    },
                    Fix = {
                        prompt = [[Fix any issues in this code:

```$ftype
$sel
```

Return ONLY the fixed code without explanations. Preserve the original structure and style.]],
                        model = model,
                        action = "replace",
                    },
                    Test = {
                        prompt = [[Generate pytest tests for this code:

```$ftype
$sel
```

Requirements:
- Use pytest fixtures where appropriate
- Include edge cases and error conditions
- Add docstrings to test functions
- Use parametrize for multiple test cases]],
                        model = model,
                        action = "display",
                    },
                    Doc = {
                        prompt = [[Generate a Google-style docstring for this function:

```$ftype
$sel
```

Return ONLY the docstring (including triple quotes), nothing else.]],
                        model = model,
                        action = "insert",
                    },
                    Refactor = {
                        prompt = [[Refactor this code to improve:
- Readability and maintainability
- Performance where possible
- Adherence to best practices

```$ftype
$sel
```

Return the refactored code with brief comments explaining major changes.]],
                        model = model,
                        action = "display",
                    },
                    Types = {
                        prompt = [[Add type hints to this Python code:

```python
$sel
```

Return ONLY the code with type hints added. Use modern Python typing (3.10+).]],
                        model = model,
                        action = "replace",
                    },
                },
            }
        end,
        keys = {
            { "<leader>og", ":Ollama Code<CR>", desc = "Generate Code", mode = { "n", "v" } },
            { "<leader>oe", ":Ollama Explain<CR>", desc = "Explain Code", mode = { "n", "v" } },
            { "<leader>or", ":Ollama Review<CR>", desc = "Review Code", mode = { "n", "v" } },
            { "<leader>of", ":Ollama Fix<CR>", desc = "Fix Code", mode = { "n", "v" } },
            { "<leader>ot", ":Ollama Test<CR>", desc = "Generate Tests", mode = { "n", "v" } },
            { "<leader>od", ":Ollama Doc<CR>", desc = "Generate Docstring", mode = { "n", "v" } },
            { "<leader>oR", ":Ollama Refactor<CR>", desc = "Refactor Code", mode = { "n", "v" } },
            { "<leader>oT", ":Ollama Types<CR>", desc = "Add Type Hints", mode = { "n", "v" } },
            { "<leader>om", "<cmd>OllamaModel<CR>", desc = "Switch Model" },
        },
    },

    ---------------------------------------------------------------------------
    -- FIM Completion via nvim-cmp
    ---------------------------------------------------------------------------
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            {
                "tzachar/cmp-ai",
                dependencies = { "nvim-lua/plenary.nvim" },
                config = function()
                    local cmp_ai = require("cmp_ai.config")
                    cmp_ai:setup({
                        max_lines = 50,
                        provider = "Ollama",
                        provider_options = {
                            model = get_fim_model(),
                            options = {
                                temperature = FIM_PARAMS.temperature,
                                top_p = FIM_PARAMS.top_p,
                                top_k = FIM_PARAMS.top_k,
                                num_ctx = FIM_PARAMS.num_ctx,
                                num_predict = FIM_PARAMS.num_predict,
                            },
                            prompt = function(lines_before, lines_after)
                                -- CodeLlama FIM format
                                return "<PRE> " .. lines_before .. " <SUF>" .. lines_after .. " <MID>"
                            end,
                        },
                        run_on_every_keystroke = false,
                        ignored_file_types = {
                            "TelescopePrompt",
                            "NvimTree",
                            "dashboard",
                            "toggleterm",
                        },
                    })
                end,
            },
        },
        opts = function(_, opts)
            opts.sources = opts.sources or {}
            table.insert(opts.sources, {
                name = "cmp_ai",
                priority = 50,
                group_index = 2,
            })
        end,
    },

    ---------------------------------------------------------------------------
    -- Which-key registration
    ---------------------------------------------------------------------------
    {
        "folke/which-key.nvim",
        opts = {
            spec = {
                { "<leader>a", group = "AI Assistant" },
                { "<leader>o", group = "Ollama" },
            },
        },
    },
}
