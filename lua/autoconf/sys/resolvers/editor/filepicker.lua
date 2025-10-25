local logger = require("autoconf.sys.core.logger")

local function build_fd_cmd(o)
  local cmd = { "fd", "--type", "f", "--color", "never" }

  -- hidden files?
  if o.hidden then
    table.insert(cmd, "--hidden")
  else
    table.insert(cmd, "--no-hidden")
  end

  -- follow symlinks?
  table.insert(cmd, o["follow-symlinks"] and "--follow" or "--no-follow")

  -- Respect gitignore and other ignore files (these are the important ones for .gitignore support)
  if o.parents       == false then table.insert(cmd, "--no-ignore-parent") end
  if o.ignore        == false then table.insert(cmd, "--no-ignore") end
  if o["git-ignore"] == false then table.insert(cmd, "--no-ignore-vcs") end
  if o["git-global"] == false then table.insert(cmd, "--no-global-ignore-file") end
  if o["git-exclude"]== false then table.insert(cmd, "--no-exclude") end
  
  -- Always exclude .git directory itself (this is the only hardcoded exclude we need)
  table.insert(cmd, "--exclude")
  table.insert(cmd, ".git")
  
  if type(o["max-depth"]) == "number" then
    table.insert(cmd, "--max-depth"); table.insert(cmd, tostring(o["max-depth"]))
  end

  return cmd
end

local M = {}

---@param opts table -- your [editor.file-picker] table
M.filepicker = function(opts)
  local ok, telescope = pcall(require, "telescope")
  if not ok then
    return logger.plugin_missing("telescope.nvim")
  end

  telescope.setup({
    defaults = {
      file_ignore_patterns = {},
      vimgrep_arguments = {
        "rg",
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--smart-case"
      },
    },
    pickers = {
      find_files = {
        find_command = build_fd_cmd(opts or {}),
        hidden       = opts.hidden,
        follow       = opts["follow-symlinks"],
      },
    },
  })

  logger.resolver_success("editor.file-picker", "configured with telescope.nvim")
end

return M