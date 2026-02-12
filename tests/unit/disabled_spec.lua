-- disabled_spec.lua
-- Test coverage for disabled.lua module
-- Ensures all disabled plugins are properly configured

describe("disabled.lua", function()
    local disabled_config

    setup(function()
        -- Load the disabled module
        disabled_config = require("docker.plugins.disabled")
    end)

    describe("Plugin Disable Configuration", function()
        it("should return a table with plugin configurations", function()
            assert.is_table(disabled_config)
            assert.is_true(#disabled_config > 0)
        end)

        it("should disable mason.nvim", function()
            local found_mason = false
            for _, plugin in ipairs(disabled_config) do
                if plugin[1] == "williamboman/mason.nvim" then
                    found_mason = true
                    assert.is_false(plugin.enabled)
                end
            end
            assert.is_true(found_mason, "mason.nvim should be disabled")
        end)

        it("should disable mason-lspconfig.nvim", function()
            local found_mason_lsp = false
            for _, plugin in ipairs(disabled_config) do
                if plugin[1] == "williamboman/mason-lspconfig.nvim" then
                    found_mason_lsp = true
                    assert.is_false(plugin.enabled)
                end
            end
            assert.is_true(found_mason_lsp, "mason-lspconfig.nvim should be disabled")
        end)

        it("should disable mini.pairs", function()
            local found_mini_pairs = false
            for _, plugin in ipairs(disabled_config) do
                if plugin[1] == "echasnovski/mini.pairs" then
                    found_mini_pairs = true
                    assert.is_false(plugin.enabled)
                end
            end
            assert.is_true(found_mini_pairs, "mini.pairs should be disabled")
        end)

        it("should disable mini.surround", function()
            local found_mini_surround = false
            for _, plugin in ipairs(disabled_config) do
                if plugin[1] == "echasnovski/mini.surround" then
                    found_mini_surround = true
                    assert.is_false(plugin.enabled)
                end
            end
            assert.is_true(found_mini_surround, "mini.surround should be disabled")
        end)

        it("should disable neodev.nvim", function()
            local found_neodev = false
            for _, plugin in ipairs(disabled_config) do
                if plugin[1] == "folke/neodev.nvim" then
                    found_neodev = true
                    assert.is_false(plugin.enabled)
                end
            end
            assert.is_true(found_neodev, "neodev.nvim should be disabled")
        end)

        it("should disable toggleterm.nvim", function()
            local found_toggleterm = false
            for _, plugin in ipairs(disabled_config) do
                if plugin[1] == "akinsho/toggleterm.nvim" then
                    found_toggleterm = true
                    assert.is_false(plugin.enabled)
                end
            end
            assert.is_true(found_toggleterm, "toggleterm.nvim should be disabled")
        end)

        it("should disable indent-blankline.nvim", function()
            local found_indent_blankline = false
            for _, plugin in ipairs(disabled_config) do
                if plugin[1] == "lukas-reineke/indent-blankline.nvim" then
                    found_indent_blankline = true
                    assert.is_false(plugin.enabled)
                end
            end
            assert.is_true(found_indent_blankline, "indent-blankline.nvim should be disabled")
        end)

        it("should disable venv-selector.nvim", function()
            local found_venv_selector = false
            for _, plugin in ipairs(disabled_config) do
                if plugin[1] == "linux-cultist/venv-selector.nvim" then
                    found_venv_selector = true
                    assert.is_false(plugin.enabled)
                end
            end
            assert.is_true(found_venv_selector, "venv-selector.nvim should be disabled")
        end)
    end)

    describe("Edge Cases", function()
        it("should handle empty plugin name gracefully", function()
            -- Test that the module doesn't contain empty plugin names
            for _, plugin in ipairs(disabled_config) do
                assert.is_string(plugin[1])
                assert.is_true(string.len(plugin[1]) > 0)
            end
        end)

        it("should have valid plugin configurations", function()
            -- Test that all plugin configurations have required structure
            for _, plugin in ipairs(disabled_config) do
                assert.is_table(plugin)
                assert.is_string(plugin[1])  -- Plugin name
                assert.is_boolean(plugin.enabled)  -- Enabled flag
            end
        end)

        it("should have exactly 8 disabled plugins", function()
            -- Verify the expected number of disabled plugins
            assert.equals(8, #disabled_config)
        end)
    end)

    describe("Property-Based Tests", function()
        it("should maintain plugin disable consistency", function()
            -- Property: All disabled plugins should have enabled = false
            for _, plugin in ipairs(disabled_config) do
                assert.is_false(plugin.enabled,
                    "Plugin " .. plugin[1] .. " should be disabled")
            end
        end)

        it("should have unique plugin names", function()
            -- Property: No duplicate plugin names
            local seen_plugins = {}
            for _, plugin in ipairs(disabled_config) do
                local plugin_name = plugin[1]
                assert.is_nil(seen_plugins[plugin_name],
                    "Duplicate plugin found: " .. plugin_name)
                seen_plugins[plugin_name] = true
            end
        end)
    end)
end)