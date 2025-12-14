-- Resolver builder utilities to reduce boilerplate in resolver definitions
local logger = require("autoconf.sys.core.logger")
local resolvers = require("autoconf.sys.core.resolvers")

local M = {}

--- Validate a value's type against expected types
--- @param path string The config path for error messages
--- @param value any The value to validate
--- @param expected_types string|string[] Expected type(s)
--- @return boolean valid
local function validate_type(path, value, expected_types)
    local actual_type = type(value)
    if type(expected_types) == "string" then
        expected_types = { expected_types }
    end
    for _, t in ipairs(expected_types) do
        if actual_type == t then
            return true
        end
    end
    local expected_str = table.concat(expected_types, " or ")
    logger.resolver_error(path, "must be " .. expected_str .. ", got: " .. actual_type)
    return false
end

--- Create a simple vim.opt boolean toggle resolver
--- @param path string The config path (e.g. "editor.cursorcolumn")
--- @param opt_name string The vim.opt option name (e.g. "cursorcolumn")
--- @param opts? table Optional settings: enabled_msg, disabled_msg
--- @return function resolver
function M.vim_opt_boolean(path, opt_name, opts)
    opts = opts or {}
    local resolver = function(value)
        if not validate_type(path, value, "boolean") then
            return
        end
        vim.opt[opt_name] = value
        local msg = value and (opts.enabled_msg or "enabled") or (opts.disabled_msg or "disabled")
        logger.resolver_success(path, msg)
    end
    resolvers.define_resolver(path, resolver)
    return resolver
end

--- Create a vim.opt number resolver with validation
--- @param path string The config path
--- @param opt_name string The vim.opt option name
--- @param opts? table Optional: min, max, format (function to format success message)
--- @return function resolver
function M.vim_opt_number(path, opt_name, opts)
    opts = opts or {}
    local resolver = function(value)
        if not validate_type(path, value, "number") then
            return
        end
        if opts.min and value < opts.min then
            logger.resolver_error(path, "must be >= " .. tostring(opts.min) .. ", got: " .. tostring(value))
            return
        end
        if opts.max and value > opts.max then
            logger.resolver_error(path, "must be <= " .. tostring(opts.max) .. ", got: " .. tostring(value))
            return
        end
        vim.opt[opt_name] = value
        local msg = opts.format and opts.format(value) or tostring(value)
        logger.resolver_success(path, msg)
    end
    resolvers.define_resolver(path, resolver)
    return resolver
end

--- Create a vim.opt string resolver
--- @param path string The config path
--- @param opt_name string The vim.opt option name
--- @param opts? table Optional: allowed (list of valid values), format
--- @return function resolver
function M.vim_opt_string(path, opt_name, opts)
    opts = opts or {}
    local resolver = function(value)
        if not validate_type(path, value, "string") then
            return
        end
        if opts.allowed then
            local valid = false
            for _, v in ipairs(opts.allowed) do
                if v == value then
                    valid = true
                    break
                end
            end
            if not valid then
                logger.resolver_error(path, "must be one of: " .. table.concat(opts.allowed, ", "))
                return
            end
        end
        vim.opt[opt_name] = value
        local msg = opts.format and opts.format(value) or value
        logger.resolver_success(path, msg)
    end
    resolvers.define_resolver(path, resolver)
    return resolver
end

--- Create a resolver that maps values to vim.opt settings
--- @param path string The config path
--- @param opt_name string The vim.opt option name
--- @param map table Mapping of input values to vim.opt values
--- @param opts? table Optional: type (default "string")
--- @return function resolver
function M.vim_opt_mapped(path, opt_name, map, opts)
    opts = opts or {}
    local value_type = opts.type or "string"
    local resolver = function(value)
        if not validate_type(path, value, value_type) then
            return
        end
        local mapped = map[value]
        if mapped == nil then
            local keys = {}
            for k, _ in pairs(map) do
                table.insert(keys, tostring(k))
            end
            logger.resolver_error(path, "must be one of: " .. table.concat(keys, ", "))
            return
        end
        vim.opt[opt_name] = mapped
        logger.resolver_success(path, tostring(value) .. " (" .. tostring(mapped) .. ")")
    end
    resolvers.define_resolver(path, resolver)
    return resolver
end

--- Create a boolean toggle resolver with custom enable/disable handlers
--- @param path string The config path
--- @param opts table Settings: on (function), off (function), enabled_msg, disabled_msg
--- @return function resolver
function M.boolean_toggle(path, opts)
    local resolver = function(value)
        if not validate_type(path, value, "boolean") then
            return
        end
        if value then
            if opts.on then
                opts.on()
            end
            logger.resolver_success(path, opts.enabled_msg or "enabled")
        else
            if opts.off then
                opts.off()
            end
            logger.resolver_success(path, opts.disabled_msg or "disabled")
        end
    end
    resolvers.define_resolver(path, resolver)
    return resolver
end

--- Create a resolver that sets a vim global variable
--- @param path string The config path
--- @param var_name string The vim.g variable name
--- @param opts? table Optional: type (default "boolean"), enabled_msg, disabled_msg
--- @return function resolver
function M.vim_g_boolean(path, var_name, opts)
    opts = opts or {}
    local resolver = function(value)
        if not validate_type(path, value, "boolean") then
            return
        end
        vim.g[var_name] = value
        local msg = value and (opts.enabled_msg or "enabled") or (opts.disabled_msg or "disabled")
        logger.resolver_success(path, msg)
    end
    resolvers.define_resolver(path, resolver)
    return resolver
end

--- Create a plugin-dependent resolver
--- @param path string The config path
--- @param plugin_name string The Lua module name to require
--- @param handler fun(plugin: any, value: any) Handler function receiving plugin and value
--- @param opts? table Optional: types (expected value types), success_msg
--- @return function resolver
function M.with_plugin(path, plugin_name, handler, opts)
    opts = opts or {}
    local resolver = function(value)
        if opts.types and not validate_type(path, value, opts.types) then
            return
        end
        local ok, plugin = pcall(require, plugin_name)
        if not ok then
            logger.resolver_error(path, plugin_name .. " not found")
            return
        end
        local success, err = pcall(handler, plugin, value)
        if success then
            logger.resolver_success(path, opts.success_msg or "configured")
        else
            logger.resolver_error(path, tostring(err))
        end
    end
    resolvers.define_resolver(path, resolver)
    return resolver
end

--- Create a resolver without auto-registration (for manual registration)
--- @param path string The config path (for logging)
--- @param expected_type string|string[] Expected type(s)
--- @param handler fun(value: any) Handler function
--- @return function resolver
function M.custom(path, expected_type, handler)
    return function(value)
        if not validate_type(path, value, expected_type) then
            return
        end
        handler(value)
    end
end

--- Helper to validate type without creating a full resolver
M.validate_type = validate_type

return M
