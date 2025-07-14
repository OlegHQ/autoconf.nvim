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

M.text_width = function(value)
    -- Validate that the value is a number
    if type(value) ~= "number" then
        logger.resolver_error("editor.text-width", "must be a number, got: " .. type(value))
        return
    end

    -- Set text width like Helix editor's maximum line length
    -- Used for :reflow command and soft-wrapping
    vim.opt.textwidth = value
    
    -- Enable soft wrapping at text width (similar to Helix soft-wrap.wrap-at-text-width)
    vim.opt.wrap = true
    vim.opt.linebreak = true
    vim.opt.breakindent = true
    
    -- Set wrapping to respect the text width
    vim.opt.wrapmargin = 0

    logger.resolver_success("editor.text-width", tostring(value) .. " characters (with visual indicator and soft-wrap)")
end

-- Formatting-related functions will be moved here
M.whitespace = function(config)
    -- Validate config structure
    if type(config) ~= "table" then
        logger.resolver_error("editor.whitespace", "must be a table, got: " .. type(config))
        return
    end

    -- Initialize listchars components
    local listchars = {}

    -- Handle render option
    local render = config.render
    if render == "all" then
        -- Show all whitespace types with Unicode characters from config
        listchars.space = "·"
        listchars.tab = "→·"
        listchars.eol = "⏎"
        listchars.trail = "·"
    elseif render == "none" then
        -- Disable all whitespace rendering
        vim.o.list = false
        logger.resolver_success("editor.whitespace", "disabled")
        return
    elseif type(render) == "table" then
        -- Handle specific render settings
        if render.space == "all" then listchars.space = "·" end
        if render.tab == "all" then listchars.tab = "→·" end
        if render.newline == "all" then listchars.eol = "⏎" end
    end

    -- Apply custom characters if provided
    local chars = config.characters
    if type(chars) == "table" then
        if chars.space then
            listchars.space = chars.space
            listchars.trail = chars.space  -- Use same character for trailing spaces
        end
        if chars.newline then
            listchars.eol = chars.newline
        end
        if chars.tab and chars.tabpad then
            listchars.tab = chars.tab .. chars.tabpad
        elseif chars.tab then
            listchars.tab = chars.tab .. "·"
        end
        -- Note: nbsp and nnbsp are not standard listchars options in Neovim
        -- They would need to be handled differently (e.g., with syntax highlighting)
    end

    -- Build listchars string with only valid Neovim listchars options
    local listchars_parts = {}
    local valid_keys = {
        space = true, tab = true, eol = true, trail = true,
        extends = true, precedes = true, nbsp = true
    }
    
    for k, v in pairs(listchars) do
        if valid_keys[k] and type(k) == "string" and type(v) == "string" and k ~= "" and v ~= "" then
            table.insert(listchars_parts, k .. ":" .. v)
        end
    end
    
    -- Only set listchars if we have valid content
    if #listchars_parts > 0 then
        local listchars_str = table.concat(listchars_parts, ",")
        
        -- Try to set listchars
        local success, err = pcall(function()
            vim.o.listchars = listchars_str
            vim.o.list = true
        end)
        
        if not success then
            logger.resolver_error("editor.whitespace", "failed to set listchars '" .. listchars_str .. "': " .. tostring(err))
            -- Fallback: use basic settings that should always work
            pcall(function()
                vim.o.listchars = "tab:>-,trail:~,eol:$"
                vim.o.list = true
            end)
            logger.resolver_success("editor.whitespace", "configured with fallback settings")
            return
        end
        
        logger.resolver_success("editor.whitespace", "configured with listchars: " .. listchars_str)
    else
        -- If no listchars specified, disable list mode
        vim.o.list = false
        logger.resolver_success("editor.whitespace", "disabled (no valid listchars)")
    end
end

return M
