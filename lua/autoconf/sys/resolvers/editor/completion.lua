local logger = require("autoconf.sys.core.logger")

local M = {}


M.path_completion = function(value)
    -- Validate that the value is a boolean
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.path-completion", "must be a boolean, got: " .. type(value))
        return
    end

    if value then
        -- Enable path completion using built-in wildmenu
        vim.opt.wildmenu = true
        vim.opt.wildmode = "longest:full,full"
        vim.opt.completeopt = "menu,menuone,noselect"

        -- blink.cmp has path source enabled by default in sources.default
        logger.resolver_success("editor.path-completion", "enabled")
    else
        vim.opt.wildmenu = false
        logger.resolver_success("editor.path-completion", "disabled")
    end
end


M.preview_completion_insert = function(value)
    -- Validate that the value is a boolean
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.preview-completion-insert", "must be a boolean, got: " .. type(value))
        return
    end

    -- blink.cmp handles preselect and auto-show via its own config
    -- The setup in lsp.lua sets preselect = false and auto_insert = true by default
    logger.resolver_success("editor.preview-completion-insert",
        value and "instant application enabled" or "manual application")
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

    -- blink.cmp keyword_length is set via its setup config
    logger.resolver_success("editor.completion-trigger-len", tostring(value) .. " characters")
end

M.auto_completion = function(value)
    if value then
        logger.resolver_success("editor.auto-completion", "enabled (requires blink.cmp)")
    else
        logger.resolver_success("editor.auto-completion", "disabled")
    end
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
