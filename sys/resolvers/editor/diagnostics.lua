local logger = require("sys.core.logger")
local M = {}

M.end_of_line_diagnostics = function(value)
    -- Validate that the value is a string
    if type(value) ~= "string" then
        logger.resolver_error("editor.end-of-line-diagnostics", "must be a string, got: " .. type(value))
        return
    end

    if value == "disable" then
        -- Disable end-of-line diagnostics
        vim.diagnostic.config({
            virtual_text = false,
        })
        logger.resolver_success("editor.end-of-line-diagnostics", "disabled")
    else
        -- Enable end-of-line diagnostics with severity filter
        local severity_map = {
            error = vim.diagnostic.severity.ERROR,
            warning = vim.diagnostic.severity.WARN,
            info = vim.diagnostic.severity.INFO,
            hint = vim.diagnostic.severity.HINT,
        }

        local min_severity = severity_map[value]
        if min_severity then
            vim.diagnostic.config({
                virtual_text = {
                    severity = { min = min_severity },
                    prefix = "●",
                    spacing = 4,
                },
            })
            logger.resolver_success("editor.end-of-line-diagnostics", "enabled for " .. value .. " and above")
        else
            logger.resolver_error("editor.end-of-line-diagnostics", "unknown severity level: " .. value)
        end
    end
end
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

    -- Process cursor_line
    if config["cursor-line"] == "disable" then
        vim.diagnostic.config({ virtual_lines = false })
        logger.resolver_success("editor.inline-diagnostics", "virtual_lines disabled for cursor line")
    else
        local severity = severity_map[config["cursor-line"]]
        if severity then
            vim.diagnostic.config({ virtual_lines = { only_current_line = true, severity = { min = severity } } })
            logger.resolver_success("editor.inline-diagnostics", "virtual_lines enabled for cursor line with severity " .. config["cursor-line"])
        else
            logger.resolver_error("editor.inline-diagnostics", "unknown severity for cursor_line: " .. config["cursor-line"])
            return
        end
    end

    -- Process other_lines
    if config["other-lines"] == "disable" then
        vim.diagnostic.config({ virtual_text = false })
        logger.resolver_success("editor.inline-diagnostics", "virtual_text disabled for other lines")
    else
        local severity = severity_map[config["other-lines"]]
        if severity then
            vim.diagnostic.config({
                virtual_text = {
                    severity = { min = severity },
                    prefix = string.rep("●", config["prefix-len"] or 1),
                    spacing = config["max-wrap"] or 20,
                },
            })
            logger.resolver_success("editor.inline-diagnostics", "virtual_text enabled for other lines with severity " .. config["other-lines"])
        else
            logger.resolver_error("editor.inline-diagnostics", "unknown severity for other_lines: " .. config["other-lines"])
            return
        end
    end

    -- Set max diagnostics
    if config["max-diagnostics"] then
        vim.diagnostic.config({ max_diagnostics = config["max-diagnostics"] })
        logger.resolver_success("editor.inline-diagnostics", "max_diagnostics set to " .. config["max-diagnostics"])
    end
end

return M