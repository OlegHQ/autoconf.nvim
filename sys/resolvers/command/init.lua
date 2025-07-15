local resolvers = require("sys.core.resolvers")
local M = {}

-- Function to register all command resolvers
M.register_command_resolvers = function()
    -- ========================================
    -- MOVEMENT COMMANDS
    -- ========================================
    
    -- Basic movement
    resolvers.define_command_resolver("move_char_left", function()
        return function()
            vim.cmd("normal! h")
        end
    end)

    resolvers.define_command_resolver("move_visual_line_down", function()
        return function()
            vim.cmd("normal! gj")
        end
    end)

    resolvers.define_command_resolver("move_visual_line_up", function()
        return function()
            vim.cmd("normal! gk")
        end
    end)

    resolvers.define_command_resolver("move_char_right", function()
        return function()
            vim.cmd("normal! l")
        end
    end)

    -- Word movement
    resolvers.define_command_resolver("move_next_word_start", function()
        return function()
            vim.cmd("normal! w")
        end
    end)

    resolvers.define_command_resolver("move_prev_word_start", function()
        return function()
            vim.cmd("normal! b")
        end
    end)

    resolvers.define_command_resolver("move_next_word_end", function()
        return function()
            vim.cmd("normal! e")
        end
    end)

    resolvers.define_command_resolver("move_next_long_word_start", function()
        return function()
            vim.cmd("normal! W")
        end
    end)

    resolvers.define_command_resolver("move_prev_long_word_start", function()
        return function()
            vim.cmd("normal! B")
        end
    end)

    resolvers.define_command_resolver("move_next_long_word_end", function()
        return function()
            vim.cmd("normal! E")
        end
    end)

    -- Find/till movement
    resolvers.define_command_resolver("find_till_char", function()
        return function()
            local char = vim.fn.getchar()
            vim.cmd("normal! t" .. vim.fn.nr2char(char))
        end
    end)

    resolvers.define_command_resolver("find_next_char", function()
        return function()
            local char = vim.fn.getchar()
            vim.cmd("normal! f" .. vim.fn.nr2char(char))
        end
    end)

    resolvers.define_command_resolver("till_prev_char", function()
        return function()
            local char = vim.fn.getchar()
            vim.cmd("normal! T" .. vim.fn.nr2char(char))
        end
    end)

    resolvers.define_command_resolver("find_prev_char", function()
        return function()
            local char = vim.fn.getchar()
            vim.cmd("normal! F" .. vim.fn.nr2char(char))
        end
    end)

    resolvers.define_command_resolver("repeat_last_motion", function()
        return function()
            vim.cmd("normal! ;")
        end
    end)

    -- Line movement
    resolvers.define_command_resolver("goto_line_start", function()
        return function()
            vim.cmd("normal! 0")
        end
    end)

    resolvers.define_command_resolver("goto_line_end", function()
        return function()
            vim.cmd("normal! $")
        end
    end)

    resolvers.define_command_resolver("goto_line", function()
        return function()
            local line = vim.v.count1
            vim.cmd("normal! " .. line .. "G")
        end
    end)

    -- Page movement
    resolvers.define_command_resolver("page_up", function()
        return function()
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<C-b>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("page_down", function()
        return function()
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<C-f>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("page_cursor_half_up", function()
        return function()
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<C-u>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("page_cursor_half_down", function()
        return function()
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<C-d>", true, false, true))
        end
    end)

    -- Jump list
    resolvers.define_command_resolver("jump_forward", function()
        return function()
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<C-i>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("jump_backward", function()
        return function()
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<C-o>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("save_selection", function()
        return function()
            vim.cmd("normal! m'")
        end
    end)

    -- ========================================
    -- CHANGES COMMANDS
    -- ========================================

    resolvers.define_command_resolver("replace", function()
        return function()
            vim.cmd("normal! r")
        end
    end)

    resolvers.define_command_resolver("replace_with_yanked", function()
        return function()
            vim.cmd("normal! R")
        end
    end)

    resolvers.define_command_resolver("switch_case", function()
        return function()
            vim.cmd("normal! ~")
        end
    end)

    resolvers.define_command_resolver("switch_to_lowercase", function()
        return function()
            vim.cmd("normal! gu")
        end
    end)

    resolvers.define_command_resolver("switch_to_uppercase", function()
        return function()
            vim.cmd("normal! gU")
        end
    end)

    resolvers.define_command_resolver("insert_mode", function()
        return function()
            vim.cmd("normal! i")
        end
    end)

    resolvers.define_command_resolver("append_mode", function()
        return function()
            vim.cmd("normal! a")
        end
    end)

    resolvers.define_command_resolver("insert_at_line_start", function()
        return function()
            vim.cmd("normal! I")
        end
    end)

    resolvers.define_command_resolver("insert_at_line_end", function()
        return function()
            vim.cmd("normal! A")
        end
    end)

    resolvers.define_command_resolver("open_below", function()
        return function()
            vim.cmd("normal! o")
        end
    end)

    resolvers.define_command_resolver("open_above", function()
        return function()
            vim.cmd("normal! O")
        end
    end)

    resolvers.define_command_resolver("undo", function()
        return function()
            vim.cmd("normal! u")
        end
    end)

    resolvers.define_command_resolver("redo", function()
        return function()
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<C-r>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("earlier", function()
        return function()
            vim.cmd("earlier")
        end
    end)

    resolvers.define_command_resolver("later", function()
        return function()
            vim.cmd("later")
        end
    end)

    resolvers.define_command_resolver("yank", function()
        return function()
            vim.cmd("normal! y")
        end
    end)

    resolvers.define_command_resolver("paste_after", function()
        return function()
            vim.cmd("normal! p")
        end
    end)

    resolvers.define_command_resolver("paste_before", function()
        return function()
            vim.cmd("normal! P")
        end
    end)

    resolvers.define_command_resolver("select_register", function()
        return function()
            local reg = vim.fn.getchar()
            vim.cmd("normal! \"" .. vim.fn.nr2char(reg))
        end
    end)

    resolvers.define_command_resolver("indent", function()
        return function()
            vim.cmd("normal! >>")
        end
    end)

    resolvers.define_command_resolver("unindent", function()
        return function()
            vim.cmd("normal! <<")
        end
    end)

    resolvers.define_command_resolver("format_selections", function()
        return function()
            vim.lsp.buf.format()
        end
    end)

    resolvers.define_command_resolver("delete_selection", function()
        return function()
            vim.cmd("normal! d")
        end
    end)

    resolvers.define_command_resolver("delete_selection_noyank", function()
        return function()
            vim.cmd("normal! \"_d")
        end
    end)

    resolvers.define_command_resolver("change_selection", function()
        return function()
            vim.cmd("normal! c")
        end
    end)

    resolvers.define_command_resolver("change_selection_noyank", function()
        return function()
            vim.cmd("normal! \"_c")
        end
    end)

    resolvers.define_command_resolver("increment", function()
        return function()
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<C-a>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("decrement", function()
        return function()
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<C-x>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("record_macro", function()
        return function()
            vim.cmd("normal! q")
        end
    end)

    resolvers.define_command_resolver("replay_macro", function()
        return function()
            local reg = vim.fn.getchar()
            vim.cmd("normal! @" .. vim.fn.nr2char(reg))
        end
    end)

    -- ========================================
    -- SHELL COMMANDS
    -- ========================================

    resolvers.define_command_resolver("shell_pipe", function()
        return function()
            local cmd = vim.fn.input("Shell command: ")
            if cmd ~= "" then
                vim.cmd("'<,'>!" .. cmd)
            end
        end
    end)

    resolvers.define_command_resolver("shell_pipe_to", function()
        return function()
            local cmd = vim.fn.input("Shell command: ")
            if cmd ~= "" then
                vim.cmd("'<,'>w !" .. cmd)
            end
        end
    end)

    resolvers.define_command_resolver("shell_insert_output", function()
        return function()
            local cmd = vim.fn.input("Shell command: ")
            if cmd ~= "" then
                vim.cmd("r !" .. cmd)
            end
        end
    end)

    resolvers.define_command_resolver("shell_append_output", function()
        return function()
            local cmd = vim.fn.input("Shell command: ")
            if cmd ~= "" then
                vim.cmd("$r !" .. cmd)
            end
        end
    end)

    resolvers.define_command_resolver("shell_keep_pipe", function()
        return function()
            local cmd = vim.fn.input("Shell command: ")
            if cmd ~= "" then
                vim.cmd("'<,'>!sh -c '" .. cmd .. " && cat || true'")
            end
        end
    end)

    -- ========================================
    -- SELECTION MANIPULATION COMMANDS
    -- ========================================

    resolvers.define_command_resolver("select_regex", function()
        return function()
            local pattern = vim.fn.input("Select regex: ")
            if pattern ~= "" then
                vim.cmd("/" .. pattern)
            end
        end
    end)

    resolvers.define_command_resolver("split_selection", function()
        return function()
            local pattern = vim.fn.input("Split on regex: ")
            if pattern ~= "" then
                vim.cmd("'<,'>s/" .. pattern .. "/\\r/g")
            end
        end
    end)

    resolvers.define_command_resolver("split_selection_on_newline", function()
        return function()
            vim.cmd("'<,'>s/\\n/\\r/g")
        end
    end)

    resolvers.define_command_resolver("merge_selections", function()
        return function()
            vim.cmd("'<,'>j")
        end
    end)

    resolvers.define_command_resolver("merge_consecutive_selections", function()
        return function()
            vim.cmd("'<,'>j")
        end
    end)

    resolvers.define_command_resolver("align_selections", function()
        return function()
            vim.cmd("'<,'>!column -t")
        end
    end)

    resolvers.define_command_resolver("trim_selections", function()
        return function()
            vim.cmd("'<,'>s/^\\s\\+\\|\\s\\+$//g")
        end
    end)

    resolvers.define_command_resolver("collapse_selection", function()
        return function()
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<Esc>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("flip_selections", function()
        return function()
            vim.cmd("normal! o")
        end
    end)

    resolvers.define_command_resolver("ensure_selections_forward", function()
        return function()
            -- Ensure selection is in forward direction
            local start_pos = vim.fn.getpos("'<")
            local end_pos = vim.fn.getpos("'>")
            if start_pos[2] > end_pos[2] or (start_pos[2] == end_pos[2] and start_pos[3] > end_pos[3]) then
                vim.cmd("normal! o")
            end
        end
    end)

    resolvers.define_command_resolver("keep_primary_selection", function()
        return function()
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<Esc>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("remove_primary_selection", function()
        return function()
            -- This is complex in vim, simplified implementation
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<Esc>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("copy_selection_on_next_line", function()
        return function()
            vim.cmd("normal! yyp")
        end
    end)

    resolvers.define_command_resolver("copy_selection_on_prev_line", function()
        return function()
            vim.cmd("normal! yyP")
        end
    end)

    resolvers.define_command_resolver("rotate_selections_backward", function()
        return function()
            -- Simplified implementation
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<C-o>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("rotate_selections_forward", function()
        return function()
            -- Simplified implementation
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<C-i>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("rotate_selection_contents_backward", function()
        return function()
            -- Complex operation, simplified
            vim.cmd("normal! <<")
        end
    end)

    resolvers.define_command_resolver("rotate_selection_contents_forward", function()
        return function()
            -- Complex operation, simplified
            vim.cmd("normal! >>")
        end
    end)

    resolvers.define_command_resolver("select_all", function()
        return function()
            vim.cmd("normal! ggVG")
        end
    end)

    resolvers.define_command_resolver("extend_line_below", function()
        return function()
            vim.cmd("normal! V")
            if vim.fn.mode() == "V" then
                vim.cmd("normal! j")
            end
        end
    end)

    resolvers.define_command_resolver("extend_to_line_bounds", function()
        return function()
            vim.cmd("normal! V")
        end
    end)

    resolvers.define_command_resolver("shrink_to_line_bounds", function()
        return function()
            vim.cmd("normal! v")
        end
    end)

    resolvers.define_command_resolver("join_selections", function()
        return function()
            vim.cmd("'<,'>j")
        end
    end)

    resolvers.define_command_resolver("join_selections_space", function()
        return function()
            vim.cmd("'<,'>j")
        end
    end)

    resolvers.define_command_resolver("keep_selections", function()
        return function()
            local pattern = vim.fn.input("Keep regex: ")
            if pattern ~= "" then
                vim.cmd("'<,'>g!/" .. pattern .. "/d")
            end
        end
    end)

    resolvers.define_command_resolver("remove_selections", function()
        return function()
            local pattern = vim.fn.input("Remove regex: ")
            if pattern ~= "" then
                vim.cmd("'<,'>g/" .. pattern .. "/d")
            end
        end
    end)

    resolvers.define_command_resolver("toggle_comments", function()
        return function()
            -- Use Comment.nvim if available, otherwise fallback
            local ok, api = pcall(require, "Comment.api")
            if ok then
                api.toggle.linewise.current()
            else
                vim.cmd("normal! gcc")
            end
        end
    end)

    -- Tree-sitter selection commands
    resolvers.define_command_resolver("expand_selection", function()
        return function()
            -- Requires treesitter, simplified fallback
            vim.cmd("normal! va(")
        end
    end)

    resolvers.define_command_resolver("shrink_selection", function()
        return function()
            -- Requires treesitter, simplified fallback
            vim.cmd("normal! vi(")
        end
    end)

    resolvers.define_command_resolver("select_prev_sibling", function()
        return function()
            -- Requires treesitter, simplified fallback
            vim.cmd("normal! [m")
        end
    end)

    resolvers.define_command_resolver("select_next_sibling", function()
        return function()
            -- Requires treesitter, simplified fallback
            vim.cmd("normal! ]m")
        end
    end)

    resolvers.define_command_resolver("select_all_siblings", function()
        return function()
            -- Complex treesitter operation, simplified
            vim.cmd("normal! va{")
        end
    end)

    resolvers.define_command_resolver("select_all_children", function()
        return function()
            -- Complex treesitter operation, simplified
            vim.cmd("normal! vi{")
        end
    end)

    resolvers.define_command_resolver("move_parent_node_end", function()
        return function()
            -- Requires treesitter, simplified fallback
            vim.cmd("normal! ]}")
        end
    end)

    resolvers.define_command_resolver("move_parent_node_start", function()
        return function()
            -- Requires treesitter, simplified fallback
            vim.cmd("normal! [{")
        end
    end)

    -- ========================================
    -- SEARCH COMMANDS
    -- ========================================

    resolvers.define_command_resolver("search", function()
        return function()
            vim.cmd("normal! /")
        end
    end)

    resolvers.define_command_resolver("rsearch", function()
        return function()
            vim.cmd("normal! ?")
        end
    end)

    resolvers.define_command_resolver("search_next", function()
        return function()
            vim.cmd("normal! n")
        end
    end)

    resolvers.define_command_resolver("search_prev", function()
        return function()
            vim.cmd("normal! N")
        end
    end)

    resolvers.define_command_resolver("search_selection_detect_word_boundaries", function()
        return function()
            vim.cmd("normal! *")
        end
    end)

    resolvers.define_command_resolver("search_selection", function()
        return function()
            vim.cmd("normal! y/\\V" .. vim.api.nvim_replace_termcodes("<C-r>\"", true, false, true) .. vim.api.nvim_replace_termcodes("<CR>", true, false, true))
        end
    end)

    -- ========================================
    -- VIEW MODE COMMANDS
    -- ========================================

    resolvers.define_command_resolver("align_view_center", function()
        return function()
            vim.cmd("normal! zz")
        end
    end)

    resolvers.define_command_resolver("align_view_top", function()
        return function()
            vim.cmd("normal! zt")
        end
    end)

    resolvers.define_command_resolver("align_view_bottom", function()
        return function()
            vim.cmd("normal! zb")
        end
    end)

    resolvers.define_command_resolver("align_view_middle", function()
        return function()
            vim.cmd("normal! zs")
        end
    end)

    resolvers.define_command_resolver("scroll_down", function()
        return function()
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<C-e>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("scroll_up", function()
        return function()
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<C-y>", true, false, true))
        end
    end)

    -- ========================================
    -- GOTO MODE COMMANDS
    -- ========================================

    resolvers.define_command_resolver("goto_file_start", function()
        return function()
            vim.cmd("normal! gg")
        end
    end)

    resolvers.define_command_resolver("goto_column", function()
        return function()
            local col = vim.v.count1
            vim.cmd("normal! " .. col .. "|")
        end
    end)

    resolvers.define_command_resolver("goto_last_line", function()
        return function()
            vim.cmd("normal! G")
        end
    end)

    resolvers.define_command_resolver("goto_file", function()
        return function()
            vim.cmd("normal! gf")
        end
    end)

    resolvers.define_command_resolver("goto_first_nonwhitespace", function()
        return function()
            vim.cmd("normal! ^")
        end
    end)

    resolvers.define_command_resolver("goto_window_top", function()
        return function()
            vim.cmd("normal! H")
        end
    end)

    resolvers.define_command_resolver("goto_window_center", function()
        return function()
            vim.cmd("normal! M")
        end
    end)

    resolvers.define_command_resolver("goto_window_bottom", function()
        return function()
            vim.cmd("normal! L")
        end
    end)

    resolvers.define_command_resolver("goto_type_definition", function()
        return function()
            vim.lsp.buf.type_definition()
        end
    end)

    resolvers.define_command_resolver("goto_implementation", function()
        return function()
            vim.lsp.buf.implementation()
        end
    end)

    resolvers.define_command_resolver("goto_last_accessed_file", function()
        return function()
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<C-^>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("goto_last_modified_file", function()
        return function()
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<C-^>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("goto_next_buffer", function()
        return function()
            vim.cmd("bnext")
        end
    end)

    resolvers.define_command_resolver("goto_previous_buffer", function()
        return function()
            vim.cmd("bprevious")
        end
    end)

    resolvers.define_command_resolver("goto_last_modification", function()
        return function()
            vim.cmd("normal! '.")
        end
    end)

    resolvers.define_command_resolver("move_line_down", function()
        return function()
            vim.cmd("normal! j")
        end
    end)

    resolvers.define_command_resolver("move_line_up", function()
        return function()
            vim.cmd("normal! k")
        end
    end)

    resolvers.define_command_resolver("goto_word", function()
        return function()
            -- This would require a more complex implementation with labels
            vim.cmd("normal! w")
        end
    end)

    -- ========================================
    -- MATCH MODE COMMANDS
    -- ========================================

    resolvers.define_command_resolver("match_brackets", function()
        return function()
            vim.cmd("normal! %")
        end
    end)

    resolvers.define_command_resolver("surround_add", function()
        return function()
            local char = vim.fn.getchar()
            local surround_char = vim.fn.nr2char(char)
            -- Simplified surround implementation
            vim.cmd("normal! `<i" .. surround_char .. vim.api.nvim_replace_termcodes("<Esc>", true, false, true) .. "`>a" .. surround_char .. vim.api.nvim_replace_termcodes("<Esc>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("surround_replace", function()
        return function()
            local from_char = vim.fn.getchar()
            local to_char = vim.fn.getchar()
            -- Simplified implementation
            vim.cmd("normal! cs" .. vim.fn.nr2char(from_char) .. vim.fn.nr2char(to_char))
        end
    end)

    resolvers.define_command_resolver("surround_delete", function()
        return function()
            local char = vim.fn.getchar()
            -- Simplified implementation
            vim.cmd("normal! ds" .. vim.fn.nr2char(char))
        end
    end)

    resolvers.define_command_resolver("select_textobject_around", function()
        return function()
            local obj = vim.fn.getchar()
            vim.cmd("normal! va" .. vim.fn.nr2char(obj))
        end
    end)

    resolvers.define_command_resolver("select_textobject_inner", function()
        return function()
            local obj = vim.fn.getchar()
            vim.cmd("normal! vi" .. vim.fn.nr2char(obj))
        end
    end)

    -- ========================================
    -- WINDOW MODE COMMANDS
    -- ========================================

    resolvers.define_command_resolver("rotate_view", function()
        return function()
            vim.cmd("wincmd w")
        end
    end)

    resolvers.define_command_resolver("vsplit", function()
        return function()
            vim.cmd("vsplit")
        end
    end)

    resolvers.define_command_resolver("hsplit", function()
        return function()
            vim.cmd("split")
        end
    end)

    resolvers.define_command_resolver("jump_view_left", function()
        return function()
            vim.cmd("wincmd h")
        end
    end)

    resolvers.define_command_resolver("jump_view_down", function()
        return function()
            vim.cmd("wincmd j")
        end
    end)

    resolvers.define_command_resolver("jump_view_up", function()
        return function()
            vim.cmd("wincmd k")
        end
    end)

    resolvers.define_command_resolver("jump_view_right", function()
        return function()
            vim.cmd("wincmd l")
        end
    end)

    resolvers.define_command_resolver("wclose", function()
        return function()
            vim.cmd("close")
        end
    end)

    resolvers.define_command_resolver("wonly", function()
        return function()
            vim.cmd("only")
        end
    end)

    resolvers.define_command_resolver("swap_view_left", function()
        return function()
            vim.cmd("wincmd H")
        end
    end)

    resolvers.define_command_resolver("swap_view_down", function()
        return function()
            vim.cmd("wincmd J")
        end
    end)

    resolvers.define_command_resolver("swap_view_up", function()
        return function()
            vim.cmd("wincmd K")
        end
    end)

    resolvers.define_command_resolver("swap_view_right", function()
        return function()
            vim.cmd("wincmd L")
        end
    end)

    -- ========================================
    -- SPACE MODE COMMANDS
    -- ========================================

    resolvers.define_command_resolver("file_picker", function()
        return function()
            -- Use telescope if available, otherwise fallback
            local ok, builtin = pcall(require, "telescope.builtin")
            if ok then
                builtin.find_files()
            else
                vim.cmd("edit .")
            end
        end
    end)

    resolvers.define_command_resolver("file_picker_in_current_directory", function()
        return function()
            local ok, builtin = pcall(require, "telescope.builtin")
            if ok then
                builtin.find_files({ cwd = vim.fn.getcwd() })
            else
                vim.cmd("edit .")
            end
        end
    end)

    resolvers.define_command_resolver("buffer_picker", function()
        return function()
            local ok, builtin = pcall(require, "telescope.builtin")
            if ok then
                builtin.buffers()
            else
                vim.cmd("ls")
            end
        end
    end)

    resolvers.define_command_resolver("jumplist_picker", function()
        return function()
            local ok, builtin = pcall(require, "telescope.builtin")
            if ok then
                builtin.jumplist()
            else
                vim.cmd("jumps")
            end
        end
    end)

    resolvers.define_command_resolver("changed_file_picker", function()
        return function()
            local ok, builtin = pcall(require, "telescope.builtin")
            if ok then
                builtin.git_status()
            else
                vim.cmd("!git status --porcelain")
            end
        end
    end)

    resolvers.define_command_resolver("hover", function()
        return function()
            vim.lsp.buf.hover()
        end
    end)

    resolvers.define_command_resolver("symbol_picker", function()
        return function()
            local ok, builtin = pcall(require, "telescope.builtin")
            if ok then
                builtin.lsp_document_symbols()
            else
                vim.lsp.buf.document_symbol()
            end
        end
    end)

    resolvers.define_command_resolver("workspace_symbol_picker", function()
        return function()
            local ok, builtin = pcall(require, "telescope.builtin")
            if ok then
                builtin.lsp_workspace_symbols()
            else
                vim.lsp.buf.workspace_symbol()
            end
        end
    end)

    resolvers.define_command_resolver("diagnostics_picker", function()
        return function()
            local ok, builtin = pcall(require, "telescope.builtin")
            if ok then
                builtin.diagnostics({ bufnr = 0 })
            else
                vim.diagnostic.setloclist()
            end
        end
    end)

    resolvers.define_command_resolver("workspace_diagnostics_picker", function()
        return function()
            local ok, builtin = pcall(require, "telescope.builtin")
            if ok then
                builtin.diagnostics()
            else
                vim.diagnostic.setqflist()
            end
        end
    end)

    resolvers.define_command_resolver("rename_symbol", function()
        return function()
            vim.lsp.buf.rename()
        end
    end)

    resolvers.define_command_resolver("code_action", function()
        return function()
            vim.lsp.buf.code_action()
        end
    end)

    resolvers.define_command_resolver("select_references_to_symbol_under_cursor", function()
        return function()
            vim.lsp.buf.references()
        end
    end)

    resolvers.define_command_resolver("last_picker", function()
        return function()
            local ok, builtin = pcall(require, "telescope.builtin")
            if ok then
                builtin.resume()
            else
                vim.cmd("echo 'No telescope available'")
            end
        end
    end)

    resolvers.define_command_resolver("toggle_block_comments", function()
        return function()
            local ok, api = pcall(require, "Comment.api")
            if ok then
                api.toggle.blockwise.current()
            else
                vim.cmd("normal! gbc")
            end
        end
    end)

    resolvers.define_command_resolver("toggle_line_comments", function()
        return function()
            local ok, api = pcall(require, "Comment.api")
            if ok then
                api.toggle.linewise.current()
            else
                vim.cmd("normal! gcc")
            end
        end
    end)

    resolvers.define_command_resolver("paste_clipboard_after", function()
        return function()
            vim.cmd("normal! \"+p")
        end
    end)

    resolvers.define_command_resolver("paste_clipboard_before", function()
        return function()
            vim.cmd("normal! \"+P")
        end
    end)

    resolvers.define_command_resolver("yank_to_clipboard", function()
        return function()
            vim.cmd("normal! \"+y")
        end
    end)

    resolvers.define_command_resolver("yank_main_selection_to_clipboard", function()
        return function()
            vim.cmd("normal! \"+yy")
        end
    end)

    resolvers.define_command_resolver("replace_selections_with_clipboard", function()
        return function()
            vim.cmd("normal! \"+p")
        end
    end)

    resolvers.define_command_resolver("global_search", function()
        return function()
            local ok, builtin = pcall(require, "telescope.builtin")
            if ok then
                builtin.live_grep()
            else
                local pattern = vim.fn.input("Search: ")
                if pattern ~= "" then
                    vim.cmd("vimgrep /" .. pattern .. "/j **/*")
                    vim.cmd("copen")
                end
            end
        end
    end)

    resolvers.define_command_resolver("command_palette", function()
        return function()
            local ok, builtin = pcall(require, "telescope.builtin")
            if ok then
                builtin.commands()
            else
                vim.cmd(":")
            end
        end
    end)

    -- ========================================
    -- INSERT MODE COMMANDS
    -- ========================================

    resolvers.define_command_resolver("commit_undo_checkpoint", function()
        return function()
            -- In insert mode, this would be Ctrl-s
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<C-g>u", true, false, true))
        end
    end)

    resolvers.define_command_resolver("completion", function()
        return function()
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<C-x><C-o>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("insert_register", function()
        return function()
            local reg = vim.fn.getchar()
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<C-r>", true, false, true) .. vim.fn.nr2char(reg))
        end
    end)

    resolvers.define_command_resolver("delete_word_backward", function()
        return function()
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<C-w>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("delete_word_forward", function()
        return function()
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<M-d>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("kill_to_line_start", function()
        return function()
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<C-u>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("kill_to_line_end", function()
        return function()
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<C-k>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("delete_char_backward", function()
        return function()
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<BS>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("delete_char_forward", function()
        return function()
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<Del>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("insert_newline", function()
        return function()
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<CR>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("goto_line_end_newline", function()
        return function()
            vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<End>", true, false, true))
        end
    end)

    -- ========================================
    -- UNIMPAIRED COMMANDS
    -- ========================================

    resolvers.define_command_resolver("goto_next_diag", function()
        return function()
            vim.diagnostic.goto_next()
        end
    end)

    resolvers.define_command_resolver("goto_prev_diag", function()
        return function()
            vim.diagnostic.goto_prev()
        end
    end)

    resolvers.define_command_resolver("goto_last_diag", function()
        return function()
            local diagnostics = vim.diagnostic.get(0)
            if #diagnostics > 0 then
                vim.diagnostic.goto_next({ cursor_position = { math.huge, math.huge } })
            end
        end
    end)

    resolvers.define_command_resolver("goto_first_diag", function()
        return function()
            local diagnostics = vim.diagnostic.get(0)
            if #diagnostics > 0 then
                vim.diagnostic.goto_next({ cursor_position = { 1, 1 } })
            end
        end
    end)

    resolvers.define_command_resolver("goto_next_function", function()
        return function()
            vim.cmd("normal! ]m")
        end
    end)

    resolvers.define_command_resolver("goto_prev_function", function()
        return function()
            vim.cmd("normal! [m")
        end
    end)

    resolvers.define_command_resolver("goto_next_class", function()
        return function()
            vim.cmd("normal! ]]")
        end
    end)

    resolvers.define_command_resolver("goto_prev_class", function()
        return function()
            vim.cmd("normal! [[")
        end
    end)

    resolvers.define_command_resolver("goto_next_parameter", function()
        return function()
            -- Simplified implementation
            vim.cmd("normal! f,")
        end
    end)

    resolvers.define_command_resolver("goto_prev_parameter", function()
        return function()
            -- Simplified implementation
            vim.cmd("normal! F,")
        end
    end)

    resolvers.define_command_resolver("goto_next_comment", function()
        return function()
            vim.cmd("normal! /\\v^\\s*\\/\\/")
        end
    end)

    resolvers.define_command_resolver("goto_prev_comment", function()
        return function()
            vim.cmd("normal! ?\\v^\\s*\\/\\/")
        end
    end)

    resolvers.define_command_resolver("goto_next_test", function()
        return function()
            vim.cmd("normal! /\\v(test|it|describe)")
        end
    end)

    resolvers.define_command_resolver("goto_prev_test", function()
        return function()
            vim.cmd("normal! ?\\v(test|it|describe)")
        end
    end)

    resolvers.define_command_resolver("goto_next_paragraph", function()
        return function()
            vim.cmd("normal! }")
        end
    end)

    resolvers.define_command_resolver("goto_prev_paragraph", function()
        return function()
            vim.cmd("normal! {")
        end
    end)

    resolvers.define_command_resolver("goto_next_change", function()
        return function()
            vim.cmd("normal! ]c")
        end
    end)

    resolvers.define_command_resolver("goto_prev_change", function()
        return function()
            vim.cmd("normal! [c")
        end
    end)

    resolvers.define_command_resolver("goto_last_change", function()
        return function()
            vim.cmd("normal! G]c")
        end
    end)

    resolvers.define_command_resolver("goto_first_change", function()
        return function()
            vim.cmd("normal! gg[c")
        end
    end)

    resolvers.define_command_resolver("add_newline_below", function()
        return function()
            vim.cmd("normal! o" .. vim.api.nvim_replace_termcodes("<Esc>", true, false, true))
        end
    end)

    resolvers.define_command_resolver("add_newline_above", function()
        return function()
            vim.cmd("normal! O" .. vim.api.nvim_replace_termcodes("<Esc>", true, false, true))
        end
    end)

    -- ========================================
    -- MINOR MODE COMMANDS
    -- ========================================

    resolvers.define_command_resolver("select_mode", function()
        return function()
            vim.cmd("normal! v")
        end
    end)

    resolvers.define_command_resolver("command_mode", function()
        return function()
            vim.cmd("normal! :")
        end
    end)

    -- ========================================
    -- EXISTING COMMANDS (keeping for compatibility)
    -- ========================================

    resolvers.define_command_resolver("goto_definition", function()
        return function()
            vim.lsp.buf.definition()
        end
    end)

    resolvers.define_command_resolver("goto_reference", function()
        return function()
            vim.lsp.buf.references()
        end
    end)

    resolvers.define_command_resolver("write", function()
        return function()
            vim.cmd("write")
        end
    end)

    resolvers.define_command_resolver("quit", function()
        return function()
            vim.cmd("quit")
        end
    end)

    resolvers.define_command_resolver("normal_mode", function()
        return function()
            vim.cmd("stopinsert")
        end
    end)
end

return M
