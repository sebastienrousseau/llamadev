-- keymaps.lua
-- Centralized keymapping configuration
local opts = { noremap = true, silent = true }
local keymap = vim.keymap.set

return {
    {
        "LazyVim/LazyVim",
        opts = function(_, opts)
            -- General
            keymap("n", "<leader>w", ":w<CR>", { desc = "Save file" })
            keymap("n", "<leader>q", ":q<CR>", { desc = "Quit" })
            
            -- Python specific
            keymap("n", "<leader>pr", ":w<CR>:!python %<CR>", { desc = "Run Python file" })
            keymap("n", "<leader>pi", ":VenvSelect<CR>", { desc = "Select Python Env" })
            keymap("n", "<leader>pt", ":!pytest<CR>", { desc = "Run Pytest" })
            
            -- LSP
            keymap("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code actions" })
            keymap("n", "<leader>cf", vim.lsp.buf.format, { desc = "Format code" })
            keymap("n", "<leader>cr", vim.lsp.buf.rename, { desc = "Rename symbol" })
            
            -- Telescope
            keymap("n", "<leader>ff", ":Telescope find_files<CR>", { desc = "Find files" })
            keymap("n", "<leader>fg", ":Telescope live_grep<CR>", { desc = "Find text" })
            keymap("n", "<leader>fb", ":Telescope file_browser<CR>", { desc = "File browser" })
            keymap("n", "<leader>fp", ":Telescope project<CR>", { desc = "Projects" })
            
            -- Terminal
            keymap("n", "<leader>tt", ":ToggleTerm direction=float<CR>", { desc = "Toggle terminal" })
            keymap("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
            
            -- Testing
            keymap("n", "<leader>tn", ":TestNearest<CR>", { desc = "Test nearest" })
            keymap("n", "<leader>tf", ":TestFile<CR>", { desc = "Test file" })
            keymap("n", "<leader>ts", ":TestSuite<CR>", { desc = "Test suite" })
            
            -- Debugging
            keymap("n", "<F5>", ":lua require'dap'.continue()<CR>", { desc = "Continue" })
            keymap("n", "<F10>", ":lua require'dap'.step_over()<CR>", { desc = "Step over" })
            keymap("n", "<F11>", ":lua require'dap'.step_into()<CR>", { desc = "Step into" })
            keymap("n", "<F12>", ":lua require'dap'.step_out()<CR>", { desc = "Step out" })
        end
    }
}