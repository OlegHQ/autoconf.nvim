local source = debug.getinfo(1, "S").source:sub(2)
local tests_root = vim.fn.fnamemodify(source, ":p:h")
local autoconf_root = vim.fn.fnamemodify(tests_root, ":h")
local start_root = vim.fn.fnamemodify(autoconf_root, ":h")
local workbench_root = start_root .. "/workbench.nvim"
vim.opt.runtimepath:append(workbench_root)

local toml = require("autoconf.toml")
local translator = require("autoconf.sys.resolvers.editor.workbench")
local parsed = toml.parse([[
[editor.workbench]
enable = true

[editor.workbench.sidebar]
position = "right"
width = 40
views = ["files"]
follow-active-file = false

[editor.workbench.search]
debounce-ms = 0
max-results = 500
hidden = true
ignored = false
follow-symlinks = false

[editor.workbench.preview]
enable = false
max-bytes = 65536

[editor.workbench.session]
persist = false
max-results-history = 5
]])

local translated = assert(translator.translate(parsed.editor.workbench))
assert(translated.enabled == true, "TOML enable maps to public enabled without losing true")
assert(translated.sidebar.position == "right" and translated.sidebar.width == 40, "nested sidebar fields translate")
assert(translated.sidebar.follow_active_file == false, "false follow-active-file is retained")
assert(vim.deep_equal(translated.sidebar.views, { "files" }), "views list is copied and replaced")
assert(translated.search.debounce_ms == 0 and translated.search.hidden == true, "numeric zero and true search fields translate")
assert(translated.search.ignored == false and translated.search.follow_symlinks == false, "false search fields are retained")
assert(translated.preview.enabled == false and translated.session.persist == false, "nested false enable/persist are retained")
assert(translator.is_supported_path("editor.workbench.search.hidden"), "health recognizes a declared nested TOML key")
assert(translator.is_supported_path("editor.workbench.sidebar.views"), "health recognizes a declared TOML list as one atomic value")
assert(not translator.is_supported_path("editor.workbench.search.unknown"), "health rejects unknown nested TOML keys")

local workbench = require("workbench")
assert(workbench.get_status().reason == "not_setup", "TOML translation alone does not initialize Workbench")
local invalid_resolved = translator.configure({ enable = true, sidebar = { width = 40, unsupported = true } })
assert(invalid_resolved == false, "unknown TOML fields are rejected instead of passed through")
assert(workbench.get_status().reason == "not_setup", "failed TOML validation leaves Workbench uninitialized")

local resolvers = require("autoconf.sys.core.resolvers")
require("autoconf.sys.resolvers.editor").register_editor_resolvers()
require("autoconf.sys.core.resolution").resolve_configs(parsed)

local status = workbench.get_status()
assert(status.state == "enabled", "nested editor.workbench.enable activates the explicitly configured standalone feature")
local function setting(path)
  for _, item in ipairs(status.settings) do if item.path == path then return item end end
end
assert(setting("sidebar.width").effective == 40 and setting("sidebar.width").provenance == "autoconf.toml", "effective setting reports TOML provenance")
assert(setting("search.hidden").effective == true and setting("search.hidden").provenance == "autoconf.toml", "true boolean setting reaches effective state")
assert(setting("preview.enabled").effective == false, "false preview setting reaches effective state")
assert(status.editor_settings.completion.available, "Autoconf completion adapter is registered")
assert(status.editor_settings.formatting.available, "Autoconf formatting adapter is registered")
assert(status.editor_settings.diagnostics.available, "Autoconf diagnostics adapter is registered on supported Neovim")

local completion = require("autoconf.sys.resolvers.editor.completion")
local formatting = require("autoconf.sys.resolvers.editor.formatting")
local diagnostics = require("autoconf.sys.resolvers.editor.diagnostics")
local foreign_group = vim.api.nvim_create_augroup("AutoconfWorkbenchSibling", { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", { group = foreign_group, callback = function() end })
local foreign_before = #vim.api.nvim_get_autocmds({ event = "BufWritePre", group = foreign_group })

assert(workbench.execute("settings.toggle_completion", { enabled = false }).ok, "completion action applies an explicit false")
assert(completion.status().requested.auto_completion == false, "completion requested state reflects live adapter action")
assert(completion.blink_options().enabled() == false, "Blink's dynamic effective option reflects the action")
assert(workbench.execute("settings.toggle_formatting", { enabled = true }).ok, "format action installs the Autoconf-owned hook")
assert(formatting.auto_format_status().requested and formatting.auto_format_status().effective, "formatting status reports requested/effective hook state")
assert(workbench.execute("settings.toggle_diagnostics", { enabled = true }).ok, "diagnostics action applies a live setting")
assert(diagnostics.inline_diagnostics_status().effective, "diagnostics getter reads the active Neovim configuration")
assert(vim.diagnostic.config().virtual_lines == true, "diagnostics action changes the real Neovim setting")
assert(#vim.api.nvim_get_autocmds({ event = "BufWritePre", group = foreign_group }) == foreign_before, "formatting toggle preserves a sibling save hook")

-- Resolver reapplication replaces its adapter registrations instead of stacking
-- duplicate actions/resources, and does not undo a live action override.
require("autoconf.sys.core.resolution").resolve_configs(parsed)
local repeated = workbench.get_status()
local adapter_resources = 0
for _, resource in ipairs(repeated.resources.resources) do
  if resource.label:match("^setting%-adapter:") then adapter_resources = adapter_resources + 1 end
end
assert(adapter_resources == 3, "repeated TOML setup retains exactly one registration per host adapter")
assert(completion.status().requested.auto_completion == false, "re-registering adapters preserves live host state")
assert(#vim.api.nvim_get_autocmds({ event = "BufWritePre", group = foreign_group }) == foreign_before, "repeated setup leaves sibling save hooks intact")

require("autoconf.sys.core.resolution").resolve_configs({ editor = { workbench = { enable = true } } })
local reset = workbench.get_status()
local reset_settings = {}
for _, item in ipairs(reset.settings) do reset_settings[item.path] = item end
assert(reset_settings["search.hidden"].effective == false and reset_settings["search.hidden"].provenance == "default",
  "replacing the TOML source clears omitted keys and restores their default provenance")
assert(reset_settings["sidebar.width"].effective == 32 and reset_settings["preview.enabled"].effective == true,
  "replacing the TOML source restores omitted values to defaults")
require("autoconf.sys.core.resolution").resolve_configs(parsed)

-- An invalid nested field is rejected without changing the last valid settings.
local before_invalid = workbench.get_status()
require("autoconf.sys.core.resolution").resolve_configs({ editor = { workbench = { search = { hidden = false, unknown = true } } } })
local after_invalid = workbench.get_status()
assert(after_invalid.state == before_invalid.state, "unknown TOML field cannot change enabled state")
assert(setting("search.hidden").effective == true, "baseline parsed TOML was retained")
local hidden_after = workbench.get_status().settings
for _, item in ipairs(hidden_after) do
  if item.path == "search.hidden" then assert(item.effective == true, "unknown config did not partially apply known siblings") end
end

-- Reset only the settings touched in this isolated process; no config file is
-- written by a live action or by a TOML resolver.
assert(workbench.execute("settings.toggle_completion", { enabled = true }).ok)
assert(workbench.execute("settings.toggle_formatting", { enabled = false }).ok)
assert(workbench.execute("settings.toggle_diagnostics", { enabled = false }).ok)
assert(formatting.auto_format_status().effective == false, "formatting disable removes its owned hook")
assert(#vim.api.nvim_get_autocmds({ event = "BufWritePre", group = foreign_group }) == foreign_before, "formatting disable still preserves sibling hook")
assert(resolvers.has_resolver("editor.workbench"), "Autoconf registers the nested workbench resolver")

print("autoconf workbench settings integration tests passed")
