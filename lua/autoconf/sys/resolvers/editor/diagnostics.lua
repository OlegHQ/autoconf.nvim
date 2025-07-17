local logger = require("autoconf.sys.core.logger")
local M = {}


-- Diagnostic-related functions will be moved here
local severity_map = {
    error = vim.diagnostic.severity.ERROR,
    warning = vim.diagnostic.severity.WARN,
    info = vim.diagnostic.severity.INFO,
    hint = vim.diagnostic.severity.HINT,
}

M.inline_diagnostics = function(config)
    local ok, lsp_lines = pcall(require, "lsp_lines")
    if not ok then
        logger.resolver_error("editor.inline-diagnostics", "lsp_lines module not found")
        return
    end

    lsp_lines.setup()

    -- Validate config is a table
    if type(config) ~= "table" then
        logger.resolver_error("editor.inline-diagnostics", "must be a table, got: " .. type(config))
        return
    end

    if config["only-current-line"] then
        vim.diagnostic.config({ virtual_lines = { only_current_line = true } })
        return
    end

    if config.enabled then
        vim.diagnostic.config({ virtual_lines = true })
    end
end

return M
