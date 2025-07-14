-- Editor-specific resolver implementations
-- This file contains resolvers for editor-specific configuration options

-- Import logger

local resolvers = require("sys.core.resolvers")
local base = require("sys.resolvers.editor.base")
local gutters = require("sys.resolvers.editor.gutters")
local statusline = require("sys.resolvers.editor.statusline")
local registers = require("sys.resolvers.editor.registers")
local scrolling = require("sys.resolvers.editor.scrolling")
local formatting = require("sys.resolvers.editor.formatting")
local appearance = require("sys.resolvers.editor.appearance")
local completion = require("sys.resolvers.editor.completion")
local ui = require("sys.resolvers.editor.ui")
local diagnostics = require("sys.resolvers.editor.diagnostics")
local lsp = require("sys.resolvers.editor.lsp")
local filepicker = require("sys.resolvers.editor.filepicker")

local M = {}

-- Function to register editor-specific resolvers
M.register_editor_resolvers = function()
    -- Scrolloff resolver - Number of lines of padding around the edge of the screen when scrolling
    resolvers.define_resolver("editor.scrolloff", base.scrolloff)

    -- Default yank register resolver - Default register used for yank/paste
    resolvers.define_resolver("editor.default-yank-register", registers.default_yank_register)

    -- Middle click paste resolver - Middle click paste support
    resolvers.define_resolver("editor.middle-click-paste", base.middle_click_paste)

    -- Scroll lines resolver - Number of lines to scroll per scroll wheel step
    resolvers.define_resolver("editor.scroll-lines", scrolling.scroll_lines)

    -- Auto-format resolver - Automatic formatting on save
    resolvers.define_resolver("editor.auto-format", formatting.auto_format)

    -- Continue comments resolver - Automatically continue comments on new lines
    resolvers.define_resolver("editor.continue-comments", ui.continue_comments)

    -- Cursor column resolver - Show/hide cursor column
    resolvers.define_resolver("editor.cursorcolumn", appearance.cursorcolumn)


    -- Path completion resolver - Enable path completion
    resolvers.define_resolver("editor.path-completion", completion.path_completion)

    -- Auto-info resolver - Display info boxes
    resolvers.define_resolver("editor.auto-info", lsp.auto_info)

    -- Bufferline resolver - Show buffer tabs
    resolvers.define_resolver("editor.bufferline", statusline.bufferline)

    -- Color modes resolver - Color mode indicator
    resolvers.define_resolver("editor.color-modes", appearance.color_modes)

    -- Completion timeout resolver - Delay before showing completions
    resolvers.define_resolver("editor.completion-timeout", completion.completion_timeout)

    -- Completion trigger length resolver - Minimum length to trigger completion
    resolvers.define_resolver("editor.completion-trigger-len", completion.completion_trigger_len)

    -- Completion replace resolver - Replace entire word vs part before cursor
    resolvers.define_resolver("editor.completion-replace", completion.completion_replace)

    -- Preview completion insert resolver - Apply completion instantly when selected
    resolvers.define_resolver("editor.preview-completion-insert", completion.preview_completion_insert)

    -- Default line ending resolver - File line ending format
    resolvers.define_resolver("editor.default-line-ending", base.default_line_ending)

    -- Editor config resolver - Support for .editorconfig files
    resolvers.define_resolver("editor.editor-config", ui.editor_config)

    -- End of line diagnostics resolver - Diagnostics at end of line
    resolvers.define_resolver("editor.end-of-line-diagnostics", diagnostics.end_of_line_diagnostics)

    -- Idle timeout resolver - Time before idle timers trigger
    resolvers.define_resolver("editor.idle-timeout", base.idle_timeout)

    -- Indent heuristic resolver - How indentation is computed
    resolvers.define_resolver("editor.indent-heuristic", ui.indent_heuristic)

    -- Insert final newline resolver - Add final newline on save
    resolvers.define_resolver("editor.insert-final-newline", formatting.insert_final_newline)

    -- Jump label alphabet resolver - Characters for jump labels
    resolvers.define_resolver("editor.jump-label-alphabet", ui.jump_label_alphabet)

    -- Popup border resolver - Border around popups
    resolvers.define_resolver("editor.popup-border", lsp.popup_border)

    -- Text width resolver - Maximum line length
    resolvers.define_resolver("editor.text-width", formatting.text_width)

    -- Trim final newlines resolver - Remove trailing newlines
    resolvers.define_resolver("editor.trim-final-newlines", formatting.trim_final_newlines)

    -- Trim trailing whitespace resolver - Remove trailing whitespace
    resolvers.define_resolver("editor.trim-trailing-whitespace", formatting.trim_trailing_whitespace)

    -- True color resolver - Override terminal truecolor detection
    resolvers.define_resolver("editor.true-color", appearance.true_color)

    -- Undercurl resolver - Override terminal undercurl detection
    resolvers.define_resolver("editor.undercurl", appearance.undercurl)



    -- Gutters resolver - Configure editor gutters (diagnostics, line-numbers, diff)
    resolvers.define_resolver("editor.gutters", gutters.resolver)
    gutters.define_array_resolvers()



    -- Line numbers resolver
    resolvers.define_resolver("editor.line-number", gutters.line_number)

    -- Cursor line resolver
    resolvers.define_resolver("editor.cursorline", appearance.cursorline)

    -- Mouse resolver
    resolvers.define_resolver("editor.mouse", ui.mouse)

    -- Theme resolver
    resolvers.define_resolver("theme", appearance.theme)

    -- Cursor shape resolver
    resolvers.define_resolver("editor.cursor-shape", appearance.cursor_shape)

    -- Statusline resolver (lualine integration)
    resolvers.define_resolver("editor.statusline", statusline.statusline)

    -- Auto-completion resolver
    resolvers.define_resolver("editor.auto-completion", completion.auto_completion)
    resolvers.define_resolver("editor.indent-guides", ui.indent_guides)
    resolvers.define_resolver("editor.auto-pairs", completion.auto_pairs)
    resolvers.define_resolver("editor.whitespace", formatting.whitespace)
    resolvers.define_resolver("editor.soft-wrap", ui.soft_wrap)
    resolvers.define_resolver("editor.auto-save", base.auto_save)

    resolvers.define_resolver("editor.inline-diagnostics", diagnostics.inline_diagnostics)
    resolvers.define_resolver("editor.file-picker", filepicker.filepicker)
end

return M
