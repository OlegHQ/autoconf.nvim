local M = {}

M.init_base = function()
    vim.cmd("set shortmess+=I")
    vim.g.mapleader = " "
    vim.g.maplocalleader = ","

    vim.opt.fillchars:append({ eob = " " })
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

return M
