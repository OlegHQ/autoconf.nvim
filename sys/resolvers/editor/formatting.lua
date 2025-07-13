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

    -- Set text width and color column
    vim.opt.textwidth = value
    vim.opt.colorcolumn = tostring(value)

    logger.resolver_success("editor.text-width", tostring(value) .. " characters")
end

-- Formatting-related functions will be moved here
return M
