local logger = require("sys.core.logger")

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
            local clients = vim.lsp.get_clients()
            if #clients > 0 then
                return "⠋" -- Simple spinner character
            end
            return ""
        end,
        ["selections"] = function()
            -- Return a custom function for selection count
            local mode = vim.fn.mode()
            if mode == "v" or mode == "V" or mode == "\22" then
                local count = vim.fn.wordcount().visual_chars
                if count and count > 0 then
                    return tostring(count)
                end
            end
            return ""
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
            theme = {
                normal = {
                    a = { bg = 'none', fg = 'none' },
                    b = { bg = 'none', fg = 'none' },
                    c = { bg = 'none', fg = 'none' },
                    x = { bg = 'none', fg = 'none' },
                    y = { bg = 'none', fg = 'none' },
                    z = { bg = 'none', fg = 'none' },
                },
                insert = {
                    a = { bg = 'none', fg = 'none' },
                    b = { bg = 'none', fg = 'none' },
                    c = { bg = 'none', fg = 'none' },
                    x = { bg = 'none', fg = 'none' },
                    y = { bg = 'none', fg = 'none' },
                    z = { bg = 'none', fg = 'none' },
                },
                visual = {
                    a = { bg = 'none', fg = 'none' },
                    b = { bg = 'none', fg = 'none' },
                    c = { bg = 'none', fg = 'none' },
                    x = { bg = 'none', fg = 'none' },
                    y = { bg = 'none', fg = 'none' },
                    z = { bg = 'none', fg = 'none' },
                },
                replace = {
                    a = { bg = 'none', fg = 'none' },
                    b = { bg = 'none', fg = 'none' },
                    c = { bg = 'none', fg = 'none' },
                    x = { bg = 'none', fg = 'none' },
                    y = { bg = 'none', fg = 'none' },
                    z = { bg = 'none', fg = 'none' },
                },
                command = {
                    a = { bg = 'none', fg = 'none' },
                    b = { bg = 'none', fg = 'none' },
                    c = { bg = 'none', fg = 'none' },
                    x = { bg = 'none', fg = 'none' },
                    y = { bg = 'none', fg = 'none' },
                    z = { bg = 'none', fg = 'none' },
                },
                inactive = {
                    a = { bg = 'none', fg = 'none' },
                    b = { bg = 'none', fg = 'none' },
                    c = { bg = 'none', fg = 'none' },
                    x = { bg = 'none', fg = 'none' },
                    y = { bg = 'none', fg = 'none' },
                    z = { bg = 'none', fg = 'none' },
                },
            },
            component_separators = { left = '', right = '' },
            section_separators = { left = '', right = '' },
            globalstatus = true,
            padding = 0,
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
            local component
            if element == "mode" and value.mode then
                component = {
                    "mode",
                    padding = { left = 0, right = 3 },
                    fmt = function(str)
                        local key
                        if str == "NORMAL" then
                            key = "normal"
                        elseif str == "INSERT" or str == "REPLACE" then
                            key = "insert"
                        elseif str:find("VISUAL") or str:find("SELECT") then
                            key = "select"
                        end
                        if key and value.mode[key] then
                            return value.mode[key]
                        end
                        return str
                    end,
                }
            else
                component = map_helix_to_lualine_component(element)
            end
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



M.bufferline = function(value)
    -- Validate that the value is a string
    if type(value) ~= "string" then
        logger.resolver_error("editor.bufferline", "must be a string (always/never/multiple), got: " .. type(value))
        return
    end

    if value == "always" then
        -- Always show bufferline
        vim.opt.showtabline = 2

        -- Try to use bufferline.nvim if available
        local bufferline_ok, bufferline = pcall(require, "bufferline")
        if bufferline_ok then
            bufferline.setup({
                options = {
                    mode = "buffers",
                    numbers = "none",
                    close_command = "bdelete! %d",
                    right_mouse_command = "bdelete! %d",
                    left_mouse_command = "buffer %d",
                    middle_mouse_command = nil,
                    indicator = {
                        icon = '▎',
                        style = 'icon',
                    },
                    buffer_close_icon = '',
                    modified_icon = '●',
                    close_icon = '',
                    left_trunc_marker = '',
                    right_trunc_marker = '',
                    max_name_length = 18,
                    max_prefix_length = 15,
                    truncate_names = true,
                    tab_size = 18,
                    diagnostics = "nvim_lsp",
                    diagnostics_update_in_insert = false,
                    show_buffer_icons = true,
                    show_buffer_close_icons = true,
                    show_close_icon = true,
                    show_tab_indicators = true,
                    persist_buffer_sort = true,
                    separator_style = "slant",
                    enforce_regular_tabs = false,
                    always_show_bufferline = true,
                    sort_by = 'id'
                }
            })
            logger.resolver_success("editor.bufferline", "always enabled with bufferline.nvim")
        else
            logger.resolver_success("editor.bufferline", "always enabled with built-in tabline")
        end
    elseif value == "multiple" then
        -- Show bufferline only when multiple buffers
        vim.opt.showtabline = 1
        logger.resolver_success("editor.bufferline", "enabled for multiple buffers")
    else -- "never"
        -- Never show bufferline
        vim.opt.showtabline = 0
        logger.resolver_success("editor.bufferline", "disabled")
    end
end



return M