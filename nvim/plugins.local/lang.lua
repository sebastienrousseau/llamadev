-- llamadev — Python language wiring (LSP + Treesitter).
-- SPDX-License-Identifier: Apache-2.0 OR MIT
--
-- This is the ONE language drop-in langdev adds to the user's own
-- chezmoi-managed Neovim config. It is copied to
-- ~/.config/nvim/lua/plugins.local/lang.lua and auto-imported via the
-- dotfiles' `plugins.local` convention.
--
-- Language servers are installed at BUILD time by the Containerfile's
-- toolchain stage (into /opt/venv) and configured directly here via
-- nvim-lspconfig, so no network is needed on first launch and the set is
-- reproducible. (Mason, if present in the dotfiles' config, is not relied
-- upon: the binaries below already live on PATH inside the image.)
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
