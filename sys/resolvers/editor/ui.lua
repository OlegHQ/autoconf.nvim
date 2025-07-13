local logger = require("sys.core.logger")
local M = {}



M.mouse = function(value)
    if value then
        vim.opt.mouse = "a"
    else
        vim.opt.mouse = ""
    end
    logger.resolver_success("editor.mouse", value)
end

M.continue_comments = function(value)
    -- Validate that the value is a boolean
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.continue-comments", "must be a boolean, got: " .. type(value))
        return
    end

    if value then
        -- Enable comment continuation by setting formatoptions
        vim.opt.formatoptions:append("cro")
        logger.resolver_success("editor.continue-comments", "enabled")
    else
        -- Disable comment continuation by removing from formatoptions
        vim.opt.formatoptions:remove("cro")
        logger.resolver_success("editor.continue-comments", "disabled")
    end
end

M.editor_config = function(value)
    -- Validate that the value is a boolean
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.editor-config", "must be a boolean, got: " .. type(value))
        return
    end

    if value then
        -- Try to enable editorconfig support
        local editorconfig_ok, editorconfig = pcall(require, "editorconfig")
        if editorconfig_ok then
            -- Plugin-based editorconfig
            logger.resolver_success("editor.editor-config", "enabled with editorconfig plugin")
        else
            -- Built-in editorconfig (Neovim 0.9+)
            if vim.fn.has("nvim-0.9") == 1 then
                vim.g.editorconfig = true
                logger.resolver_success("editor.editor-config", "enabled with built-in support")
            else
                logger.resolver_error("editor.editor-config", "requires Neovim 0.9+ or editorconfig plugin")
            end
        end
    else
        vim.g.editorconfig = false
        logger.resolver_success("editor.editor-config", "disabled")
    end
end


M.jump_label_alphabet = function(value)
    -- Validate that the value is a string
    if type(value) ~= "string" then
        logger.resolver_error("editor.jump-label-alphabet", "must be a string, got: " .. type(value))
        return
    end

    -- Store alphabet for jump plugins
    vim.g.helix_jump_alphabet = value

    -- Configure hop.nvim if available
    local hop_ok, hop = pcall(require, "hop")
    if hop_ok then
        hop.setup({
            keys = value,
        })
        logger.resolver_success("editor.jump-label-alphabet", "configured with hop.nvim: " .. value)
    else
        logger.resolver_success("editor.jump-label-alphabet", "stored for jump plugins: " .. value)
    end
end



M.indent_heuristic = function(value)
    -- Validate that the value is a string
    if type(value) ~= "string" then
        logger.resolver_error("editor.indent-heuristic", "must be a string, got: " .. type(value))
        return
    end

    if value == "simple" then
        -- Simple indentation (copy from previous line)
        vim.opt.autoindent = true
        vim.opt.smartindent = false
        vim.opt.cindent = false
        logger.resolver_success("editor.indent-heuristic", "simple (copy previous line)")
    elseif value == "tree-sitter" then
        -- Tree-sitter based indentation
        vim.opt.autoindent = true
        vim.opt.smartindent = true
        vim.opt.cindent = false

        -- Enable tree-sitter indent if available
        local ts_ok, ts_configs = pcall(require, "nvim-treesitter.configs")
        if ts_ok then
            ts_configs.setup({
                indent = {
                    enable = true,
                },
            })
            logger.resolver_success("editor.indent-heuristic", "tree-sitter based")
        else
            logger.resolver_success("editor.indent-heuristic", "tree-sitter (fallback to smart)")
        end
    else -- "hybrid" or default
        -- Hybrid approach (both auto and smart)
        vim.opt.autoindent = true
        vim.opt.smartindent = true
        vim.opt.cindent = true
        logger.resolver_success("editor.indent-heuristic", "hybrid (auto + smart + cindent)")
    end
end

-- UI-related functions will be moved here
return M
