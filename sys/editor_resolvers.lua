-- Editor-specific resolver implementations
-- This file contains resolvers for editor-specific configuration options

-- Import logger
local logger = require("sys.logger")

-- Function to register editor-specific resolvers
local function register_editor_resolvers(resolvers)
    -- Scrolloff resolver - Number of lines of padding around the edge of the screen when scrolling
    resolvers.define_resolver("editor.scrolloff", function(value)
        -- Validate that the value is a number
        if type(value) ~= "number" then
            logger.resolver_error("editor.scrolloff", "must be a number, got: " .. type(value))
            return
        end
        
        -- Validate that the value is non-negative
        if value < 0 then
            logger.resolver_error("editor.scrolloff", "must be non-negative, got: " .. tostring(value))
            return
        end
        
        -- Set the scrolloff option
        vim.opt.scrolloff = value
        
        logger.resolver_success("editor.scrolloff", tostring(value) .. " lines")
    end)
    
    -- Default yank register resolver - Default register used for yank/paste
    resolvers.define_resolver("editor.default-yank-register", function(value)
        -- Validate that the value is a string
        if type(value) ~= "string" then
            logger.resolver_error("editor.default-yank-register", "must be a string, got: " .. type(value))
            return
        end
        
        -- Validate that the value is a valid register name
        if not value:match("^[a-zA-Z0-9\"*+%-]$") then
            logger.resolver_error("editor.default-yank-register", "must be a valid register name, got: " .. value)
            return
        end
        
        -- Set the default register by configuring clipboard
        if value == "+" then
            vim.opt.clipboard = "unnamedplus"
        elseif value == "*" then
            vim.opt.clipboard = "unnamed"
        elseif value == "\"" then
            vim.opt.clipboard = ""
        else
            -- For other registers, we'll set it as the default
            vim.opt.clipboard = ""
            vim.g.default_yank_register = value
        end
        
        logger.resolver_success("editor.default-yank-register", "set to register '" .. value .. "'")
    end)
    
    -- Middle click paste resolver - Middle click paste support
    resolvers.define_resolver("editor.middle-click-paste", function(value)
        -- Validate that the value is a boolean
        if type(value) ~= "boolean" then
            logger.resolver_error("editor.middle-click-paste", "must be a boolean, got: " .. type(value))
            return
        end
        
        -- Configure middle-click paste behavior
        if value then
            -- Enable middle-click paste
            vim.keymap.set({'n', 'v'}, '<MiddleMouse>', '<MiddleMouse>', { desc = 'Middle click paste' })
            vim.keymap.set('i', '<MiddleMouse>', '<C-r>*', { desc = 'Middle click paste in insert mode' })
        else
            -- Disable middle-click paste by mapping to nothing
            vim.keymap.set({'n', 'v', 'i'}, '<MiddleMouse>', '<Nop>', { desc = 'Disable middle click paste' })
        end
        
        logger.resolver_success("editor.middle-click-paste", value and "enabled" or "disabled")
    end)
    
    -- Scroll lines resolver - Number of lines to scroll per scroll wheel step
    resolvers.define_resolver("editor.scroll-lines", function(value)
        -- Validate that the value is a number
        if type(value) ~= "number" then
            logger.resolver_error("editor.scroll-lines", "must be a number, got: " .. type(value))
            return
        end
        
        -- Validate that the value is positive
        if value <= 0 then
            logger.resolver_error("editor.scroll-lines", "must be positive, got: " .. tostring(value))
            return
        end
        
        -- Set scroll wheel behavior
        vim.opt.scroll = value
        
        -- Configure scroll wheel mappings for precise control
        vim.keymap.set({'n', 'v'}, '<ScrollWheelUp>', '<C-y>', { desc = 'Scroll up' })
        vim.keymap.set({'n', 'v'}, '<ScrollWheelDown>', '<C-e>', { desc = 'Scroll down' })
        
        -- Set the number of lines to scroll
        vim.cmd(string.format('set scroll=%d', value))
        
        logger.resolver_success("editor.scroll-lines", tostring(value) .. " lines per scroll step")
    end)
    
    -- Auto-format resolver - Automatic formatting on save
    resolvers.define_resolver("editor.auto-format", function(value)
        -- Validate that the value is a boolean
        if type(value) ~= "boolean" then
            logger.resolver_error("editor.auto-format", "must be a boolean, got: " .. type(value))
            return
        end
        
        if value then
            -- Enable auto-formatting using LSP and conform.nvim if available
            local conform_ok, conform = pcall(require, "conform")
            if conform_ok then
                -- Use conform.nvim for formatting
                vim.api.nvim_create_autocmd("BufWritePre", {
                    pattern = "*",
                    callback = function(args)
                        conform.format({ bufnr = args.buf })
                    end,
                    desc = "Auto-format on save using conform.nvim"
                })
                logger.resolver_success("editor.auto-format", "enabled with conform.nvim")
            else
                -- Fallback to LSP formatting
                vim.api.nvim_create_autocmd("BufWritePre", {
                    pattern = "*",
                    callback = function()
                        vim.lsp.buf.format({ timeout_ms = 2000 })
                    end,
                    desc = "Auto-format on save using LSP"
                })
                logger.resolver_success("editor.auto-format", "enabled with LSP formatting")
            end
        else
            -- Disable auto-formatting by clearing the autocommand
            vim.api.nvim_clear_autocmds({ pattern = "*", event = "BufWritePre" })
            logger.resolver_success("editor.auto-format", "disabled")
        end
    end)
    
    -- Continue comments resolver - Automatically continue comments on new lines
    resolvers.define_resolver("editor.continue-comments", function(value)
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
    end)
    
    -- Cursor column resolver - Show/hide cursor column
    resolvers.define_resolver("editor.cursorcolumn", function(value)
        -- Validate that the value is a boolean
        if type(value) ~= "boolean" then
            logger.resolver_error("editor.cursorcolumn", "must be a boolean, got: " .. type(value))
            return
        end
        
        -- Set cursor column option
        vim.opt.cursorcolumn = value
        
        logger.resolver_success("editor.cursorcolumn", value and "enabled" or "disabled")
    end)
    
    -- Gutters resolver - Configure editor gutters (diagnostics, line-numbers, diff)
    resolvers.define_resolver("editor.gutters", function(value)
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
                vim.opt.signcolumn = "yes:2"  -- Allow two signs per line
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
                virtual_text = false,  -- Keep virtual text off by default
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
    end)
    
    -- Path completion resolver - Enable path completion
    resolvers.define_resolver("editor.path-completion", function(value)
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
    end)
    
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
                vim.opt.signcolumn = "yes:2"  -- Allow two signs per line
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
                virtual_text = false,  -- Keep virtual text off by default
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
    for i = 1, 10 do
        resolvers.define_resolver("editor.gutters." .. i, create_gutter_item_resolver(i))
    end
end

return {
    register_editor_resolvers = register_editor_resolvers
}
