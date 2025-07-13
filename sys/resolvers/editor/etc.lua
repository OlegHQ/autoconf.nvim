local logger = require("sys.core.logger")
local resolvers = require("sys.core.resolvers")

local M = {}

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

M.line_number = function(value)
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
    logger.resolver_success("editor.line-number", value)
end

M.cursorline = function(value)
    vim.opt.cursorline = value
    logger.resolver_success("editor.cursorline", value)
end

M.mouse = function(value)
    if value then
        vim.opt.mouse = "a"
    else
        vim.opt.mouse = ""
    end
    logger.resolver_success("editor.mouse", value)
end

M.theme = function(value)
    local success, err = pcall(function()
        vim.cmd("colorscheme " .. value)
    end)

    if success then
        logger.resolver_success("theme", value)
    else
        logger.resolver_error("theme", "Failed to set theme '" .. value .. "': " .. tostring(err))
        vim.notify("Theme '" .. value .. "' not found. Please install the theme or check the name.",
            vim.log.levels.WARN)
    end
end

M.cursor_shape = function(value)
    if type(value) ~= "table" then
        logger.resolver_error("editor.cursor-shape", "cursor-shape config must be a table")
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
        logger.resolver_success("editor.cursor-shape", tostring(vim.opt.guicursor:get()))
    end
end

M.statusline = function(value)
    -- Register lualine dependency

    -- Check if lualine is available
    local lualine_ok, lualine = pcall(require, "lualine")
    if not lualine_ok then
        logger.plugin_missing("lualine.nvim")
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
        lualine_config.sections.lualine_a = { 'mode' }
        lualine_config.sections.lualine_b = { 'branch', 'diff', 'diagnostics' }
        lualine_config.sections.lualine_c = { 'filename' }
    end

    if #lualine_config.sections.lualine_x == 0 and #lualine_config.sections.lualine_y == 0 and #lualine_config.sections.lualine_z == 0 then
        lualine_config.sections.lualine_x = { 'encoding', 'fileformat', 'filetype' }
        lualine_config.sections.lualine_y = { 'progress' }
        lualine_config.sections.lualine_z = { 'location' }
    end

    -- Setup lualine with the configuration
    lualine.setup(lualine_config)
    logger.resolver_success("editor.statusline", "configured with lualine")
end

M.auto_completion = function(value)
    if value then
        -- Register completion-related dependencies
        logger.resolver_success("editor.auto-completion", "enabled (requires nvim-cmp)")
    else
        logger.resolver_success("editor.auto-completion", "disabled")
    end
end

return M
