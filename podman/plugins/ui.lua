-- ui.lua
-- For more details, see: https://www.lazyvim.org/plugins/ui#snacksnvim
return {
    {
        "folke/snacks.nvim",
        opts = {
            dashboard = {
                preset = {
                    -- Dashboard header logo
                    header = [[
▗▖   ▗▖    ▗▄▖ ▗▖  ▗▖ ▗▄▖ ▗▄▄▄ ▗▄▄▄▖▗▖  ▗▖
▐▌   ▐▌   ▐▌ ▐▌▐▛▚▞▜▌▐▌ ▐▌▐▌  █▐▌   ▐▌  ▐▌
▐▌   ▐▌   ▐▛▀▜▌▐▌  ▐▌▐▛▀▜▌▐▌  █▐▛▀▀▘▐▌  ▐▌
▐▙▄▄▖▐▙▄▄▖▐▌ ▐▌▐▌  ▐▌▐▌ ▐▌▐▙▄▄▀▐▙▄▄▖ ▝▚▞▘


✨ AI Powered Dev Environment ✨
          ]],
          -- Dashboard keys configuration
          -- stylua: ignore
          ---@type snacks.dashboard.Item[]
          keys = {
            {
              icon = "📂", -- Find File
              key = "f",
              desc = "Find File",
              action = ":lua Snacks.dashboard.pick('files')"
            }, {
              icon = "📝", -- New File
              key = "n",
              desc = "New File",
              action = ":ene | startinsert"
            }, {
              icon = "🔎", -- Find Text
              key = "g",
              desc = "Find Text",
              action = ":lua Snacks.dashboard.pick('live_grep')"
            }, {
              icon = "🕒", -- Recent Files
              key = "r",
              desc = "Recent Files",
              action = ":lua Snacks.dashboard.pick('oldfiles')"
            }, {
              icon = "⚙️", -- Config
              key = "c",
              desc = "Config",
              action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})"
            }, {
              icon = "♻️", -- Restore Session
              key = "s",
              desc = "Restore Session",
              section = "session"
            }, {
              icon = "✨", -- Lazy Extras
              key = "x",
              desc = "Lazy Extras",
              action = ":LazyExtras"
            }, {
              icon = "🐍", -- Python Environment
              key = "p",
              desc = "Python Env",
              action = ":!python --version"
            }, {
              icon = "📦", -- Manage Packages
              key = "m",
              desc = "Manage Packages",
              action = ":Lazy"
            }, {
              icon = "❌", -- Quit
              key = "q",
              desc = "Quit",
              action = ":qa"
            }
          }
        }
      }
    }
  },

  -----------------------------------------------------------------------------
  -- Better Notifications
  -----------------------------------------------------------------------------
  {
    "rcarriga/nvim-notify",
    opts = {
      timeout = 3000,
      max_height = function()
        return math.floor(vim.o.lines * 0.75)
      end,
      max_width = function()
        return math.floor(vim.o.columns * 0.75)
      end,
      on_open = function(win)
        vim.api.nvim_win_set_config(win, { zindex = 100 })
      end
    }
  },

  -----------------------------------------------------------------------------
  -- Symbol Outline (like VS Code's Outline panel)
  -----------------------------------------------------------------------------
  {
    "simrat39/symbols-outline.nvim",
    cmd = "SymbolsOutline",
    keys = {
      { "<leader>cs", "<cmd>SymbolsOutline<cr>", desc = "Symbols Outline" },
    },
    config = true
  },

  -----------------------------------------------------------------------------
  -- Better Word Highlighting
  -----------------------------------------------------------------------------
  {
    "RRethy/vim-illuminate",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      delay = 200,
      large_file_cutoff = 2000,
      large_file_overrides = {
        providers = { "lsp" }
      }
    },
    config = function(_, opts)
      require("illuminate").configure(opts)
    end
  },

  -----------------------------------------------------------------------------
  -- File Explorer (Left Side Panel, like VS Code)
  -----------------------------------------------------------------------------
  {
    "nvim-tree/nvim-tree.lua",
    cmd = "NvimTreeToggle",
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle File Explorer" },
    },
    config = function()
      require("nvim-tree").setup({
        view = {
          width = 40,
          side = "left",
        },
        renderer = {
          icons = {
            show = {
              git = false,
              folder = true,
              file = true,
              folder_arrow = true,
            },
          },
        },
      })
    end,
    dependencies = { "nvim-tree/nvim-web-devicons" }, -- For file icons
  },

  -----------------------------------------------------------------------------
  -- Buffer Tabs (akin to VS Code's open file tabs)
  -----------------------------------------------------------------------------
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("bufferline").setup({
        options = {
          -- Make buffer line look more like basic editor tabs
          show_buffer_close_icons = false,
          show_close_icon = false,
        },
      })
    end,
  },

  -----------------------------------------------------------------------------
  -- VS Code–style Completion Icons
  -----------------------------------------------------------------------------
  {
    "onsails/lspkind.nvim",
    event = "VeryLazy",
    config = function()
      require("lspkind").init({
        mode = "symbol_text",
        preset = "default",
        symbol_map = {
          Text = "",
          Method = "",
          Function = "",
          Constructor = "",
          Field = "ﰠ",
          Variable = "",
          Class = "ﴯ",
          Interface = "",
          Module = "",
          Property = "ﰠ",
          Unit = "",
          Value = "",
          Enum = "",
          Keyword = "",
          Snippet = "",
          Color = "",
          File = "",
          Reference = "",
          Folder = "",
          EnumMember = "",
          Constant = "",
          Struct = "פּ",
          Event = "",
          Operator = "",
          TypeParameter = "",
        },
      })
    end,
  },
}