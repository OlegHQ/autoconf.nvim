local logger = require("autoconf.sys.core.logger")

local M = {}
local state = {
    auto_completion = true,
    path_completion = true,
    preview_insert = true,
    keyword_length = 2,
    snippets = true,
    blink = "pending (setup on first InsertEnter)",
}

local function valid_boolean(path, value)
    if type(value) == "boolean" then return true end
    logger.resolver_error(path, "must be a boolean, got: " .. type(value))
    return false
end

function M.blink_options()
    -- Blink v1 accepts partial options through its documented setup API.
    -- Functions keep TOML toggles effective after Blink's one-time setup.
    return {
        enabled = function() return state.auto_completion end,
        completion = {
            list = {
                selection = {
                    preselect = false,
                    auto_insert = function() return state.preview_insert end,
                },
            },
        },
        sources = {
            min_keyword_length = function() return state.keyword_length end,
            providers = {
                path = { enabled = function() return state.path_completion end },
                snippets = { enabled = function() return state.snippets end },
            },
        },
    }
end

function M.set_blink_status(status)
    state.blink = status
end

function M.lsp_capabilities(base)
    local capabilities = vim.deepcopy(base)
    local completion = vim.tbl_get(capabilities, "textDocument", "completion", "completionItem")
    if completion then completion.snippetSupport = state.snippets end
    return capabilities
end

function M.snippets_enabled()
    return state.snippets
end

function M.status()
    return {
        requested = {
            auto_completion = state.auto_completion,
            path_completion = state.path_completion,
            preview_insert = state.preview_insert,
            keyword_length = state.keyword_length,
            snippets = state.snippets,
        },
        effective = state.blink,
        restart_required = false,
    }
end


M.path_completion = function(value)
    if not valid_boolean("editor.path-completion", value) then return end
    state.path_completion = value

    if value then
        -- Preserve Neovim's command-line path completion as well as Blink's
        -- insert-mode path provider.
        vim.opt.wildmenu = true
        vim.opt.wildmode = "longest:full,full"
        vim.opt.completeopt = "menu,menuone,noselect"
    else
        vim.opt.wildmenu = false
    end
    logger.resolver_success("editor.path-completion", value and "requested; applied when Blink initializes" or "disabled")
end


M.preview_completion_insert = function(value)
    if not valid_boolean("editor.preview-completion-insert", value) then return end
    state.preview_insert = value
    logger.resolver_success("editor.preview-completion-insert", value and "preview insertion requested" or "preview insertion disabled")
end


M.completion_replace = function(value)
    -- Validate that the value is a boolean
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.completion-replace", "must be a boolean, got: " .. type(value))
        return
    end

    -- blink.cmp handles replace behavior internally
    vim.opt.completeopt = value and "menu,menuone,noselect,replace" or "menu,menuone,noselect"
    logger.resolver_success("editor.completion-replace",
        value and "replace entire word" or "replace part before cursor")
end


M.completion_timeout = function(value)
    -- Validate that the value is a number
    if type(value) ~= "number" then
        logger.resolver_error("editor.completion-timeout", "must be a number, got: " .. type(value))
        return
    end

    -- Set updatetime for general responsiveness
    vim.opt.updatetime = value
    logger.resolver_success("editor.completion-timeout", tostring(value) .. "ms")
end


M.completion_trigger_len = function(value)
    -- Validate that the value is a number
    if type(value) ~= "number" then
        logger.resolver_error("editor.completion-trigger-len", "must be a number, got: " .. type(value))
        return
    end

    if value < 0 or value % 1 ~= 0 then
        logger.resolver_error("editor.completion-trigger-len", "must be a non-negative integer")
        return
    end
    state.keyword_length = value
    logger.resolver_success("editor.completion-trigger-len", tostring(value) .. " characters")
end

M.auto_completion = function(value)
    if not valid_boolean("editor.auto-completion", value) then return false end
    state.auto_completion = value
    logger.resolver_success("editor.auto-completion", value and "enabled in Blink when initialized" or "disabled in Blink")
    return true
end

M.snippets = function(value)
    if not valid_boolean("editor.lsp.snippets", value) then return end
    state.snippets = value
    logger.resolver_success("editor.lsp.snippets", value and "enabled in Blink and LSP capabilities" or "disabled in Blink and LSP capabilities")
end

M.auto_pairs = function(value)
    -- Defer autopairs setup
    vim.schedule(function()
        if type(value) ~= "boolean" and type(value) ~= "table" then return end

        local autopairs_ok, autopairs = pcall(require, "nvim-autopairs")
        if not autopairs_ok then return end

        if type(value) == "boolean" then
            if value then
                autopairs.setup {}
            else
                autopairs.setup { disable_filetype = { "all" } }
            end
        else
            autopairs.setup { pairs = value }
        end
    end)
end

return M
