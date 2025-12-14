local logger = require("autoconf.sys.core.logger")
local builder = require("autoconf.sys.core.resolver_builder")

local M = {}

-- Scroll lines - custom logic for scroll wheel keymaps
M.scroll_lines = builder.custom("editor.scroll-lines", "number", function(value)
    if value <= 0 then
        logger.resolver_error("editor.scroll-lines", "must be positive, got: " .. tostring(value))
        return
    end

    vim.opt.scroll = value
    vim.keymap.set({ 'n', 'v' }, '<ScrollWheelUp>', '<C-y>', { desc = 'Scroll up' })
    vim.keymap.set({ 'n', 'v' }, '<ScrollWheelDown>', '<C-e>', { desc = 'Scroll down' })
    vim.cmd(string.format('set scroll=%d', value))

    logger.resolver_success("editor.scroll-lines", tostring(value) .. " lines per scroll step")
end)

return M