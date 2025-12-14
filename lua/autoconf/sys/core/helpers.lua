-- Re-export from focused modules for backward compatibility
local merge = require("autoconf.sys.core.merge")
local lifecycle = require("autoconf.sys.core.lifecycle")
local resolution = require("autoconf.sys.core.resolution")

local M = {}

-- Re-export deep_merge from merge module
M.deep_merge = merge.deep_merge

-- Re-export Lifecycle enum from lifecycle module
M.Lifecycle = lifecycle.Lifecycle

-- Re-export late_init_resolvers (now called execute_late_init)
M.late_init_resolvers = lifecycle.execute_late_init

-- Re-export resolve_configs from resolution module
M.resolve_configs = resolution.resolve_configs

return M
