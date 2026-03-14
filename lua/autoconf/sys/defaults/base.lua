local M = {}

M.init_base = function()
    vim.cmd("set shortmess+=I")
    vim.g.mapleader = " "
    vim.g.maplocalleader = ","

    -- Hide default mode display if lualine is installed
    if pcall(require, "lualine") then
        vim.opt.showmode = false
    end

    vim.opt.fillchars:append({ eob = " " })

    -- Enable cursorline with Helix-style (number only) highlighting
    vim.opt.cursorline = true
    vim.opt.cursorlineopt = 'number'

    -- Disable automatic line wrapping while typing
    vim.opt.formatoptions:remove({ "t", "c" })
end

M.init_tree_sitter = function()
    local ok_treesitter, treesitter_configs = pcall(require, "nvim-treesitter.configs")
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
    vim.cmd("silent! packadd comment.nvim")
    local ok_comment, comment = pcall(require, "Comment")
    if not ok_comment then
        return
    end

    comment.setup()
    vim.keymap.del("n", "gcc")
end

M.init_auto_mkdir = function()
    vim.api.nvim_create_autocmd({ "BufWritePre" }, {
        callback = function()
            local dir = vim.fn.expand("<afile>:p:h")
            if vim.fn.isdirectory(dir) == 0 then
                vim.fn.mkdir(dir, "p")
            end
        end,
    })
end

return M

