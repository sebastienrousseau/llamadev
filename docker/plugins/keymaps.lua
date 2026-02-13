-- keymaps.lua
-- Modern IDE Keybindings for 2026
-- VS Code-style shortcuts, chord progressions, and intelligent navigation

return {
    {
        "LazyVim/LazyVim",
        opts = function()
            local map = vim.keymap.set
            local opts = function(desc)
                return { noremap = true, silent = true, desc = desc }
            end

            -----------------------------------------------------------------
            -- General Keymaps (VS Code style)
            -----------------------------------------------------------------
            -- File operations
            map("n", "<C-s>", "<cmd>w<CR>", opts("Save file"))
            map("i", "<C-s>", "<Esc><cmd>w<CR>a", opts("Save file"))
            map("n", "<C-S-s>", "<cmd>wa<CR>", opts("Save all files"))
            map("n", "<leader>w", "<cmd>w<CR>", opts("Save file"))
            map("n", "<leader>W", "<cmd>wa<CR>", opts("Save all"))
            map("n", "<leader>q", "<cmd>q<CR>", opts("Quit"))
            map("n", "<leader>Q", "<cmd>qa<CR>", opts("Quit all"))

            -- Undo/Redo (VS Code style)
            map("n", "<C-z>", "u", opts("Undo"))
            map("i", "<C-z>", "<Esc>ui", opts("Undo"))
            map("n", "<C-S-z>", "<C-r>", opts("Redo"))
            map("n", "<C-y>", "<C-r>", opts("Redo"))

            -----------------------------------------------------------------
            -- Navigation (VS Code & Modern IDE style)
            -----------------------------------------------------------------
            -- Quick file switching
            map("n", "<C-Tab>", "<cmd>bnext<CR>", opts("Next buffer"))
            map("n", "<C-S-Tab>", "<cmd>bprev<CR>", opts("Previous buffer"))
            map("n", "<S-h>", "<cmd>BufferLineCyclePrev<CR>", opts("Prev buffer"))
            map("n", "<S-l>", "<cmd>BufferLineCycleNext<CR>", opts("Next buffer"))

            -- Window navigation
            map("n", "<C-h>", "<C-w>h", opts("Go to left window"))
            map("n", "<C-j>", "<C-w>j", opts("Go to lower window"))
            map("n", "<C-k>", "<C-w>k", opts("Go to upper window"))
            map("n", "<C-l>", "<C-w>l", opts("Go to right window"))

            -- Window management
            map("n", "<leader>wv", "<cmd>vsplit<CR>", opts("Vertical split"))
            map("n", "<leader>ws", "<cmd>split<CR>", opts("Horizontal split"))
            map("n", "<leader>wc", "<cmd>close<CR>", opts("Close window"))
            map("n", "<leader>wo", "<cmd>only<CR>", opts("Close other windows"))
            map("n", "<leader>w=", "<C-w>=", opts("Equal window sizes"))

            -- Quick movement
            map("n", "<C-d>", "<C-d>zz", opts("Scroll down & center"))
            map("n", "<C-u>", "<C-u>zz", opts("Scroll up & center"))
            map("n", "n", "nzzzv", opts("Next search result & center"))
            map("n", "N", "Nzzzv", opts("Prev search result & center"))

            -- Go to line (Ctrl+G style)
            map("n", "<C-g>", ":", opts("Go to command line"))

            -----------------------------------------------------------------
            -- Command Palette & Search (VS Code style)
            -----------------------------------------------------------------
            map("n", "<C-p>", "<cmd>Telescope find_files<CR>", opts("Find files"))
            map("n", "<C-S-p>", "<cmd>Telescope commands<CR>", opts("Command palette"))
            map("n", "<leader><leader>", "<cmd>Telescope commands<CR>", opts("Command palette"))
            map("n", "<C-S-f>", "<cmd>Telescope live_grep<CR>", opts("Search in files"))
            map("n", "<C-S-e>", "<cmd>NvimTreeToggle<CR>", opts("Toggle explorer"))

            -- Symbol navigation
            map("n", "<C-S-o>", "<cmd>Telescope lsp_document_symbols<CR>", opts("Go to symbol"))
            map("n", "<C-t>", "<cmd>Telescope lsp_workspace_symbols<CR>", opts("Workspace symbols"))

            -----------------------------------------------------------------
            -- Code Actions (VS Code & IDE style)
            -----------------------------------------------------------------
            map("n", "<leader>ca", vim.lsp.buf.code_action, opts("Code actions"))
            map("n", "<leader>cf", vim.lsp.buf.format, opts("Format code"))
            map("n", "<leader>cr", vim.lsp.buf.rename, opts("Rename symbol"))
            map("n", "<leader>cd", vim.lsp.buf.definition, opts("Go to definition"))
            map("n", "<leader>cD", vim.lsp.buf.declaration, opts("Go to declaration"))
            map("n", "<leader>ci", vim.lsp.buf.implementation, opts("Go to implementation"))
            map("n", "<leader>ct", vim.lsp.buf.type_definition, opts("Type definition"))

            -- Quick info
            map("n", "K", vim.lsp.buf.hover, opts("Hover info"))
            map("n", "<C-k>", vim.lsp.buf.signature_help, opts("Signature help"))
            map("i", "<C-k>", vim.lsp.buf.signature_help, opts("Signature help"))

            -- Go to (g prefix)
            map("n", "gd", vim.lsp.buf.definition, opts("Go to definition"))
            map("n", "gD", vim.lsp.buf.declaration, opts("Go to declaration"))
            map("n", "gi", vim.lsp.buf.implementation, opts("Go to implementation"))
            map("n", "gr", "<cmd>Telescope lsp_references<CR>", opts("Go to references"))
            map("n", "gt", vim.lsp.buf.type_definition, opts("Go to type definition"))

            -- Format (F2 = rename, like VS Code)
            map("n", "<F2>", vim.lsp.buf.rename, opts("Rename symbol"))

            -----------------------------------------------------------------
            -- Python Specific Keymaps
            -----------------------------------------------------------------
            map("n", "<leader>pr", "<cmd>w<CR><cmd>!python %<CR>", opts("Run Python file"))
            map("n", "<leader>pi", "<cmd>!python -i %<CR>", opts("Run Python interactive"))
            map("n", "<leader>pt", "<cmd>!pytest<CR>", opts("Run pytest"))
            map("n", "<leader>pT", "<cmd>!pytest -v<CR>", opts("Run pytest verbose"))
            map("n", "<leader>pf", "<cmd>!pytest --tb=short<CR>", opts("Run pytest (short traceback)"))
            map("n", "<leader>pd", "<cmd>lua require('dap-python').test_method()<CR>", opts("Debug test method"))
            map("n", "<leader>pD", "<cmd>lua require('dap-python').debug_selection()<CR>", opts("Debug selection"))

            -----------------------------------------------------------------
            -- File Explorer
            -----------------------------------------------------------------
            map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", opts("Toggle explorer"))
            map("n", "<leader>E", "<cmd>NvimTreeFocus<CR>", opts("Focus explorer"))
            map("n", "<leader>o", "<cmd>NvimTreeFindFile<CR>", opts("Reveal file in explorer"))

            -----------------------------------------------------------------
            -- Find & Search
            -----------------------------------------------------------------
            map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", opts("Find files"))
            map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", opts("Find text"))
            map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", opts("Find buffers"))
            map("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>", opts("Recent files"))
            map("n", "<leader>fc", "<cmd>Telescope grep_string<CR>", opts("Find word under cursor"))
            map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", opts("Help tags"))
            map("n", "<leader>fm", "<cmd>Telescope marks<CR>", opts("Find marks"))
            map("n", "<leader>fk", "<cmd>Telescope keymaps<CR>", opts("Find keymaps"))

            -----------------------------------------------------------------
            -- Buffer Management
            -----------------------------------------------------------------
            map("n", "<leader>bd", "<cmd>bdelete<CR>", opts("Delete buffer"))
            map("n", "<leader>bD", "<cmd>bdelete!<CR>", opts("Force delete buffer"))
            map("n", "<leader>bo", "<cmd>BufferLineCloseOthers<CR>", opts("Close other buffers"))
            map("n", "<leader>bp", "<cmd>BufferLineTogglePin<CR>", opts("Pin buffer"))
            map("n", "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<CR>", opts("Close non-pinned buffers"))

            -----------------------------------------------------------------
            -- Terminal
            -----------------------------------------------------------------
            map("n", "<leader>tt", "<cmd>ToggleTerm direction=float<CR>", opts("Float terminal"))
            map("n", "<leader>th", "<cmd>ToggleTerm direction=horizontal<CR>", opts("Horizontal terminal"))
            map("n", "<leader>tv", "<cmd>ToggleTerm direction=vertical size=80<CR>", opts("Vertical terminal"))
            map("n", "<C-`>", "<cmd>ToggleTerm direction=float<CR>", opts("Toggle terminal"))
            map("t", "<Esc>", "<C-\\><C-n>", opts("Exit terminal mode"))
            map("t", "<C-h>", "<C-\\><C-n><C-w>h", opts("Go to left window"))
            map("t", "<C-j>", "<C-\\><C-n><C-w>j", opts("Go to lower window"))
            map("t", "<C-k>", "<C-\\><C-n><C-w>k", opts("Go to upper window"))
            map("t", "<C-l>", "<C-\\><C-n><C-w>l", opts("Go to right window"))

            -----------------------------------------------------------------
            -- Testing (Neotest)
            -----------------------------------------------------------------
            map("n", "<leader>tn", "<cmd>lua require('neotest').run.run()<CR>", opts("Test nearest"))
            map("n", "<leader>tf", "<cmd>lua require('neotest').run.run(vim.fn.expand('%'))<CR>", opts("Test file"))
            map("n", "<leader>ts", "<cmd>lua require('neotest').summary.toggle()<CR>", opts("Test summary"))
            map("n", "<leader>to", "<cmd>lua require('neotest').output.open()<CR>", opts("Test output"))
            map("n", "<leader>tS", "<cmd>lua require('neotest').run.stop()<CR>", opts("Stop test"))

            -----------------------------------------------------------------
            -- Debugging (DAP)
            -----------------------------------------------------------------
            map("n", "<F5>", "<cmd>lua require('dap').continue()<CR>", opts("Continue"))
            map("n", "<F10>", "<cmd>lua require('dap').step_over()<CR>", opts("Step over"))
            map("n", "<F11>", "<cmd>lua require('dap').step_into()<CR>", opts("Step into"))
            map("n", "<F12>", "<cmd>lua require('dap').step_out()<CR>", opts("Step out"))
            map("n", "<leader>db", "<cmd>lua require('dap').toggle_breakpoint()<CR>", opts("Toggle breakpoint"))
            map("n", "<leader>dB", "<cmd>lua require('dap').set_breakpoint(vim.fn.input('Condition: '))<CR>", opts("Conditional breakpoint"))
            map("n", "<leader>dc", "<cmd>lua require('dap').continue()<CR>", opts("Continue"))
            map("n", "<leader>di", "<cmd>lua require('dap').step_into()<CR>", opts("Step into"))
            map("n", "<leader>do", "<cmd>lua require('dap').step_over()<CR>", opts("Step over"))
            map("n", "<leader>dO", "<cmd>lua require('dap').step_out()<CR>", opts("Step out"))
            map("n", "<leader>dr", "<cmd>lua require('dap').repl.toggle()<CR>", opts("Toggle REPL"))
            map("n", "<leader>du", "<cmd>lua require('dapui').toggle()<CR>", opts("Toggle DAP UI"))

            -----------------------------------------------------------------
            -- Git
            -----------------------------------------------------------------
            map("n", "<leader>gg", "<cmd>LazyGit<CR>", opts("LazyGit"))
            map("n", "<leader>gc", "<cmd>Telescope git_commits<CR>", opts("Git commits"))
            map("n", "<leader>gb", "<cmd>Telescope git_branches<CR>", opts("Git branches"))
            map("n", "<leader>gs", "<cmd>Telescope git_status<CR>", opts("Git status"))
            map("n", "<leader>gd", "<cmd>Gitsigns diffthis<CR>", opts("Git diff"))
            map("n", "<leader>gB", "<cmd>Gitsigns blame_line<CR>", opts("Git blame line"))
            map("n", "<leader>gh", "<cmd>Gitsigns preview_hunk<CR>", opts("Preview hunk"))
            map("n", "<leader>gr", "<cmd>Gitsigns reset_hunk<CR>", opts("Reset hunk"))
            map("n", "<leader>gR", "<cmd>Gitsigns reset_buffer<CR>", opts("Reset buffer"))

            -----------------------------------------------------------------
            -- Diagnostics
            -----------------------------------------------------------------
            map("n", "<leader>xd", vim.diagnostic.open_float, opts("Line diagnostics"))
            map("n", "[d", vim.diagnostic.goto_prev, opts("Previous diagnostic"))
            map("n", "]d", vim.diagnostic.goto_next, opts("Next diagnostic"))
            map("n", "<leader>xl", "<cmd>Trouble diagnostics toggle<CR>", opts("Diagnostics list"))
            map("n", "<leader>xq", "<cmd>Trouble quickfix toggle<CR>", opts("Quickfix list"))

            -----------------------------------------------------------------
            -- AI/LLM Integration (see ai.lua for full keymaps)
            -----------------------------------------------------------------
            -- Quick terminal access to Ollama CLI
            map("n", "<leader>aI", "<cmd>ToggleTerm direction=float<CR>ollama run codellama:7b-code-q4_K_M<CR>", opts("AI Terminal Chat"))
            map("n", "<leader>al", "<cmd>!ollama list<CR>", opts("List Ollama Models"))
            map("n", "<leader>as", function()
                local provider = vim.fn.getenv("LLM_PROVIDER") or "ollama"
                local host = provider == "lmstudio"
                    and (vim.fn.getenv("LMSTUDIO_HOST") or "http://localhost:1234")
                    or (vim.fn.getenv("OLLAMA_HOST") or "http://localhost:11434")
                vim.notify("LLM Provider: " .. provider .. "\nEndpoint: " .. host, vim.log.levels.INFO)
            end, opts("Show LLM Status"))

            -----------------------------------------------------------------
            -- Utility
            -----------------------------------------------------------------
            -- Clear search highlight
            map("n", "<Esc>", "<cmd>nohlsearch<CR>", opts("Clear search highlight"))
            map("n", "<leader>uh", "<cmd>nohlsearch<CR>", opts("Clear search highlight"))

            -- Better indenting
            map("v", "<", "<gv", opts("Indent left"))
            map("v", ">", ">gv", opts("Indent right"))

            -- Move lines
            map("n", "<A-j>", "<cmd>m .+1<CR>==", opts("Move line down"))
            map("n", "<A-k>", "<cmd>m .-2<CR>==", opts("Move line up"))
            map("v", "<A-j>", ":m '>+1<CR>gv=gv", opts("Move selection down"))
            map("v", "<A-k>", ":m '<-2<CR>gv=gv", opts("Move selection up"))
            map("i", "<A-j>", "<Esc><cmd>m .+1<CR>==gi", opts("Move line down"))
            map("i", "<A-k>", "<Esc><cmd>m .-2<CR>==gi", opts("Move line up"))

            -- Duplicate lines
            map("n", "<A-S-j>", "<cmd>t.<CR>", opts("Duplicate line down"))
            map("n", "<A-S-k>", "<cmd>t.-1<CR>", opts("Duplicate line up"))
            map("v", "<A-S-j>", ":t'><CR>gv", opts("Duplicate selection down"))
            map("v", "<A-S-k>", ":t'<-1<CR>gv", opts("Duplicate selection up"))

            -- Select all
            map("n", "<C-a>", "ggVG", opts("Select all"))

            -- Quick escape
            map("i", "jk", "<Esc>", opts("Quick escape"))
            map("i", "jj", "<Esc>", opts("Quick escape"))

            -- Zen mode / Focus
            map("n", "<leader>z", "<cmd>ZenMode<CR>", opts("Zen mode"))

            -----------------------------------------------------------------
            -- Lazy & Mason
            -----------------------------------------------------------------
            map("n", "<leader>ll", "<cmd>Lazy<CR>", opts("Lazy plugin manager"))
            map("n", "<leader>lm", "<cmd>Mason<CR>", opts("Mason package manager"))
            map("n", "<leader>li", "<cmd>LspInfo<CR>", opts("LSP info"))
        end,
    },

    -----------------------------------------------------------------
    -- ToggleTerm for terminal support
    -----------------------------------------------------------------
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        opts = {
            size = function(term)
                if term.direction == "horizontal" then
                    return 15
                elseif term.direction == "vertical" then
                    return vim.o.columns * 0.4
                end
            end,
            open_mapping = [[<C-\>]],
            direction = "float",
            float_opts = {
                border = "curved",
                width = function() return math.floor(vim.o.columns * 0.85) end,
                height = function() return math.floor(vim.o.lines * 0.85) end,
            },
            shell = vim.o.shell,
            close_on_exit = true,
            start_in_insert = true,
        },
    },

    -----------------------------------------------------------------
    -- Zen Mode for distraction-free coding
    -----------------------------------------------------------------
    {
        "folke/zen-mode.nvim",
        cmd = "ZenMode",
        opts = {
            window = {
                width = 120,
                options = {
                    signcolumn = "no",
                    number = false,
                    relativenumber = false,
                },
            },
            plugins = {
                gitsigns = { enabled = false },
                tmux = { enabled = true },
            },
        },
    },
}
