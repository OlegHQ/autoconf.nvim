local M = {}

-- Registry to store resolvers
M.resolvers = {}

-- Registry to store command resolvers (separate from config resolvers)
M.command_resolvers = {}

-- Registry to track keymap resolution status
M.keymap_status = {}

-- Registry to store plugin dependencies
M.plugin_dependencies = {}

-- Function to define a resolver for a specific config path
function M.define_resolver(config_item_path, resolver_function)
    -- Check if the resolver function is valid
    if type(resolver_function) ~= "function" then
        error("Resolver function must be a valid function")
    end

    -- Register the resolver for the given config item path
    M.resolvers[config_item_path] = resolver_function
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
    if type(resolver_function) ~= "function" then
        error("Command resolver function must be a valid function")
    end

    -- Register the command resolver
    M.command_resolvers[command_name] = resolver_function
end

-- Function to get a command resolver
function M.get_command_resolver(command_name)
    return M.command_resolvers[command_name]
end

-- Function to check if a command resolver exists
function M.has_command_resolver(command_name)
    return M.command_resolvers[command_name] ~= nil
end

-- Function to attempt keymap binding
function M.attempt_to_keymap(keys, mode, command)
    local key_path = "keys." .. mode .. "." .. keys
    
    -- First check if the command has a command resolver
    if not M.has_command_resolver(command) then
        M.keymap_status[key_path] = {
            resolved = false,
            error = "Command '" .. command .. "' has no command resolver",
            keys = keys,
            mode = mode,
            command = command
        }
        print("Keymap unresolved: " .. key_path .. " -> Command '" .. command .. "' has no command resolver")
        return false
    end
    
    -- Map Helix mode names to Neovim mode names
    local mode_map = {
        normal = "n",
        insert = "i",
        visual = "v",
        select = "s",
        command = "c",
        terminal = "t"
    }
    
    local nvim_mode = mode_map[mode] or mode
    
    -- Get the command function from the command resolver
    local command_resolver = M.get_command_resolver(command)
    local command_function = command_resolver()
    
    -- Try to set the keymap
    local success, err = pcall(function()
        vim.keymap.set(nvim_mode, keys, command_function, { desc = "Helix keymap: " .. command })
    end)
    
    -- Store the result
    M.keymap_status[key_path] = {
        resolved = success,
        error = err,
        keys = keys,
        mode = mode,
        nvim_mode = nvim_mode,
        command = command
    }
    
    if success then
        print("Keymap resolved: " .. key_path .. " -> " .. tostring(command))
    else
        print("Keymap failed: " .. key_path .. " -> " .. tostring(err))
    end
    
    return success
end

-- Function to check if a keymap was resolved
function M.is_keymap_resolved(key_path)
    local status = M.keymap_status[key_path]
    return status and status.resolved or false
end

-- Function to get keymap status
function M.get_keymap_status(key_path)
    return M.keymap_status[key_path]
end

-- Function to check if a path is a keymap path
function M.is_keymap_path(path)
    return path:match("^keys%.%w+%.") ~= nil
end

-- Function to register a plugin dependency
function M.register_plugin_dependency(plugin_name, description)
    M.plugin_dependencies[plugin_name] = {
        name = plugin_name,
        description = description or plugin_name,
        required = true
    }
end

-- Function to check if a plugin is installed
function M.is_plugin_installed(plugin_name)
    -- Check if plugin is available via pcall require
    local ok, _ = pcall(require, plugin_name)
    if ok then
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

-- Load resolver implementations from separate file
local resolvers_impl = require("sys.resolvers_impl")

-- Initialize all resolver implementations
resolvers_impl.init_resolvers(M)


-- Debug function to show resolver lookup process
function M.debug_resolver_lookup(path, value)
    print("=== Debug: Resolver lookup for path: " .. path .. " ===")
    
    -- Split the path into parts
    local parts = {}
    for part in path:gmatch("[^%.]+") do
        table.insert(parts, part)
    end
    
    -- Show what paths will be tried
    print("Trying paths in order:")
    for i = #parts, 1, -1 do
        local current_path = table.concat(parts, ".", 1, i)
        local has_resolver = M.has_resolver(current_path)
        print("  " .. current_path .. " -> " .. (has_resolver and "FOUND" or "not found"))
        
        if has_resolver then
            if i == #parts then
                print("    Will call with original value: " .. tostring(value))
            else
                print("    Will call with nested structure for remaining parts")
            end
            break
        end
    end
    print("=== End Debug ===")
end

-- Helper function to check if a path would be resolved using hierarchical fallback
-- This mimics the try_resolve_with_fallback logic but without calling the resolver
function M.would_be_resolved(full_path)
    -- Special handling for keymap paths
    if M.is_keymap_path(full_path) then
        local mode = full_path:match("^keys%.(%w+)%.")
        local keys = full_path:match("^keys%.%w+%.(.+)$")
        
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