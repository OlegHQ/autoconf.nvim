local M = {}

-- Registry to store resolvers
M.resolvers = {}

-- Registry to store command resolvers (separate from config resolvers)
M.command_resolvers = {}

-- Registry to track keymap resolution status
M.keymap_status = {}

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

-- Sample resolver implementations
M.define_resolver("editor.line-number", function(value)
    if value == "relative" then
        vim.opt.number = true
        vim.opt.relativenumber = true
    elseif value == "absolute" then
        vim.opt.number = true
        vim.opt.relativenumber = false
    else
        vim.opt.number = false
        vim.opt.relativenumber = false
    end
end)

M.define_resolver("editor.cursorline", function(value)
    vim.opt.cursorline = value
end)

M.define_resolver("editor.mouse", function(value)
    if value then
        vim.opt.mouse = "a"
    else
        vim.opt.mouse = ""
    end
end)

M.define_resolver("editor.auto-completion", function(value)
    -- This would typically configure completion plugins
end)

M.define_resolver("theme", function(value)
    -- This would typically set the colorscheme
    -- Example: vim.cmd("colorscheme " .. value)
end)

-- Command resolvers for Helix commands (using separate command resolver registry)
M.define_command_resolver("goto_definition", function()
    return function()
        vim.lsp.buf.definition()
    end
end)

M.define_command_resolver("goto_reference", function()
    return function()
        vim.lsp.buf.references()
    end
end)

M.define_command_resolver("write", function()
    return function()
        vim.cmd("write")
    end
end)

M.define_command_resolver("quit", function()
    return function()
        vim.cmd("quit")
    end
end)

M.define_command_resolver("normal_mode", function()
    return function()
        vim.cmd("stopinsert")
    end
end)

-- Note: delete_selection and yank would need more complex implementations
-- These are placeholders for now
M.define_command_resolver("delete_selection", function()
    return function()
        vim.cmd("normal! d")
    end
end)

M.define_command_resolver("yank", function()
    return function()
        vim.cmd("normal! y")
    end
end)

return M