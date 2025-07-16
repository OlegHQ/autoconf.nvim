local resolvers = require("sys.core.resolvers")
local M = {}

-- Function to register all command resolvers
M.register_command_resolvers = function()
    -- File pickers
    local builtin = require("telescope.builtin")
    resolvers.define_command_resolver("file_picker", function(_) return builtin.find_files, nil end)
    resolvers.define_command_resolver("global_search", function(_) return builtin.live_grep, nil end)
    resolvers.define_command_resolver("buffer_picker", function(_) return builtin.buffers, nil end)
    resolvers.define_command_resolver("diagnostics_picker", function(_)
        return ":lua require('telescope.builtin').diagnostics({ bufnr=0 })<CR>", { noremap = true, silent = true }
    end)

    resolvers.define_command_resolver("toggle_comments", function(mode)
        local api = require("Comment.api")
        if mode == "n" then
            return function()
                return api.toggle.linewise.current()
            end, nil
        else
            return function()
                local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
                vim.api.nvim_feedkeys(esc, "nx", false)
                api.locked("toggle.linewise")(vim.fn.visualmode())
                return vim.cmd("normal! gv")
            end, nil
        end
    end)

    resolvers.define_command_resolver("paste_over_selection", function(_) return "\"_dP", nil end)
    resolvers.define_command_resolver("substitute_word_globally",
        function(_) return ":%s/\\<<C-r><C-w>\\>/\\<C-r><C-w>/gI<Left><Left><Left>", nil end)
    resolvers.define_command_resolver("substitute_word_line",
        function(_) return ":s/\\<<C-r><C-w>\\>/\\<C-r><C-w>/gI<Left><Left><Left>", nil end)
    resolvers.define_command_resolver("indent_right", function(mode)
        if mode == "n" then
            return ">>", { noremap = true, silent = true }
        else
            return ">gv", { noremap = true, silent = true }
        end
    end)
    resolvers.define_command_resolver("indent_left", function(mode)
        if mode == "n" then
            return "<<", { noremap = true, silent = true }
        else
            return "<gv", { noremap = true, silent = true }
        end
    end)
    resolvers.define_command_resolver("yank_main_selection_to_clipboard",
        function(_) return "\"+y$", { noremap = true, silent = true } end)

    resolvers.define_command_resolver("replace_with_yanked",
        function(_) return "c", { noremap = true, silent = true } end)

    resolvers.define_command_resolver("redo", function(_) return "<C-r>", { noremap = true, silent = true } end)
resolvers.define_command_resolver("move_selection_down", function(_) return ":m '>+1<CR>gv=gv", nil end)
resolvers.define_command_resolver("move_selection_up", function(_) return ":m '<-2<CR>gv=gv", nil end)
resolvers.define_command_resolver("visual_escape", function(_) return "<Esc>", { noremap = true, silent = true } end)
end

return M
