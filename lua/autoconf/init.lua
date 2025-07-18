-- Add the config directory to the Lua path
local loader = require("autoconf.sys.core.loader")
local resolvers = require("autoconf.sys.core.resolvers")
local commands = require("autoconf.sys.commands")
local defaults = require("autoconf.sys.defaults")
local logger = require("autoconf.sys.core.logger")
local resolver_implementations = require("autoconf.sys.resolvers")
local helpers = require("autoconf.sys.core.helpers")
local defaults_lsp = require("autoconf.sys.defaults.lsp")
local defaults_base = require("autoconf.sys.defaults.base")
local defaults_tabs = require("autoconf.sys.defaults.tabs")
local themes = require("autoconf.sys.core.themes")

local M = {}

function M.init()
    -- Setup logger command
    logger.setup_debug_command()

    -- Plugin dependencies
    resolvers.register_plugin_dependency("lualine.nvim", "Statusline plugin for statusline configuration", "lualine")
    resolvers.register_plugin_dependency("nvim-autopairs", "Auto-pairing of brackets and quotes", "nvim-autopairs")
    resolvers.register_plugin_dependency("nvim-lspconfig", "LSP configuration for Neovim", "lspconfig")
    resolvers.register_plugin_dependency("nvim-cmp", "Completion plugin for auto-completion features")
    resolvers.register_plugin_dependency("telescope.nvim", "Fuzzy finder for file picker functionality")
    resolvers.register_plugin_dependency("nvim-treesitter", "Syntax highlighting and parsing")
    resolvers.register_plugin_dependency("gitsigns.nvim", "Git integration for diff signs in gutters", "gitsigns")
    resolvers.register_plugin_dependency("conform.nvim", "Formatting plugin for auto-format functionality", "conform")
    resolvers.register_plugin_dependency("cmp-path", "Path completion source for nvim-cmp", "cmp_path")
    resolvers.register_plugin_dependency("bufferline.nvim", "Buffer line/tab display at the top of the editor",
        "bufferline")
    resolvers.register_plugin_dependency("hop.nvim", "Jump navigation plugin for jump-label functionality", "hop")
    resolvers.register_plugin_dependency("lsp_lines",
        "renders diagnostics using virtual lines on top of the real line of code", "lsp_lines")
    resolvers.register_plugin_dependency("indent-blankline.nvim", " Indent guides for Neovim", "ibl")

    themes.load_all_themes()

    -- Path to the TOML config file (update this to your actual config path)
    local config_path = "config.toml"
    local languages_path = "languages.toml"

    -- Load the TOML config
    local user_config, err = loader.load_config(config_path)
    if not user_config then
        logger.config_error(config_path, err)
        return
    end

    logger.info("Configuration loaded from: %s", config_path)

    -- Merge default config with user config (user config overrides defaults)
    local config = helpers.deep_merge(defaults.default_config, user_config)

    defaults_base.init_base()
    defaults_base.init_tree_sitter()
    defaults_base.init_comment()

    -- Load the TOML config
    local languages_config, err = loader.load_config(languages_path)
    if not languages_config then
        logger.config_error(languages_path, err)
        return
    else
        local languages = {}
        for _, language in ipairs(languages_config.language) do
            languages[language["name"]] = language
        end
        defaults_lsp.setup(languages)
        defaults_tabs.setup_tabs(languages)
    end

    -- Initialize resolvers
    resolver_implementations.initalize_resolvers()
    helpers.resolve_configs(config, nil, false)

    -- Setup commands
    commands.setup_helix_health_command()
    commands.setup_theme_check_command()

    if config.editor and config.editor.theme then
        local theme_applier = require("autoconf.sys.resolvers.theme")
        local theme_config = themes.get_theme(config.editor.theme)
        if theme_config then
            theme_applier.apply_helix_theme(theme_config)
        end
    end
end

return M
