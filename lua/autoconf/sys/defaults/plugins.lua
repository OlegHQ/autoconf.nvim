-- Declarative plugin dependency manifest
-- All plugin dependencies are defined here instead of procedural calls in init.lua

local M = {}

--- Plugin dependency definitions
--- @field name string Plugin name (for display)
--- @field desc string Human-readable description
--- @field module string|nil Lua module name for require() check (nil = check runtimepath only)
M.dependencies = {
    {
        name = "lualine.nvim",
        desc = "Statusline plugin for statusline configuration",
        module = "lualine"
    },
    {
        name = "nvim-autopairs",
        desc = "Auto-pairing of brackets and quotes",
        module = "nvim-autopairs"
    },
    {
        name = "nvim-lspconfig",
        desc = "LSP configuration for Neovim",
        module = "lspconfig"
    },
    {
        name = "nvim-cmp",
        desc = "Completion plugin for auto-completion features",
        module = nil  -- Check runtimepath only
    },
    {
        name = "telescope.nvim",
        desc = "Fuzzy finder for file picker functionality",
        module = nil  -- Check runtimepath only
    },
    {
        name = "nvim-treesitter",
        desc = "Syntax highlighting and parsing",
        module = nil  -- Check runtimepath only
    },
    {
        name = "gitsigns.nvim",
        desc = "Git integration for diff signs in gutters",
        module = "gitsigns"
    },
    {
        name = "conform.nvim",
        desc = "Formatting plugin for auto-format functionality",
        module = "conform"
    },
    {
        name = "cmp-path",
        desc = "Path completion source for nvim-cmp",
        module = "cmp_path"
    },
    {
        name = "bufferline.nvim",
        desc = "Buffer line/tab display at the top of the editor",
        module = "bufferline"
    },
    {
        name = "hop.nvim",
        desc = "Jump navigation plugin for jump-label functionality",
        module = "hop"
    },
    {
        name = "lsp_lines",
        desc = "Renders diagnostics using virtual lines on top of the real line of code",
        module = "lsp_lines"
    },
    {
        name = "indent-blankline.nvim",
        desc = "Indent guides for Neovim",
        module = "ibl"
    },
}

--- Register all plugin dependencies with the resolvers module
--- @param resolvers table The resolvers module
function M.register_all(resolvers)
    for _, plugin in ipairs(M.dependencies) do
        resolvers.register_plugin_dependency(plugin.name, plugin.desc, plugin.module)
    end
end

--- Get a list of plugin names
--- @return string[]
function M.get_plugin_names()
    local names = {}
    for _, plugin in ipairs(M.dependencies) do
        table.insert(names, plugin.name)
    end
    return names
end

--- Get plugin count
--- @return number
function M.count()
    return #M.dependencies
end

return M
