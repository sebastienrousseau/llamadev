-- LuaCheck configuration for llamadev project
-- This configuration enforces zero-warning policy

stds.nvim = {
  globals = {
    vim = {
      fields = {
        "g", "b", "w", "o", "bo", "wo", "go", "env",
        "api", "fn", "cmd", "opt", "loop", "defer_fn",
        "schedule", "wait", "tbl_extend", "tbl_deep_extend",
        "list_extend", "validate", "F", "ui", "lsp"
      }
    },
    -- Busted testing framework globals
    "describe", "it", "before_each", "after_each",
    "setup", "teardown", "pending", "clear",
    "assert", "spy", "stub", "mock",
    -- Additional test utilities
    "finally", "lazy_setup", "lazy_teardown"
  }
}

-- Use Lua 5.1 + Neovim standard
std = "lua51+nvim"

-- Enable caching for faster subsequent runs
cache = true

-- Show error codes in output
codes = true

-- Treat warnings as errors (zero-warning policy)
fatal = true

-- Files and directories to exclude
exclude_files = {
  ".luarocks/**",
  "lua_modules/**",
  "**/node_modules/**",
  ".git/**"
}

-- Ignore specific warnings (empty by default for zero-warning policy)
ignore = {
  -- Uncomment and add specific codes only if absolutely necessary
  -- "113", -- Accessing undefined variable (only if you need to ignore specific cases)
}

-- Configuration for specific file patterns
files["tests/**/*_spec.lua"] = {
  std = "lua51+nvim+busted"
}

files["tests/**/*.lua"] = {
  std = "lua51+nvim+busted"
}

-- Plugin configuration files
files["**/plugins/*.lua"] = {
  std = "lua51+nvim",
  globals = {"require"}
}

-- Maximum line length (aligned with stylua configuration)
max_line_length = 120

-- Enable additional checks
unused_args = true
unused = true
global = true
redefined = true
unused_secondaries = true

-- Security-focused rules (treat as errors)
-- Check for potentially dangerous patterns
max_complexity = 10