-- Integration tests for container environment configuration
-- Tests verify that all required files exist and configurations are consistent

local function file_exists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

local function read_file(path)
    local f = io.open(path, "r")
    if not f then
        return nil
    end
    local content = f:read("*all")
    f:close()
    return content
end

local function get_project_root()
    -- Determine project root by looking for Makefile
    local paths = { ".", "..", "../.." }
    for _, base in ipairs(paths) do
        if file_exists(base .. "/Makefile") then
            return base
        end
    end
    return "."
end

describe("Container Configuration Integration", function()
    local root

    setup(function()
        root = get_project_root()
    end)

    describe("Docker configuration", function()
        it("should have all required files", function()
            local required_files = {
                "/docker/Dockerfile",
                "/docker/docker-compose.yml",
                "/docker/requirements.txt",
                "/docker/start.sh",
                "/docker/.env",
                "/docker/.bash_aliases",
                "/docker/.bash_profile",
                "/docker/.bashrc",
            }
            for _, file in ipairs(required_files) do
                local path = root .. file
                assert.is_true(
                    file_exists(path),
                    "Missing required file: " .. file
                )
            end
        end)

        it("should have all plugin configuration files", function()
            local plugins = {
                "coding.lua",
                "disabled.lua",
                "keymaps.lua",
                "toggleterm.lua",
                "ui.lua",
            }
            for _, plugin in ipairs(plugins) do
                local path = root .. "/docker/plugins/" .. plugin
                assert.is_true(
                    file_exists(path),
                    "Missing plugin: " .. plugin
                )
            end
        end)

        it("should have non-root USER directive in Dockerfile", function()
            local dockerfile = read_file(root .. "/docker/Dockerfile")
            assert.is_not_nil(dockerfile, "Could not read Dockerfile")
            assert.is_truthy(
                dockerfile:match("USER%s+%${?USERNAME}?"),
                "Dockerfile should use non-root USER"
            )
        end)

        it("should have multi-stage build", function()
            local dockerfile = read_file(root .. "/docker/Dockerfile")
            assert.is_not_nil(dockerfile)
            local from_count = 0
            for _ in dockerfile:gmatch("FROM%s+") do
                from_count = from_count + 1
            end
            assert.is_true(
                from_count >= 3,
                "Dockerfile should have at least 3 build stages"
            )
        end)

        it("should expose correct ports", function()
            local dockerfile = read_file(root .. "/docker/Dockerfile")
            assert.is_not_nil(dockerfile)
            assert.is_truthy(
                dockerfile:match("EXPOSE%s+11434"),
                "Dockerfile should expose Ollama port 11434"
            )
        end)
    end)

    describe("Podman configuration", function()
        it("should have all required files", function()
            local required_files = {
                "/podman/Containerfile",
                "/podman/podman-compose.yml",
                "/podman/requirements.txt",
                "/podman/start.sh",
                "/podman/.env",
                "/podman/.bash_aliases",
                "/podman/.bash_profile",
                "/podman/.bashrc",
            }
            for _, file in ipairs(required_files) do
                local path = root .. file
                assert.is_true(
                    file_exists(path),
                    "Missing required file: " .. file
                )
            end
        end)

        it("should have all plugin configuration files", function()
            local plugins = {
                "coding.lua",
                "disabled.lua",
                "keymaps.lua",
                "toggleterm.lua",
                "ui.lua",
            }
            for _, plugin in ipairs(plugins) do
                local path = root .. "/podman/plugins/" .. plugin
                assert.is_true(
                    file_exists(path),
                    "Missing plugin: " .. plugin
                )
            end
        end)

        it("should have non-root USER directive in Containerfile", function()
            local containerfile = read_file(root .. "/podman/Containerfile")
            assert.is_not_nil(containerfile, "Could not read Containerfile")
            assert.is_truthy(
                containerfile:match("USER%s+%${?USERNAME}?"),
                "Containerfile should use non-root USER"
            )
        end)

        it("should use tini as entrypoint for proper signal handling", function()
            local containerfile = read_file(root .. "/podman/Containerfile")
            assert.is_not_nil(containerfile)
            assert.is_truthy(
                containerfile:match("tini"),
                "Containerfile should use tini for signal handling"
            )
        end)
    end)

    describe("Configuration consistency", function()
        it("should have matching Python versions in both .env files", function()
            local docker_env = read_file(root .. "/docker/.env")
            local podman_env = read_file(root .. "/podman/.env")
            assert.is_not_nil(docker_env)
            assert.is_not_nil(podman_env)

            local docker_py = docker_env:match('PYTHON_VERSION="([^"]+)"')
            local podman_py = podman_env:match('PYTHON_VERSION="([^"]+)"')

            assert.are.equal(
                docker_py,
                podman_py,
                "Python versions should match between Docker and Podman"
            )
        end)

        it("should have matching VERSION in both .env files", function()
            local docker_env = read_file(root .. "/docker/.env")
            local podman_env = read_file(root .. "/podman/.env")
            assert.is_not_nil(docker_env)
            assert.is_not_nil(podman_env)

            local docker_ver = docker_env:match('VERSION="([^"]+)"')
            local podman_ver = podman_env:match('VERSION="([^"]+)"')

            assert.are.equal(
                docker_ver,
                podman_ver,
                "Versions should match between Docker and Podman"
            )
        end)

        it("should have matching requirements.txt files", function()
            local docker_req = read_file(root .. "/docker/requirements.txt")
            local podman_req = read_file(root .. "/podman/requirements.txt")
            assert.is_not_nil(docker_req)
            assert.is_not_nil(podman_req)
            assert.are.equal(
                docker_req,
                podman_req,
                "requirements.txt should be identical"
            )
        end)

        it("should have matching plugin configurations", function()
            local plugins = {
                "coding.lua",
                "disabled.lua",
                "keymaps.lua",
                "toggleterm.lua",
                "ui.lua",
            }
            for _, plugin in ipairs(plugins) do
                local docker_plugin = read_file(
                    root .. "/docker/plugins/" .. plugin
                )
                local podman_plugin = read_file(
                    root .. "/podman/plugins/" .. plugin
                )
                assert.is_not_nil(docker_plugin, "Missing docker plugin: " .. plugin)
                assert.is_not_nil(podman_plugin, "Missing podman plugin: " .. plugin)
                assert.are.equal(
                    docker_plugin,
                    podman_plugin,
                    "Plugin " .. plugin .. " should be identical in both directories"
                )
            end
        end)
    end)

    describe("Security configuration", function()
        it("should have HEALTHCHECK in Dockerfile", function()
            local dockerfile = read_file(root .. "/docker/Dockerfile")
            assert.is_not_nil(dockerfile)
            assert.is_truthy(
                dockerfile:match("HEALTHCHECK"),
                "Dockerfile should have HEALTHCHECK directive"
            )
        end)

        it("should have HEALTHCHECK in Containerfile", function()
            local containerfile = read_file(root .. "/podman/Containerfile")
            assert.is_not_nil(containerfile)
            assert.is_truthy(
                containerfile:match("HEALTHCHECK"),
                "Containerfile should have HEALTHCHECK directive"
            )
        end)

        it("should disable core dumps", function()
            local dockerfile = read_file(root .. "/docker/Dockerfile")
            assert.is_not_nil(dockerfile)
            assert.is_truthy(
                dockerfile:match("core%s+0"),
                "Dockerfile should disable core dumps"
            )
        end)

        it("should remove SUID/SGID binaries", function()
            local dockerfile = read_file(root .. "/docker/Dockerfile")
            assert.is_not_nil(dockerfile)
            assert.is_truthy(
                dockerfile:match("chmod%s+a%-s"),
                "Dockerfile should remove SUID/SGID bits"
            )
        end)

        it("should have secret scanning stage", function()
            local dockerfile = read_file(root .. "/docker/Dockerfile")
            assert.is_not_nil(dockerfile)
            assert.is_truthy(
                dockerfile:match("gitleaks"),
                "Dockerfile should include gitleaks for secret scanning"
            )
        end)
    end)
end)

describe("Plugin Configuration Integration", function()
    local root

    setup(function()
        root = get_project_root()
    end)

    describe("All plugins", function()
        it("should return valid Lua tables", function()
            local plugins = {
                "coding.lua",
                "disabled.lua",
                "keymaps.lua",
                "toggleterm.lua",
                "ui.lua",
            }

            -- Mock vim global
            _G.vim = {
                api = { nvim_set_keymap = function() end },
                keymap = { set = function() end },
                fn = { exists = function() return 0 end },
                o = { lines = 50, columns = 200 },
                lsp = {
                    buf = {
                        format = function() end,
                        code_action = function() end,
                        rename = function() end,
                    },
                },
                cmd = function() end,
            }

            for _, plugin in ipairs(plugins) do
                local path = root .. "/docker/plugins/" .. plugin
                local content = read_file(path)
                assert.is_not_nil(content, "Could not read " .. plugin)

                -- Try to load the plugin (use loadstring for Lua 5.1 compatibility)
                local load_func = loadstring or load
                local chunk, err = load_func(content, plugin)
                assert.is_not_nil(chunk, "Failed to parse " .. plugin .. ": " .. (err or ""))

                -- Execute and check return value
                local ok, result = pcall(chunk)
                assert.is_true(ok, "Failed to execute " .. plugin)
                assert.is_table(result, plugin .. " should return a table")
            end
        end)
    end)
end)
