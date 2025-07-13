local logger = require("sys.core.logger")

local M = {}

M.auto_format = function(value)
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
end

M.scroll_lines = function(value)
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
    vim.keymap.set({ 'n', 'v' }, '<ScrollWheelUp>', '<C-y>', { desc = 'Scroll up' })
    vim.keymap.set({ 'n', 'v' }, '<ScrollWheelDown>', '<C-e>', { desc = 'Scroll down' })

    -- Set the number of lines to scroll
    vim.cmd(string.format('set scroll=%d', value))

    logger.resolver_success("editor.scroll-lines", tostring(value) .. " lines per scroll step")
end

M.middle_click_paste = function(value)
    -- Validate that the value is a boolean
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.middle-click-paste", "must be a boolean, got: " .. type(value))
        return
    end

    -- Configure middle-click paste behavior
    if value then
        -- Enable middle-click paste
        vim.keymap.set({ 'n', 'v' }, '<MiddleMouse>', '<MiddleMouse>', { desc = 'Middle click paste' })
        vim.keymap.set('i', '<MiddleMouse>', '<C-r>*', { desc = 'Middle click paste in insert mode' })
    else
        -- Disable middle-click paste by mapping to nothing
        vim.keymap.set({ 'n', 'v', 'i' }, '<MiddleMouse>', '<Nop>', { desc = 'Disable middle click paste' })
    end

    logger.resolver_success("editor.middle-click-paste", value and "enabled" or "disabled")
end

M.default_yank_register = function(value)
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
end

M.scrolloff = function(value)
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

M.cursorcolumn = function(value)
    -- Validate that the value is a boolean
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.cursorcolumn", "must be a boolean, got: " .. type(value))
        return
    end

    -- Set cursor column option
    vim.opt.cursorcolumn = value

    logger.resolver_success("editor.cursorcolumn", value and "enabled" or "disabled")
end

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

M.atomic_save = function(value)
    -- Validate that the value is a boolean
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.atomic-save", "must be a boolean, got: " .. type(value))
        return
    end

    if value then
        -- Enable atomic saves using backup files
        vim.opt.backup = true
        vim.opt.writebackup = true
        vim.opt.backupdir = vim.fn.stdpath("cache") .. "/backup"

        -- Create backup directory if it doesn't exist
        local backup_dir = vim.fn.stdpath("cache") .. "/backup"
        if vim.fn.isdirectory(backup_dir) == 0 then
            vim.fn.mkdir(backup_dir, "p")
        end

        logger.resolver_success("editor.atomic-save", "enabled with backup files")
    else
        vim.opt.backup = false
        vim.opt.writebackup = false
        logger.resolver_success("editor.atomic-save", "disabled")
    end
end

M.auto_info = function(value)
    -- Validate that the value is a boolean
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.auto-info", "must be a boolean, got: " .. type(value))
        return
    end

    if value then
        -- Enable auto-info by configuring LSP hover
        vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
            vim.lsp.handlers.hover, {
                border = "rounded",
                focusable = false,
                style = "minimal",
            }
        )

        -- Auto-show hover info on cursor hold
        vim.api.nvim_create_autocmd("CursorHold", {
            pattern = "*",
            callback = function()
                local clients = vim.lsp.get_clients({ bufnr = 0 })
                if #clients > 0 then
                    vim.lsp.buf.hover()
                end
            end,
            desc = "Auto-show hover info"
        })

        logger.resolver_success("editor.auto-info", "enabled with LSP hover")
    else
        -- Disable auto-info
        vim.api.nvim_clear_autocmds({ pattern = "*", event = "CursorHold" })
        logger.resolver_success("editor.auto-info", "disabled")
    end
end

M.bufferline = function(value)
    -- Validate that the value is a string
    if type(value) ~= "string" then
        logger.resolver_error("editor.bufferline", "must be a string (always/never/multiple), got: " .. type(value))
        return
    end

    if value == "always" then
        -- Always show bufferline
        vim.opt.showtabline = 2

        -- Try to use bufferline.nvim if available
        local bufferline_ok, bufferline = pcall(require, "bufferline")
        if bufferline_ok then
            bufferline.setup({
                options = {
                    mode = "buffers",
                    numbers = "none",
                    close_command = "bdelete! %d",
                    right_mouse_command = "bdelete! %d",
                    left_mouse_command = "buffer %d",
                    middle_mouse_command = nil,
                    indicator = {
                        icon = '▎',
                        style = 'icon',
                    },
                    buffer_close_icon = '',
                    modified_icon = '●',
                    close_icon = '',
                    left_trunc_marker = '',
                    right_trunc_marker = '',
                    max_name_length = 18,
                    max_prefix_length = 15,
                    truncate_names = true,
                    tab_size = 18,
                    diagnostics = "nvim_lsp",
                    diagnostics_update_in_insert = false,
                    show_buffer_icons = true,
                    show_buffer_close_icons = true,
                    show_close_icon = true,
                    show_tab_indicators = true,
                    persist_buffer_sort = true,
                    separator_style = "slant",
                    enforce_regular_tabs = false,
                    always_show_bufferline = true,
                    sort_by = 'id'
                }
            })
            logger.resolver_success("editor.bufferline", "always enabled with bufferline.nvim")
        else
            logger.resolver_success("editor.bufferline", "always enabled with built-in tabline")
        end
    elseif value == "multiple" then
        -- Show bufferline only when multiple buffers
        vim.opt.showtabline = 1
        logger.resolver_success("editor.bufferline", "enabled for multiple buffers")
    else -- "never"
        -- Never show bufferline
        vim.opt.showtabline = 0
        logger.resolver_success("editor.bufferline", "disabled")
    end
end

M.color_modes = function(value)
    -- Validate that the value is a boolean
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.color-modes", "must be a boolean, got: " .. type(value))
        return
    end

    if value then
        -- Enable colored mode indicator (requires statusline plugin)
        vim.g.helix_color_modes = true
        logger.resolver_success("editor.color-modes", "enabled (requires statusline plugin support)")
    else
        vim.g.helix_color_modes = false
        logger.resolver_success("editor.color-modes", "disabled")
    end
end

M.undercurl = function(value)
    -- Validate that the value is a boolean
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.undercurl", "must be a boolean, got: " .. type(value))
        return
    end

    if value then
        -- Enable undercurl support
        vim.g.undercurl = true
        -- Set up undercurl highlight
        vim.cmd([[
                if &term =~ "xterm" || &term =~ "screen" || &term =~ "tmux"
                    let &t_Cs = "\e[4:3m"
                    let &t_Ce = "\e[4:0m"
                endif
            ]])
        logger.resolver_success("editor.undercurl", "enabled")
    else
        vim.g.undercurl = false
        logger.resolver_success("editor.undercurl", "disabled")
    end
end

M.true_color = function(value)
    -- Validate that the value is a boolean
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.true-color", "must be a boolean, got: " .. type(value))
        return
    end

    -- Set terminal GUI colors
    vim.opt.termguicolors = value

    logger.resolver_success("editor.true-color", value and "enabled" or "disabled")
end


M.trim_trailing_whitespace = function(value)
    -- Validate that the value is a boolean
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.trim-trailing-whitespace", "must be a boolean, got: " .. type(value))
        return
    end

    if value then
        -- Trim trailing whitespace on save
        vim.api.nvim_create_autocmd("BufWritePre", {
            pattern = "*",
            callback = function()
                local save_cursor = vim.fn.getpos(".")
                vim.cmd([[%s/\s\+$//e]])
                vim.fn.setpos(".", save_cursor)
            end,
            desc = "Trim trailing whitespace on save"
        })
        logger.resolver_success("editor.trim-trailing-whitespace", "enabled")
    else
        logger.resolver_success("editor.trim-trailing-whitespace", "disabled")
    end
end

M.trim_final_newlines = function(value)
    -- Validate that the value is a boolean
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.trim-final-newlines", "must be a boolean, got: " .. type(value))
        return
    end

    if value then
        -- Trim final newlines on save
        vim.api.nvim_create_autocmd("BufWritePre", {
            pattern = "*",
            callback = function()
                local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                local last_line = #lines

                -- Find the last non-empty line
                while last_line > 0 and lines[last_line] == "" do
                    last_line = last_line - 1
                end

                -- Remove trailing empty lines
                if last_line < #lines then
                    vim.api.nvim_buf_set_lines(0, last_line, -1, false, {})
                end
            end,
            desc = "Trim final newlines on save"
        })
        logger.resolver_success("editor.trim-final-newlines", "enabled")
    else
        logger.resolver_success("editor.trim-final-newlines", "disabled")
    end
end

M.text_width = function(value)
    -- Validate that the value is a number
    if type(value) ~= "number" then
        logger.resolver_error("editor.text-width", "must be a number, got: " .. type(value))
        return
    end

    -- Set text width and color column
    vim.opt.textwidth = value
    vim.opt.colorcolumn = tostring(value)

    logger.resolver_success("editor.text-width", tostring(value) .. " characters")
end

M.popup_border = function(value)
    -- Validate that the value is a string
    if type(value) ~= "string" then
        logger.resolver_error("editor.popup-border", "must be a string, got: " .. type(value))
        return
    end

    local border_style = value == "none" and "none" or "rounded"

    -- Configure LSP borders
    vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
        vim.lsp.handlers.hover, {
            border = border_style,
        }
    )

    vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
        vim.lsp.handlers.signature_help, {
            border = border_style,
        }
    )

    -- Configure diagnostic borders
    vim.diagnostic.config({
        float = {
            border = border_style,
        },
    })

    logger.resolver_success("editor.popup-border", value)
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

M.insert_final_newline = function(value)
    -- Validate that the value is a boolean
    if type(value) ~= "boolean" then
        logger.resolver_error("editor.insert-final-newline", "must be a boolean, got: " .. type(value))
        return
    end

    if value then
        -- Add final newline on save
        vim.opt.fixendofline = true
        vim.api.nvim_create_autocmd("BufWritePre", {
            pattern = "*",
            callback = function()
                local lines = vim.api.nvim_buf_get_lines(0, -2, -1, false)
                if #lines > 0 and lines[1] ~= "" then
                    vim.api.nvim_buf_set_lines(0, -1, -1, false, { "" })
                end
            end,
            desc = "Insert final newline on save"
        })
        logger.resolver_success("editor.insert-final-newline", "enabled")
    else
        vim.opt.fixendofline = false
        logger.resolver_success("editor.insert-final-newline", "disabled")
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

M.idle_timeout = function(value)
    -- Validate that the value is a number
    if type(value) ~= "number" then
        logger.resolver_error("editor.idle-timeout", "must be a number, got: " .. type(value))
        return
    end

    -- Set updatetime for CursorHold events
    vim.opt.updatetime = value
    logger.resolver_success("editor.idle-timeout", tostring(value) .. "ms")
end

M.end_of_line_diagnostics = function(value)
    -- Validate that the value is a string
    if type(value) ~= "string" then
        logger.resolver_error("editor.end-of-line-diagnostics", "must be a string, got: " .. type(value))
        return
    end

    if value == "disable" then
        -- Disable end-of-line diagnostics
        vim.diagnostic.config({
            virtual_text = false,
        })
        logger.resolver_success("editor.end-of-line-diagnostics", "disabled")
    else
        -- Enable end-of-line diagnostics with severity filter
        local severity_map = {
            error = vim.diagnostic.severity.ERROR,
            warning = vim.diagnostic.severity.WARN,
            info = vim.diagnostic.severity.INFO,
            hint = vim.diagnostic.severity.HINT,
        }

        local min_severity = severity_map[value]
        if min_severity then
            vim.diagnostic.config({
                virtual_text = {
                    severity = { min = min_severity },
                    prefix = "●",
                    spacing = 4,
                },
            })
            logger.resolver_success("editor.end-of-line-diagnostics", "enabled for " .. value .. " and above")
        else
            logger.resolver_error("editor.end-of-line-diagnostics", "unknown severity level: " .. value)
        end
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

M.default_line_ending = function(value)
    -- Validate that the value is a string
    if type(value) ~= "string" then
        logger.resolver_error("editor.default-line-ending", "must be a string, got: " .. type(value))
        return
    end

    -- Map Helix line ending names to Neovim fileformat
    local format_map = {
        native = vim.fn.has("win32") == 1 and "dos" or "unix",
        lf = "unix",
        crlf = "dos",
        cr = "mac",
        ff = "unix",  -- Form feed (treat as unix)
        nel = "unix", -- Next line (treat as unix)
    }

    local fileformat = format_map[value]
    if fileformat then
        vim.opt.fileformat = fileformat
        vim.opt.fileformats = fileformat
        logger.resolver_success("editor.default-line-ending", value .. " (" .. fileformat .. ")")
    else
        logger.resolver_error("editor.default-line-ending", "unknown line ending format: " .. value)
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

return M
