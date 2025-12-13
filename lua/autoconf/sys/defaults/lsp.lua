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
    else
    end
    return settings
end

local function setup_cmp()
    local ok_cmp_lsp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
    local ok_cmp, cmp = pcall(require, "cmp")
    if not ok_cmp_lsp or not ok_cmp then
        return
    end

    capabilities = vim.tbl_deep_extend("force", {}, vim.lsp.protocol.make_client_capabilities(),
        cmp_lsp.default_capabilities())

    -- if feature("nvim-cmp") then
    local cmp_select = { behavior = cmp.SelectBehavior.Select }

    cmp.setup({
        confirmation = { completeopt = "menu,menuone,noinsert" },
        mapping = cmp.mapping.preset.insert({
            ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
            ["<C-n>"] = cmp.mapping.select_next_item(
                cmp_select),
            ["<Tab>"] = cmp.mapping(function(fallback)
                local function has_words_before()
                    unpack = (unpack or table.unpack)
                    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                    return ((col ~= 0) and (vim.api.nvim_buf_get_lines(0, (line - 1), line, true)[1]:sub(col, col):match("%s") == nil))
                end
                if cmp.visible() then
                    if (#cmp.get_entries() == 1) then
                        return cmp.confirm({ select = true })
                    else
                        return cmp.select_next_item()
                    end
                elseif has_words_before() then
                    cmp.complete()
                    if (#cmp.get_entries() == 1) then
                        return cmp.confirm({ select = true })
                    else
                        return nil
                    end
                else
                    return fallback()
                end
            end, { "i", "s" }),
            ["<CR>"] = cmp.mapping({
                c = cmp.mapping.confirm({
                    behavior =
                        cmp.ConfirmBehavior.Replace,
                    select = true
                }),
                i = function(fallback)
                    if (cmp.visible() and cmp.get_active_entry()) then
                        return cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
                    else
                        return fallback()
                    end
                end,
                s = cmp.mapping.confirm({ select = true })
            }),
            ["<C-Space>"] = cmp.mapping.complete()
        }),
        sources = cmp.config.sources({ { name = "nvim_lsp" }, { name = "buffer" } }),
        preselect = false
    })
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
        else
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
                    -- Use new vim.lsp.config API (Neovim 0.11+)
                    vim.lsp.config[server_name] = final_config
                    vim.lsp.enable(server_name)
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
    setup_cmp()
    setup_languages(languages)
    setup_conform()
end

return M
