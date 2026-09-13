local logger = require("autoconf.sys.core.logger")
local M = {}
local requested_inline = nil


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
        return false
    end

    local inline_config = false
    if config["only-current-line"] then
        inline_config = { only_current_line = true }
    elseif config.enabled then
        inline_config = true
    end
    requested_inline = config.enabled == true or config["only-current-line"] == true

    if vim.fn.has("nvim-0.11") == 1 then
        vim.diagnostic.config({ virtual_lines = inline_config })
        return true
    end

    local ok, lsp_lines = pcall(require, "lsp_lines")
    if ok then
        lsp_lines.setup()
        vim.diagnostic.config({ virtual_lines = inline_config })
        return true
    elseif inline_config then
        logger.warn("editor.inline-diagnostics requested, but lsp_lines is not available")
        return false
    end
    return true
end

function M.inline_diagnostics_status()
    local ok, config = pcall(vim.diagnostic.config)
    if not ok or type(config) ~= "table" then
        return { requested = requested_inline == true, effective = false, state = "unavailable" }
    end
    local value = config.virtual_lines
    local effective = value == true or type(value) == "table"
    local requested = requested_inline
    if requested == nil then requested = effective end
    return {
        requested = requested,
        effective = effective,
        state = "ready",
    }
end

function M.inline_diagnostics_capabilities()
    if vim.fn.has("nvim-0.11") == 1 then return { available = true, state = "ready" } end
    return { available = false, state = "unavailable", reason = "inline diagnostics require Neovim 0.11 or lsp_lines" }
end

return M
