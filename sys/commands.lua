local M = {}

-- Function to collect all config keys recursively
local function collect_config_keys(config, prefix, keys)
    prefix = prefix or ""
    keys = keys or {}
    
    for key, value in pairs(config) do
        local full_key = prefix == "" and key or (prefix .. "." .. key)
        
        if type(value) == "table" then
            -- Recursively collect keys from nested tables
            collect_config_keys(value, full_key, keys)
        else
            -- Add the key-value pair to our collection
            table.insert(keys, {
                key = full_key,
                value = value,
                type = type(value)
            })
        end
    end
    
    return keys
end

-- Function to create the HelixHealth command
function M.setup_helix_health_command()
    vim.api.nvim_create_user_command('HelixHealth', function()
        local loader = require("sys.loader")
        local resolvers = require("sys.resolvers")
        
        -- Load the config
        local config_path = "config.toml"
        local config, err = loader.load_config(config_path)
        
        if not config then
            vim.notify("Failed to load config: " .. err, vim.log.levels.ERROR)
            return
        end
        
        -- Collect all config keys
        local config_keys = collect_config_keys(config)
        
        -- Sort keys alphabetically for better readability
        table.sort(config_keys, function(a, b) return a.key < b.key end)
        
        -- Create the health report
        local lines = {}
        table.insert(lines, "# Helix Configuration Health Report")
        table.insert(lines, "")
        table.insert(lines, "Configuration file: " .. config_path)
        table.insert(lines, "Total configuration keys: " .. #config_keys)
        table.insert(lines, "")
        
        local resolved_count = 0
        local unresolved_count = 0
        
        -- Check each config key
        for _, item in ipairs(config_keys) do
            local status
            local is_resolved = false
            
            -- Special handling for keymap paths
            if resolvers.is_keymap_path(item.key) then
                is_resolved = resolvers.is_keymap_resolved(item.key)
                status = is_resolved and "✓ KEYMAP RESOLVED" or "✗ KEYMAP FAILED"
                
                -- Add error details if keymap failed
                if not is_resolved then
                    local keymap_status = resolvers.get_keymap_status(item.key)
                    if keymap_status and keymap_status.error then
                        status = status .. " (" .. tostring(keymap_status.error) .. ")"
                    end
                end
            else
                is_resolved = resolvers.has_resolver(item.key)
                status = is_resolved and "✓ RESOLVED" or "✗ NOT RESOLVED"
            end
            
            local value_str = tostring(item.value)
            
            -- Truncate long values
            if #value_str > 50 then
                value_str = value_str:sub(1, 47) .. "..."
            end
            
            table.insert(lines, string.format("%-30s %-20s %s", item.key, status, value_str))
            
            if is_resolved then
                resolved_count = resolved_count + 1
            else
                unresolved_count = unresolved_count + 1
            end
        end
        
        table.insert(lines, "")
        table.insert(lines, "## Plugin Dependencies")
        table.insert(lines, "")
        
        local plugin_dependencies = resolvers.get_plugin_dependencies()
        local installed_plugins = 0
        local missing_plugins = 0
        
        -- Sort plugin names for consistent output
        local plugin_names = {}
        for name, _ in pairs(plugin_dependencies) do
            table.insert(plugin_names, name)
        end
        table.sort(plugin_names)
        
        for _, plugin_name in ipairs(plugin_names) do
            local status = resolvers.check_plugin_status(plugin_name)
            if status then
                local plugin_status = status.installed and "✓ INSTALLED" or "✗ MISSING"
                table.insert(lines, string.format("%-30s %-15s %s", plugin_name, plugin_status, status.description))
                
                if status.installed then
                    installed_plugins = installed_plugins + 1
                else
                    missing_plugins = missing_plugins + 1
                end
            end
        end
        
        table.insert(lines, "")
        table.insert(lines, "## Summary")
        table.insert(lines, "### Configuration")
        table.insert(lines, "Resolved: " .. resolved_count)
        table.insert(lines, "Unresolved: " .. unresolved_count)
        table.insert(lines, "Coverage: " .. string.format("%.1f%%", (resolved_count / #config_keys) * 100))
        table.insert(lines, "")
        table.insert(lines, "### Plugins")
        table.insert(lines, "Installed: " .. installed_plugins)
        table.insert(lines, "Missing: " .. missing_plugins)
        if #plugin_names > 0 then
            table.insert(lines, "Plugin Coverage: " .. string.format("%.1f%%", (installed_plugins / #plugin_names) * 100))
        end
        
        -- Create a new buffer to display the health report
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.api.nvim_buf_set_option(buf, 'modifiable', false)
        vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
        
        -- Open the buffer in a new window
        vim.cmd('split')
        vim.api.nvim_win_set_buf(0, buf)
        vim.api.nvim_buf_set_name(buf, 'HelixHealth')
        
    end, {
        desc = 'Show Helix configuration health status'
    })
end

return M