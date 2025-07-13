-- Editor-specific resolver implementations
-- This file contains resolvers for editor-specific configuration options

-- Import logger

local resolvers = require("sys.core.resolvers")
local base = require("sys.resolvers.editor.base")
local gutters = require("sys.resolvers.editor.gutters")
local etc = require("sys.resolvers.editor.etc")

local M = {}

-- Function to register editor-specific resolvers
M.register_editor_resolvers = function()
    -- Scrolloff resolver - Number of lines of padding around the edge of the screen when scrolling
    resolvers.define_resolver("editor.scrolloff", base.scrolloff)

    -- Default yank register resolver - Default register used for yank/paste
    resolvers.define_resolver("editor.default-yank-register", base.default_yank_register)

    -- Middle click paste resolver - Middle click paste support
    resolvers.define_resolver("editor.middle-click-paste", base.middle_click_paste)

    -- Scroll lines resolver - Number of lines to scroll per scroll wheel step
    resolvers.define_resolver("editor.scroll-lines", base.scroll_lines)

    -- Auto-format resolver - Automatic formatting on save
    resolvers.define_resolver("editor.auto-format", base.auto_format)

    -- Continue comments resolver - Automatically continue comments on new lines
    resolvers.define_resolver("editor.continue-comments", base.continue_comments)

    -- Cursor column resolver - Show/hide cursor column
    resolvers.define_resolver("editor.cursorcolumn", base.cursorcolumn)


    -- Path completion resolver - Enable path completion
    resolvers.define_resolver("editor.path-completion", base.path_completion)

    -- Atomic save resolver - Atomic file saving
    resolvers.define_resolver("editor.atomic-save", base.atomic_save)

    -- Auto-info resolver - Display info boxes
    resolvers.define_resolver("editor.auto-info", base.auto_info)

    -- Bufferline resolver - Show buffer tabs
    resolvers.define_resolver("editor.bufferline", base.bufferline)

    -- Color modes resolver - Color mode indicator
    resolvers.define_resolver("editor.color-modes", base.color_modes)

    -- Completion timeout resolver - Delay before showing completions
    resolvers.define_resolver("editor.completion-timeout", base.completion_timeout)

    -- Completion trigger length resolver - Minimum length to trigger completion
    resolvers.define_resolver("editor.completion-trigger-len", base.completion_trigger_len)

    -- Completion replace resolver - Replace entire word vs part before cursor
    resolvers.define_resolver("editor.completion-replace", base.completion_replace)

    -- Preview completion insert resolver - Apply completion instantly when selected
    resolvers.define_resolver("editor.preview-completion-insert", base.preview_completion_insert)

    -- Default line ending resolver - File line ending format
    resolvers.define_resolver("editor.default-line-ending", base.default_line_ending)

    -- Editor config resolver - Support for .editorconfig files
    resolvers.define_resolver("editor.editor-config", base.editor_config)

    -- End of line diagnostics resolver - Diagnostics at end of line
    resolvers.define_resolver("editor.end-of-line-diagnostics", base.end_of_line_diagnostics)

    -- Idle timeout resolver - Time before idle timers trigger
    resolvers.define_resolver("editor.idle-timeout", base.idle_timeout)

    -- Indent heuristic resolver - How indentation is computed
    resolvers.define_resolver("editor.indent-heuristic", base.indent_heuristic)

    -- Insert final newline resolver - Add final newline on save
    resolvers.define_resolver("editor.insert-final-newline", base.insert_final_newline)

    -- Jump label alphabet resolver - Characters for jump labels
    resolvers.define_resolver("editor.jump-label-alphabet", base.jump_label_alphabet)

    -- Popup border resolver - Border around popups
    resolvers.define_resolver("editor.popup-border", base.popup_border)

    -- Text width resolver - Maximum line length
    resolvers.define_resolver("editor.text-width", base.text_width)

    -- Trim final newlines resolver - Remove trailing newlines
    resolvers.define_resolver("editor.trim-final-newlines", base.trim_final_newlines)

    -- Trim trailing whitespace resolver - Remove trailing whitespace
    resolvers.define_resolver("editor.trim-trailing-whitespace", base.trim_trailing_whitespace)

    -- True color resolver - Override terminal truecolor detection
    resolvers.define_resolver("editor.true-color", base.true_color)

    -- Undercurl resolver - Override terminal undercurl detection
    resolvers.define_resolver("editor.undercurl", base.undercurl)



    -- Gutters resolver - Configure editor gutters (diagnostics, line-numbers, diff)
    resolvers.define_resolver("editor.gutters", gutters.resolver)
    gutters.define_array_resolvers()



    -- Line numbers resolver
    resolvers.define_resolver("editor.line-number", etc.line_number)

    -- Cursor line resolver
    resolvers.define_resolver("editor.cursorline", etc.cursorline)

    -- Mouse resolver
    resolvers.define_resolver("editor.mouse", etc.mouse)

    -- Theme resolver
    resolvers.define_resolver("theme", etc.theme)

    -- Cursor shape resolver
    resolvers.define_resolver("editor.cursor-shape", etc.cursor_shape)

    -- Statusline resolver (lualine integration)
    resolvers.define_resolver("editor.statusline", etc.statusline)

    -- Auto-completion resolver
    resolvers.define_resolver("editor.auto-completion", etc.auto_completion)
end

return M
