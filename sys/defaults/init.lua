local M = {}

M.default_config = {
    editor = {
        scrolloff = 5,
        mouse = true,
        ["default-yank-register"] = '"',
        ["middle-click-paste"] = true,
        ["scroll-lines"] = 3,
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
        ["auto-info"] = true,
        ["true-color"] = false,
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
        ["end-of-line-diagnostics"] = "disable",
        ["editor-config"] = true,
        
        ["clipboard-provider"] = {
            -- Leave empty to use platform default (or specify: "termcode", "x-clip", etc.)
        },
        
        statusline = {
            left = {"mode", "spinner", "file-name", "read-only-indicator", "file-modification-indicator"},
            center = {},
            right = {"diagnostics", "selections", "register", "position", "file-encoding"},
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
            diagnostics = {"warning", "error"},
            ["workspace-diagnostics"] = {"warning", "error"}
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
            render = false,
            character = "│",
            ["skip-levels"] = 0
        },
        
        gutters = {
            layout = {"diagnostics", "spacer", "line-numbers", "spacer", "diff"},
            ["line-numbers"] = {
                ["min-width"] = 3
            }
            -- diagnostics, diff, and spacer gutters are unused in config but listed for completeness
        },
        
        ["soft-wrap"] = {
            enable = false,
            ["max-wrap"] = 20,
            ["max-indent-retain"] = 40,
            ["wrap-indicator"] = "↪ ",
            ["wrap-at-text-width"] = false
        },
        
        ["inline-diagnostics"] = {
            ["cursor-line"] = "disable",
            ["other-lines"] = "disable",
            ["prefix-len"] = 1,
            ["max-wrap"] = 20,
            ["max-diagnostics"] = 10
        }
    }
}

return M
