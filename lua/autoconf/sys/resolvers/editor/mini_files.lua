local logger = require("autoconf.sys.core.logger")

local M = {}

local _setup_done = false
local _lua_config = nil
local _schedule_armed = false

local ALLOWED_TOP = {
  content = true,
  mappings = true,
  options = true,
  windows = true,
}

--- Whitelist TOML-safe subtrees for require('mini.files').setup()
--- @param opts table|nil
--- @return table
local function to_setup_table(opts)
  if type(opts) ~= "table" then
    return {}
  end
  local out = {}
  for top, sub in pairs(opts) do
    if ALLOWED_TOP[top] and type(sub) == "table" then
      out[top] = vim.deepcopy(sub)
    end
  end
  return out
end

function M.ensure_setup()
  if _setup_done then
    return true
  end
  local ok, mf = pcall(require, "mini.files")
  if not ok then
    return false
  end
  mf.setup(_lua_config or {})
  _setup_done = true
  return true
end

--- Called from editor.mini-files resolver; defers require + setup to next main loop tick
function M.configure(opts)
  _lua_config = to_setup_table(opts)

  if not _schedule_armed then
    _schedule_armed = true
    vim.schedule(function()
      M.ensure_setup()
    end)
  end

  logger.resolver_success("editor.mini-files", "configured (deferred setup)")
end

return M
