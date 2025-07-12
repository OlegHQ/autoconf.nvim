-- Add the config directory to the Lua path
local config_path = vim.fn.stdpath("config")
package.path = package.path .. ";" .. config_path .. "/?.lua;" .. config_path .. "/?/init.lua"

local loader = require("sys.loader")
local resolvers = require("sys.resolvers")
local commands = require("sys.commands")
local default_config = require("sys.default_config")

-- Path to the TOML config file (update this to your actual config path)
local config_path = "config.toml"

-- Deep merge function to merge user config with defaults
local function deep_merge(default, override)
    local result = {}
    
    -- Copy all values from default
    for key, value in pairs(default) do
        if type(value) == "table" then
            result[key] = deep_merge(value, {})
        else
            result[key] = value
        end
    end
    
    -- Override with values from override table
    for key, value in pairs(override) do
        if type(value) == "table" and type(result[key]) == "table" then
            result[key] = deep_merge(result[key], value)
        else
            result[key] = value
        end
    end
    
    return result
end

-- Load the TOML config
local user_config, err = loader.load_config(config_path)
if not user_config then
    vim.notify("Failed to load config: " .. err, vim.log.levels.ERROR)
    return
end

-- Merge default config with user config (user config overrides defaults)
local config = deep_merge(default_config.default_config, user_config)

function resolve_configs(config, prefix)
    prefix = prefix or ""
    
    for key, value in pairs(config) do
        local full_key = prefix == "" and key or (prefix .. "." .. key)
        
        if type(value) == "table" then
            -- Recursively process nested tables
            resolve_configs(value, full_key)
        else
            -- Special handling for keymap paths (keys.mode.combo)
            if resolvers.is_keymap_path(full_key) then
                -- Extract mode and keys from the path
                local mode = full_key:match("^keys%.(%w+)%.")
                local keys = full_key:match("^keys%.%w+%.(.+)$")
                
                if mode and keys then
                    resolvers.attempt_to_keymap(keys, mode, value)
                end
            else
                -- Check if there's a resolver for this config path
                if resolvers.has_resolver(full_key) then
                    local resolver = resolvers.get_resolver(full_key)
                    resolver(value)
                end
            end
        end
    end
end

-- Pretty print the parsed config
resolve_configs(config)

-- Setup commands
commands.setup_helix_health_command()

-- Plugin dependencies
resolvers.register_plugin_dependency("lualine.nvim", "Statusline plugin for statusline configuration")
resolvers.register_plugin_dependency("nvim-lspconfig", "LSP configuration for Neovim")
resolvers.register_plugin_dependency("nvim-cmp", "Completion plugin for auto-completion features")
resolvers.register_plugin_dependency("telescope.nvim", "Fuzzy finder for file picker functionality")
resolvers.register_plugin_dependency("nvim-treesitter", "Syntax highlighting and parsing")
