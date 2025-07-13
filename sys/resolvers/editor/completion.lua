local logger = require("sys.core.logger")

local M = {}


M.path_completion = function(value)
    -- Validate that the value is a boolean
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.path-completion", "must be a boolean, got: " .. type(value))
        return
    end

    if value then
        -- Enable path completion using built-in completion
        vim.opt.wildmenu = true
        vim.opt.wildmode = "longest:full,full"

        -- Configure completion options for better path completion
        vim.opt.completeopt = "menu,menuone,noselect"

        -- Check if nvim-cmp is available for enhanced completion
        local cmp_ok, cmp = pcall(require, "cmp")
        if cmp_ok then
            -- Add path completion source to nvim-cmp if not already configured
            local config = cmp.get_config()
            if config and config.sources then
                -- Check if path source is already present
                local has_path_source = false
                for _, source in ipairs(config.sources) do
                    if source.name == "path" then
                        has_path_source = true
                        break
                    end
                end

                if not has_path_source then
                    table.insert(config.sources, { name = "path" })
                    cmp.setup(config)
                end
            end
            logger.resolver_success("editor.path-completion", "enabled with nvim-cmp")
        else
            logger.resolver_success("editor.path-completion", "enabled with built-in completion")
        end
    else
        -- Disable enhanced path completion
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

    -- Configure nvim-cmp if available
    local cmp_ok, cmp = pcall(require, "cmp")
    if cmp_ok then
        cmp.setup({
            preselect = value and cmp.PreselectMode.Item or cmp.PreselectMode.None,
            completion = {
                autocomplete = value and { cmp.TriggerEvent.TextChanged } or false,
            },
        })
        logger.resolver_success("editor.preview-completion-insert",
            value and "instant application enabled" or "manual application")
    else
        logger.resolver_success("editor.preview-completion-insert", "configured for built-in completion")
    end
end


M.completion_replace = function(value)
    -- Validate that the value is a boolean
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.completion-replace", "must be a boolean, got: " .. type(value))
        return
    end

    -- Configure nvim-cmp if available
    local cmp_ok, cmp = pcall(require, "cmp")
    if cmp_ok then
        cmp.setup({
            completion = {
                completeopt = value and "menu,menuone,noselect,replace" or "menu,menuone,noselect",
            },
        })
        logger.resolver_success("editor.completion-replace",
            value and "replace entire word" or "replace part before cursor")
    else
        logger.resolver_success("editor.completion-replace", "configured for built-in completion")
    end
end




M.completion_timeout = function(value)
    -- Validate that the value is a number
    if type(value) ~= "number" then
        logger.resolver_error("editor.completion-timeout", "must be a number, got: " .. type(value))
        return
    end

    -- Configure nvim-cmp if available
    local cmp_ok, cmp = pcall(require, "cmp")
    if cmp_ok then
        cmp.setup({
            completion = {
                keyword_length = 1,
                autocomplete = {
                    require('cmp.types').cmp.TriggerEvent.TextChanged,
                },
            },
            experimental = {
                ghost_text = value <= 50, -- Enable ghost text for instant completion
            },
        })
        logger.resolver_success("editor.completion-timeout", tostring(value) .. "ms with nvim-cmp")
    else
        -- Set updatetime for built-in completion
        vim.opt.updatetime = value
        logger.resolver_success("editor.completion-timeout", tostring(value) .. "ms with built-in completion")
    end
end


M.completion_trigger_len = function(value)
    -- Validate that the value is a number
    if type(value) ~= "number" then
        logger.resolver_error("editor.completion-trigger-len", "must be a number, got: " .. type(value))
        return
    end

    -- Configure nvim-cmp if available
    local cmp_ok, cmp = pcall(require, "cmp")
    if cmp_ok then
        cmp.setup({
            completion = {
                keyword_length = value,
            },
        })
        logger.resolver_success("editor.completion-trigger-len", tostring(value) .. " characters with nvim-cmp")
    else
        -- Set for built-in completion
        vim.opt.complete = ".,w,b,u,t,i,kspell"
        logger.resolver_success("editor.completion-trigger-len",
            tostring(value) .. " characters with built-in completion")
    end
end



M.auto_completion = function(value)
    if value then
        -- Register completion-related dependencies
        logger.resolver_success("editor.auto-completion", "enabled (requires nvim-cmp)")
    else
        logger.resolver_success("editor.auto-completion", "disabled")
    end
end

-- Completion-related functions will be moved here
return M
