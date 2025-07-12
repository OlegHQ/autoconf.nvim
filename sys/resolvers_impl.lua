-- Resolver implementations for Helix configuration
-- This file contains all the actual resolver functions that handle specific configuration paths

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

-- Function to register all resolver implementations
local function register_resolvers(resolvers)
    -- Line numbers resolver
    resolvers.define_resolver("editor.line-number", function(value)
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
    resolvers.define_resolver("editor.cursorline", function(value)
        vim.opt.cursorline = value
        print("Cursor line highlight set to: " .. tostring(value))
    end)

    -- Mouse resolver
    resolvers.define_resolver("editor.mouse", function(value)
        if value then
            vim.opt.mouse = "a"
        else
            vim.opt.mouse = ""
        end
        print("Mouse support set to: " .. tostring(value))
    end)

    -- Theme resolver
    resolvers.define_resolver("theme", function(value)
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
    resolvers.define_resolver("editor.cursor-shape", function(value)
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
            print("Cursor shape configured: " .. tostring(vim.opt.guicursor:get()))
        end
    end)

    -- Statusline resolver (lualine integration)
    resolvers.define_resolver("editor.statusline", function(value)
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
    resolvers.define_resolver("editor.auto-completion", function(value)
        if value then
            -- Register completion-related dependencies
            print("Auto-completion enabled (requires nvim-cmp)")
        else
            print("Auto-completion disabled")
        end
    end)
end

-- Function to register all command resolvers
local function register_command_resolvers(resolvers)
    -- Command resolvers for Helix commands (using separate command resolver registry)
    resolvers.define_command_resolver("goto_definition", function()
        return function()
            vim.lsp.buf.definition()
        end
    end)

    resolvers.define_command_resolver("goto_reference", function()
        return function()
            vim.lsp.buf.references()
        end
    end)

    resolvers.define_command_resolver("write", function()
        return function()
            vim.cmd("write")
        end
    end)

    resolvers.define_command_resolver("quit", function()
        return function()
            vim.cmd("quit")
        end
    end)

    resolvers.define_command_resolver("normal_mode", function()
        return function()
            vim.cmd("stopinsert")
        end
    end)

    -- Note: delete_selection and yank would need more complex implementations
    -- These are placeholders for now
    resolvers.define_command_resolver("delete_selection", function()
        return function()
            vim.cmd("normal! d")
        end
    end)

    resolvers.define_command_resolver("yank", function()
        return function()
            vim.cmd("normal! y")
        end
    end)
end

-- Main function to initialize all resolvers
local function init_resolvers(resolvers)
    register_resolvers(resolvers)
    register_command_resolvers(resolvers)
    
    -- Load and register editor-specific resolvers
    local editor_resolvers = require("sys.editor_resolvers")
    editor_resolvers.register_editor_resolvers(resolvers)
end

return {
    init_resolvers = init_resolvers
} 