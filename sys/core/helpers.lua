local logger = require("sys.core.logger")
local resolvers = require("sys.core.resolvers")

local M = {}

-- Deep merge function to merge user config with defaults
M.deep_merge = function(default, override)
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

-- Helper function to build nested table from path parts and value
local function build_nested_table(path_parts, value, start_index)
    start_index = start_index or 1

    if start_index > #path_parts then
        return value
    end

    local result = {}
    local current_key = path_parts[start_index]
    result[current_key] = build_nested_table(path_parts, value, start_index + 1)

    return result
end

-- Helper function to split a path into parts
local function split_path(path)
    local parts = {}
    for part in path:gmatch("[^%.]+") do
        table.insert(parts, part)
    end
    return parts
end

-- Smart resolver function with hierarchical fallback
local function try_resolve_with_fallback(full_path, value, debug)
    -- Special handling for keymap paths (keys.mode.combo)
    if resolvers.is_keymap_path(full_path) then
        local mode = full_path:match("^keys%.(%w+)%.")
        local keys = full_path:match("^keys%.%w+%.(.+)$")

        if mode and keys then
            resolvers.attempt_to_keymap(keys, mode, value)
        end
        return true
    end

    -- Split the path into parts
    local path_parts = split_path(full_path)

    local paths_tried = {}

    -- Try resolvers from most specific to least specific
    for i = #path_parts, 1, -1 do
        -- Build the current path to try
        local current_path = table.concat(path_parts, ".", 1, i)
        local has_resolver = resolvers.has_resolver(current_path)

        table.insert(paths_tried, {
            path = current_path,
            found = has_resolver,
            direct = i == #path_parts
        })

        -- Check if there's a resolver for this path
        if has_resolver then
            local resolver = resolvers.get_resolver(current_path)

            -- If this is the exact path, use the original value
            if i == #path_parts then
                resolver(value)
            else
                -- Build nested structure for remaining path parts
                local nested_value = build_nested_table(path_parts, value, i + 1)
                resolver(nested_value)
                logger.resolver_fallback(full_path, current_path)
            end

            if debug then
                logger.debug_resolver_lookup(full_path, paths_tried)
            end
            return true
        end
    end

    if debug then
        logger.debug_resolver_lookup(full_path, paths_tried)
    end
    return false
end

M.resolve_configs = function(config, prefix, debug)
    prefix = prefix or ""

    for key, value in pairs(config) do
        local full_key = prefix == "" and key or (prefix .. "." .. key)

        if type(value) == "table" then
            -- First try to resolve this path as a whole (in case there's a resolver that handles nested configs)
            if not try_resolve_with_fallback(full_key, value, debug) then
                -- If no resolver found, recursively process nested tables
                M.resolve_configs(value, full_key, debug)
            end
        else
            -- Try to resolve with hierarchical fallback
            try_resolve_with_fallback(full_key, value, debug)
        end
    end
end

return M
