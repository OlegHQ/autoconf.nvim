local M = {}

-- Cache require calls at the top
local ok_treesitter, treesitter_configs
local ok_comment, comment

-- Try loading the required modules
ok_treesitter, treesitter_configs = pcall(require, "nvim-treesitter.configs")
ok_comment, comment = pcall(require, "Comment")

M.init_base = function()
    vim.cmd("set shortmess+=I")
    vim.g.mapleader = " "
    vim.g.maplocalleader = ","

    vim.opt.fillchars:append({ eob = " " })
end

M.init_tree_sitter = function()
    if not ok_treesitter then
        return
    end

    treesitter_configs.setup({
        highlight = {
            enable = true,
            disable = { "" },
            additional_vim_regex_highlighting = false
        },
        ident = { enable = true }
    })
end

M.init_comment = function()
    if not ok_comment then
        return
    end

    comment.setup()
    vim.keymap.del("n", "gcc")
end

return M
