-- Configuration resolution logic
local logger = require("autoconf.sys.core.logger")
local resolvers = require("autoconf.sys.core.resolvers")
local lifecycle = require("autoconf.sys.core.lifecycle")

local M = {}

--- Split a dotted path into parts
--- @param path string
--- @return string[]
local function split_path(path)
    local parts = {}
    for part in path:gmatch("[^%.]+") do
        table.insert(parts, part)
    end
    return parts
end

--- Build a nested table from path parts and a value
--- @param path_parts string[]
--- @param value any
--- @param start_index number|nil
--- @return table|any
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

--- Try to resolve a config path using hierarchical fallback
--- @param full_path string The full dotted path
--- @param value any The value at this path
--- @param debug boolean|nil Whether to enable debug logging
--- @return boolean Whether resolution was successful
local function try_resolve_with_fallback(full_path, value, debug)
    -- Special handling for keymap paths (keys.mode.combo)
    if resolvers.is_keymap_path(full_path) then
        local mode, keys, has_space = resolvers.match_keymap_mode_keys(full_path)

        if mode and keys then
            resolvers.attempt_to_keymap(full_path, keys, mode, value, has_space)
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
            local resolver, resolver_lifecycle = lifecycle.unwrap_resolver(resolvers.get_resolver(current_path))

            -- If this is the exact path, use the original value
            if i == #path_parts then
                if resolver_lifecycle == lifecycle.Lifecycle.LATE then
                    lifecycle.queue_late_init(current_path, resolver, value)
                else
                    resolver(value)
                end
            else
                -- Build nested structure for remaining path parts
                local nested_value = build_nested_table(path_parts, value, i + 1)
                if resolver_lifecycle == lifecycle.Lifecycle.LATE then
                    lifecycle.queue_late_init(current_path, resolver, nested_value)
                else
                    resolver(nested_value)
                end
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

--- Recursively resolve all configuration values
--- @param config table The configuration table to resolve
--- @param prefix string|nil The current path prefix
--- @param debug boolean|nil Whether to enable debug logging
function M.resolve_configs(config, prefix, debug)
    prefix = prefix or ""

    for key, value in pairs(config) do
        local full_key = prefix == "" and key or (prefix .. "." .. key)

        if type(value) == "table" then
            if not try_resolve_with_fallback(full_key, value, debug) then
                M.resolve_configs(value, full_key, debug)
            end
        else
            try_resolve_with_fallback(full_key, value, debug)
        end
    end
end

return M
