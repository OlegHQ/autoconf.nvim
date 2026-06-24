local resolvers = require("autoconf.sys.core.resolvers")
local logger = require("autoconf.sys.core.logger")
-- Individual gutter resolvers for indexed gutter entries
-- These handle editor.gutters.1, editor.gutters.2, etc.
local gutter_config = {
    want_diagnostics = false,
    want_line_numbers = false,
    want_diff = false,
    gutter_order = {}
}

-- Register resolvers for commonly used gutter indices
local function define_resolver()
end


local function gutters(value)
    -- Validate that the value is a table
    if type(value) ~= "table" then
        logger.resolver_error("editor.gutters", "must be a table, got: " .. type(value))
        return
    end

    -- Handle both direct array and config format
    local gutters_array = value
    if value.layout then
        gutters_array = value.layout
    end

    -- Parse gutter configuration
    local want_diagnostics = false
    local want_line_numbers = false
    local want_diff = false

    for _, gutter in ipairs(gutters_array) do
        if gutter == "diagnostics" then
            want_diagnostics = true
        elseif gutter == "line-numbers" then
            want_line_numbers = true
        elseif gutter == "diff" then
            want_diff = true
            -- "spacer" is ignored as Neovim can't insert arbitrary spacing
        end
    end

    -- Configure line numbers
    if want_line_numbers then
        vim.opt.number = true
    else
        vim.opt.number = false
    end

    -- Configure sign column for diagnostics and diff
    if want_diagnostics or want_diff then
        vim.opt.signcolumn = "yes"
    else
        vim.opt.signcolumn = "no"
    end

    -- Configure diagnostics signs
    if want_diagnostics then
        vim.diagnostic.config({
            signs = {
                text = {
                    [vim.diagnostic.severity.ERROR] = '●',
                    [vim.diagnostic.severity.WARN] = '◍',
                    [vim.diagnostic.severity.INFO] = '◎',
                    [vim.diagnostic.severity.HINT] = '◯',
                }
            },
            virtual_text = false, 
            underline = true,
            severity_sort = true,
        })
    else
        vim.diagnostic.config({
            signs = false,
        })
    end

    -- Configure diff signs (git) — defer to first buffer read
    if want_diff then
        vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
            once = true,
            callback = function()
                local gitsigns_ok, gitsigns = pcall(require, "gitsigns")
                if gitsigns_ok then
                    gitsigns.setup({
                        signs = {
                            add = { text = '│' },
                            change = { text = '│' },
                            delete = { text = '_' },
                            topdelete = { text = '‾' },
                            changedelete = { text = '~' },
                            untracked = { text = '┆' },
                        },
                        signcolumn = true,
                        numhl = false,
                        linehl = false,
                        word_diff = false,
                        watch_gitdir = {
                            interval = 1000,
                            follow_files = true
                        },
                        attach_to_untracked = true,
                        current_line_blame = false,
                        sign_priority = 6,
                        update_debounce = 100,
                        status_formatter = nil,
                        max_file_length = 40000,
                        preview_config = {
                            border = 'single',
                            style = 'minimal',
                            relative = 'cursor',
                            row = 0,
                            col = 1
                        },
                    })
                    logger.resolver_success("editor.gutters", "diff signs enabled with gitsigns.nvim")
                else
                    logger.warn("editor.gutters diff signs requested, but gitsigns.nvim is not available")
                end
            end,
        })
    end

    logger.resolver_success("editor.gutters", "configured")
end


local line_number = function(value)
    if value == "relative" then
        vim.opt.number = true
        vim.opt.relativenumber = true
    elseif value == "absolute" then
        vim.opt.number = true
        vim.opt.relativenumber = false
    else
        vim.opt.number = false
        vim.opt.relativenumber = false
    end
    logger.resolver_success("editor.line-number", value)
end

return {
    define_array_resolvers = define_resolver,
    resolver = gutters,
    line_number = line_number
}
