local logger = require("sys.core.logger")

local M = {}

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

M.auto_completion = function(value)
    if value then
        -- Register completion-related dependencies
        logger.resolver_success("editor.auto-completion", "enabled (requires nvim-cmp)")
    else
        logger.resolver_success("editor.auto-completion", "disabled")
    end
end

return M
