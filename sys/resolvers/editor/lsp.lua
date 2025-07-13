local logger = require("sys.core.logger")

local M = {}

M.auto_info = function(value)
    -- Validate that the value is a boolean
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.auto-info", "must be a boolean, got: " .. type(value))
        return
    end

    if value then
        -- Enable auto-info by configuring LSP hover
        vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
            vim.lsp.handlers.hover, {
                border = "rounded",
                focusable = false,
                style = "minimal",
            }
        )

        -- Auto-show hover info on cursor hold
        vim.api.nvim_create_autocmd("CursorHold", {
            pattern = "*",
            callback = function()
                local clients = vim.lsp.get_clients({ bufnr = 0 })
                if #clients > 0 then
                    vim.lsp.buf.hover()
                end
            end,
            desc = "Auto-show hover info"
        })

        logger.resolver_success("editor.auto-info", "enabled with LSP hover")
    else
        -- Disable auto-info
        vim.api.nvim_clear_autocmds({ pattern = "*", event = "CursorHold" })
        logger.resolver_success("editor.auto-info", "disabled")
    end
end

M.popup_border = function(value)
    -- Validate that the value is a string
    if type(value) ~= "string" then
        logger.resolver_error("editor.popup-border", "must be a string, got: " .. type(value))
        return
    end

    local border_style = value == "none" and "none" or "rounded"

    -- Configure LSP borders
    vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
        vim.lsp.handlers.hover, {
            border = border_style,
        }
    )

    vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
        vim.lsp.handlers.signature_help, {
            border = border_style,
        }
    )

    -- Configure diagnostic borders
    vim.diagnostic.config({
        float = {
            border = border_style,
        },
    })

    logger.resolver_success("editor.popup-border", value)
end

-- LSP-related functions will be moved here
return M
