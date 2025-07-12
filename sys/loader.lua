local toml = require("toml")

local M = {}

-- Load and parse a TOML config file
-- @param file_path string Path to the TOML file
-- @return table Parsed configuration table
-- @return nil, string Error message if parsing fails
function M.load_config(file_path)
    -- Read file contents
    local file, err = io.open(file_path, "r")
    if not file then
        return nil, "Failed to open file: " .. (err or "unknown error")
    end
    
    local content = file:read("*a")
    file:close()

    -- Parse TOML content
    local ok, config = pcall(toml.parse, content)
    if not ok then
        return nil, "Failed to parse TOML: " .. (config or "unknown error")
    end

    return config
end

return M