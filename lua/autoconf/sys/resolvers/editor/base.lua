local logger = require("autoconf.sys.core.logger")
local builder = require("autoconf.sys.core.resolver_builder")

local M = {}

-- Middle-click paste requires custom keymap setup
M.middle_click_paste = builder.boolean_toggle("editor.middle-click-paste", {
    on = function()
        vim.keymap.set({ 'n', 'v' }, '<MiddleMouse>', '<MiddleMouse>', { desc = 'Middle click paste' })
        vim.keymap.set('i', '<MiddleMouse>', '<C-r>*', { desc = 'Middle click paste in insert mode' })
    end,
    off = function()
        vim.keymap.set({ 'n', 'v', 'i' }, '<MiddleMouse>', '<Nop>', { desc = 'Disable middle click paste' })
    end
})

-- Simple number resolvers using builder
M.scrolloff = builder.vim_opt_number("editor.scrolloff", "scrolloff", {
    min = 0,
    format = function(v) return tostring(v) .. " lines" end
})

M.idle_timeout = builder.vim_opt_number("editor.idle-timeout", "updatetime", {
    format = function(v) return tostring(v) .. "ms" end
})




M.default_line_ending = function(value)
    -- Validate that the value is a string
    if type(value) ~= "string" then
        logger.resolver_error("editor.default-line-ending", "must be a string, got: " .. type(value))
        return
    end

    -- Map Helix line ending names to Neovim fileformat
    local format_map = {
        native = vim.fn.has("win32") == 1 and "dos" or "unix",
        lf = "unix",
        crlf = "dos",
        cr = "mac",
        ff = "unix",  -- Form feed (treat as unix)
        nel = "unix", -- Next line (treat as unix)
    }

    local fileformat = format_map[value]
    if fileformat then
        vim.opt.fileformat = fileformat
        vim.opt.fileformats = fileformat
        logger.resolver_success("editor.default-line-ending", value .. " (" .. fileformat .. ")")
    else
        logger.resolver_error("editor.default-line-ending", "unknown line ending format: " .. value)
    end
end



M.auto_save = function(config)
    -- Validate config structure
    if type(config) ~= "table" then
        logger.resolver_error("editor.auto-save", "must be a table, got: " .. type(config))
        return
    end

    -- Clear any existing auto-save autocmds
    vim.api.nvim_clear_autocmds({ pattern = "*", event = { "FocusLost", "CursorHold" } })

    -- Handle focus-lost auto-save
    local focus_lost = config["focus-lost"]
    if type(focus_lost) == "boolean" and focus_lost then
        vim.api.nvim_create_autocmd("FocusLost", {
            pattern = "*",
            callback = function()
                vim.cmd("silent! wall")
            end,
            desc = "Auto-save on focus lost"
        })
    end

    -- Handle after-delay auto-save
    local after_delay = config["after-delay"]
    if type(after_delay) == "table" and after_delay.enable then
        local timeout = tonumber(after_delay.timeout) or 3000
        vim.api.nvim_create_autocmd("CursorHold", {
            pattern = "*",
            callback = function()
                vim.cmd("silent! update")
            end,
            desc = "Auto-save after delay",
            group = vim.api.nvim_create_augroup("AutoSaveAfterDelay", { clear = true })
        })
        vim.opt.updatetime = timeout
    end

    logger.resolver_success("editor.auto-save", "configured")
end

return M
