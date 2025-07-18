-- Logger module for Helix configuration system
-- Provides controlled logging with debug mode toggle

local M = {}

-- Logger state
M.debug_mode = false
M.log_levels = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4
}

-- Current log level (only messages at or above this level will be shown)
M.current_level = M.log_levels.ERROR

-- Enable debug mode
function M.enable_debug()
    M.debug_mode = true
    M.current_level = M.log_levels.DEBUG
    M.info("Debug mode enabled")
end

-- Disable debug mode
function M.disable_debug()
    M.debug_mode = false
    M.current_level = M.log_levels.INFO
    M.info("Debug mode disabled")
end

-- Check if debug mode is enabled
function M.is_debug_enabled()
    return M.debug_mode
end

-- Toggle debug mode
function M.toggle_debug()
    if M.debug_mode then
        M.disable_debug()
    else
        M.enable_debug()
    end
end

-- Internal logging function
local function log(level, level_name, message, ...)
    if level < M.current_level then
        return
    end
    
    local formatted_message
    if select('#', ...) > 0 then
        formatted_message = string.format(message, ...)
    else
        formatted_message = tostring(message)
    end
    
    -- Add timestamp and level prefix
    local timestamp = os.date("%H:%M:%S")
    local prefix = string.format("[%s] [%s]", timestamp, level_name)
    
    -- Use vim.notify for better integration with Neovim
    local notify_level = vim.log.levels.INFO
    if level == M.log_levels.DEBUG then
        notify_level = vim.log.levels.DEBUG
    elseif level == M.log_levels.WARN then
        notify_level = vim.log.levels.WARN
    elseif level == M.log_levels.ERROR then
        notify_level = vim.log.levels.ERROR
    end
    
    -- Output to console and vim.notify
    print(prefix .. " " .. formatted_message)
    
    -- Only use vim.notify for warnings and errors to avoid spam
    if level >= M.log_levels.WARN then
        vim.notify(formatted_message, notify_level)
    end
end

-- Debug level logging (only shown when debug mode is on)
function M.debug(message, ...)
    log(M.log_levels.DEBUG, "DEBUG", message, ...)
end

-- Info level logging
function M.info(message, ...)
    log(M.log_levels.INFO, "INFO", message, ...)
end

-- Warning level logging
function M.warn(message, ...)
    log(M.log_levels.WARN, "WARN", message, ...)
end

-- Error level logging
function M.error(message, ...)
    log(M.log_levels.ERROR, "ERROR", message, ...)
end

-- Resolver-specific logging functions
function M.resolver_success(resolver_name, value)
    M.info("Resolver '%s' applied successfully: %s", resolver_name, tostring(value))
end

function M.resolver_error(resolver_name, error_msg)
    M.error("Resolver '%s' failed: %s", resolver_name, error_msg)
end

function M.resolver_fallback(original_path, fallback_path)
    M.debug("Resolver fallback: %s -> %s", original_path, fallback_path)
end

function M.keymap_success(key_path, command)
    M.info("Keymap resolved: %s -> %s", key_path, command)
end

function M.keymap_error(key_path, error_msg)
    M.error("Keymap failed: %s -> %s", key_path, error_msg)
end


function M.config_error(config_path, error_msg)
    M.error("Failed to load configuration from %s: %s", config_path, error_msg)
end

-- Plugin-related logging
function M.plugin_missing(plugin_name)
    M.warn("Plugin '%s' not found", plugin_name)
end

function M.plugin_found(plugin_name)
    M.debug("Plugin '%s' found", plugin_name)
end

-- Hierarchical resolver debugging
function M.debug_resolver_lookup(full_path, paths_tried)
    if not M.debug_mode then return end
    
    M.debug("=== Resolver lookup for path: %s ===", full_path)
    M.debug("Trying paths in order:")
    for i, path_info in ipairs(paths_tried) do
        local status = path_info.found and "FOUND" or "not found"
        M.debug("  %s -> %s", path_info.path, status)
        if path_info.found then
            if path_info.direct then
                M.debug("    Will call with original value")
            else
                M.debug("    Will call with nested structure for remaining parts")
            end
            break
        end
    end
    M.debug("=== End resolver lookup ===")
end

-- Create vim command to toggle debug mode
function M.setup_debug_command()
    vim.api.nvim_create_user_command('AutoconfDebug', function(opts)
        local action = opts.args:lower()
        if action == "on" or action == "enable" then
            M.enable_debug()
        elseif action == "off" or action == "disable" then
            M.disable_debug()
        elseif action == "toggle" or action == "" then
            M.toggle_debug()
        elseif action == "status" then
            M.info("Debug mode is %s", M.debug_mode and "enabled" or "disabled")
        else
            M.error("Invalid argument. Use: on|off|toggle|status")
        end
    end, {
        nargs = '?',
        complete = function()
            return {'on', 'off', 'toggle', 'status'}
        end,
        desc = 'Control Helix configuration debug mode'
    })
end

return M
