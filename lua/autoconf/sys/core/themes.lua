local loader = require("autoconf.sys.core.loader")
local logger = require("autoconf.sys.core.logger")

local M = {}

M.loaded_themes = {}

function M.load_all_themes()
    -- Skip if already loaded
    if vim.tbl_count(M.loaded_themes) > 0 then
        return M.loaded_themes
    end
    
    -- Get the Neovim config directory
    local config_dir = vim.fn.stdpath('config')
    local themes_dir = config_dir .. '/themes'
    
    -- Check if themes directory exists
    if vim.fn.isdirectory(themes_dir) == 0 then
        logger.warn("Themes directory not found: %s", themes_dir)
        return M.loaded_themes
    end
    
    -- Find all .toml files in the themes directory
    local toml_files = vim.fn.glob(themes_dir .. '/*.toml', false, true)
    
    if #toml_files == 0 then
        logger.info("No TOML theme files found in: %s", themes_dir)
        return M.loaded_themes
    end
    
    -- Load each TOML file
    for _, file_path in ipairs(toml_files) do
        -- Get just the filename without extension
        local filename = vim.fn.fnamemodify(file_path, ':t:r')
        
        -- Use relative path from themes directory for the loader
        local relative_path = 'themes/' .. filename .. '.toml'
        
        -- Load the TOML config using the same loader as init.lua
        local theme_config, err = loader.load_config(relative_path)
        
        if theme_config then
            M.loaded_themes[filename] = theme_config
            logger.info("Loaded theme: %s from %s", filename, relative_path)
        else
            logger.config_error(relative_path, err)
        end
    end
    
    logger.info("Loaded %d theme(s) from: %s", vim.tbl_count(M.loaded_themes), themes_dir)
    return M.loaded_themes
end

function M.get_theme(theme_name)
    return M.loaded_themes[theme_name]
end

function M.list_available_themes()
    local theme_names = {}
    
    for name, _ in pairs(M.loaded_themes) do
        table.insert(theme_names, name)
    end
    
    table.sort(theme_names)
    return theme_names
end

return M
