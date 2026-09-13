local resolvers = require("autoconf.sys.core.resolvers")
local completion = require("autoconf.sys.resolvers.editor.completion")
local logger = require("autoconf.sys.core.logger")

local M = {}
local base_capabilities
local formatters_by_ft = {}
local configured_servers = {}
local lsp_enabled = true
local format_status = "not requested"
local blink_status = "pending (setup on first InsertEnter)"
local deferred_group
local blink_setup_complete = false

local function get_base_capabilities()
    if base_capabilities then return base_capabilities end

    local ok, blink = pcall(require, "blink.cmp")
    if ok and type(blink.get_lsp_capabilities) == "function" then
        local caps_ok, caps = pcall(blink.get_lsp_capabilities)
        if caps_ok and type(caps) == "table" then
            base_capabilities = caps
        else
            logger.warn("Blink LSP capabilities unavailable; using Neovim defaults: " .. tostring(caps))
        end
    elseif not ok then
        logger.warn("blink.cmp is unavailable; configured servers will use Neovim's default LSP capabilities")
    end

    if not base_capabilities then
        base_capabilities = vim.lsp.protocol.make_client_capabilities()
    end
    return base_capabilities
end

local function get_lsp_setup()
    return {
        on_attach = function()
            for _, value in ipairs(resolvers.on_lsp_attach_keymaps) do value() end
        end,
        capabilities = completion.lsp_capabilities(get_base_capabilities()),
    }
end

local function configure_server(server_name, final_config)
    if vim.lsp.config ~= nil then
        vim.lsp.config(server_name, final_config)
        local resolved_config = vim.lsp.config[server_name]
        if resolved_config and resolved_config.cmd then
            configured_servers[server_name] = true
            vim.lsp.enable(server_name, lsp_enabled)
        end
        return
    end

    local ok, lspconfig = pcall(require, "lspconfig")
    if not ok then
        logger.warn("nvim-lspconfig unavailable; cannot configure " .. server_name)
        return
    end
    if lspconfig[server_name] then
        configured_servers[server_name] = true
        lspconfig[server_name].setup(final_config)
        if not lsp_enabled then
            logger.warn("this Neovim version cannot reversibly disable legacy lspconfig server " .. server_name)
        end
    end
end

local function setup_languages(languages)
    if vim.lsp.config == nil then
        local ok, lspconfig = pcall(require, "lspconfig")
        if not ok then return end
    end

    for name, config in pairs(languages) do
        local formatters = config.formatter
        if type(formatters) == "string" then formatters = { formatters } end
        if formatters ~= nil then formatters_by_ft[name] = vim.deepcopy(formatters) end

        local lsp = config.lsp
        if lsp then
            local server_name
            local custom_config = {}

            if type(lsp) == "string" then
                server_name = lsp
            elseif type(lsp) == "table" then
                server_name = lsp.server
                if server_name then
                    for key, value in pairs(lsp) do
                        if key ~= "server" then custom_config[key] = value end
                    end
                end
            end

            if server_name then
                local final_config = vim.tbl_deep_extend("force", get_lsp_setup(), custom_config)
                configure_server(server_name, final_config)
            end
        end
    end
end

local function setup_blink()
    if blink_setup_complete then return true end

    local ok, blink = pcall(require, "blink.cmp")
    if not ok or type(blink.setup) ~= "function" then
        blink_status = "unavailable"
        completion.set_blink_status(blink_status)
        logger.warn("completion settings are unsupported because blink.cmp.setup is unavailable")
        return false
    end

    local setup_ok, err = pcall(blink.setup, completion.blink_options())
    if not setup_ok then
        blink_status = "setup failed: " .. tostring(err)
        completion.set_blink_status(blink_status)
        logger.warn("Blink setup failed; requested completion settings are not effective: " .. tostring(err))
        return false
    end

    blink_setup_complete = true
    blink_status = "setup requested through Blink's one-shot public API; active config has no public getter"
    completion.set_blink_status(blink_status)
    return true
end

local function setup_deferred_blink()
    if blink_setup_complete then return end
    deferred_group = deferred_group or vim.api.nvim_create_augroup("AutoconfDeferredCompletion", { clear = true })
    vim.api.nvim_clear_autocmds({ group = deferred_group })
    if vim.api.nvim_get_mode().mode:sub(1, 1) == "i" then
        setup_blink()
    else
        vim.api.nvim_create_autocmd("InsertEnter", {
            group = deferred_group,
            once = true,
            callback = setup_blink,
            desc = "Initialize Blink completion on first insert",
        })
    end
end

local function format_with_conform(bufnr)
    local ok, conform = pcall(require, "conform")
    if not ok or type(conform.format) ~= "function" then
        format_status = "Conform unavailable; LSP fallback requested"
        return false
    end

    local opts = { bufnr = bufnr, timeout_ms = 500, lsp_format = "fallback" }
    local formatters = formatters_by_ft[vim.bo[bufnr].filetype]
    if formatters ~= nil then opts.formatters = vim.deepcopy(formatters) end
    local call_ok, result = pcall(conform.format, opts)
    if not call_ok then
        format_status = "Conform failed; LSP fallback requested"
        logger.warn("Conform format failed: " .. tostring(result))
        return false
    end
    format_status = result == false and "Conform found no applicable formatter; LSP fallback requested"
        or "Conform invoked on demand"
    return result ~= false
end

function M.format_buffer(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "" then return false end

    if format_with_conform(bufnr) then return true end
    local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/formatting" })
    if #clients == 0 then
        format_status = "formatting unavailable"
        return false
    end
    local ok, err = pcall(vim.lsp.buf.format, { bufnr = bufnr, timeout_ms = 2000 })
    if not ok then logger.warn("LSP formatting unavailable: " .. tostring(err)) end
    if format_status == "Conform unavailable; LSP fallback requested"
        or format_status == "Conform failed; LSP fallback requested"
        or format_status == "Conform found no applicable formatter; LSP fallback requested" then
        format_status = ok and "LSP fallback on demand" or "formatting unavailable"
    end
    if ok then format_status = "LSP formatting requested on demand" end
    return ok
end

function M.set_lsp_enabled(value)
    if type(value) ~= "boolean" then return false end
    lsp_enabled = value
    vim.g.lsp_enabled = value

    if type(vim.lsp.enable) == "function" then
        for server_name in pairs(configured_servers) do
            local ok, err = pcall(vim.lsp.enable, server_name, value)
            if not ok then logger.warn("could not " .. (value and "enable " or "disable ") .. server_name .. ": " .. tostring(err)) end
        end
    elseif not value then
        logger.warn("this Neovim version cannot reversibly disable configured LSP servers")
    end
    return true
end

function M.setup(languages)
    setup_languages(languages or {})
    setup_blink()
end

function M.setup_deferred(languages)
    setup_languages(languages or {})
    setup_deferred_blink()
end

function M.status()
    local servers = {}
    local restart_required = false
    for name in pairs(configured_servers) do
        local enabled = lsp_enabled
        if type(vim.lsp.is_enabled) == "function" then
            local ok, value = pcall(vim.lsp.is_enabled, name)
            if ok then enabled = value end
        end
        local config = vim.lsp.config and vim.lsp.config[name]
        local snippet_support = config and vim.tbl_get(config, "capabilities", "textDocument", "completion", "completionItem", "snippetSupport")
        if snippet_support ~= nil and snippet_support ~= completion.snippets_enabled() then
            restart_required = true
        end
        table.insert(servers, { name = name, enabled = enabled })
    end
    table.sort(servers, function(a, b) return a.name < b.name end)
    local current_format_status = format_status
    if vim.g.autoconf_auto_format_requested == true and current_format_status == "not requested" then
        current_format_status = "armed; Conform is deferred until BufWritePre"
    end
    return {
        lsp_requested = lsp_enabled,
        servers = servers,
        format_requested = vim.g.autoconf_auto_format_requested,
        format_effective = current_format_status,
        blink_effective = blink_status,
        restart_required = restart_required,
    }
end

return M
