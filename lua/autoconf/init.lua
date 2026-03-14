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

function M.init()
    -- Setup logger command
    logger.setup_debug_command()
    plugins.register_all(resolvers)

    local config_path = "config.toml"
    local languages_path = "languages.toml"

    local user_config, err = loader.load_config(config_path)
    if not user_config then
        logger.config_error(config_path, err)
        return
    end

    local config = helpers.deep_merge(defaults.default_config, user_config)

    defaults_base.init_base()
    defaults_base.init_auto_mkdir()

    local languages_config, lang_err = loader.load_config(languages_path)
    local languages = {}
    if not languages_config then
        logger.config_error(languages_path, lang_err)
    else
        for _, language in ipairs(languages_config.language) do
            languages[language["name"]] = language
        end
        defaults_tabs.setup_tabs(languages)
    end

    resolver_implementations.initalize_resolvers()
    helpers.resolve_configs(config, nil, false)

    commands.setup_helix_health_command()
    commands.setup_sudo_write_command()

    helpers.late_init_resolvers()

    -- Defer heavy plugin setup to after UI renders
    vim.schedule(function()
        defaults_base.init_tree_sitter()
        -- Defer CMP + conform to InsertEnter, LSP servers register now
        if next(languages) then
            defaults_lsp.setup_deferred(languages)
        end
    end)
end

M.define_resolver = function(path, resolver)
    resolvers.define_resolver(path, resolver)
end

M.define_command_resolver = function(name, resolver)
    resolvers.define_command_resolver(name, resolver)
end

M.Lifecycle = helpers.Lifecycle

return M

