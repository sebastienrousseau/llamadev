-- ui.lua
-- LlamaDev IDE - Apple-level UI Design System
-- Designed by Jony Ive combo: designer → animator → interactor → reviewer
return {
    -----------------------------------------------------------------------------
    -- Catppuccin Theme - Premium dark theme with semantic tokens
    -----------------------------------------------------------------------------
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        lazy = false,
        opts = {
            flavour = "mocha",
            transparent_background = false,
            term_colors = true,
            dim_inactive = { enabled = true, shade = "dark", percentage = 0.15 },
            styles = {
                comments = { "italic" },
                conditionals = { "italic" },
                functions = { "bold" },
                keywords = { "bold" },
            },
            integrations = {
                cmp = true,
                gitsigns = true,
                nvimtree = true,
                treesitter = true,
                notify = true,
                which_key = true,
                indent_blankline = { enabled = true, colored_indent_levels = false },
                telescope = { enabled = true, style = "nvchad" },
                native_lsp = {
                    enabled = true,
                    virtual_text = {
                        errors = { "italic" },
                        hints = { "italic" },
                        warnings = { "italic" },
                        information = { "italic" },
                    },
                    underlines = {
                        errors = { "undercurl" },
                        hints = { "undercurl" },
                        warnings = { "undercurl" },
                        information = { "undercurl" },
                    },
                },
            },
            custom_highlights = function(colors)
                return {
                    -- Enhanced focus indicators (3:1 contrast minimum)
                    CursorLine = { bg = colors.surface0 },
                    CursorLineNr = { fg = colors.lavender, bold = true },
                    Visual = { bg = colors.surface1, bold = true },
                    -- Semantic status colors
                    DiagnosticError = { fg = colors.red },
                    DiagnosticWarn = { fg = colors.peach },
                    DiagnosticInfo = { fg = colors.sky },
                    DiagnosticHint = { fg = colors.teal },
                    -- Panel borders
                    FloatBorder = { fg = colors.surface2 },
                    NormalFloat = { bg = colors.base },
                    -- Which-key styling
                    WhichKeyFloat = { bg = colors.mantle },
                    WhichKeyBorder = { fg = colors.surface2 },
                }
            end,
        },
        config = function(_, opts)
            require("catppuccin").setup(opts)
            vim.cmd.colorscheme("catppuccin")
        end,
    },

    -----------------------------------------------------------------------------
    -- Snacks.nvim - Minimal, focused Dashboard
    -----------------------------------------------------------------------------
    {
        "folke/snacks.nvim",
        opts = {
            dashboard = {
                preset = {
                    header = [[
  ╭──────────────────────────────────────────╮
  │                                          │
  │   ██╗     ██╗      █████╗ ███╗   ███╗   │
  │   ██║     ██║     ██╔══██╗████╗ ████║   │
  │   ██║     ██║     ███████║██╔████╔██║   │
  │   ██║     ██║     ██╔══██║██║╚██╔╝██║   │
  │   ███████╗███████╗██║  ██║██║ ╚═╝ ██║   │
  │   ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝   │
  │                                          │
  │         AI-Powered Python IDE            │
  │                                          │
  ╰──────────────────────────────────────────╯]],
                    ---@type snacks.dashboard.Item[]
                    keys = {
                        { icon = " ", key = "f", desc = "Find File", action = ":Telescope find_files" },
                        { icon = " ", key = "g", desc = "Find Text", action = ":Telescope live_grep" },
                        { icon = " ", key = "r", desc = "Recent", action = ":Telescope oldfiles" },
                        { icon = " ", key = "e", desc = "Explorer", action = ":NvimTreeToggle" },
                        { icon = " ", key = "c", desc = "Config", action = ":e $MYVIMRC" },
                        { icon = " ", key = "l", desc = "Lazy", action = ":Lazy" },
                        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
                    },
                },
            },
        },
    },

    -----------------------------------------------------------------------------
    -- Which-Key - Discoverable keybindings
    -----------------------------------------------------------------------------
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            preset = "helix",
            delay = 300,
            icons = {
                breadcrumb = "»",
                separator = "→",
                group = "+",
            },
            win = {
                border = "rounded",
                padding = { 1, 2 },
            },
        },
        config = function(_, opts)
            local wk = require("which-key")
            wk.setup(opts)
            wk.add({
                { "<leader>a", group = "AI" },
                { "<leader>b", group = "Buffer" },
                { "<leader>c", group = "Code" },
                { "<leader>d", group = "Debug" },
                { "<leader>f", group = "Find" },
                { "<leader>g", group = "Git" },
                { "<leader>p", group = "Python" },
                { "<leader>t", group = "Test" },
                { "<leader>w", group = "Window" },
                { "<leader>x", group = "Diagnostics" },
            })
        end,
    },

    -----------------------------------------------------------------------------
    -- Telescope - Fuzzy finder with premium styling
    -----------------------------------------------------------------------------
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope-ui-select.nvim",
        },
        cmd = "Telescope",
        keys = {
            { "<leader><leader>", "<cmd>Telescope commands<cr>", desc = "Commands" },
            { "<C-p>", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
            { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Files" },
            { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Grep" },
            { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
            { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent" },
            { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help" },
            { "<leader>ss", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Symbols" },
            { "<leader>gc", "<cmd>Telescope git_commits<cr>", desc = "Commits" },
            { "<leader>gb", "<cmd>Telescope git_branches<cr>", desc = "Branches" },
        },
        opts = {
            defaults = {
                prompt_prefix = "   ",
                selection_caret = "  ",
                entry_prefix = "  ",
                sorting_strategy = "ascending",
                layout_strategy = "horizontal",
                layout_config = {
                    horizontal = {
                        prompt_position = "top",
                        preview_width = 0.5,
                    },
                    width = 0.8,
                    height = 0.8,
                },
                borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
                file_ignore_patterns = { "node_modules", ".git/", "__pycache__" },
            },
        },
        config = function(_, opts)
            local telescope = require("telescope")
            local actions = require("telescope.actions")
            -- Enhanced navigation mappings
            opts.defaults = opts.defaults or {}
            opts.defaults.mappings = {
                i = {
                    ["<C-j>"] = actions.move_selection_next,
                    ["<C-k>"] = actions.move_selection_previous,
                    ["<C-n>"] = actions.cycle_history_next,
                    ["<C-p>"] = actions.cycle_history_prev,
                    ["<C-u>"] = actions.preview_scrolling_up,
                    ["<C-d>"] = actions.preview_scrolling_down,
                    ["<Esc>"] = actions.close,
                },
                n = {
                    ["j"] = actions.move_selection_next,
                    ["k"] = actions.move_selection_previous,
                    ["q"] = actions.close,
                    ["<Esc>"] = actions.close,
                },
            }
            opts.extensions = {
                ["ui-select"] = {
                    require("telescope.themes").get_dropdown({})
                }
            }
            telescope.setup(opts)
            telescope.load_extension("ui-select")
        end,
    },

    -----------------------------------------------------------------------------
    -- Notifications - Minimal, non-intrusive
    -----------------------------------------------------------------------------
    {
        "rcarriga/nvim-notify",
        opts = {
            timeout = 2000,
            max_height = function() return math.floor(vim.o.lines * 0.5) end,
            max_width = function() return math.floor(vim.o.columns * 0.4) end,
            render = "compact",
            stages = "fade",
            top_down = true,
        },
    },

    -----------------------------------------------------------------------------
    -- Lualine - Clean status line
    -----------------------------------------------------------------------------
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            options = {
                theme = "catppuccin",
                component_separators = "",
                section_separators = "",
                globalstatus = true,
            },
            sections = {
                lualine_a = { { "mode", fmt = function(str) return str:sub(1,1) end } },
                lualine_b = { "branch" },
                lualine_c = { { "filename", path = 1 }, "diagnostics" },
                lualine_x = { "filetype" },
                lualine_y = { "progress" },
                lualine_z = { "location" },
            },
        },
    },

    -----------------------------------------------------------------------------
    -- Indent guides - Subtle visual hierarchy
    -----------------------------------------------------------------------------
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            indent = { char = "│", highlight = "IblIndent" },
            scope = { enabled = true, show_start = false, show_end = false },
            exclude = { filetypes = { "help", "dashboard", "lazy", "NvimTree" } },
        },
    },

    -----------------------------------------------------------------------------
    -- File Explorer - Clean sidebar with enhanced navigation
    -----------------------------------------------------------------------------
    {
        "nvim-tree/nvim-tree.lua",
        cmd = { "NvimTreeToggle", "NvimTreeFocus" },
        keys = {
            { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Explorer" },
        },
        opts = {
            view = { width = 30, side = "left" },
            renderer = {
                indent_markers = { enable = true },
                icons = {
                    show = { file = true, folder = true, folder_arrow = true, git = true },
                    glyphs = {
                        folder = { arrow_closed = "", arrow_open = "" },
                    },
                },
            },
            filters = { dotfiles = false },
            git = { enable = true, ignore = false },
            on_attach = function(bufnr)
                local api = require("nvim-tree.api")
                local function opts(desc)
                    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
                end
                -- Default mappings
                api.config.mappings.default_on_attach(bufnr)
                -- Enhanced navigation (vim-style)
                vim.keymap.set("n", "l", api.node.open.edit, opts("Open"))
                vim.keymap.set("n", "h", api.node.navigate.parent_close, opts("Close Directory"))
                vim.keymap.set("n", "v", api.node.open.vertical, opts("Open: Vertical Split"))
                vim.keymap.set("n", "s", api.node.open.horizontal, opts("Open: Horizontal Split"))
                vim.keymap.set("n", "t", api.node.open.tab, opts("Open: New Tab"))
                vim.keymap.set("n", "<Tab>", api.node.open.preview, opts("Preview"))
            end,
        },
        dependencies = { "nvim-tree/nvim-web-devicons" },
    },

    -----------------------------------------------------------------------------
    -- Buffer tabs - Minimal tab line
    -----------------------------------------------------------------------------
    {
        "akinsho/bufferline.nvim",
        event = "VeryLazy",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        keys = {
            { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev" },
            { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next" },
            { "<leader>bd", "<cmd>bdelete<cr>", desc = "Close" },
        },
        opts = {
            options = {
                mode = "buffers",
                show_buffer_close_icons = false,
                show_close_icon = false,
                indicator = { style = "underline" },
                diagnostics = "nvim_lsp",
                offsets = {
                    { filetype = "NvimTree", text = "", padding = 1 },
                },
                separator_style = "thin",
            },
        },
    },

    -----------------------------------------------------------------------------
    -- Git signs - Inline git status
    -----------------------------------------------------------------------------
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            signs = {
                add = { text = "│" },
                change = { text = "│" },
                delete = { text = "_" },
                topdelete = { text = "‾" },
                changedelete = { text = "~" },
            },
            current_line_blame = false,
        },
    },

    -----------------------------------------------------------------------------
    -- Word highlighting
    -----------------------------------------------------------------------------
    {
        "RRethy/vim-illuminate",
        event = { "BufReadPost", "BufNewFile" },
        opts = { delay = 200, large_file_cutoff = 2000 },
        config = function(_, opts)
            require("illuminate").configure(opts)
        end,
    },

    -----------------------------------------------------------------------------
    -- Todo comments
    -----------------------------------------------------------------------------
    {
        "folke/todo-comments.nvim",
        event = { "BufReadPost", "BufNewFile" },
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = { signs = false },
    },

    -----------------------------------------------------------------------------
    -- Trouble - Diagnostics panel
    -----------------------------------------------------------------------------
    {
        "folke/trouble.nvim",
        cmd = "Trouble",
        keys = {
            { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics" },
        },
        opts = {},
    },

    -----------------------------------------------------------------------------
    -- Completion icons
    -----------------------------------------------------------------------------
    {
        "onsails/lspkind.nvim",
        event = "VeryLazy",
        config = function()
            require("lspkind").init({ mode = "symbol", preset = "codicons" })
        end,
    },
}
