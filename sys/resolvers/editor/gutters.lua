local resolvers = require("sys.core.resolvers")
local logger = require("sys.core.logger")
-- Individual gutter resolvers for indexed gutter entries
-- These handle editor.gutters.1, editor.gutters.2, etc.
local gutter_config = {
    want_diagnostics = false,
    want_line_numbers = false,
    want_diff = false,
    gutter_order = {}
}

-- Helper function to apply gutter configuration
local function apply_gutter_config()
    -- Configure line numbers
    if gutter_config.want_line_numbers then
        vim.opt.number = true
    else
        vim.opt.number = false
    end

    -- Configure sign column for diagnostics and diff
    if gutter_config.want_diagnostics or gutter_config.want_diff then
        if gutter_config.want_diagnostics and gutter_config.want_diff then
            vim.opt.signcolumn = "yes:2" -- Allow two signs per line
        else
            vim.opt.signcolumn = "yes"
        end
    else
        vim.opt.signcolumn = "no"
    end

    -- Configure diagnostics signs
    if gutter_config.want_diagnostics then
        vim.diagnostic.config({
            signs = true,
            virtual_text = false, -- Keep virtual text off by default
            underline = true,
            severity_sort = true,
        })
    else
        vim.diagnostic.config({
            signs = false,
        })
    end

    -- Configure diff signs (git)
    if gutter_config.want_diff then
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
        end
    end

    local enabled_gutters = {}
    if gutter_config.want_diagnostics then table.insert(enabled_gutters, "diagnostics") end
    if gutter_config.want_line_numbers then table.insert(enabled_gutters, "line-numbers") end
    if gutter_config.want_diff then table.insert(enabled_gutters, "diff") end

    logger.resolver_success("editor.gutters", "configured: " .. table.concat(enabled_gutters, ", "))
end

-- Generic gutter item resolver that handles all numbered entries
local function create_gutter_item_resolver(index)
    return function(value)
        -- Validate that the value is a string
        if type(value) ~= "string" then
            logger.resolver_error("editor.gutters." .. index, "must be a string, got: " .. type(value))
            return
        end

        -- Store the gutter type in the appropriate index
        gutter_config.gutter_order[index] = value

        -- Update the configuration flags
        if value == "diagnostics" then
            gutter_config.want_diagnostics = true
        elseif value == "line-numbers" then
            gutter_config.want_line_numbers = true
        elseif value == "diff" then
            gutter_config.want_diff = true
            -- "spacer" is ignored as Neovim can't insert arbitrary spacing
        end

        -- Apply the configuration (this will be called multiple times but that's okay)
        apply_gutter_config()

        logger.resolver_success("editor.gutters." .. index, "set to '" .. value .. "'")
    end
end

-- Register resolvers for commonly used gutter indices
local function define_resolver()
    for i = 1, 10 do
        resolvers.define_resolver("editor.gutters." .. i, create_gutter_item_resolver(i))
    end
end


local function gutters(value)
    -- Validate that the value is a table (array)
    if type(value) ~= "table" then
        logger.resolver_error("editor.gutters", "must be a table/array, got: " .. type(value))
        return
    end

    -- Parse gutter configuration
    local want_diagnostics = false
    local want_line_numbers = false
    local want_diff = false

    for _, gutter in ipairs(value) do
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
        if want_diagnostics and want_diff then
            vim.opt.signcolumn = "yes:2" -- Allow two signs per line
        else
            vim.opt.signcolumn = "yes"
        end
    else
        vim.opt.signcolumn = "no"
    end

    -- Configure diagnostics signs
    if want_diagnostics then
        vim.diagnostic.config({
            signs = true,
            virtual_text = false, -- Keep virtual text off by default
            underline = true,
            severity_sort = true,
        })
    else
        vim.diagnostic.config({
            signs = false,
        })
    end

    -- Configure diff signs (git)
    if want_diff then
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
            logger.resolver_error("editor.gutters", "gitsigns.nvim plugin required for diff signs")
        end
    end

    local enabled_gutters = {}
    if want_diagnostics then table.insert(enabled_gutters, "diagnostics") end
    if want_line_numbers then table.insert(enabled_gutters, "line-numbers") end
    if want_diff then table.insert(enabled_gutters, "diff") end

    logger.resolver_success("editor.gutters", "configured: " .. table.concat(enabled_gutters, ", "))
end


return {
    define_array_resolvers = define_resolver,
    resolver = gutters
}
