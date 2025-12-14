local logger = require("autoconf.sys.core.logger")
local builder = require("autoconf.sys.core.resolver_builder")

local M = {}

-- Simple boolean toggles using builder
M.cursorcolumn = builder.vim_opt_boolean("editor.cursorcolumn", "cursorcolumn")

M.color_modes = builder.vim_g_boolean("editor.color-modes", "helix_color_modes", {
    enabled_msg = "enabled (requires statusline plugin support)"
})

M.true_color = builder.vim_opt_boolean("editor.true-color", "termguicolors")

M.cursorline = builder.vim_opt_boolean("editor.cursorline", "cursorline")

-- Undercurl requires custom on/off logic
M.undercurl = builder.boolean_toggle("editor.undercurl", {
    on = function()
        vim.g.undercurl = true
        vim.cmd([[
            if &term =~ "xterm" || &term =~ "screen" || &term =~ "tmux"
                let &t_Cs = "\e[4:3m"
                let &t_Ce = "\e[4:0m"
            endif
        ]])
    end,
    off = function()
        vim.g.undercurl = false
    end
})

-- Theme requires custom error handling
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


-- Appearance-related functions will be moved here
return M
