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

-- Helper function to map Helix statusline elements to lualine components
local function map_helix_to_lualine_component(element)
    local component_map = {
        ["mode"] = "mode",
        ["file-name"] = "filename",
        ["position"] = "location",
        ["diagnostics"] = "diagnostics",
        ["spinner"] = function()
            -- Return a custom function for LSP spinner
            return function()
                local clients = vim.lsp.get_active_clients()
                if #clients > 0 then
                    return "⠋" -- Simple spinner character
                end
                return ""
            end
        end,
        ["selections"] = function()
            -- Return a custom function for selection count
            return function()
                local mode = vim.fn.mode()
                if mode == "v" or mode == "V" or mode == "\22" then
                    return "SEL"
                end
                return ""
            end
        end,
        ["progress"] = "progress",
        ["branch"] = "branch",
        ["diff"] = "diff",
        ["encoding"] = "encoding",
        ["fileformat"] = "fileformat",
        ["filetype"] = "filetype",
    }
    
    return component_map[element] or element
end

-- RESOLVER IMPLEMENTATIONS

-- Line numbers resolver
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
    print("Line numbers set to: " .. tostring(value))
end)

-- Cursor line resolver
M.define_resolver("editor.cursorline", function(value)
    vim.opt.cursorline = value
    print("Cursor line highlight set to: " .. tostring(value))
end)

-- Mouse resolver
M.define_resolver("editor.mouse", function(value)
    if value then
        vim.opt.mouse = "a"
    else
        vim.opt.mouse = ""
    end
    print("Mouse support set to: " .. tostring(value))
end)

-- Theme resolver
M.define_resolver("theme", function(value)
    local success, err = pcall(function()
        vim.cmd("colorscheme " .. value)
    end)
    
    if success then
        print("Theme set to: " .. value)
    else
        print("Failed to set theme '" .. value .. "': " .. tostring(err))
        vim.notify("Theme '" .. value .. "' not found. Please install the theme or check the name.", vim.log.levels.WARN)
    end
end)

-- Cursor shape resolver
M.define_resolver("editor.cursor-shape", function(value)
    if type(value) ~= "table" then
        print("cursor-shape config must be a table")
        return
    end
    
    local guicursor_parts = {}
    
    -- Map Helix cursor shapes to Neovim guicursor values
    local shape_map = {
        block = "block",
        bar = "ver25",
        underline = "hor25",
        hidden = "block-blinkon0"
    }
    
    -- Map Helix modes to Neovim modes
    local mode_map = {
        normal = "n",
        insert = "i",
        select = "v",
        visual = "v"
    }
    
    for helix_mode, shape in pairs(value) do
        local nvim_mode = mode_map[helix_mode]
        local nvim_shape = shape_map[shape]
        
        if nvim_mode and nvim_shape then
            table.insert(guicursor_parts, nvim_mode .. ":" .. nvim_shape)
        end
    end
    
    if #guicursor_parts > 0 then
        vim.opt.guicursor = table.concat(guicursor_parts, ",")
        print("Cursor shape configured: " .. vim.opt.guicursor:get())
    end
end)

-- Statusline resolver (lualine integration)
M.define_resolver("editor.statusline", function(value)
    -- Register lualine dependency
    
    -- Check if lualine is available
    local lualine_ok, lualine = pcall(require, "lualine")
    if not lualine_ok then
        print("lualine.nvim not found. Statusline configuration skipped.")
        return
    end
    
    -- Default lualine configuration
    local lualine_config = {
        options = {
            theme = 'auto',
            component_separators = { left = '', right = '' },
            section_separators = { left = '', right = '' },
        },
        sections = {
            lualine_a = {},
            lualine_b = {},
            lualine_c = {},
            lualine_x = {},
            lualine_y = {},
            lualine_z = {}
        }
    }
    
    -- Handle separator if specified
    if value.separator then
        lualine_config.options.component_separators = { left = value.separator, right = value.separator }
    end
    
    -- Map Helix statusline sections to lualine sections
    if value.left and type(value.left) == "table" then
        for _, element in ipairs(value.left) do
            local component = map_helix_to_lualine_component(element)
            if #lualine_config.sections.lualine_a == 0 then
                table.insert(lualine_config.sections.lualine_a, component)
            else
                table.insert(lualine_config.sections.lualine_b, component)
            end
        end
    end
    
    if value.center and type(value.center) == "table" then
        for _, element in ipairs(value.center) do
            local component = map_helix_to_lualine_component(element)
            table.insert(lualine_config.sections.lualine_c, component)
        end
    end
    
    if value.right and type(value.right) == "table" then
        for i, element in ipairs(value.right) do
            local component = map_helix_to_lualine_component(element)
            if i == 1 then
                table.insert(lualine_config.sections.lualine_x, component)
            elseif i == 2 then
                table.insert(lualine_config.sections.lualine_y, component)
            else
                table.insert(lualine_config.sections.lualine_z, component)
            end
        end
    end
    
    -- Set default components if none specified
    if #lualine_config.sections.lualine_a == 0 and #lualine_config.sections.lualine_b == 0 and #lualine_config.sections.lualine_c == 0 then
        lualine_config.sections.lualine_a = {'mode'}
        lualine_config.sections.lualine_b = {'branch', 'diff', 'diagnostics'}
        lualine_config.sections.lualine_c = {'filename'}
    end
    
    if #lualine_config.sections.lualine_x == 0 and #lualine_config.sections.lualine_y == 0 and #lualine_config.sections.lualine_z == 0 then
        lualine_config.sections.lualine_x = {'encoding', 'fileformat', 'filetype'}
        lualine_config.sections.lualine_y = {'progress'}
        lualine_config.sections.lualine_z = {'location'}
    end
    
    -- Setup lualine with the configuration
    lualine.setup(lualine_config)
    print("Statusline configured with lualine")
end)

-- Auto-completion resolver
M.define_resolver("editor.auto-completion", function(value)
    if value then
        -- Register completion-related dependencies
        print("Auto-completion enabled (requires nvim-cmp)")
    else
        print("Auto-completion disabled")
    end
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