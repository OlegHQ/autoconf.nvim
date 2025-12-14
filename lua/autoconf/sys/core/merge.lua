-- Deep merge utility for configuration tables
local M = {}

--- Deep merge two tables, with override taking precedence
--- @param default table The base table
--- @param override table The overriding table
--- @return table The merged result (new table, inputs not modified)
function M.deep_merge(default, override)
    local result = {}

    -- Copy all values from default
    for key, value in pairs(default) do
        if type(value) == "table" then
            result[key] = M.deep_merge(value, {})
        else
            result[key] = value
        end
    end

    -- Override with values from override table
    for key, value in pairs(override) do
        if type(value) == "table" and type(result[key]) == "table" then
            result[key] = M.deep_merge(result[key], value)
        else
            result[key] = value
        end
    end

    return result
end

return M
