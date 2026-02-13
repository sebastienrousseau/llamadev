-- disabled.lua
-- Disable plugins not needed for our AI-first Python IDE setup
return {
    -- Disable mason.nvim (we manage tools via container)
    { "mason-org/mason.nvim", enabled = false },
    { "mason-org/mason-lspconfig.nvim", enabled = false },

    -- Disable mini plugins we don't use (using dedicated alternatives)
    { "nvim-mini/mini.pairs", enabled = false },
    { "nvim-mini/mini.surround", enabled = false },

    -- Disable neodev (not needed for our Python-focused setup)
    { "folke/neodev.nvim", enabled = false },

    -- Disable venv-selector (we use container-managed venv)
    { "linux-cultist/venv-selector.nvim", enabled = false },

    -- Disable persistence (we use container state)
    { "folke/persistence.nvim", enabled = false },
}
