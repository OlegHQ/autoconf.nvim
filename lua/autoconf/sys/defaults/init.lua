local M = {}

M.default_config = {
    editor = {
        tabstop = 4,
        softtabstop = 4,
        shiftwidth = 2,
        expandtab = true,
        smartindent = true,
        nu = true,
        undofile = true,
        incsearch = true,
        backup = false,
        hlsearch = false,
        swapfile = false,
        wrap = false,
        scrolloff = 5,
        mouse = false,
        ["default-yank-register"] = '"',
        ["middle-click-paste"] = true,
        ["scroll-lines"] = 8,
        ["line-number"] = "absolute",
        cursorline = false,
        cursorcolumn = false,
        ["continue-comments"] = true,
        ["auto-completion"] = true,
        ["path-completion"] = true,
        ["auto-format"] = true,
        ["idle-timeout"] = 250,
        ["completion-timeout"] = 250,
        ["preview-completion-insert"] = true,
        ["completion-trigger-len"] = 2,
        ["completion-replace"] = false,
        ["auto-info"] = false,
        undercurl = false,
        rulers = {},
        bufferline = "never",
        ["color-modes"] = false,
        ["text-width"] = 80,
        ["workspace-lsp-roots"] = {},
        ["default-line-ending"] = "native",
        ["insert-final-newline"] = true,
        ["trim-final-newlines"] = false,
        ["trim-trailing-whitespace"] = false,
        ["popup-border"] = "none",
        ["indent-heuristic"] = "hybrid",
        ["jump-label-alphabet"] = "abcdefghijklmnopqrstuvwxyz",
        ["editor-config"] = true,
        ["true-color"] = true,

        statusline = {
            left = { "mode", "spinner", "file-name", "read-only-indicator", "file-modification-indicator" },
            center = {},
            right = { "diagnostics", "selections", "register", "position", "file-encoding" },
            separator = "│",
            mode = {
                normal = "NOR",
                insert = "INS",
                select = "SEL",
                command = "CMD",
                visual = "VIS",
                replace = "REP",
                terminal = "TER"
            },
            diagnostics = { "warning", "error" },
            ["workspace-diagnostics"] = { "warning", "error" }
        },

        lsp = {
            enable = true,
            ["display-messages"] = true,
            ["display-progress-messages"] = false,
            ["auto-signature-help"] = true,
            ["display-inlay-hints"] = false,
            ["display-color-swatches"] = true,
            ["display-signature-help-docs"] = true,
            snippets = true,
            ["goto-reference-include-declaration"] = true
        },

        ["cursor-shape"] = {
            normal = "block",
            insert = "block",
            select = "block"
        },

        ["file-picker"] = {
            hidden = true,
            ["follow-symlinks"] = true,
            ["deduplicate-links"] = true,
            parents = true,
            ignore = true,
            ["git-ignore"] = true,
            ["git-global"] = true,
            ["git-exclude"] = true
        },

        ["auto-pairs"] = {
            ["("] = ")",
            ["{"] = "}",
            ["["] = "]",
            ["'"] = "'",
            ['"'] = '"',
            ["`"] = "`",
            ["<"] = ">"
        },

        ["auto-save"] = {
            ["focus-lost"] = false,
            ["after-delay"] = {
                enable = false,
                timeout = 3000
            }
        },

        whitespace = {
            render = "none",
            characters = {
                space = "·",
                nbsp = "⍽",
                nnbsp = "␣",
                tab = "→",
                newline = "⏎",
                tabpad = "·"
            }
        },

        ["indent-guides"] = {
            render = true,
            character = "│",
            ["skip-levels"] = 0
        },

        gutters = {
            layout = { "diagnostics", "spacer", "line-numbers", "spacer", "diff" },
            ["line-numbers"] = {
                ["min-width"] = 1
            }
        },

        ["soft-wrap"] = {
            enable = false,
            ["max-wrap"] = 20,
            ["max-indent-retain"] = 40,
            ["wrap-indicator"] = "↪ ",
            ["wrap-at-text-width"] = false
        },

        ["inline-diagnostics"] = {
            enabled = true,
            ["only-current-line"] = true
        }
    },

    keys = {
        normal = {
            ["C-c"] = "toggle_comments",
            [">"] = "indent_right",
            ["<"] = "indent_left",
            ["S-U"] = "redo",
            gd = "goto_definition",
            gy = "goto_type_definition",
            gr = "goto_reference",
            gi = "goto_implementation",
            space = {
                f = "file_picker",
                ["/"] = "global_search",
                d = "diagnostics_picker",
                b = "buffer_picker",
                s = "substitute_word_globally",
                S = "substitute_word_line",
                k = "hover",
                r = "rename_symbol",
                a = "code_action",
                e = "diagnostic_open_float",
            }
        },
        visual = {
            [">"] = "indent_right",
            ["<"] = "indent_left",
            ["S-R"] = "replace_with_yanked",
            J = "move_selection_down",
            K = "move_selection_up",
            [","] = "visual_escape",
            space = {
                Y = "yank_main_selection_to_clipboard"
            }
        },
        visualselect = {
            ["C-c"] = "toggle_comments",
            space = {
                p = "paste_over_selection"
            }
        }
    }
}

return M

