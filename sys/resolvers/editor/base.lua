local logger = require("sys.core.logger")
local M = {}



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



M.auto_save = function(config)
    -- Validate config structure
    if type(config) ~= "table" then
        logger.resolver_error("editor.auto-save", "must be a table, got: " .. type(config))
        return
    end

    -- Clear any existing auto-save autocmds
    vim.api.nvim_clear_autocmds({ pattern = "*", event = { "FocusLost", "CursorHold" } })

    -- Handle focus-lost auto-save
    local focus_lost = config["focus-lost"]
    if type(focus_lost) == "boolean" and focus_lost then
        vim.api.nvim_create_autocmd("FocusLost", {
            pattern = "*",
            callback = function()
                vim.cmd("silent! wall")
            end,
            desc = "Auto-save on focus lost"
        })
    end

    -- Handle after-delay auto-save
    local after_delay = config["after-delay"]
    if type(after_delay) == "table" and after_delay.enable then
        local timeout = tonumber(after_delay.timeout) or 3000
        vim.api.nvim_create_autocmd("CursorHold", {
            pattern = "*",
            callback = function()
                vim.cmd("silent! update")
            end,
            desc = "Auto-save after delay",
            group = vim.api.nvim_create_augroup("AutoSaveAfterDelay", { clear = true })
        })
        vim.opt.updatetime = timeout
    end

    logger.resolver_success("editor.auto-save", "configured")
end

return M
