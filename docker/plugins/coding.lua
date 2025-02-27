-- coding.lua
-- A Neovim configuration aligned with requirements.txt for Python in 2025:
--
-- 1) LSP: pylsp for language features, ruff-lsp for linting
-- 2) Mypy for type checking
-- 3) Codespell for spell checking
-- 4) Debugging with debugpy
-- 5) Testing (pytest) via neotest
-- 6) pip-audit for security checks
-- 7) mdformat for documentation formatting
-- 8) venv-selector for environment management

return {
    -----------------------------------------------------------------------------
    -- Autocompletion with nvim-cmp
    -----------------------------------------------------------------------------
    {
        "hrsh7th/nvim-cmp",
        -- If using LazyVim, this plugin is often included by default.
        -- We override the config to add extra keybindings.
        opts = function(_, opts)
            local cmp = require("cmp")
            -- Example: cycle suggestions with <C-j>/<C-k>:
            opts.mapping = vim.tbl_deep_extend("force", opts.mapping, {
                ["<C-j>"] = cmp.mapping.select_next_item({
                    behavior = cmp.SelectBehavior.Insert
                }),
                ["<C-k>"] = cmp.mapping.select_prev_item({
                    behavior = cmp.SelectBehavior.Insert
                })
            })
        end
    },

    -----------------------------------------------------------------------------
    -- Treesitter Configuration
    -----------------------------------------------------------------------------
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            if type(opts.ensure_installed) == "table" then
                vim.list_extend(opts.ensure_installed, {
                    "python", "markdown", "json", "toml", "yaml", "bash", "vim",
                    "regex"
                })
            end
        end
    },

    -----------------------------------------------------------------------------
    -- Global on_attach for LSP
    -----------------------------------------------------------------------------
    {
        "neovim/nvim-lspconfig",
        lazy = true, -- Let other plugins load it
        config = function()
            local on_attach = function(client, bufnr)
                -- We disable LSP formatting to avoid conflicts with null-ls or ruff
                client.server_capabilities.documentFormattingProvider = false

                local bufmap = function(mode, lhs, rhs, desc)
                    if desc then desc = "[LSP] " .. desc end
                    vim.keymap
                        .set(mode, lhs, rhs, {buffer = bufnr, desc = desc})
                end

                -- Common LSP Keymaps
                bufmap("n", "<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
                bufmap("n", "<leader>ca", vim.lsp.buf.code_action, "Code Action")
                bufmap("n", "gd", vim.lsp.buf.definition, "Go to Definition")
                bufmap("n", "gr", vim.lsp.buf.references, "Go to References")
                bufmap("n", "K", vim.lsp.buf.hover, "Hover Documentation")
                bufmap("n", "<leader>e", vim.diagnostic.open_float,
                       "Show Diagnostics")
            end

            _G.lsp_on_attach = on_attach
        end
    },

    -----------------------------------------------------------------------------
    -- LSP: pylsp (for completions/definition/etc) + ruff-lsp (linting/auto-fixes)
    -----------------------------------------------------------------------------
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim"
        },
        event = {"BufReadPre", "BufNewFile"},
        config = function()
            local lspconfig = require("lspconfig")
            local on_attach = _G.lsp_on_attach

            

            -- "ruff_lsp" for fast linting and formatting
            lspconfig.ruff_lsp.setup({
                on_attach = on_attach,
                init_options = {
                    settings = {
                        -- Ruff configuration
                        args = {
                            "--line-length=88",  -- Default black line length
                            "--select=E,F,W,I,N,UP,B,A,C4,DTZ,T20,RET,SIM,PL"
                        },
                        -- Enable autofix on save
                        codeAction = {
                            enable = true,
                            applyOnSave = {
                                enable = true,
                                types = {"organizeImports", "fixAll"}
                            }
                        }
                    }
                }
            })
        end
    },

    -----------------------------------------------------------------------------
    -- Mason Tool Installation
    -----------------------------------------------------------------------------
    {
        "williamboman/mason.nvim",
        opts = {
            ensure_installed = {
                -- LSP servers
                "pylsp",
                "ruff-lsp",
                -- Tools
                "mypy",
                "codespell",
                "debugpy",
                "pip-audit",
                "mdformat",
                "mdformat-black",
                "poetry",        -- Now included
                "pre-commit"     -- Now included
            }
        }
    },
    {
        "williamboman/mason-lspconfig.nvim",
        opts = {
            ensure_installed = {"pylsp", "ruff-lsp"},
            automatic_installation = true
        }
    },

    -----------------------------------------------------------------------------
    -- Debugging Support: nvim-dap + debugpy
    -----------------------------------------------------------------------------
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            -- Order matters: nvim-nio must load before nvim-dap-ui
            "nvim-neotest/nvim-nio",
            "rcarriga/nvim-dap-ui",
            "mfussenegger/nvim-dap-python"
        },
        config = function()
            local dap = require("dap")
            local dapui = require("dapui")
            local dap_python = require("dap-python")

            -- Use the currently active python
            dap_python.setup(vim.fn.exepath("python"))
            dap_python.test_runner = "pytest"

            dapui.setup({
                layouts = {
                    {
                        elements = {
                            "scopes",
                            "breakpoints",
                            "stacks",
                            "watches"
                        },
                        size = 40,
                        position = "left"
                    },
                    {
                        elements = {"repl", "console"},
                        size = 10,
                        position = "bottom"
                    }
                }
            })

            -- Debugging Keymaps
            vim.keymap.set("n", "<F5>", dap.continue, {desc = "[DAP] Continue"})
            vim.keymap.set("n", "<F10>", dap.step_over,
                           {desc = "[DAP] Step Over"})
            vim.keymap.set("n", "<F11>", dap.step_into,
                           {desc = "[DAP] Step Into"})
            vim.keymap
                .set("n", "<F12>", dap.step_out, {desc = "[DAP] Step Out"})
            vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint,
                           {desc = "[DAP] Toggle Breakpoint"})
        end
    },

    -----------------------------------------------------------------------------
    -- Formatting Configuration with conform.nvim
    -----------------------------------------------------------------------------
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                python = {"ruff"}, -- Using ruff for Python formatting
                markdown = {"mdformat"}
            },
            -- Format on save
            format_on_save = {
                timeout_ms = 1000,
                lsp_fallback = true
            },
            -- Customize formatters
            formatters = {
                mdformat = {
                    args = {"--number"}
                }
            }
        }
    },

    -----------------------------------------------------------------------------
    -- Testing with Neotest + Pytest
    -----------------------------------------------------------------------------
    {
        "nvim-neotest/neotest",
        dependencies = {
            "nvim-neotest/nvim-nio",
            "nvim-neotest/neotest-python",
            "nvim-lua/plenary.nvim",
            "antoinemadec/FixCursorHold.nvim",
            "nvim-treesitter/nvim-treesitter"
        },
        config = function()
            local neotest = require("neotest")
            neotest.setup({
                adapters = {
                    require("neotest-python")({
                        dap = {justMyCode = false},
                        runner = "pytest",
                        -- Coverage and async support
                        args = {
                            "--cov",
                            "--cov-report=term-missing",
                            "-v",
                            "--asyncio-mode=auto"
                        }
                    })
                }
            })

            -- Keymaps for Neotest
            vim.keymap.set("n", "<leader>tt", neotest.run.run,
                           {desc = "[Test] Run nearest test"})
            vim.keymap.set("n", "<leader>tf",
                           function()
                neotest.run.run(vim.fn.expand("%"))
            end, {desc = "[Test] Run test file"})
            vim.keymap.set("n", "<leader>ts", neotest.summary.toggle,
                           {desc = "[Test] Toggle summary"})
        end
    },

    -----------------------------------------------------------------------------
    -- Python Docstring Support (Neogen)
    -----------------------------------------------------------------------------
    {
        "danymat/neogen",
        dependencies = {"nvim-treesitter/nvim-treesitter"},
        config = function()
            require("neogen").setup({
                enabled = true,
                languages = {
                    python = {
                        template = {
                            annotation_convention = "google_docstrings"
                        }
                    }
                }
            })
            vim.keymap.set("n", "<Leader>nd", ":Neogen<CR>",
                           {desc = "[Docs] Generate Docstring"})
        end
    },

    -----------------------------------------------------------------------------
    -- Linting Configuration with nvim-lint
    -----------------------------------------------------------------------------
    {
        "mfussenegger/nvim-lint",
        event = {"BufReadPre", "BufNewFile"},
        config = function()
            local lint = require("lint")
            lint.linters_by_ft = {
                python = {"mypy", "codespell"},
                markdown = {"codespell"},
                text = {"codespell"}
            }
            
            -- Configure mypy
            lint.linters.mypy.args = {
                "--ignore-missing-imports",
                "--check-untyped-defs"
            }

            -- Run linting automatically on save
            vim.api.nvim_create_autocmd({"BufWritePost"}, {
                callback = function()
                    lint.try_lint()
                end,
            })
        end
    },

    -----------------------------------------------------------------------------
    -- Enhanced Python Syntax & Indentation
    -----------------------------------------------------------------------------
    {
        "Vimjas/vim-python-pep8-indent",
        ft = "python"
    },
    {
        "vim-python/python-syntax",
        ft = "python",
        config = function()
            vim.g.python_highlight_all = 1
        end
    }
}