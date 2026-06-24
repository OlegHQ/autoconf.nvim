local resolvers = require("autoconf.sys.core.resolvers")

local M = {}
local capabilities = nil
local formatters_by_ft = {}

local function on_attach()
    for _, value in ipairs(resolvers.on_lsp_attach_keymaps) do
        value()
    end
end

local function get_lsp_setup()
    local settings = { on_attach = on_attach }
    if capabilities then
        settings["capabilities"] = capabilities
    end
    return settings
end

local function setup_blink()
    local ok, blink = pcall(require, "blink.cmp")
    if not ok then
        return
    end

    blink.setup({
        keymap = {
            preset = "none",
            ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
            ["<C-e>"] = { "hide" },
            ["<C-p>"] = { "select_prev", "fallback" },
            ["<C-n>"] = { "select_next", "fallback" },
            ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
            ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
            ["<CR>"] = { "accept", "fallback" },
        },
        completion = {
            list = {
                selection = { preselect = false, auto_insert = true },
            },
            menu = { auto_show = true },
            documentation = { auto_show = true, auto_show_delay_ms = 200 },
            ghost_text = { enabled = false },
        },
        sources = {
            default = { "lsp", "path", "buffer" },
        },
        signature = { enabled = true },
    })

    capabilities = blink.get_lsp_capabilities()
end

local function setup_languages(languages)
    -- Check if we should use the new vim.lsp.config API (Neovim 0.11+)
    local use_new_api = vim.lsp.config ~= nil
    local lspconfig = nil

    if not use_new_api then
        -- Fall back to old lspconfig for older Neovim versions
        local ok_lspconfig
        ok_lspconfig, lspconfig = pcall(require, "lspconfig")
        if not ok_lspconfig then
            return
        end
    end

    for name, config in pairs(languages) do
        local formatters = config.formatter
        local lsp = config.lsp
        if (type(formatters) == "string") then
            formatters = { formatters }
        end
        formatters_by_ft[name] = formatters

        -- Handle lsp configuration (string or table)
        if lsp then
            local server_name
            local custom_config = {}

            if type(lsp) == "string" then
                -- Legacy string format: lsp = "server_name"
                server_name = lsp
            elseif type(lsp) == "table" then
                -- New table format: lsp = { server = "name", cmd = {...}, settings = {...}, ... }
                server_name = lsp.server
                if server_name then
                    -- Copy all fields except 'server' into custom_config
                    for key, value in pairs(lsp) do
                        if key ~= "server" then
                            custom_config[key] = value
                        end
                    end
                end
            end

            if server_name then
                local base_setup = get_lsp_setup()
                -- Merge custom config with base setup (custom config takes precedence)
                local final_config = vim.tbl_deep_extend("force", base_setup, custom_config)

                if use_new_api then
                    -- Merge with runtime/lsp defaults from nvim-lspconfig instead of replacing them.
                    vim.lsp.config(server_name, final_config)
                    local resolved_config = vim.lsp.config[server_name]
                    if resolved_config and resolved_config.cmd then
                        vim.lsp.enable(server_name)
                    end
                else
                    -- Use old lspconfig API (backward compatibility)
                    if lspconfig[server_name] then
                        lspconfig[server_name].setup(final_config)
                    end
                end
            end
        end
    end
end

local function setup_conform()
    local ok_conform, conform = pcall(require, "conform")
    if not ok_conform then
        return
    end

    return conform.setup({ formatters_by_ft = formatters_by_ft, format_on_save = { timeout_ms = 500, lsp_format = "fallback" }, default_format_opts = { lsp_format = "fallback" } })
end

M.setup = function(languages)
    setup_blink()
    setup_languages(languages)
    setup_conform()
end

--- Deferred setup: registers LSP servers immediately but defers blink + conform
--- to first InsertEnter for faster startup
M.setup_deferred = function(languages)
    -- LSP server registration is cheap with vim.lsp.config (no require needed)
    setup_languages(languages)

    -- Defer blink.cmp and conform until first InsertEnter
    local deferred_done = false
    vim.api.nvim_create_autocmd("InsertEnter", {
        once = true,
        callback = function()
            if deferred_done then return end
            deferred_done = true
            setup_blink()
            setup_conform()
        end,
    })
end

return M
