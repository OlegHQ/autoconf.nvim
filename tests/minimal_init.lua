local source = debug.getinfo(1, "S").source:sub(2)
local tests_root = vim.fn.fnamemodify(source, ":p:h")
local plugin_root = vim.fn.fnamemodify(tests_root, ":h")
vim.o.loadplugins = false
vim.o.undofile = false
vim.o.swapfile = false
vim.opt.runtimepath:prepend(plugin_root)
