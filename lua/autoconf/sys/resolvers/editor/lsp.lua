local logger = require("autoconf.sys.core.logger")
local builder = require("autoconf.sys.core.resolver_builder")

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

-- LSP enable/disable resolver (auto-registered)
M.enable = builder.boolean_toggle("editor.lsp.enable", {
    on = function()
        vim.g.lsp_enabled = true
    end,
    off = function()
        vim.g.lsp_enabled = false
        -- Stop all LSP clients
        for _, client in pairs(vim.lsp.get_clients()) do
            client.stop()
        end
    end
})

-- Display LSP messages resolver (auto-registered)
M.display_messages = builder.boolean_toggle("editor.lsp.display-messages", {
    on = function()
        -- Enable LSP messages (default behavior)
        vim.lsp.handlers["window/showMessage"] = vim.lsp.handlers["window/showMessage"]
    end,
    off = function()
        -- Disable LSP messages by overriding handler to no-op
        vim.lsp.handlers["window/showMessage"] = function() end
    end
})

-- Display progress messages resolver (auto-registered)
M.display_progress_messages = builder.boolean_toggle("editor.lsp.display-progress-messages", {
    on = function()
        vim.g.lsp_progress_enabled = true
    end,
    off = function()
        vim.g.lsp_progress_enabled = false
        -- Override progress handler to no-op
        vim.lsp.handlers["$/progress"] = function() end
    end
})

-- Auto signature help resolver
M.auto_signature_help = function(value)
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.lsp.auto-signature-help", "must be a boolean, got: " .. type(value))
        return
    end

    if value then
        -- Enable auto signature help on cursor hold in insert mode
        vim.api.nvim_create_autocmd("CursorHoldI", {
            pattern = "*",
            callback = function()
                local clients = vim.lsp.get_clients({ bufnr = 0 })
                if #clients > 0 then
                    vim.lsp.buf.signature_help()
                end
            end,
            desc = "Auto-show signature help"
        })
        logger.resolver_success("editor.lsp.auto-signature-help", "enabled")
    else
        -- Disable auto signature help
        vim.api.nvim_clear_autocmds({ pattern = "*", event = "CursorHoldI" })
        logger.resolver_success("editor.lsp.auto-signature-help", "disabled")
    end
end

-- Display inlay hints resolver
M.display_inlay_hints = function(value)
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.lsp.display-inlay-hints", "must be a boolean, got: " .. type(value))
        return
    end

    if value then
        -- Enable inlay hints (Neovim 0.10+)
        if vim.lsp.inlay_hint then
            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(args)
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if client and client.server_capabilities.inlayHintProvider then
                        vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
                    end
                end,
                desc = "Enable inlay hints on LSP attach"
            })
            logger.resolver_success("editor.lsp.display-inlay-hints", "enabled")
        else
            logger.resolver_error("editor.lsp.display-inlay-hints", "requires Neovim 0.10+")
        end
    else
        -- Disable inlay hints
        if vim.lsp.inlay_hint then
            vim.lsp.inlay_hint.enable(false)
        end
        logger.resolver_success("editor.lsp.display-inlay-hints", "disabled")
    end
end

-- Display signature help docs resolver
M.display_signature_help_docs = function(value)
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.lsp.display-signature-help-docs", "must be a boolean, got: " .. type(value))
        return
    end

    -- Configure signature help handler
    vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
        vim.lsp.handlers.signature_help, {
            border = "rounded",
            focusable = false,
            style = "minimal",
            -- Show or hide documentation based on value
            show_documentation = value,
        }
    )

    logger.resolver_success("editor.lsp.display-signature-help-docs", value and "enabled" or "disabled")
end

-- Snippets resolver (auto-registered)
M.snippets = builder.boolean_toggle("editor.lsp.snippets", {
    on = function()
        vim.g.lsp_snippets_enabled = true
    end,
    off = function()
        vim.g.lsp_snippets_enabled = false
        -- Override LSP capabilities to disable snippet support
        local original_make_client_capabilities = vim.lsp.protocol.make_client_capabilities
        vim.lsp.protocol.make_client_capabilities = function()
            local capabilities = original_make_client_capabilities()
            capabilities.textDocument.completion.completionItem.snippetSupport = false
            return capabilities
        end
    end
})

-- Goto reference include declaration resolver
M.goto_reference_include_declaration = function(value)
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.lsp.goto-reference-include-declaration", "must be a boolean, got: " .. type(value))
        return
    end

    -- Store the setting for use in references function
    vim.g.lsp_include_declaration = value

    -- Override the references function to respect this setting
    local original_references = vim.lsp.buf.references
    vim.lsp.buf.references = function(context, options)
        local new_context = context or {}
        new_context.includeDeclaration = value
        return original_references(new_context, options)
    end

    logger.resolver_success("editor.lsp.goto-reference-include-declaration", value and "enabled" or "disabled")
end

-- Display color swatches resolver
M.display_color_swatches = function(value)
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.lsp.display-color-swatches", "must be a boolean, got: " .. type(value))
        return
    end

    if value then
        -- Enable color swatches - try to use nvim-colorizer or similar
        local colorizer_ok, colorizer = pcall(require, "colorizer")
        if colorizer_ok then
            colorizer.setup()
            logger.resolver_success("editor.lsp.display-color-swatches", "enabled with colorizer")
        else
            -- Fallback: enable basic color highlighting
            vim.g.lsp_color_swatches_enabled = true
            logger.resolver_success("editor.lsp.display-color-swatches", "enabled (basic)")
        end
    else
        -- Disable color swatches
        vim.g.lsp_color_swatches_enabled = false
        local colorizer_ok, colorizer = pcall(require, "colorizer")
        if colorizer_ok then
            colorizer.detach_from_buffer()
        end
        logger.resolver_success("editor.lsp.display-color-swatches", "disabled")
    end
end

-- LSP-related functions
return M

