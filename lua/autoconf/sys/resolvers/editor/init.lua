-- Editor-specific resolver implementations
-- This file contains resolvers for editor-specific configuration options
--
-- Resolvers using builder.vim_opt_*, builder.vim_g_*, builder.boolean_toggle, etc.
-- are auto-registered when their modules are loaded.
-- Only non-auto-registered resolvers need explicit registration here.

local resolvers = require("autoconf.sys.core.resolvers")

local M = {}

-- Function to register editor-specific resolvers
M.register_editor_resolvers = function()
    -- Load modules to trigger auto-registration of builder-based resolvers
    local base = require("autoconf.sys.resolvers.editor.base")
    local gutters = require("autoconf.sys.resolvers.editor.gutters")
    local statusline = require("autoconf.sys.resolvers.editor.statusline")
    local registers = require("autoconf.sys.resolvers.editor.registers")
    local scrolling = require("autoconf.sys.resolvers.editor.scrolling")
    local formatting = require("autoconf.sys.resolvers.editor.formatting")
    local appearance = require("autoconf.sys.resolvers.editor.appearance")
    local completion = require("autoconf.sys.resolvers.editor.completion")
    local ui = require("autoconf.sys.resolvers.editor.ui")
    local diagnostics = require("autoconf.sys.resolvers.editor.diagnostics")
    local lsp = require("autoconf.sys.resolvers.editor.lsp")
    local filepicker = require("autoconf.sys.resolvers.editor.filepicker")
    local mini_files = require("autoconf.sys.resolvers.editor.mini_files")
    -- ========================================
    -- Resolvers NOT using auto-registration
    -- (builder.custom or manual functions)
    -- ========================================

    -- Base resolvers
    resolvers.define_resolver("editor.default-line-ending", base.default_line_ending)
    resolvers.define_resolver("editor.auto-save", base.auto_save)

    -- Appearance resolvers (theme is manual, cursor_shape is complex)
    resolvers.define_resolver("theme", appearance.theme)
    resolvers.define_resolver("editor.cursor-shape", appearance.cursor_shape)

    -- Completion resolvers
    resolvers.define_resolver("editor.path-completion", completion.path_completion)
    resolvers.define_resolver("editor.completion-timeout", completion.completion_timeout)
    resolvers.define_resolver("editor.completion-trigger-len", completion.completion_trigger_len)
    resolvers.define_resolver("editor.completion-replace", completion.completion_replace)
    resolvers.define_resolver("editor.preview-completion-insert", completion.preview_completion_insert)
    resolvers.define_resolver("editor.auto-completion", completion.auto_completion)
    resolvers.define_resolver("editor.auto-pairs", completion.auto_pairs)

    -- Formatting resolvers
    resolvers.define_resolver("editor.auto-format", formatting.auto_format)
    resolvers.define_resolver("editor.insert-final-newline", formatting.insert_final_newline)
    resolvers.define_resolver("editor.trim-final-newlines", formatting.trim_final_newlines)
    resolvers.define_resolver("editor.trim-trailing-whitespace", formatting.trim_trailing_whitespace)
    resolvers.define_resolver("editor.whitespace", formatting.whitespace)

    -- UI resolvers
    resolvers.define_resolver("editor.editor-config", ui.editor_config)
    resolvers.define_resolver("editor.indent-heuristic", ui.indent_heuristic)
    resolvers.define_resolver("editor.jump-label-alphabet", ui.jump_label_alphabet)
    resolvers.define_resolver("editor.indent-guides", ui.indent_guides)
    resolvers.define_resolver("editor.soft-wrap", ui.soft_wrap)

    -- Gutters
    resolvers.define_resolver("editor.gutters", gutters.resolver)
    gutters.define_array_resolvers()
    resolvers.define_resolver("editor.line-number", gutters.line_number)

    -- Statusline
    resolvers.define_resolver("editor.bufferline", statusline.bufferline)
    resolvers.define_resolver("editor.statusline", statusline.statusline)

    -- LSP resolvers (auto-registered: enable, display-messages, display-progress-messages, snippets)
    resolvers.define_resolver("editor.auto-info", lsp.auto_info)
    resolvers.define_resolver("editor.popup-border", lsp.popup_border)
    resolvers.define_resolver("editor.lsp.auto-signature-help", lsp.auto_signature_help)
    resolvers.define_resolver("editor.lsp.display-inlay-hints", lsp.display_inlay_hints)
    resolvers.define_resolver("editor.lsp.display-signature-help-docs", lsp.display_signature_help_docs)
    resolvers.define_resolver("editor.lsp.goto-reference-include-declaration", lsp.goto_reference_include_declaration)
    resolvers.define_resolver("editor.lsp.display-color-swatches", lsp.display_color_swatches)

    -- Diagnostics and file picker
    resolvers.define_resolver("editor.inline-diagnostics", diagnostics.inline_diagnostics)
    resolvers.define_resolver("editor.file-picker", filepicker.filepicker)
    resolvers.define_resolver("editor.mini-files", mini_files.configure)

    -- Simple vim.opt pass-through resolvers
    resolvers.define_resolver("editor.tabstop", function(value) vim.opt.tabstop = value end)
    resolvers.define_resolver("editor.softtabstop", function(value) vim.opt.softtabstop = value end)
    resolvers.define_resolver("editor.shiftwidth", function(value) vim.opt.shiftwidth = value end)
    resolvers.define_resolver("editor.expandtab", function(value) vim.opt.expandtab = value end)
    resolvers.define_resolver("editor.smartindent", function(value) vim.opt.smartindent = value end)
    resolvers.define_resolver("editor.nu", function(value) vim.opt.nu = value end)
    resolvers.define_resolver("editor.undofile", function(value) vim.opt.undofile = value end)
    resolvers.define_resolver("editor.incsearch", function(value) vim.opt.incsearch = value end)
    resolvers.define_resolver("editor.backup", function(value) vim.opt.backup = value end)
    resolvers.define_resolver("editor.hlsearch", function(value) vim.opt.hlsearch = value end)
    resolvers.define_resolver("editor.swapfile", function(value) vim.opt.swapfile = value end)
    resolvers.define_resolver("editor.wrap", function(value) vim.opt.wrap = value end)
    resolvers.define_resolver("editor.cursorline", function(value) vim.opt.cursorline = value end)
    resolvers.define_resolver("editor.cursorlineopt", function(value) vim.opt.cursorlineopt = value end)
end

return M
