local toml = require("autoconf.toml")

local M = {}

-- Strip comments from TOML content
-- @param content string Raw TOML content
-- @return string TOML content with comments removed
local function strip_comments(content)
    local lines = {}
    for line in content:gmatch("[^\n]*") do
        -- Find the first # that's not inside quotes
        local in_quotes = false
        local quote_char = nil
        local comment_start = nil
        
        for i = 1, #line do
            local char = line:sub(i, i)
            if char == '"' or char == "'" then
                if not in_quotes then
                    in_quotes = true
                    quote_char = char
                elseif char == quote_char then
                    -- Check if it's escaped
                    local escaped = false
                    local j = i - 1
                    while j >= 1 and line:sub(j, j) == '\\' do
                        escaped = not escaped
                        j = j - 1
                    end
                    if not escaped then
                        in_quotes = false
                        quote_char = nil
                    end
                end
            elseif char == '#' and not in_quotes then
                comment_start = i
                break
            end
        end
        
        -- Remove comment if found
        if comment_start then
            line = line:sub(1, comment_start - 1):match("^(.-)%s*$") or ""
        end
        
        table.insert(lines, line)
    end
    
    return table.concat(lines, "\n")
end

-- Load and parse a TOML config file
-- @param filename string Name of the config file (e.g., "config.toml")
-- @return table Parsed configuration table
-- @return nil, string Error message if parsing fails
function M.load_config(filename)
    -- Get Neovim config directories to search
    local config_paths = {
        vim.fn.stdpath("config"),
        vim.fn.stdpath("config") .. "/lua",
        vim.fn.stdpath("data") .. "/nvim",
    }
    
    local file_path = nil
    local file = nil
    local err = nil
    
    -- Search for the config file in each config directory
    for _, config_dir in ipairs(config_paths) do
        local candidate_path = config_dir .. "/" .. filename
        file, err = io.open(candidate_path, "r")
        if file then
            file_path = candidate_path
            break
        end
    end
    
    -- If file not found in any config directory, return error
    if not file then
        return nil, "Failed to find config file '" .. filename .. "' in config directories: " .. (err or "unknown error")
    end
    
    local content = file:read("*a")
    file:close()

    -- Strip comments before parsing to prevent hanging
    content = strip_comments(content)

    -- Parse TOML content
    local ok, config = pcall(toml.parse, content)
    if not ok then
        return nil, "Failed to parse TOML: " .. (config or "unknown error")
    end

    return config
end

return M