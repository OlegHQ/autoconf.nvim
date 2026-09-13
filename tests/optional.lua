local completion = require("autoconf.sys.resolvers.editor.completion")
local defaults_lsp = require("autoconf.sys.defaults.lsp")

defaults_lsp.setup_deferred({})
vim.api.nvim_exec_autocmds("InsertEnter", { modeline = false })
assert(completion.status().effective == "unavailable", "missing Blink is reported as unsupported")

defaults_lsp.setup_deferred({ lua = { formatter = "not-installed" } })
local buffer = vim.api.nvim_create_buf(true, false)
vim.bo[buffer].filetype = "lua"
vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "local value = 1" })
assert(defaults_lsp.format_buffer(buffer) == false, "missing Conform and LSP reports formatting unavailable")
assert(defaults_lsp.status().format_effective == "formatting unavailable",
    "health state does not claim formatting succeeded without a provider")

local get_clients = vim.lsp.get_clients
local lsp_format = vim.lsp.buf.format
local format_calls = 0
vim.lsp.get_clients = function(filter)
    if filter.method == "textDocument/formatting" then return { { name = "test_formatter" } } end
    return {}
end
vim.lsp.buf.format = function() format_calls = format_calls + 1 end
assert(defaults_lsp.format_buffer(buffer) == true, "available LSP formatter is used as fallback")
assert(format_calls == 1, "LSP fallback executes once")
assert(defaults_lsp.status().format_effective == "LSP formatting requested on demand",
    "health identifies the LSP fallback")
vim.lsp.get_clients = get_clients
vim.lsp.buf.format = lsp_format

print("autoconf optional-dependency tests passed")
