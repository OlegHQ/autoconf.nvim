local logger = require("autoconf.sys.core.logger")

local M = {}

-- Cached config, setup deferred to first use
local _fzf_config = nil
local _setup_done = false

local function build_fzf_config(opts)
  local fd_opts = "--type f --color never"

  if opts.hidden then
    fd_opts = fd_opts .. " --hidden"
  else
    fd_opts = fd_opts .. " --no-hidden"
  end

  fd_opts = fd_opts .. (opts["follow-symlinks"] and " --follow" or " --no-follow")

  if opts["git-ignore"] == false then fd_opts = fd_opts .. " --no-ignore-vcs" end
  if opts.ignore == false then fd_opts = fd_opts .. " --no-ignore" end
  if opts.parents == false then fd_opts = fd_opts .. " --no-ignore-parent" end

  fd_opts = fd_opts .. " --exclude .git"

  if type(opts["max-depth"]) == "number" then
    fd_opts = fd_opts .. " --max-depth " .. tostring(opts["max-depth"])
  end

  return {
    files = { fd_opts = fd_opts },
    grep = {
      rg_opts = "--color=never --no-heading --with-filename --line-number --column --smart-case",
    },
  }
end

--- Ensure fzf-lua is set up (called on first use)
function M.ensure_setup()
  if _setup_done then return true end
  -- Clear FZF_DEFAULT_OPTS to prevent --height conflicts in Neovim terminal
  vim.env.FZF_DEFAULT_OPTS = ""
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then return false end
  if _fzf_config then
    fzf.setup(_fzf_config)
  end
  _setup_done = true
  return true
end

---@param opts table -- your [editor.file-picker] table
M.filepicker = function(opts)
  -- Build config now, but defer require("fzf-lua") to first keypress
  _fzf_config = build_fzf_config(opts or {})
  logger.resolver_success("editor.file-picker", "configured (deferred setup)")
end

return M
