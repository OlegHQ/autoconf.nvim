local cfg = {
    editor = {
        guicursor = "", tabstop = 4, softtabstop = 4, shiftwidth = 2, expandtab = true, smartindent = true, nu = true, relativenumber = true, undofile = true, incsearch = true, termguicolors = true, backup = false, hlsearch = false, swapfile = false, wrap = false },
    languages = {
        fennel = {},
        c = {},
        cucumber = { formatter = "prettier" },
        swift = { lsp = "sourcekit", formatter = "swiftformat" },
        ocaml = { lsp = "ocamllsp", formatter = "ocamlformat" },
        python = { lsp = "pyright", formatter = "black", tab = { width = 4, expand = true } },
        typescript = { lsp = "ts_ls", formatter = "biome", tab = { width = 4, expand = false } },
        mojo = { formatter = "mojo_format", lsp = "mojo", tab = { width = 4, expand = true } },
        javascript = { lsp = "ts_ls", formatter = "biome" },
        go = { lsp = "gopls", formatter = { "goimports", "gofmt" } },
        rust = {}
    },
    features = { ["nvim-treesitter"] = true, Comment = true, telescope = true, ["nvim-cmp"] = true, conform = true, ["nvim-lspconfig"] = true, gitsigns = true },
    themes = { ["catppuccin-latte"] = true }
}
local default_lang_settings = {
    filetypes = {
        typescript = { "typescript", "typescriptreact" } },
    tabs = {
        go = { width = 4, expand = false },
        javascript = { width = 2, expand = true },
        typescript = { width = 2, expand = true },
        python = { width = 4, expand = true }
    }
}
local function feature(name)
    local f = cfg.features
    if f then
        return f[name]
    else
        return false
    end
end
for k, v in pairs(cfg.editor) do
    vim.opt[k] = v
end
if feature("nvim-treesitter") then
    local configs = require("nvim-treesitter.configs")
    configs.setup({
        highlight = {
            enable = true,
            disable = { "" },
            additional_vim_regex_highlighting = false
        },
        ident = { enable = true }
    })
else
end
if feature("Comment") then
    local cmt = require("Comment")
    local api = require("Comment.api")
    cmt.setup()
    vim.keymap.del("n", "gcc")
    local function _7_()
        return api.toggle.linewise.current()
    end
    vim.keymap.set("n", "<C-c>", _7_)
    local function _8_()
        local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
        vim.api.nvim_feedkeys(esc, "nx", false)
        api.locked("toggle.linewise")(vim.fn.visualmode())
        return vim.cmd("normal! gv")
    end
    vim.keymap.set("x", "<C-c>", _8_, { desc = "Comment toggle linewise (visual) and preserve the visual selection" })
else
end
vim.cmd("set shortmess+=I")
vim.g.mapleader = " "
vim.g.maplocalleader = ","
do
    local s_21 = vim.keymap.set
    if feature("telescope") then
        local builtin = require("telescope.builtin")
        s_21("n", "<leader>f", builtin.find_files, {})
        s_21("n", "<leader>/", builtin.live_grep, {})
        s_21("n", "<leader>d", ":lua require('telescope.builtin').diagnostics({ bufnr=0 })<CR>",
            { noremap = true, silent = true })
        s_21("n", "<leader>b", builtin.buffers, {})
    else
    end
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
local function setup_tabs(languages, defaults)
    local tabset_group = vim.api.nvim_create_augroup("tabset", { clear = true })
    for name, c in pairs(languages) do
        local lang_setting = c.tab
        local tabsettings
        if not lang_setting then
            tabsettings = defaults.tabs[name]
        else
            tabsettings = lang_setting
        end
        local settings
        if not tabsettings then
            settings = { width = 4, expand = true }
        else
            settings = tabsettings
        end
        local width = settings.width
        local expand = settings.expand
        local ft = defaults.filetypes[name]
        local types
        if not ft then
            types = { name }
        else
            types = ft
        end
        for _, t in ipairs(types) do
            local function _31_()
                vim.opt["tabstop"] = width
                vim.opt["shiftwidth"] = width
                vim.opt["expandtab"] = expand
                return nil
            end
            vim.api.nvim_create_autocmd("FileType", { group = tabset_group, pattern = t, callback = _31_ })
        end
    end
    return nil
end
setup_tabs(cfg.languages, default_lang_settings)
if feature("gitsigns") then
    local gitsigns = require("gitsigns")
    return gitsigns.setup()
else
    return nil
end
