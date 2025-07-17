local logger = require("sys.core.logger")

local M = {}


M.cursorcolumn = function(value)
    -- Validate that the value is a boolean
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.cursorcolumn", "must be a boolean, got: " .. type(value))
        return
    end

    -- Set cursor column option
    vim.opt.cursorcolumn = value

    logger.resolver_success("editor.cursorcolumn", value and "enabled" or "disabled")
end


M.color_modes = function(value)
    -- Validate that the value is a boolean
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.color-modes", "must be a boolean, got: " .. type(value))
        return
    end

    if value then
        -- Enable colored mode indicator (requires statusline plugin)
        vim.g.helix_color_modes = true
        logger.resolver_success("editor.color-modes", "enabled (requires statusline plugin support)")
    else
        vim.g.helix_color_modes = false
        logger.resolver_success("editor.color-modes", "disabled")
    end
end



M.true_color = function(value)
    -- Validate that the value is a boolean
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.true-color", "must be a boolean, got: " .. type(value))
        return
    end

    -- Set terminal GUI colors
    vim.opt.termguicolors = value

    logger.resolver_success("editor.true-color", value and "enabled" or "disabled")
end


M.undercurl = function(value)
    -- Validate that the value is a boolean
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.undercurl", "must be a boolean, got: " .. type(value))
        return
    end

    if value then
        -- Enable undercurl support
        vim.g.undercurl = true
        -- Set up undercurl highlight
        vim.cmd([[
                if &term =~ "xterm" || &term =~ "screen" || &term =~ "tmux"
                    let &t_Cs = "\e[4:3m"
                    let &t_Ce = "\e[4:0m"
                endif
            ]])
        logger.resolver_success("editor.undercurl", "enabled")
    else
        vim.g.undercurl = false
        logger.resolver_success("editor.undercurl", "disabled")
    end
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


M.cursorline = function(value)
    vim.opt.cursorline = value
    logger.resolver_success("editor.cursorline", value)
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


-- Appearance-related functions will be moved here
return M
