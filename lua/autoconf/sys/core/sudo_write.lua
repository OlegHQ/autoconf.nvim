-- Sudo write functionality with floating terminal for password entry
local M = {}

function M.write()
    local filepath = vim.fn.expand("%:p")
    local original_buf = vim.api.nvim_get_current_buf()

    -- Validate file path
    if filepath == "" then
        vim.notify("No file to save", vim.log.levels.ERROR)
        return
    end

    -- Get buffer content
    local lines = vim.api.nvim_buf_get_lines(original_buf, 0, -1, false)

    -- Write to temp file
    local temp = os.tmpname()
    local ok = vim.fn.writefile(lines, temp)
    if ok ~= 0 then
        vim.notify("Failed to create temp file", vim.log.levels.ERROR)
        return
    end

    -- Create floating window
    local buf = vim.api.nvim_create_buf(false, true)
    local width = math.min(60, math.floor(vim.o.columns * 0.6))
    local height = 6
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        col = math.floor((vim.o.columns - width) / 2),
        row = math.floor((vim.o.lines - height) / 2),
        style = "minimal",
        border = "rounded",
        title = " Sudo Write ",
        title_pos = "center",
    })

    -- Escape filepath for shell
    local escaped_path = filepath:gsub("'", "'\\''")
    local escaped_temp = temp:gsub("'", "'\\''")

    -- Build command: copy temp to target, then cleanup
    -- Use full path to sudo and run via shell to ensure proper PATH
    local cmd = string.format(
        "/usr/bin/sudo cp '%s' '%s' && rm '%s' && echo '' && echo '✓ Saved successfully!' || (rm '%s' 2>/dev/null; echo '' && echo '✗ Save failed')",
        escaped_temp, escaped_path, escaped_temp, escaped_temp
    )

    -- Run in terminal with proper shell
    vim.fn.termopen({ "/bin/sh", "-c", cmd }, {
        on_exit = function(_, exit_code, _)
            vim.schedule(function()
                if exit_code == 0 then
                    -- Mark original buffer as saved
                    if vim.api.nvim_buf_is_valid(original_buf) then
                        vim.bo[original_buf].modified = false
                    end
                end

                -- Auto-close after delay
                vim.defer_fn(function()
                    if vim.api.nvim_win_is_valid(win) then
                        vim.api.nvim_win_close(win, true)
                    end
                    if vim.api.nvim_buf_is_valid(buf) then
                        vim.api.nvim_buf_delete(buf, { force = true })
                    end
                end, exit_code == 0 and 1000 or 3000)
            end)
        end
    })

    -- Enter terminal mode for password input
    vim.cmd("startinsert")
end

return M
