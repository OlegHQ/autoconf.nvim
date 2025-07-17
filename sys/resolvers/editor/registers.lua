local logger = require("sys.core.logger")
local M = {}

M.default_yank_register = function(value)
    -- Validate that the value is a string
    if type(value) ~= "string" then
        logger.resolver_error("editor.default-yank-register", "must be a string, got: " .. type(value))
        return
    end

    -- Validate that the value is a valid register name
    if not value:match("^[a-zA-Z0-9\"*+%-]$") then
        logger.resolver_error("editor.default-yank-register", "must be a valid register name, got: " .. value)
        return
    end

    -- Set the default register by configuring clipboard
    if value == "+" then
        vim.opt.clipboard = "unnamedplus"
    elseif value == "*" then
        vim.opt.clipboard = "unnamed"
    elseif value == "\"" then
        vim.opt.clipboard = ""
    else
        -- For other registers, we'll set it as the default
        vim.opt.clipboard = ""
        vim.g.default_yank_register = value
    end

    logger.resolver_success("editor.default-yank-register", "set to register '" .. value .. "'")
end

-- Register-related functions will be moved here
return M