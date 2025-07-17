local logger = require("sys.core.logger")
local M = {}

M.scroll_lines = function(value)
    -- Validate that the value is a number
    if type(value) ~= "number" then
        logger.resolver_error("editor.scroll-lines", "must be a number, got: " .. type(value))
        return
    end

    -- Validate that the value is positive
    if value <= 0 then
        logger.resolver_error("editor.scroll-lines", "must be positive, got: " .. tostring(value))
        return
    end

    -- Set scroll wheel behavior
    vim.opt.scroll = value

    -- Configure scroll wheel mappings for precise control
    vim.keymap.set({ 'n', 'v' }, '<ScrollWheelUp>', '<C-y>', { desc = 'Scroll up' })
    vim.keymap.set({ 'n', 'v' }, '<ScrollWheelDown>', '<C-e>', { desc = 'Scroll down' })

    -- Set the number of lines to scroll
    vim.cmd(string.format('set scroll=%d', value))

    logger.resolver_success("editor.scroll-lines", tostring(value) .. " lines per scroll step")
end

return M