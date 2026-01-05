local resolvers = require("autoconf.sys.core.resolvers")
local M = {}

-- Function to register all command resolvers
M.register_command_resolvers = function()
    -- File pickers
    local ok_builtin, builtin = pcall(require, "telescope.builtin")

    if ok_builtin then
        resolvers.define_command_resolver("file_picker", builtin.find_files)
        resolvers.define_command_resolver("global_search", builtin.live_grep)
        resolvers.define_command_resolver("buffer_picker", builtin.buffers)
        resolvers.define_command_resolver("diagnostics_picker", {
            cmd = ":lua require('telescope.builtin').diagnostics({ bufnr=0 })<CR>",
            opts = { noremap = true, silent = true }
        })
    end

    local ok_comment, api = pcall(require, "Comment.api")
    if ok_comment then
        resolvers.define_command_resolver("toggle_comments",
            {
                per_mode = {
                    n = api.toggle.linewise.current,
                },
                fn = function()
                    local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
                    vim.api.nvim_feedkeys(esc, "nx", false)
                    api.locked("toggle.linewise")(vim.fn.visualmode())
                    return vim.cmd("normal! gv")
                end
            })
    end
    resolvers.define_command_resolver("paste_over_selection", "\"_dP")
    resolvers.define_command_resolver("substitute_word_globally",
        ":%s/\\<<C-r><C-w>\\>/\\<C-r><C-w>/gI<Left><Left><Left>")
    resolvers.define_command_resolver("substitute_word_line",
        ":s/\\<<C-r><C-w>\\>/\\<C-r><C-w>/gI<Left><Left><Left>")
    resolvers.define_command_resolver("indent_right", {
        per_mode = {
            n = {
                cmd = ">>",
                opts = { noremap = true, silent = true }
            }
        },
        cmd = ">gv",
        opts = { noremap = true, silent = true }
    })
    resolvers.define_command_resolver("indent_left", {
        per_mode = {
            n = {
                cmd = "<<",
                opts = { noremap = true, silent = true }
            }
        },
        cmd = "<gv",
        opts = { noremap = true, silent = true }
    })
    resolvers.define_command_resolver("yank_main_selection_to_clipboard", function()
        -- Check if we're in SSH/Mosh environment
        local is_remote = os.getenv("SSH_CONNECTION") or os.getenv("SSH_CLIENT") or os.getenv("MOSH_SESSION")

        if is_remote then
            -- Use OSC52 for remote connections
            local mode = vim.fn.mode()
            local lines = {}

            if mode == 'v' or mode == 'V' or mode == '\22' then  -- \22 is visual-block mode
                -- We're in visual mode, get the current selection
                -- First yank to a register to get the text
                vim.cmd('normal! "ay')
                lines = vim.fn.split(vim.fn.getreg('a'), '\n')
            else
                -- Not in visual mode, try to get previous visual selection
                local start_pos = vim.fn.getpos("'<")
                local end_pos = vim.fn.getpos("'>")

                -- Validate positions
                if start_pos[2] == 0 or end_pos[2] == 0 then
                    -- No valid visual selection, fallback to current line
                    lines = {vim.fn.getline('.')}
                else
                    local start_line, start_col = start_pos[2], start_pos[3]
                    local end_line, end_col = end_pos[2], end_pos[3]

                    -- Get lines and validate
                    local raw_lines = vim.fn.getline(start_line, end_line)
                    if type(raw_lines) == 'table' and #raw_lines > 0 then
                        lines = raw_lines

                        -- Trim selection boundaries for characterwise selection
                        if start_line == end_line then
                            -- Single line selection
                            if type(lines[1]) == 'string' and start_col > 0 and end_col > 0 then
                                lines[1] = string.sub(lines[1], start_col, end_col)
                            end
                        else
                            -- Multi-line selection
                            if type(lines[1]) == 'string' and start_col > 0 then
                                lines[1] = string.sub(lines[1], start_col)
                            end
                            if type(lines[#lines]) == 'string' and end_col > 0 then
                                lines[#lines] = string.sub(lines[#lines], 1, end_col)
                            end
                        end
                    else
                        -- Fallback to current line
                        lines = {vim.fn.getline('.')}
                    end
                end
            end

            -- Ensure we have valid lines
            if #lines == 0 or not lines[1] then
                lines = {vim.fn.getline('.')}
            end

            -- Copy using OSC52 with tmux-aware output
            local text = table.concat(lines, '\n')
            local encoded = vim.base64.encode(text)
            local osc52_seq = string.format('\027]52;c;%s\027\\', encoded)

            -- If inside tmux, write directly to the client's tty for reliable passthrough
            local tmux = os.getenv("TMUX")
            if tmux then
                local handle = io.popen("tmux display-message -p '#{client_tty}'")
                if handle then
                    local tty = handle:read("*l")
                    handle:close()
                    if tty and tty ~= "" then
                        local tty_handle = io.open(tty, "w")
                        if tty_handle then
                            tty_handle:write(osc52_seq)
                            tty_handle:close()
                        end
                    end
                end
            else
                -- Not in tmux, use Neovim's built-in OSC52
                require("vim.ui.clipboard.osc52").copy("+")(lines)
            end

            -- Switch to normal mode
            if mode ~= 'n' then
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
            end
        else
            -- Use system clipboard for local connections and switch to normal mode
            vim.cmd('normal! "+y')
            local mode = vim.fn.mode()
            if mode ~= 'n' then
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
            end
        end
    end)

    resolvers.define_command_resolver("replace_with_yanked",
        { cmd = "c", opts = { noremap = true, silent = true } })

    resolvers.define_command_resolver("redo", { cmd = "<C-r>", opts = { noremap = true, silent = true } })
    resolvers.define_command_resolver("move_selection_down", ":m '>+1<CR>gv=gv")
    resolvers.define_command_resolver("move_selection_up", ":m '<-2<CR>gv=gv")
    resolvers.define_command_resolver("visual_escape", { cmd = "<Esc>", opts = { noremap = true, silent = true } })


    local function lsp_cmd(v)
        return string.format("<cmd>lua %s()<CR>", v)
    end

    -- lsp commands
    resolvers.define_command_resolver("hover", {
        on_lsp_attach = true,
        cmd = lsp_cmd("vim.lsp.buf.hover")
    })
    resolvers.define_command_resolver("rename_symbol", {
        on_lsp_attach = true,
        cmd = lsp_cmd("vim.lsp.buf.rename")
    })
    resolvers.define_command_resolver("code_action", {
        on_lsp_attach = true,
        cmd = lsp_cmd("vim.lsp.buf.code_action")
    })
    resolvers.define_command_resolver("diagnostic_open_float", {
        on_lsp_attach = true,
        cmd = lsp_cmd("vim.diagnostic.open_float")
    })
    resolvers.define_command_resolver("goto_definition", {
        on_lsp_attach = true,
        cmd = lsp_cmd("vim.lsp.buf.definition")
    })
    resolvers.define_command_resolver("goto_type_definition", {
        on_lsp_attach = true,
        cmd = lsp_cmd("vim.lsp.buf.type_definition")
    })
    resolvers.define_command_resolver("goto_reference", {
        on_lsp_attach = true,
        cmd = lsp_cmd("vim.lsp.buf.references")
    })
    resolvers.define_command_resolver("goto_implementation", {
        on_lsp_attach = true,
        cmd = lsp_cmd("vim.lsp.buf.implementation")
    })

    -- Sudo write command
    resolvers.define_command_resolver("sudo_write", function()
        require("autoconf.sys.core.sudo_write").write()
    end)
end

return M
