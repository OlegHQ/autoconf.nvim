-- Resolver implementations for Helix configuration
-- This file contains all the actual resolver functions that handle specific configuration paths

-- Import logger
local editor = require("autoconf.sys.resolvers.editor")
local command = require("autoconf.sys.resolvers.command")

return {
    initalize_resolvers = function()
        editor.register_editor_resolvers()
        command.register_command_resolvers()
    end
}
