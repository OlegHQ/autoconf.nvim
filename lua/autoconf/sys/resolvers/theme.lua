local M = {}

function M.apply_helix_theme(helix_theme)
    -- Clear existing highlights
    vim.cmd('highlight clear')
    if vim.fn.exists('syntax_on') then vim.cmd('syntax reset') end
    vim.o.background = 'dark'
    vim.g.colors_name = 'helix_theme'

    -- Helper to set highlight groups
    local function set_hl(group, attrs)
        local bg = attrs.bg and 'guibg=' .. attrs.bg or ''
        local fg = attrs.fg and 'guifg=' .. attrs.fg or ''
        local style = ''

        if attrs.modifiers then
            local mod_map = {
                bold = 'bold',
                italic = 'italic',
                underlined = 'underline',
                reversed = 'reverse',
            }
            for _, mod in ipairs(attrs.modifiers) do
                style = style .. (mod_map[mod] or '') .. ','
            end
        end

        if attrs.underline then
            style = style .. 'underline,'
            if attrs.underline.color then
                vim.cmd(string.format(
                    'highlight %s guisp=%s gui=%s %s %s',
                    group, attrs.underline.color, style, fg, bg
                ))
                return
            end
        end

        if style ~= '' then style = 'gui=' .. style end
        vim.cmd(string.format('highlight %s %s %s %s', group, style, fg, bg))
    end

    -- Map Helix keys to Neovim highlight groups
    local mappings = {
        -- Basic UI
        ['ui.background'] = { 'Normal', 'NormalNC', 'EndOfBuffer', 'SignColumn' },
        ['ui.text'] = { 'Normal' },
        ['ui.cursor'] = { 'Cursor' },
        ['ui.selection'] = { 'Visual' },
        ['ui.linenr'] = { 'LineNr' },
        ['ui.linenr.selected'] = { 'CursorLineNr' },
        ['ui.statusline'] = { 'StatusLine' },
        ['ui.statusline.inactive'] = { 'StatusLineNC' },
        ['ui.popup'] = { 'Pmenu' },
        ['ui.text.focus'] = { 'PmenuSel' },
        ['ui.window'] = { 'WinSeparator' },
        ['ui.menu'] = { 'WildMenu' },
        ['ui.menu.selected'] = { 'WildMenu' },

        -- Diagnostics
        ['error'] = { 'DiagnosticError' },
        ['warning'] = { 'DiagnosticWarn' },
        ['info'] = { 'DiagnosticInfo' },
        ['hint'] = { 'DiagnosticHint' },

        -- Syntax
        ['keyword'] = { '@keyword' },
        ['function'] = { '@function' },
        ['type'] = { '@type' },
        ['string'] = { '@string' },
        ['comment'] = { '@comment' },
        ['variable'] = { '@variable' },
        ['constant'] = { '@constant' },
        ['operator'] = { '@operator' },
        ['punctuation'] = { '@punctuation' },
        ['tag'] = { '@tag' },

        -- Plugins
        ['diff.plus'] = { 'GitSignsAdd' },
        ['diff.minus'] = { 'GitSignsDelete' },
        ['diff.delta'] = { 'GitSignsChange' },
        ['ui.bufferline'] = { 'BufferLineBackground' },
        ['ui.bufferline.active'] = { 'BufferLineBufferSelected' },
        ['ui.virtual.indent-guide'] = { 'IndentBlanklineChar' },
    }

    -- Apply mappings
    for helix_key, nvim_groups in pairs(mappings) do
        local attrs = helix_theme[helix_key]
        if attrs then
            if type(attrs) == 'string' then
                attrs = { fg = attrs }
            end
            for _, group in ipairs(nvim_groups) do
                set_hl(group, attrs)
            end
        end
    end

    -- Plugin-specific configuration
    if helix_theme['ui.statusline'] then
        require('lualine').setup({
            options = {
                theme = {
                    normal = {
                        a = { fg = helix_theme['ui.statusline'].fg, bg = helix_theme['ui.statusline'].bg },
                        b = { fg = helix_theme['ui.statusline'].fg, bg = helix_theme['ui.statusline'].bg },
                        c = { fg = helix_theme['ui.statusline'].fg, bg = helix_theme['ui.statusline'].bg }
                    }
                }
            }
        })
    end

    -- Set terminal colors if palette exists
    if helix_theme.palette then
        local term_colors = {
            black = 0,
            red = 1,
            green = 2,
            yellow = 3,
            blue = 4,
            magenta = 5,
            cyan = 6,
            white = 7,
            light_black = 8,
            light_red = 9,
            light_green = 10,
            light_yellow = 11,
            light_blue = 12,
            light_magenta = 13,
            light_cyan = 14,
            light_white = 15
        }

        for name, color in pairs(helix_theme.palette) do
            local idx = term_colors[name]
            if idx then
                vim.g['terminal_color_' .. idx] = color
            end
        end
    end
end

return M
