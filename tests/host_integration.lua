local function fail(message)
    error("Autoconf host integration: " .. message)
end

local function assert_true(value, message)
    if not value then fail(message) end
end

local function group_count(event, group)
    return #vim.api.nvim_get_autocmds({ event = event, group = group })
end

local source = debug.getinfo(1, "S").source:sub(2)
local tests_root = vim.fn.fnamemodify(source, ":p:h")
local plugin_root = vim.fn.fnamemodify(tests_root, ":h")
local host_root = vim.fn.fnamemodify(plugin_root, ":h:h:h:h")
local completion = require("autoconf.sys.resolvers.editor.completion")
local editor_lsp = require("autoconf.sys.resolvers.editor.lsp")
local defaults_lsp = require("autoconf.sys.defaults.lsp")

vim.opt.undofile = false
vim.opt.swapfile = false
vim.wait(100)

-- LSP capabilities must be registered before first InsertEnter loads Blink UI.
assert_true(package.loaded["blink.cmp.completion"] == nil, "Blink UI loaded during startup")
local configured = vim.lsp.config.pyright
assert_true(configured ~= nil, "configured pyright server is registered")
assert_true(vim.tbl_get(configured, "capabilities", "textDocument", "completion", "completionItem", "snippetSupport") == true,
    "Blink snippet capabilities are supplied before InsertEnter")
assert_true(group_count("InsertEnter", "AutoconfDeferredCompletion") == 1, "only one deferred Blink hook exists")
assert_true(group_count("BufWritePre", "AutoconfAutoFormat") == 1, "one Autoconf save-format hook exists")

-- Use a real local LSP process to verify the initialize payload, then start an
-- independently-owned client and prove the Autoconf toggle leaves it alive.
local python = vim.fn.exepath("python3")
assert_true(python ~= "", "python3 is required for the local fake LSP")
local server = tests_root .. "/fixtures/lsp_probe.py"
local root = vim.fn.tempname()
vim.fn.mkdir(root, "p")
vim.fn.writefile({ "root" }, root .. "/.autoconf-root")
local buffer_path = root .. "/probe.acf"
vim.fn.writefile({ "probe" }, buffer_path)
local capture = root .. "/initialize.json"
local external_capture = root .. "/external-initialize.json"
local command = { python, server, capture }
local external_command = { python, server, external_capture }

editor_lsp.snippets(true)
vim.lsp.config("autoconf_host_probe", {
    cmd = command,
    filetypes = { "autoconf_probe" },
    root_markers = { ".autoconf-root" },
})
defaults_lsp.setup_deferred({ autoconf_probe = { lsp = "autoconf_host_probe" } })

local buffer = vim.fn.bufadd(buffer_path)
vim.fn.bufload(buffer)
vim.bo[buffer].filetype = "autoconf_probe"
vim.api.nvim_set_current_buf(buffer)
vim.api.nvim_exec_autocmds("FileType", { buffer = buffer, modeline = false })
local attached = vim.wait(5000, function()
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = buffer })) do
        if client.name == "autoconf_host_probe" then return true end
    end
    return false
end, 20)
assert_true(attached, "configured fake LSP attached")
local initialize_ready = vim.wait(3000, function() return vim.fn.filereadable(capture) == 1 end, 20)
assert_true(initialize_ready, "fake server captured initialize capabilities")
local initialize = vim.json.decode(table.concat(vim.fn.readfile(capture), "\n"))
assert_true(initialize.snippetSupport == true, "client initialize includes Blink snippet support")
assert_true(package.loaded["blink.cmp.completion"] == nil, "client initialized before completion UI")

local external_id = vim.lsp.start({
    name = "autoconf_external_probe",
    cmd = external_command,
    root_dir = root,
    capabilities = vim.lsp.protocol.make_client_capabilities(),
}, { bufnr = buffer })
assert_true(external_id ~= nil, "independent client starts")
assert_true(vim.wait(3000, function() return vim.fn.filereadable(external_capture) == 1 end, 20),
    "independent client initialized")

editor_lsp.enable(false)
assert_true(vim.wait(3000, function()
    return vim.lsp.get_client_by_id(external_id) ~= nil
        and vim.lsp.get_clients({ bufnr = buffer })[1] ~= nil
        and vim.lsp.get_client_by_id(external_id).name == "autoconf_external_probe"
end, 20), "external client remains after configured LSP disable")
editor_lsp.enable(true)
assert_true(vim.wait(3000, function()
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = buffer })) do
        if client.name == "autoconf_host_probe" then return true end
    end
    return false
end, 20), "configured server can be re-enabled")
assert_true(vim.lsp.get_client_by_id(external_id) ~= nil, "external client remains after re-enable")

-- The actual installed Blink 1.10.2 accepts these documented fields, and
-- toggles remain live after its one-time setup.
completion.auto_completion(false)
completion.path_completion(false)
completion.preview_completion_insert(false)
completion.completion_trigger_len(4)
editor_lsp.snippets(false)
vim.api.nvim_exec_autocmds("InsertEnter", { modeline = false })
local blink_config = require("blink.cmp.config")
assert_true(blink_config.enabled() == false, "auto-completion false reaches Blink")
assert_true(blink_config.sources.min_keyword_length() == 4, "keyword length reaches Blink")
assert_true(blink_config.sources.providers.path.enabled() == false, "path source false reaches Blink")
assert_true(blink_config.sources.providers.snippets.enabled() == false, "snippet source false reaches Blink")
assert_true(blink_config.completion.list.selection.auto_insert() == false, "preview insertion false reaches Blink")
assert_true(defaults_lsp.status().restart_required, "snippet capability change reports restart required")
completion.auto_completion(true)
completion.path_completion(true)
completion.preview_completion_insert(true)
completion.completion_trigger_len(2)
editor_lsp.snippets(true)
assert_true(blink_config.enabled() == true, "auto-completion true reaches Blink")
assert_true(blink_config.sources.min_keyword_length() == 2, "keyword length resets in Blink")
assert_true(blink_config.sources.providers.path.enabled() == true, "path source re-enabled")
assert_true(blink_config.sources.providers.snippets.enabled() == true, "snippet source re-enabled")
assert_true(blink_config.completion.list.selection.auto_insert() == true, "preview insertion re-enabled")
assert_true(not defaults_lsp.status().restart_required, "restored snippet capability removes restart requirement")

-- Exercise the real Conform API with a temporary formatter, through the one
-- Autoconf BufWritePre hook; setup contains no second format-on-save hook.
local conform = require("conform")
local format_count = root .. "/format-count"
conform.setup({
    formatters = {
        autoconf_probe_upper = {
            command = python,
            args = { tests_root .. "/fixtures/uppercase.py", format_count },
            stdin = true,
        },
    },
})
defaults_lsp.setup_deferred({ lua = { formatter = "autoconf_probe_upper" } })
completion.auto_completion(true)
local save_path = root .. "/format.lua"
local save_buffer = vim.fn.bufadd(save_path)
vim.fn.bufload(save_buffer)
vim.bo[save_buffer].filetype = "lua"
vim.api.nvim_buf_set_lines(save_buffer, 0, -1, false, { "lower case" })
vim.api.nvim_set_current_buf(save_buffer)
vim.api.nvim_buf_call(save_buffer, function() vim.cmd("write!") end)
assert_true(vim.fn.readfile(save_path)[1] == "LOWER CASE", "real Conform formatter ran during save")
assert_true(#vim.api.nvim_get_autocmds({ event = "BufWritePre", group = "Conform" }) == 0,
    "Conform did not install a duplicate save hook")

-- Health output reports requested/effective/restart-required state.
vim.cmd("AutoconfHealth")
local health = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
assert_true(health:find("## Effective Feature State", 1, true) ~= nil, "health includes feature state")
assert_true(health:find("Completion requested: auto=true", 1, true) ~= nil, "health reports requested completion settings")
assert_true(health:find("Auto-format requested:", 1, true) ~= nil, "health reports requested/effective formatting")
assert_true(health:find("Restart required for configured LSP capabilities:", 1, true) ~= nil,
    "health reports restart requirement")

for _, client in ipairs(vim.lsp.get_clients({ bufnr = buffer })) do
    if client.name == "autoconf_external_probe" then client:stop(true) end
end
editor_lsp.enable(false)
vim.fn.delete(root, "rf")
print("autoconf host integration passed on " .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch)
