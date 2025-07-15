local M = {}

M.init_base = function()
    vim.cmd("set shortmess+=I")
    vim.g.mapleader = " "
    vim.g.maplocalleader = ","
end

M.init_tree_sitter = function()
    local configs = require("nvim-treesitter.configs")
    configs.setup({
        highlight = {
            enable = true,
            disable = { "" },
            additional_vim_regex_highlighting = false
        },
        ident = { enable = true }
    })
end

M.init_comment = function()
    local cmt = require("Comment")
    cmt.setup()
    vim.keymap.del("n", "gcc")
end

M.init_default_keymaps = function()
    local s_21 = vim.keymap.set
    -- if feature("telescope") then
    local builtin = require("telescope.builtin")
    s_21("n", "<leader>/", builtin.live_grep, {})
    s_21("n", "<leader>d", ":lua require('telescope.builtin').diagnostics({ bufnr=0 })<CR>",
        { noremap = true, silent = true })
    s_21("n", "<leader>b", builtin.buffers, {})
    -- else
    -- end
    s_21("x", "<leader>p", "\"_dP")
    s_21("n", "<leader>s", ":%s/\\<<C-r><C-w>\\>/\\<C-r><C-w>/gI<Left><Left><Left>")
    s_21("n", "<leader>S", ":s/\\<<C-r><C-w>\\>/\\<C-r><C-w>/gI<Left><Left><Left>")
    s_21("n", ">", ">>", { noremap = true, silent = true })
    s_21("v", ">", ">gv", { noremap = true, silent = true })
    s_21("n", "<", "<<", { noremap = true, silent = true })
    s_21("v", "<", "<gv", { noremap = true, silent = true })
    s_21("v", "<leader>Y", "\"+y$", { noremap = true, silent = true })
    s_21("v", "<S-R>", "c", { noremap = true, silent = true })
    s_21("n", "<S-U>", "<C-r>", { noremap = true, silent = true })
    s_21("v", "J", ":m '>+1<CR>gv=gv")
    s_21("v", "K", ":m '<-2<CR>gv=gv")
    s_21("v", ",", "<Esc>", { noremap = true, silent = true })
end

return M
