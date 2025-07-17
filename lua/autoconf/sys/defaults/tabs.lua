local M = {}

local default_lang_settings = {
    filetypes = {
        typescript = { "typescript", "typescriptreact" } },
    tabs = {
        go = { width = 4, expand = false },
        javascript = { width = 2, expand = true },
        typescript = { width = 2, expand = true },
        python = { width = 4, expand = true }
    }
}

M.setup_tabs = function(languages)
    local defaults = default_lang_settings
    local tabset_group = vim.api.nvim_create_augroup("tabset", { clear = true })
    for name, c in pairs(languages) do
        local lang_setting = c.tab
        local tabsettings
        if not lang_setting then
            tabsettings = defaults.tabs[name]
        else
            tabsettings = lang_setting
        end
        local settings
        if not tabsettings then
            settings = { width = 4, expand = true }
        else
            settings = tabsettings
        end
        local width = settings.width
        local expand = settings.expand
        local ft = defaults.filetypes[name]
        local types
        if not ft then
            types = { name }
        else
            types = ft
        end
        for _, t in ipairs(types) do
            local function _31_()
                vim.opt["tabstop"] = width
                vim.opt["shiftwidth"] = width
                vim.opt["expandtab"] = expand
                return nil
            end
            vim.api.nvim_create_autocmd("FileType", { group = tabset_group, pattern = t, callback = _31_ })
        end
    end
    return nil
end

return M
