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
local plugins = require("autoconf.sys.defaults.plugins")

local M = {}

-- additional mappings for multi cursor
vim.g.VM_maps = {
  ["Add Cursor Down"] = "<C-S-j>",
  ["Add Cursor Up"] = "<C-S-k>",
}

function M.init()

    -- Setup logger command
    logger.setup_debug_command()

    -- Register plugin dependencies from manifest
    plugins.register_all(resolvers)

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
    commands.setup_sudo_write_command()

    -- Late init resolvers
    helpers.late_init_resolvers()
end

M.define_resolver = function(path, resolver)
    resolvers.define_resolver(path, resolver)
end

M.define_command_resolver = function(name, resolver)
    resolvers.define_command_resolver(name, resolver)
end

M.Lifecycle = helpers.Lifecycle

return M

