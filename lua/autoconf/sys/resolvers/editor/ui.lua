local logger = require("autoconf.sys.core.logger")
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

M.indent_guides = function(value)
    -- Validate that the value is a table
    if type(value) ~= "table" then
        logger.resolver_error("editor.indent-guides", "must be a table, got: " .. type(value))
        return
    end

    local render = value["render"]
    local character = value["character"] or "│"
    local skip_levels = value["skip-levels"] or 0

    -- Check if ibl (indent-blankline v3) is available
    local ibl_ok, ibl = pcall(require, "ibl")
    if not ibl_ok then
        if render then
            logger.resolver_error("editor.indent-guides", "ibl not found (indent-blankline v3 required)")
        else
            logger.resolver_success("editor.indent-guides", "disabled (plugin not found)")
        end
        return
    end

    if render then
        -- Configure ibl with proper v3 structure
        local config = {
            indent = {
                char = character,
            },
            scope = { enabled = false },
        }

        ibl.setup(config)
        logger.resolver_success("editor.indent-guides", "enabled with character: " .. character)
    else
        -- Disable indent guides by setting char to empty string
        ibl.setup({ indent = { char = "" } })
        logger.resolver_success("editor.indent-guides", "disabled")
    end
end

-- UI-related functions will be moved here
M.soft_wrap = function(config)
    -- Validate config structure
    if type(config) ~= "table" then
        logger.resolver_error("editor.soft-wrap", "must be a table, got: " .. type(config))
        return
    end

    -- Handle enable option
    local enable = config.enable
    if type(enable) ~= "boolean" then
        logger.resolver_error("editor.soft-wrap.enable", "must be a boolean, got: " .. type(enable))
        return
    end

    -- Set basic wrap settings
    vim.wo.wrap = enable
    vim.wo.linebreak = enable and config["max-wrap"] ~= 0

    -- Handle wrap indicator
    local wrap_indicator = config["wrap-indicator"]
    if wrap_indicator == false then
        vim.o.showbreak = ""
    elseif type(wrap_indicator) == "string" then
        vim.o.showbreak = wrap_indicator
    elseif enable then
        vim.o.showbreak = "↪ "
    end

    -- Handle indent retention
    local max_indent_retain = config["max-indent-retain"]
    if type(max_indent_retain) == "number" then
        vim.o.breakindent = true
        vim.o.breakindentopt = "shift:" .. max_indent_retain
    elseif enable then
        vim.o.breakindent = true
        vim.o.breakindentopt = "shift:40"
    end

    -- Handle wrap at text width
    local wrap_at_text_width = config["wrap-at-text-width"]
    if wrap_at_text_width and vim.bo.textwidth > 0 then
        vim.wo.colorcolumn = tostring(vim.bo.textwidth)
    elseif wrap_at_text_width then
        logger.resolver_warning("editor.soft-wrap", "wrap-at-text-width requires text-width to be set")
    end

    logger.resolver_success("editor.soft-wrap", "configured")
end

return M
