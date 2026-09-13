local logger = require("autoconf.sys.core.logger")
local builder = require("autoconf.sys.core.resolver_builder")
local completion = require("autoconf.sys.resolvers.editor.completion")

local M = {}
local float_opts = { hover = {}, signature_help = {} }
local auto_info_group = vim.api.nvim_create_augroup("AutoconfAutoInfo", { clear = true })
local signature_help_group = vim.api.nvim_create_augroup("AutoconfAutoSignatureHelp", { clear = true })
local inlay_hint_group = vim.api.nvim_create_augroup("AutoconfInlayHints", { clear = true })
local inlay_hint_buffers = {}
local handler_owners = {}
local state = {
    auto_info = false,
    auto_signature_help = false,
    display_messages = false,
    display_progress_messages = false,
}

function M.hover()
    vim.lsp.buf.hover(float_opts.hover)
end

function M.signature_help()
    vim.lsp.buf.signature_help(float_opts.signature_help)
end

M.auto_info = function(value)
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.auto-info", "must be a boolean, got: " .. type(value))
        return
    end

    vim.api.nvim_clear_autocmds({ group = auto_info_group })
    state.auto_info = value
    if value then
        float_opts.hover.border = float_opts.hover.border or "rounded"
        float_opts.hover.focusable = false
        float_opts.hover.style = "minimal"
        vim.api.nvim_create_autocmd("CursorHold", {
            group = auto_info_group,
            callback = function(args)
                if #vim.lsp.get_clients({ bufnr = args.buf }) > 0 then M.hover() end
            end,
            desc = "Autoconf auto hover",
        })
        logger.resolver_success("editor.auto-info", "enabled with scoped LSP hover")
    else
        logger.resolver_success("editor.auto-info", "disabled")
    end
end

M.popup_border = function(value)
    if type(value) ~= "string" then
        logger.resolver_error("editor.popup-border", "must be a string, got: " .. type(value))
        return
    end

    local border_style = value == "none" and "none" or "rounded"
    float_opts.hover.border = border_style
    float_opts.signature_help.border = border_style
    vim.diagnostic.config({ float = { border = border_style } })
    logger.resolver_success("editor.popup-border", value)
end

M.enable = builder.boolean_toggle("editor.lsp.enable", {
    on = function() require("autoconf.sys.defaults.lsp").set_lsp_enabled(true) end,
    off = function() require("autoconf.sys.defaults.lsp").set_lsp_enabled(false) end,
})

local function set_handler_enabled(method, enabled)
    vim.lsp.handlers = vim.lsp.handlers or {}
    local owner = handler_owners[method]
    local current = vim.lsp.handlers[method]

    if enabled then
        if not owner then return true end
        if current ~= owner.wrapper then
            handler_owners[method] = nil
            return false
        end
        vim.lsp.handlers[method] = owner.original
        handler_owners[method] = nil
        return true
    end

    if owner then
        if current == owner.wrapper then return true end
        -- Do not replace a handler installed by a user or another plugin.
        handler_owners[method] = nil
        return false
    end

    local record = { original = current, wrapper = function() end }
    vim.lsp.handlers[method] = record.wrapper
    handler_owners[method] = record
    return true
end

local function message_toggle(path, method, value, status_key)
    if type(value) ~= "boolean" then
        logger.resolver_error(path, "must be a boolean, got: " .. type(value))
        return
    end
    local owned = set_handler_enabled(method, value)
    state[status_key] = value
    if owned then
        logger.resolver_success(path, value and "enabled" or "disabled")
    else
        logger.warn(path .. " could not change the handler because another owner replaced it")
    end
end

M.display_messages = function(value)
    message_toggle("editor.lsp.display-messages", "window/showMessage", value, "display_messages")
end

M.display_progress_messages = function(value)
    message_toggle("editor.lsp.display-progress-messages", "$/progress", value, "display_progress_messages")
end

M.auto_signature_help = function(value)
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.lsp.auto-signature-help", "must be a boolean, got: " .. type(value))
        return
    end

    vim.api.nvim_clear_autocmds({ group = signature_help_group })
    state.auto_signature_help = value
    if value then
        vim.api.nvim_create_autocmd("CursorHoldI", {
            group = signature_help_group,
            callback = function(args)
                if #vim.lsp.get_clients({ bufnr = args.buf }) > 0 then M.signature_help() end
            end,
            desc = "Autoconf auto signature help",
        })
        logger.resolver_success("editor.lsp.auto-signature-help", "enabled")
    else
        logger.resolver_success("editor.lsp.auto-signature-help", "disabled")
    end
end

M.display_inlay_hints = function(value)
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.lsp.display-inlay-hints", "must be a boolean, got: " .. type(value))
        return
    end

    vim.api.nvim_clear_autocmds({ group = inlay_hint_group })
    if value and vim.lsp.inlay_hint then
        vim.api.nvim_create_autocmd("LspAttach", {
            group = inlay_hint_group,
            callback = function(args)
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if client and client.server_capabilities.inlayHintProvider then
                    vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
                    inlay_hint_buffers[args.buf] = true
                end
            end,
            desc = "Autoconf enable inlay hints on attach",
        })
        logger.resolver_success("editor.lsp.display-inlay-hints", "enabled")
    elseif value then
        logger.resolver_error("editor.lsp.display-inlay-hints", "requires Neovim 0.10+")
    else
        for bufnr in pairs(inlay_hint_buffers) do
            if vim.api.nvim_buf_is_valid(bufnr) and vim.lsp.inlay_hint then
                pcall(vim.lsp.inlay_hint.enable, false, { bufnr = bufnr })
            end
            inlay_hint_buffers[bufnr] = nil
        end
        logger.resolver_success("editor.lsp.display-inlay-hints", "disabled for Autoconf-owned buffers")
    end
end

M.display_signature_help_docs = function(value)
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.lsp.display-signature-help-docs", "must be a boolean, got: " .. type(value))
        return
    end
    float_opts.signature_help.border = float_opts.signature_help.border or "rounded"
    float_opts.signature_help.focusable = false
    float_opts.signature_help.style = "minimal"
    float_opts.signature_help.show_documentation = value
    logger.resolver_success("editor.lsp.display-signature-help-docs", value and "enabled" or "disabled")
end

M.snippets = completion.snippets

M.goto_reference_include_declaration = function(value)
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.lsp.goto-reference-include-declaration", "must be a boolean, got: " .. type(value))
        return
    end
    vim.g.lsp_include_declaration = value
    logger.resolver_success("editor.lsp.goto-reference-include-declaration", value and "enabled" or "disabled")
end

function M.references()
    return vim.lsp.buf.references({ includeDeclaration = vim.g.lsp_include_declaration ~= false })
end

M.display_color_swatches = function(value)
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.lsp.display-color-swatches", "must be a boolean, got: " .. type(value))
        return
    end

    if value then
        local colorizer_ok, colorizer = pcall(require, "colorizer")
        if colorizer_ok then
            colorizer.setup()
            logger.resolver_success("editor.lsp.display-color-swatches", "enabled with colorizer")
        else
            vim.g.lsp_color_swatches_enabled = false
            logger.warn("editor.lsp.display-color-swatches is unsupported: colorizer is not installed")
        end
    else
        vim.g.lsp_color_swatches_enabled = false
        local colorizer_ok, colorizer = pcall(require, "colorizer")
        if colorizer_ok and type(colorizer.detach_from_buffer) == "function" then
            colorizer.detach_from_buffer()
        end
        logger.resolver_success("editor.lsp.display-color-swatches", "disabled")
    end
end

function M.status()
    return {
        auto_info = state.auto_info,
        auto_signature_help = state.auto_signature_help,
        display_messages = state.display_messages,
        display_progress_messages = state.display_progress_messages,
        snippets = completion.snippets_enabled(),
        owned_inlay_hint_buffers = vim.tbl_keys(inlay_hint_buffers),
    }
end

return M
