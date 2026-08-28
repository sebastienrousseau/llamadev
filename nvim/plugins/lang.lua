-- llamadev — Python language wiring (LSP + Treesitter).
-- SPDX-License-Identifier: MIT
--
-- Language servers are installed at BUILD time by the Containerfile's
-- toolchain stage (into /opt/venv) and configured directly here via
-- nvim-lspconfig. Mason is disabled (see common/nvim/plugins/disabled.lua),
-- so no network is needed on first launch and the set is reproducible.
--
--   * basedpyright  -> type checking + completion/hover/go-to (Pyright fork)
--   * ruff (server) -> linting + formatting via `ruff server` (NOT ruff-lsp)
return {
  -- Ensure the Python grammar is compiled into the image at build time.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "python" })
    end,
  },

  -- LSP servers. Binaries live in /opt/venv/bin (on PATH in the image).
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Type checker + IntelliSense.
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                typeCheckingMode = "standard",
                diagnosticMode = "openFilesOnly",
                useLibraryCodeForTypes = true,
              },
            },
          },
        },
        -- Linter/formatter LSP shipped inside the `ruff` binary.
        ruff = {
          cmd = { "ruff", "server" },
          -- Let basedpyright own hover so the two don't collide.
          on_attach = function(client, _)
            client.server_capabilities.hoverProvider = false
          end,
        },
      },
    },
  },
}
