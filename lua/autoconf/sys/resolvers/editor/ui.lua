local logger = require("autoconf.sys.core.logger")
local builder = require("autoconf.sys.core.resolver_builder")

local M = {}

-- Mouse - maps boolean to vim.opt.mouse value
M.mouse = builder.vim_opt_mapped("editor.mouse", "mouse", {
    [true] = "a",
    [false] = ""
}, { type = "boolean" })

-- Continue comments - custom formatoptions handling
M.continue_comments = builder.boolean_toggle("editor.continue-comments", {
    on = function()
        vim.opt.formatoptions:append("cro")
    end,
    off = function()
        vim.opt.formatoptions:remove("cro")
    end
})

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

    vim.g.helix_jump_alphabet = value
    logger.resolver_success("editor.jump-label-alphabet", "stored: " .. value)
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
    -- Defer ibl setup to after UI renders
    vim.schedule(function()
        if type(value) ~= "table" then
            return
        end

        local render = value["render"]
        local character = value["character"] or "│"

        local ibl_ok, ibl = pcall(require, "ibl")
        if not ibl_ok then return end

        if render then
            ibl.setup({ indent = { char = character }, scope = { enabled = false } })
        else
            ibl.setup({ indent = { char = "" } })
        end
    end)
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

    if not enable then
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
    if enable then
        -- Enable break indent but start from column 0
        vim.o.breakindent = true
        -- Remove any shift to ensure wrapping starts from column 0
        vim.o.breakindentopt = ""
    else
        vim.o.breakindent = false
        vim.o.breakindentopt = ""
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

