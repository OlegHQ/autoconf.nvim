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

-- Helper function to build nested table from path parts and value
local function build_nested_table(path_parts, value, start_index)
    start_index = start_index or 1
    
    if start_index > #path_parts then
        return value
    end
    
    local result = {}
    local current_key = path_parts[start_index]
    result[current_key] = build_nested_table(path_parts, value, start_index + 1)
    
    return result
end

-- Helper function to split a path into parts
local function split_path(path)
    local parts = {}
    for part in path:gmatch("[^%.]+") do
        table.insert(parts, part)
    end
    return parts
end

-- Smart resolver function with hierarchical fallback
local function try_resolve_with_fallback(full_path, value, debug)
    -- Special handling for keymap paths (keys.mode.combo)
    if resolvers.is_keymap_path(full_path) then
        local mode = full_path:match("^keys%.(%w+)%.")
        local keys = full_path:match("^keys%.%w+%.(.+)$")
        
        if mode and keys then
            resolvers.attempt_to_keymap(keys, mode, value)
        end
        return true
    end
    
    -- Split the path into parts
    local path_parts = split_path(full_path)
    
    if debug then
        print("=== Debug: Resolving path: " .. full_path .. " ===")
        print("Trying paths in order:")
    end
    
    -- Try resolvers from most specific to least specific
    for i = #path_parts, 1, -1 do
        -- Build the current path to try
        local current_path = table.concat(path_parts, ".", 1, i)
        
        if debug then
            local has_resolver = resolvers.has_resolver(current_path)
            print("  " .. current_path .. " -> " .. (has_resolver and "FOUND" or "not found"))
        end
        
        -- Check if there's a resolver for this path
        if resolvers.has_resolver(current_path) then
            local resolver = resolvers.get_resolver(current_path)
            
            -- If this is the exact path, use the original value
            if i == #path_parts then
                if debug then
                    print("    Calling resolver with original value: " .. tostring(value))
                end
                resolver(value)
            else
                -- Build nested structure for remaining path parts
                local nested_value = build_nested_table(path_parts, value, i + 1)
                if debug then
                    print("    Calling resolver with nested structure for remaining parts")
                end
                resolver(nested_value)
            end
            
            if debug then
                print("=== Resolved successfully ===")
            end
            return true
        end
    end
    
    if debug then
        print("=== No resolver found ===")
    end
    return false
end

function resolve_configs(config, prefix, debug)
    prefix = prefix or ""
    
    for key, value in pairs(config) do
        local full_key = prefix == "" and key or (prefix .. "." .. key)
        
        if type(value) == "table" then
            -- First try to resolve this path as a whole (in case there's a resolver that handles nested configs)
            if not try_resolve_with_fallback(full_key, value, debug) then
                -- If no resolver found, recursively process nested tables
                resolve_configs(value, full_key, debug)
            end
        else
            -- Try to resolve with hierarchical fallback
            try_resolve_with_fallback(full_key, value, debug)
        end
    end
end

-- Load the TOML config
local user_config, err = loader.load_config(config_path)
if not user_config then
    vim.notify("Failed to load config: " .. err, vim.log.levels.ERROR)
    return
end

-- Merge default config with user config (user config overrides defaults)
local config = deep_merge(default_config.default_config, user_config)

-- Pretty print the parsed config
resolve_configs(config, nil, false)

-- Setup commands
commands.setup_helix_health_command()

-- Plugin dependencies
resolvers.register_plugin_dependency("lualine.nvim", "Statusline plugin for statusline configuration")
resolvers.register_plugin_dependency("nvim-lspconfig", "LSP configuration for Neovim")
resolvers.register_plugin_dependency("nvim-cmp", "Completion plugin for auto-completion features")
resolvers.register_plugin_dependency("telescope.nvim", "Fuzzy finder for file picker functionality")
resolvers.register_plugin_dependency("nvim-treesitter", "Syntax highlighting and parsing")
