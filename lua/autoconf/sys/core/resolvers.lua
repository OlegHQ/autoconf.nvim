local M = {}

-- Import logger
local logger = require("autoconf.sys.core.logger")

-- Import keymaps module for delegation
local keymaps = require("autoconf.sys.core.keymaps")

-- Registry to store resolvers
M.resolvers = {}

-- Registry to store command resolvers (separate from config resolvers)
M.command_resolvers = {}

-- Registry to store plugin dependencies
M.plugin_dependencies = {}

-- Delegate keymap registries to keymaps module (for backward compatibility)
M.keymap_status = keymaps.keymap_status
M.on_lsp_attach_keymaps = keymaps.on_lsp_attach_keymaps

-- Function to define a resolver for a specific config path
function M.define_resolver(config_item_path, resolver_function)
    -- Check if the resolver function is valid
    if type(resolver_function) == "function" or type(resolver_function) == "table" then
        -- Register the resolver for the given config item path
        M.resolvers[config_item_path] = resolver_function
        return
    end
    error("Resolver function must be a valid function or table")
end

-- Function to get a resolver for a specific config path
function M.get_resolver(config_item_path)
    return M.resolvers[config_item_path]
end

-- Function to check if a resolver exists for a config path
function M.has_resolver(config_item_path)
    return M.resolvers[config_item_path] ~= nil
end

-- Function to define a command resolver for Helix commands
function M.define_command_resolver(command_name, resolver_function)
    -- Check if the resolver function is valid
    local is_function = type(resolver_function) == "function"
    local is_string = type(resolver_function) == "string"
    local is_table = type(resolver_function) == "table"
    if is_function or is_table or is_string then
        -- Register the command resolver
        M.command_resolvers[command_name] = resolver_function
        -- Update keymaps module reference (needed for keymap resolution)
        keymaps.set_command_resolvers(M.command_resolvers)
        return
    end

    error("Command resolver function must be a valid function")
end

-- Function to get a command resolver
function M.get_command_resolver(command_name)
    return M.command_resolvers[command_name]
end

-- Function to check if a command resolver exists
function M.has_command_resolver(command_name)
    return M.command_resolvers[command_name] ~= nil
end

-- Delegate keymap functions to keymaps module
M.attempt_to_keymap = keymaps.attempt_to_keymap
M.is_keymap_resolved = keymaps.is_keymap_resolved
M.get_keymap_status = keymaps.get_keymap_status
M.is_keymap_path = keymaps.is_keymap_path
M.match_keymap_mode_keys = keymaps.match_keymap_mode_keys

-- Function to register a plugin dependency
function M.register_plugin_dependency(plugin_name, description, lua_module_name)
    M.plugin_dependencies[plugin_name] = {
        name = plugin_name,
        description = description or plugin_name,
        required = true,
        lua_module_name = lua_module_name
    }
end

-- Function to check if a plugin is installed
function M.is_plugin_installed(plugin_name)
    -- Get dependency info to check for a specific lua module
    local dependency = M.plugin_dependencies[plugin_name]
    local lua_module_name = dependency and dependency.lua_module_name

    -- If a specific lua module is defined, try to require it first
    if lua_module_name then
        local ok, _ = pcall(require, lua_module_name)
        if ok then
            return true
        end
    end

    -- Check if plugin is available via pcall require using its name
    local ok_by_name, _ = pcall(require, plugin_name)
    if ok_by_name then
        return true
    end

    -- Check if plugin is in vim.g.loaded_plugins (for some plugin managers)
    if vim.g.loaded_plugins and vim.g.loaded_plugins[plugin_name] then
        return true
    end

    -- Check &runtimepath for plugin directories
    local runtimepath = vim.o.runtimepath
    for path in string.gmatch(runtimepath, "[^,]+") do
        -- Check for plugin in pack/*/start/ directories
        local pack_start_pattern = path .. "/pack/*/start/" .. plugin_name
        if vim.fn.isdirectory(vim.fn.expand(pack_start_pattern)) == 1 then
            return true
        end

        -- Check for plugin in pack/*/opt/ directories
        local pack_opt_pattern = path .. "/pack/*/opt/" .. plugin_name
        if vim.fn.isdirectory(vim.fn.expand(pack_opt_pattern)) == 1 then
            return true
        end

        -- Check for plugin directly in the runtime path (for lazy.nvim style)
        local direct_plugin_path = path .. "/" .. plugin_name
        if vim.fn.isdirectory(direct_plugin_path) == 1 then
            return true
        end

        -- Check for plugin in common subdirectories
        local common_subdirs = { "lazy", "plugged", "bundle" }
        for _, subdir in ipairs(common_subdirs) do
            local subdir_plugin_path = path .. "/" .. subdir .. "/" .. plugin_name
            if vim.fn.isdirectory(subdir_plugin_path) == 1 then
                return true
            end
        end
    end

    return false
end

-- Function to get all plugin dependencies
function M.get_plugin_dependencies()
    return M.plugin_dependencies
end

-- Function to check plugin dependency status
function M.check_plugin_status(plugin_name)
    local dependency = M.plugin_dependencies[plugin_name]
    if not dependency then
        return nil
    end

    return {
        name = dependency.name,
        description = dependency.description,
        required = dependency.required,
        installed = M.is_plugin_installed(plugin_name)
    }
end

-- Debug function to show resolver lookup process
function M.debug_resolver_lookup(path, value)
    if not logger.is_debug_enabled() then return end

    -- Split the path into parts
    local parts = {}
    for part in path:gmatch("[^%.]+") do
        table.insert(parts, part)
    end

    -- Create paths_tried table for the logger
    local paths_tried = {}
    for i = #parts, 1, -1 do
        local current_path = table.concat(parts, ".", 1, i)
        local has_resolver = M.has_resolver(current_path)

        table.insert(paths_tried, {
            path = current_path,
            found = has_resolver,
            direct = i == #parts
        })

        if has_resolver then
            break
        end
    end

    logger.debug_resolver_lookup(path, paths_tried)
end

-- Helper function to check if a path would be resolved using hierarchical fallback
-- This mimics the try_resolve_with_fallback logic but without calling the resolver
function M.would_be_resolved(full_path)
    -- Special handling for keymap paths
    if M.is_keymap_path(full_path) then
        local mode, keys, _ = M.match_keymap_mode_keys(full_path)
        if mode and keys then
            -- For keymaps, check if the command has a resolver
            -- We can't easily check this without the actual command value
            -- So we'll just return true for keymap paths and let the actual keymap status handle it
            return true
        end
        return false
    end

    -- Split the path into parts
    local parts = {}
    for part in full_path:gmatch("[^%.]+") do
        table.insert(parts, part)
    end

    -- Try resolvers from most specific to least specific
    for i = #parts, 1, -1 do
        local current_path = table.concat(parts, ".", 1, i)
        if M.has_resolver(current_path) then
            return true, current_path
        end
    end

    return false, nil
end

return M
