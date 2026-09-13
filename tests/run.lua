local function equal(actual, expected, message)
    if actual ~= expected then
        error((message or "values differ") .. ": expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual))
    end
end

local function autocmd_count(event, group)
    return #vim.api.nvim_get_autocmds({ event = event, group = group })
end

local fake_setup
local fake_blink = {
    get_lsp_capabilities = function()
        local caps = vim.lsp.protocol.make_client_capabilities()
        caps.textDocument.completion.completionItem.snippetSupport = true
        return caps
    end,
    setup = function(options) fake_setup = options end,
}
package.preload["blink.cmp"] = function() return fake_blink end

local completion = require("autoconf.sys.resolvers.editor.completion")
local formatting = require("autoconf.sys.resolvers.editor.formatting")
local editor_base = require("autoconf.sys.resolvers.editor.base")
local editor_lsp = require("autoconf.sys.resolvers.editor.lsp")
local editor_ui = require("autoconf.sys.resolvers.editor.ui")
local defaults_lsp = require("autoconf.sys.defaults.lsp")

-- TOML settings must alter Blink's documented option values dynamically.
local blink_options = completion.blink_options()
equal(blink_options.enabled(), true, "completion default")
equal(blink_options.sources.min_keyword_length(), 2, "completion trigger default")
equal(blink_options.sources.providers.path.enabled(), true, "path source default")
equal(blink_options.sources.providers.snippets.enabled(), true, "snippet source default")
completion.auto_completion(false)
completion.path_completion(false)
completion.preview_completion_insert(false)
completion.completion_trigger_len(3)
editor_lsp.snippets(false)
equal(blink_options.enabled(), false, "completion false setting")
equal(blink_options.sources.providers.path.enabled(), false, "path source false setting")
equal(blink_options.completion.list.selection.auto_insert(), false, "preview insert false setting")
equal(blink_options.sources.min_keyword_length(), 3, "keyword length setting")
equal(blink_options.sources.providers.snippets.enabled(), false, "snippet false setting")
completion.auto_completion(true)
completion.path_completion(true)
completion.preview_completion_insert(true)
completion.completion_trigger_len(2)
editor_lsp.snippets(true)
equal(blink_options.enabled(), true, "completion re-enable")

-- LSP capability negotiation precedes completion UI setup and follows snippets.
vim.lsp.config("autoconf_owned_fixture", { cmd = { "python3", "unused" }, filetypes = { "autoconf_fixture" } })
local original_enable = vim.lsp.enable
local enable_calls = {}
vim.lsp.enable = function(name, enabled)
    table.insert(enable_calls, { name, enabled })
end
editor_lsp.enable(false)
defaults_lsp.setup_deferred({ autoconf_fixture = { lsp = "autoconf_owned_fixture" } })
local fixture_config = vim.lsp.config.autoconf_owned_fixture
equal(vim.tbl_get(fixture_config, "capabilities", "textDocument", "completion", "completionItem", "snippetSupport"), true,
    "snippet capability present before InsertEnter")
equal(fake_setup, nil, "Blink UI remains deferred")
equal(autocmd_count("InsertEnter", "AutoconfDeferredCompletion"), 1, "single deferred completion hook")
editor_lsp.snippets(false)
defaults_lsp.setup_deferred({ autoconf_fixture = { lsp = "autoconf_owned_fixture" } })
fixture_config = vim.lsp.config.autoconf_owned_fixture
equal(vim.tbl_get(fixture_config, "capabilities", "textDocument", "completion", "completionItem", "snippetSupport"), false,
    "snippet capability false setting")
equal(autocmd_count("InsertEnter", "AutoconfDeferredCompletion"), 1, "repeated setup stays idempotent")
editor_lsp.snippets(true)

-- Disabling LSP only calls enable(false) for configured servers, never stop() on
-- clients owned by an unrelated plugin.
local get_clients = vim.lsp.get_clients
local foreign_stops = 0
vim.lsp.get_clients = function()
    return { { name = "foreign", stop = function() foreign_stops = foreign_stops + 1 end } }
end
editor_lsp.enable(true)
editor_lsp.enable(false)
editor_lsp.enable(true)
vim.lsp.get_clients = get_clients
vim.lsp.enable = original_enable
equal(foreign_stops, 0, "foreign clients are preserved")
equal(enable_calls[1][1], "autoconf_owned_fixture", "configured server identity")
equal(enable_calls[1][2], false, "configured server initially disabled")
equal(enable_calls[#enable_calls][2], true, "configured server re-enabled")

-- Each Autoconf save/hover hook has its own group and never clears foreign hooks.
local foreign_group = vim.api.nvim_create_augroup("AutoconfTestForeign", { clear = true })
vim.g.autoconf_test_foreign_save = 0
vim.g.autoconf_test_foreign_hover = 0
vim.api.nvim_create_autocmd("BufWritePre", {
    group = foreign_group,
    callback = function() vim.g.autoconf_test_foreign_save = vim.g.autoconf_test_foreign_save + 1 end,
})
vim.api.nvim_create_autocmd("CursorHold", {
    group = foreign_group,
    callback = function() vim.g.autoconf_test_foreign_hover = vim.g.autoconf_test_foreign_hover + 1 end,
})
editor_lsp.auto_info(true)
editor_lsp.auto_signature_help(true)
editor_lsp.auto_info(false)
editor_lsp.auto_info(true)
editor_lsp.auto_info(false)
editor_lsp.auto_info(true)
editor_lsp.auto_signature_help(false)
editor_lsp.auto_signature_help(true)
editor_lsp.auto_signature_help(false)
editor_lsp.auto_signature_help(true)
editor_base.auto_save({ ["focus-lost"] = false, ["after-delay"] = { enable = false } })
editor_base.auto_save({ ["focus-lost"] = false, ["after-delay"] = { enable = false } })
equal(autocmd_count("CursorHold", "AutoconfAutoInfo"), 1, "one hover hook after repeated setup")
equal(autocmd_count("CursorHoldI", "AutoconfAutoSignatureHelp"), 1, "one signature hook after setup")
equal(autocmd_count("CursorHold", "AutoconfAutoSave"), 0, "disabled delay save has no owned hook")

-- Save before InsertEnter loads Conform only for the relevant format action.
local format_calls = 0
package.preload.conform = function()
    return {
        format = function(opts)
            format_calls = format_calls + 1
            equal(opts.formatters[1], "autoconf_test_formatter", "language formatter routing")
            vim.api.nvim_buf_set_lines(opts.bufnr, 0, -1, false, { "FORMATTED" })
            return true
        end,
    }
end
defaults_lsp.setup_deferred({ lua = { formatter = "autoconf_test_formatter" } })
formatting.auto_format(true)
formatting.auto_format(true)
equal(autocmd_count("BufWritePre", "AutoconfAutoFormat"), 1, "one format hook after repeated setup")
equal(package.loaded.conform, nil, "Conform is not eagerly loaded")
local path = vim.fn.tempname() .. ".lua"
local buffer = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_name(buffer, path)
vim.bo[buffer].filetype = "lua"
vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "raw" })
vim.api.nvim_set_current_buf(buffer)
vim.api.nvim_buf_call(buffer, function() vim.cmd("write!") end)
equal(format_calls, 1, "format hook runs before first InsertEnter")
equal(vim.api.nvim_buf_get_lines(buffer, 0, -1, false)[1], "FORMATTED", "save formatter result")
equal(fake_setup, nil, "saving does not eagerly initialize completion UI")

-- Blink is configured on first InsertEnter, with only owned partial options.
vim.api.nvim_exec_autocmds("InsertEnter", { modeline = false })
equal(type(fake_setup.enabled), "function", "dynamic completion option passed to Blink")
equal(fake_setup.sources.min_keyword_length(), 2, "Blink receives current trigger setting")
equal(fake_setup.sources.providers.path.enabled(), true, "Blink receives current path setting")

formatting.auto_format(false)
formatting.auto_format(true)
formatting.auto_format(false)
formatting.auto_format(true)
equal(autocmd_count("BufWritePre", "AutoconfAutoFormat"), 1, "three enable-disable cycles do not duplicate")
formatting.auto_format(false)
editor_base.auto_save({ ["focus-lost"] = false, ["after-delay"] = { enable = false } })
editor_lsp.auto_info(false)
editor_lsp.auto_signature_help(false)
equal(autocmd_count("BufWritePre", "AutoconfTestForeign"), 1, "foreign save hook survives disable")
equal(autocmd_count("CursorHold", "AutoconfTestForeign"), 1, "foreign hover hook survives disable")
vim.api.nvim_exec_autocmds("CursorHold", { buffer = buffer, modeline = false })
equal(vim.g.autoconf_test_foreign_hover, 1, "foreign hover callback still runs")
equal(autocmd_count("BufWritePre", "AutoconfAutoFormat"), 0, "format disable removes only its own hook")
vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "should not format" })
vim.api.nvim_buf_call(buffer, function() vim.cmd("write!") end)
equal(format_calls, 1, "auto-format false does not invoke formatter")
equal(vim.g.autoconf_test_foreign_save, 2, "foreign save callback still runs after auto-format false")

-- The explicit false branch for soft-wrap must undo active wrapping.
editor_ui.soft_wrap({ enable = true, ["max-wrap"] = 20, ["wrap-indicator"] = "x" })
editor_ui.soft_wrap({ enable = false, ["max-wrap"] = 20, ["wrap-indicator"] = "x" })
equal(vim.wo.wrap, false, "soft-wrap false applies")
equal(vim.wo.linebreak, false, "soft-wrap false clears linebreak")
equal(vim.wo.breakindent, false, "soft-wrap false clears breakindent")
vim.wo.colorcolumn = "80"
vim.bo.textwidth = 72
editor_ui.soft_wrap({ enable = true, ["max-wrap"] = 20, ["wrap-indicator"] = false, ["wrap-at-text-width"] = true })
equal(vim.wo.colorcolumn, "72", "wrap-at-text-width uses textwidth")
editor_ui.soft_wrap({ enable = false, ["max-wrap"] = 20, ["wrap-indicator"] = false, ["wrap-at-text-width"] = false })
equal(vim.wo.colorcolumn, "80", "soft-wrap disable restores prior colorcolumn")

-- Disabled message/progress hooks restore their prior functions only while
-- Autoconf still owns the installed wrapper.
local original_message = vim.lsp.handlers["window/showMessage"]
editor_lsp.display_messages(false)
local owned_message = vim.lsp.handlers["window/showMessage"]
equal(type(owned_message), "function", "message suppression wrapper installed")
editor_lsp.display_messages(true)
equal(vim.lsp.handlers["window/showMessage"], original_message, "owned message handler restored")
editor_lsp.display_messages(false)
local foreign_message = function() end
vim.lsp.handlers["window/showMessage"] = foreign_message
editor_lsp.display_messages(true)
equal(vim.lsp.handlers["window/showMessage"], foreign_message, "foreign handler replacement preserved")
vim.lsp.handlers["window/showMessage"] = original_message

local original_progress = vim.lsp.handlers["$/progress"]
editor_lsp.display_progress_messages(false)
editor_lsp.display_progress_messages(true)
equal(vim.lsp.handlers["$/progress"], original_progress, "progress handler restored")

-- Repeated deferred initialization must not call Blink's one-shot setup again.
defaults_lsp.setup_deferred({ autoconf_fixture = { lsp = "autoconf_owned_fixture" } })
equal(autocmd_count("InsertEnter", "AutoconfDeferredCompletion"), 0, "completed Blink setup is not re-armed")

print("autoconf repair tests passed")

local run_source = debug.getinfo(1, "S").source:sub(2)
local tests_root = vim.fn.fnamemodify(run_source, ":p:h")
dofile(tests_root .. "/workbench_integration.lua")
