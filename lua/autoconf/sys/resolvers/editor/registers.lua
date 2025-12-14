local logger = require("autoconf.sys.core.logger")
local builder = require("autoconf.sys.core.resolver_builder")

local M = {}

-- Default yank register - complex logic for clipboard configuration
M.default_yank_register = builder.custom("editor.default-yank-register", "string", function(value)
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
        vim.opt.clipboard = ""
        vim.g.default_yank_register = value
    end

    logger.resolver_success("editor.default-yank-register", "set to register '" .. value .. "'")
end)

return M