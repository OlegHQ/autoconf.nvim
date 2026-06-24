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
    -- Validate config is a table
    if type(config) ~= "table" then
        logger.resolver_error("editor.inline-diagnostics", "must be a table, got: " .. type(config))
        return
    end

    local inline_config = false
    if config["only-current-line"] then
        inline_config = { only_current_line = true }
    elseif config.enabled then
        inline_config = true
    end

    if vim.fn.has("nvim-0.11") == 1 then
        vim.diagnostic.config({ virtual_lines = inline_config })
        return
    end

    local ok, lsp_lines = pcall(require, "lsp_lines")
    if ok then
        lsp_lines.setup()
        vim.diagnostic.config({ virtual_lines = inline_config })
    elseif inline_config then
        logger.warn("editor.inline-diagnostics requested, but lsp_lines is not available")
    end
end

return M
