local M = {}

-- Load the TOML parser
local toml = require('toml')

-- TOML parsing function using toml.lua library
function M.parse_toml(filepath)
  local file = io.open(filepath, "r")
  if not file then
    return nil, "Could not open file: " .. filepath
  end
  
  local content = file:read("*all")
  file:close()
  
  -- Parse TOML content using the toml.lua library
  local success, result = pcall(toml.parse, content)
  if not success then
    M.log("Failed to parse TOML file " .. filepath .. ": " .. tostring(result), vim.log.levels.ERROR)
    return {}
  end
  
  M.log("Successfully parsed TOML file: " .. filepath)
  return result
end

-- Deep merge two tables, with second table taking precedence
function M.deep_merge(base, override)
  if type(base) ~= "table" or type(override) ~= "table" then
    return override
  end
  
  local result = vim.deepcopy(base)
  
  for key, value in pairs(override) do
    if type(value) == "table" and type(result[key]) == "table" then
      result[key] = M.deep_merge(result[key], value)
    else
      result[key] = value
    end
  end
  
  return result
end

-- Convert Helix key notation to Vim key notation
function M.helix_key_to_vim(helix_key)
  -- Basic conversion mapping
  local key_map = {
    ["C-"] = "<C-",
    ["A-"] = "<M-",
    ["S-"] = "<S-",
    ["space"] = "<Space>",
    ["ret"] = "<CR>",
    ["esc"] = "<Esc>",
    ["tab"] = "<Tab>",
    ["del"] = "<Del>",
    ["backspace"] = "<BS>",
    ["up"] = "<Up>",
    ["down"] = "<Down>",
    ["left"] = "<Left>",
    ["right"] = "<Right>",
    ["home"] = "<Home>",
    ["end"] = "<End>",
    ["pageup"] = "<PageUp>",
    ["pagedown"] = "<PageDown>",
  }
  
  local result = helix_key
  
  -- Apply basic mappings
  for helix, vim in pairs(key_map) do
    result = result:gsub(helix, vim)
  end
  
  -- Ensure proper closing brackets for modifiers
  result = result:gsub("<C%-([^>]+)", "<C-%1>")
  result = result:gsub("<M%-([^>]+)", "<M-%1>")
  result = result:gsub("<S%-([^>]+)", "<S-%1>")
  
  return result
end

-- Convert Helix mode to Vim mode
function M.helix_mode_to_vim(helix_mode)
  local mode_map = {
    normal = "n",
    insert = "i",
    select = "v",
    visual = "v",
  }
  
  return mode_map[helix_mode] or "n"
end

-- Load and merge Helix configuration files
function M.load_helix_config()
  local config_dir = vim.fn.stdpath("config")
  local cwd = vim.fn.getcwd()
  
  -- Global config paths
  local global_config_path = config_dir .. "/helix/config.toml"
  local global_lang_path = config_dir .. "/helix/languages.toml"
  
  -- Project config paths
  local project_config_path = cwd .. "/.helix/config.toml"
  local project_lang_path = cwd .. "/.helix/languages.toml"
  
  -- Parse global configs
  local global_config = M.parse_toml(global_config_path) or {}
  local global_lang = M.parse_toml(global_lang_path) or {}
  
  -- Parse project configs
  local project_config = M.parse_toml(project_config_path) or {}
  local project_lang = M.parse_toml(project_lang_path) or {}
  
  -- Merge configurations
  local final_config = M.deep_merge(global_config, project_config)
  local final_lang = M.deep_merge(global_lang, project_lang)
  
  return {
    editor = final_config.editor or {},
    keys = final_config.keys or {},
    theme = final_config.theme,
    languages = final_lang,
  }
end

-- Safe logging function
function M.log(message, level)
  level = level or vim.log.levels.INFO
  vim.notify("[Helix Config] " .. message, level)
end

-- Check if a file exists
function M.file_exists(path)
  local file = io.open(path, "r")
  if file then
    file:close()
    return true
  end
  return false
end

-- Get config directory paths
function M.get_config_paths()
  local config_dir = vim.fn.stdpath("config")
  local cwd = vim.fn.getcwd()
  
  return {
    global = {
      config = config_dir .. "/helix/config.toml",
      languages = config_dir .. "/helix/languages.toml",
    },
    project = {
      config = cwd .. "/.helix/config.toml",
      languages = cwd .. "/.helix/languages.toml",
    },
  }
end

return M