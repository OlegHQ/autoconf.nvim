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
return M