-- disabled.lua
-- Disable plugins not needed for Python development
return {
    -- disable mason.nvim
    { "williamboman/mason.nvim", enabled = false },
    { "williamboman/mason-lspconfig.nvim", enabled = false },

    -- Disable mini.pairs since we use nvim-autopairs
    {"echasnovski/mini.pairs", enabled = false},

    -- Disable mini.surround since we use nvim-surround
    {"echasnovski/mini.surround", enabled = false},

    -- Disable language-specific plugins you don't need
    {"folke/neodev.nvim", enabled = false},

    -- If you don't need persistent terminal
    {"akinsho/toggleterm.nvim", enabled = false},

    -- If you don't need advanced indentation guides
    {"lukas-reineke/indent-blankline.nvim", enabled = false},

    -- disable venvselect
    { "linux-cultist/venv-selector.nvim", enabled = false }
}
