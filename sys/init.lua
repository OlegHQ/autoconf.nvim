local M = {}

-- Import utility functions
local util = require('sys.util')

-- Configuration state
local config_loaded = false
local config_cache = {}

-- Setup function - main entry point for the Helix config layer
function M.setup(opts)
  opts = opts or {}
  
  -- Prevent double initialization
  if config_loaded then
    util.log("Helix config already loaded, skipping", vim.log.levels.WARN)
    return
  end
  
  util.log("Loading Helix configuration...")
  
  -- Load and parse configuration files
  local success, config = pcall(util.load_helix_config)
  if not success then
    util.log("Failed to load Helix config: " .. tostring(config), vim.log.levels.ERROR)
    return
  end
  
  -- Cache the configuration
  config_cache = config
  
  -- Apply configurations in order
  local apply_success = true
  
  -- 1. Apply editor settings first (theme, UI, etc.)
  if config.editor and next(config.editor) then
    local editor_success, editor_err = pcall(function()
      require('sys.config').apply(config.editor)
    end)
    if not editor_success then
      util.log("Failed to apply editor config: " .. tostring(editor_err), vim.log.levels.ERROR)
      apply_success = false
    end
  end
  
  -- 2. Apply key mappings
  if config.keys and next(config.keys) then
    local keys_success, keys_err = pcall(function()
      require('sys.keys').apply(config.keys)
    end)
    if not keys_success then
      util.log("Failed to apply key mappings: " .. tostring(keys_err), vim.log.levels.ERROR)
      apply_success = false
    end
  end
  
  -- 3. Apply language configurations (defer if needed)
  if config.languages and next(config.languages) then
    -- Language config might need to be deferred until after plugin loading
    local lang_success, lang_err = pcall(function()
      require('sys.languages').apply(config.languages)
    end)
    if not lang_success then
      util.log("Failed to apply language config: " .. tostring(lang_err), vim.log.levels.ERROR)
      apply_success = false
    end
  end
  
  -- 4. Apply theme if specified
  if config.theme then
    local theme_success, theme_err = pcall(function()
      vim.cmd.colorscheme(config.theme)
    end)
    if not theme_success then
      util.log("Failed to apply theme '" .. config.theme .. "': " .. tostring(theme_err), vim.log.levels.WARN)
    end
  end
  
  config_loaded = true
  
  if apply_success then
    util.log("Helix configuration loaded successfully")
  else
    util.log("Helix configuration loaded with some errors", vim.log.levels.WARN)
  end
end

-- Get the cached configuration
function M.get_config()
  return config_cache
end

-- Reload configuration (useful for development)
function M.reload()
  config_loaded = false
  config_cache = {}
  M.setup()
end

-- Check if configuration is loaded
function M.is_loaded()
  return config_loaded
end

-- Setup deferred language configuration (for use after plugin loading)
function M.setup_languages_deferred()
  if not config_loaded then
    util.log("Config not loaded, cannot setup deferred languages", vim.log.levels.WARN)
    return
  end
  
  if config_cache.languages and next(config_cache.languages) then
    local success, err = pcall(function()
      require('sys.languages').apply_deferred(config_cache.languages)
    end)
    if not success then
      util.log("Failed to apply deferred language config: " .. tostring(err), vim.log.levels.ERROR)
    end
  end
end

-- Get configuration paths for debugging
function M.get_paths()
  return util.get_config_paths()
end

-- Validate configuration files exist
function M.validate_config_files()
  local paths = util.get_config_paths()
  local status = {
    global_config = util.file_exists(paths.global.config),
    global_languages = util.file_exists(paths.global.languages),
    project_config = util.file_exists(paths.project.config),
    project_languages = util.file_exists(paths.project.languages),
  }
  
  return status
end

-- Create user commands for managing Helix config
function M.setup_commands()
  vim.api.nvim_create_user_command('HelixReload', function()
    M.reload()
  end, { desc = 'Reload Helix configuration' })
  
  vim.api.nvim_create_user_command('HelixStatus', function()
    local status = M.validate_config_files()
    local paths = M.get_paths()
    
    print("Helix Configuration Status:")
    print("Loaded: " .. tostring(M.is_loaded()))
    print("\nConfig Files:")
    print("Global config: " .. paths.global.config .. " (" .. (status.global_config and "exists" or "missing") .. ")")
    print("Global languages: " .. paths.global.languages .. " (" .. (status.global_languages and "exists" or "missing") .. ")")
    print("Project config: " .. paths.project.config .. " (" .. (status.project_config and "exists" or "missing") .. ")")
    print("Project languages: " .. paths.project.languages .. " (" .. (status.project_languages and "exists" or "missing") .. ")")
  end, { desc = 'Show Helix configuration status' })
  
  vim.api.nvim_create_user_command('HelixEdit', function(opts)
    local config_type = opts.args or "config"
    local paths = M.get_paths()
    
    local file_path
    if config_type == "config" then
      file_path = paths.global.config
    elseif config_type == "languages" then
      file_path = paths.global.languages
    elseif config_type == "project-config" then
      file_path = paths.project.config
    elseif config_type == "project-languages" then
      file_path = paths.project.languages
    else
      util.log("Unknown config type: " .. config_type, vim.log.levels.ERROR)
      return
    end
    
    -- Create directory if it doesn't exist
    local dir = vim.fn.fnamemodify(file_path, ":h")
    vim.fn.mkdir(dir, "p")
    
    vim.cmd.edit(file_path)
  end, {
    desc = 'Edit Helix configuration file',
    nargs = '?',
    complete = function()
      return { "config", "languages", "project-config", "project-languages" }
    end
  })
end

return M