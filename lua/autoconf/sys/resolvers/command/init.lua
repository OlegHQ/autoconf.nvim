local resolvers = require("autoconf.sys.core.resolvers")
local M = {}

-- Function to register all command resolvers
M.register_command_resolvers = function()
    -- File pickers
    local builtin = require("telescope.builtin")
    resolvers.define_command_resolver("file_picker", builtin.find_files)
    resolvers.define_command_resolver("global_search", builtin.live_grep)
    resolvers.define_command_resolver("buffer_picker", builtin.buffers)
    resolvers.define_command_resolver("diagnostics_picker", {
        cmd = ":lua require('telescope.builtin').diagnostics({ bufnr=0 })<CR>",
        opts = { noremap = true, silent = true }
    })

    local api = require("Comment.api")
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
    resolvers.define_command_resolver("yank_main_selection_to_clipboard",
        { cmd = "\"+y$", opts = { noremap = true, silent = true } })

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
        fn = lsp_cmd("vim.lsp.buf.rename")
    })
    resolvers.define_command_resolver("code_action", {
        on_lsp_attach = true,
        fn = lsp_cmd("vim.lsp.buf.code_action")
    })
    resolvers.define_command_resolver("diagnostic_open_float", {
        on_lsp_attach = true,
        fn = lsp_cmd("vim.diagnostic.open_float")
    })
    resolvers.define_command_resolver("goto_definition", {
        on_lsp_attach = true,
        fn = lsp_cmd("vim.lsp.buf.definition")
    })
    resolvers.define_command_resolver("goto_type_definition", {
        on_lsp_attach = true,
        fn = lsp_cmd("vim.lsp.buf.type_definition")
    })
    resolvers.define_command_resolver("goto_reference", {
        on_lsp_attach = true,
        fn = lsp_cmd("vim.lsp.buf.references")
    })
    resolvers.define_command_resolver("goto_implementation", {
        on_lsp_attach = true,
        fn = lsp_cmd("vim.lsp.buf.implementation")
    })
end

return M
