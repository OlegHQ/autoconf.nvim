local M = {}

-- Import logger
local logger = require("autoconf.sys.core.logger")

-- Function to collect all config keys recursively
local function collect_config_keys(config, prefix, keys)
    prefix = prefix or ""
    keys = keys or {}

    for key, value in pairs(config) do
        local full_key = prefix == "" and key or (prefix .. "." .. key)

        if type(value) == "table" then
            local count, maximum = 0, 0
            local is_array = true
            for array_key in pairs(value) do
                if type(array_key) ~= "number" or array_key < 1 or array_key % 1 ~= 0 then
                    is_array = false
                    break
                end
                count = count + 1
                maximum = math.max(maximum, array_key)
            end
            if is_array and count == maximum and count > 0 then
                table.insert(keys, { key = full_key, value = value, type = "table" })
            else
                collect_config_keys(value, full_key, keys)
            end
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

-- Function to analyze config keys and count resolved/unresolved
local function analyze_config_keys(config_keys, resolvers)
    local resolved_count = 0
    local unresolved_count = 0
    local analyzed_keys = {}

    for _, item in ipairs(config_keys) do
        local status
        local is_resolved = false

        -- Workbench settings are validated atomically by its explicit TOML schema.
        if item.key:sub(1, #"editor.workbench.") == "editor.workbench." then
            is_resolved = require("autoconf.sys.resolvers.editor.workbench").is_supported_path(item.key)
            status = is_resolved and "✓ RESOLVED (workbench schema)" or "✗ NOT RESOLVED"
        -- Special handling for keymap paths
        elseif resolvers.is_keymap_path(item.key) then
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
            -- Use hierarchical fallback logic to check if the key would be resolved
            local would_resolve, resolver_path = resolvers.would_be_resolved(item.key)
            is_resolved = would_resolve

            if is_resolved then
                if resolver_path == item.key then
                    status = "✓ RESOLVED (direct)"
                else
                    status = "✓ RESOLVED (via " .. resolver_path .. ")"
                end
            else
                status = "✗ NOT RESOLVED"
            end
        end

        local value_str = tostring(item.value)

        -- Truncate long values
        if #value_str > 50 then
            value_str = value_str:sub(1, 47) .. "..."
        end

        table.insert(analyzed_keys, {
            key = item.key,
            status = status,
            value = value_str,
            resolved = is_resolved
        })

        if is_resolved then
            resolved_count = resolved_count + 1
        else
            unresolved_count = unresolved_count + 1
        end
    end

    return analyzed_keys, resolved_count, unresolved_count
end

-- Function to analyze plugin dependencies
local function analyze_plugin_dependencies(resolvers)
    local plugin_dependencies = resolvers.get_plugin_dependencies()
    local installed_plugins = 0
    local missing_plugins = 0
    local analyzed_plugins = {}

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
            table.insert(analyzed_plugins, {
                name = plugin_name,
                status = plugin_status,
                description = status.description
            })

            if status.installed then
                installed_plugins = installed_plugins + 1
            else
                missing_plugins = missing_plugins + 1
            end
        end
    end

    return analyzed_plugins, installed_plugins, missing_plugins, plugin_names
end

-- Function to generate header section
local function generate_header(config_path, total_keys)
    local lines = {}
    table.insert(lines, "# Helix Configuration Health Report")
    table.insert(lines, "")
    table.insert(lines, "Configuration file: " .. config_path)
    table.insert(lines, "Total configuration keys: " .. total_keys)
    table.insert(lines, "")
    return lines
end

-- Function to generate summary section
local function generate_summary(resolved_count, unresolved_count, total_keys, installed_plugins, missing_plugins,
                                total_plugins)
    local lines = {}
    table.insert(lines, "## Summary")
    table.insert(lines, "")
    table.insert(lines, "### Configuration")
    table.insert(lines, "Resolved: " .. resolved_count)
    table.insert(lines, "Unresolved: " .. unresolved_count)
    table.insert(lines, "Coverage: " .. string.format("%.1f%%", (resolved_count / total_keys) * 100))
    table.insert(lines, "")
    table.insert(lines, "### Plugins")
    table.insert(lines, "Installed: " .. installed_plugins)
    table.insert(lines, "Missing: " .. missing_plugins)
    if total_plugins > 0 then
        table.insert(lines, "Plugin Coverage: " .. string.format("%.1f%%", (installed_plugins / total_plugins) * 100))
    end
    table.insert(lines, "")
    return lines
end

-- Function to generate configuration keys section
local function generate_config_keys_section(analyzed_keys)
    local lines = {}
    table.insert(lines, "## Configuration Keys")
    table.insert(lines, "")
    table.insert(lines, string.format("%-30s %-35s %s", "Configuration Key", "Status", "Value"))
    table.insert(lines, string.rep("-", 80))

    for _, item in ipairs(analyzed_keys) do
        table.insert(lines, string.format("%-30s %-35s %s", item.key, item.status, item.value))
    end

    table.insert(lines, "")
    return lines
end

-- Function to generate plugin dependencies section
local function generate_plugin_dependencies_section(analyzed_plugins)
    local lines = {}
    table.insert(lines, "## Plugin Dependencies")
    table.insert(lines, "")

    for _, plugin in ipairs(analyzed_plugins) do
        table.insert(lines, string.format("%-30s %-15s %s", plugin.name, plugin.status, plugin.description))
    end

    table.insert(lines, "")
    return lines
end

-- Function to generate legend section
local function generate_legend()
    local lines = {}
    table.insert(lines, "## Legend")
    table.insert(lines, "")
    table.insert(lines, "### Configuration Status")
    table.insert(lines, "  ✓ RESOLVED (direct)      - Exact resolver found")
    table.insert(lines, "  ✓ RESOLVED (via parent)  - Resolved through hierarchical fallback")
    table.insert(lines, "  ✗ NOT RESOLVED          - No resolver found")
    table.insert(lines, "")
    table.insert(lines, "### Plugin Status")
    table.insert(lines, "  ✓ INSTALLED              - Plugin is available")
    table.insert(lines, "  ✗ MISSING                - Plugin not found")
    table.insert(lines, "")
    table.insert(lines, "### Keymap Status")
    table.insert(lines, "  ✓ KEYMAP RESOLVED        - Keymap successfully bound")
    table.insert(lines, "  ✗ KEYMAP FAILED          - Keymap binding failed")
    return lines
end

-- Function to create the AutoconfHealth command
function M.setup_helix_health_command()
    vim.api.nvim_create_user_command('AutoconfHealth', function()
        local loader = require("autoconf.sys.core.loader")
        local resolvers = require("autoconf.sys.core.resolvers")

        -- Load the config
        local config_path = "config.toml"
        local config, err = loader.load_config(config_path)

        if not config then
            logger.config_error(config_path, err)
            return
        end

        -- Collect and analyze all config keys
        local config_keys = collect_config_keys(config)
        table.sort(config_keys, function(a, b) return a.key < b.key end)

        local analyzed_keys, resolved_count, unresolved_count = analyze_config_keys(config_keys, resolvers)

        -- Analyze plugin dependencies
        local analyzed_plugins, installed_plugins, missing_plugins, plugin_names = analyze_plugin_dependencies(resolvers)

        local feature_lines = { "## Effective Feature State", "" }
        local completion = require("autoconf.sys.resolvers.editor.completion").status()
        local editor_lsp = require("autoconf.sys.resolvers.editor.lsp").status()
        local runtime_lsp = require("autoconf.sys.defaults.lsp").status()
        local requested = completion.requested
        table.insert(feature_lines, string.format(
            "Completion requested: auto=%s, path=%s, preview-insert=%s, keyword-length=%s, snippets=%s",
            tostring(requested.auto_completion), tostring(requested.path_completion),
            tostring(requested.preview_insert), tostring(requested.keyword_length), tostring(requested.snippets)
        ))
        table.insert(feature_lines, "Completion effective: " .. tostring(completion.effective))
        table.insert(feature_lines, string.format(
            "Auto-format requested: %s; effective: %s",
            tostring(runtime_lsp.format_requested), tostring(runtime_lsp.format_effective)
        ))
        local server_states = {}
        for _, server in ipairs(runtime_lsp.servers) do
            table.insert(server_states, server.name .. "=" .. tostring(server.enabled))
        end
        table.insert(feature_lines, string.format(
            "LSP requested: %s; configured server state: %s",
            tostring(runtime_lsp.lsp_requested), #server_states > 0 and table.concat(server_states, ", ") or "none"
        ))
        table.insert(feature_lines, string.format(
            "LSP helpers: auto-hover=%s, auto-signature=%s, messages=%s, progress=%s",
            tostring(editor_lsp.auto_info), tostring(editor_lsp.auto_signature_help),
            tostring(editor_lsp.display_messages), tostring(editor_lsp.display_progress_messages)
        ))
        table.insert(feature_lines, "Restart required for configured LSP capabilities: " .. tostring(runtime_lsp.restart_required))
        table.insert(feature_lines, "")

        -- Generate all sections
        local lines = {}

        -- 1. Header
        local header_lines = generate_header(config_path, #config_keys)
        for _, line in ipairs(header_lines) do
            table.insert(lines, line)
        end

        -- 2. Summary (moved to top)
        local summary_lines = generate_summary(resolved_count, unresolved_count, #config_keys,
            installed_plugins, missing_plugins, #plugin_names)
        for _, line in ipairs(summary_lines) do
            table.insert(lines, line)
        end

        -- 3. Configuration Keys
        local config_lines = generate_config_keys_section(analyzed_keys)
        for _, line in ipairs(config_lines) do
            table.insert(lines, line)
        end

        -- 4. Plugin Dependencies
        local plugin_lines = generate_plugin_dependencies_section(analyzed_plugins)
        for _, line in ipairs(plugin_lines) do
            table.insert(lines, line)
        end

        for _, line in ipairs(feature_lines) do
            table.insert(lines, line)
        end

        -- 5. Legend (moved to end)
        local legend_lines = generate_legend()
        for _, line in ipairs(legend_lines) do
            table.insert(lines, line)
        end

        -- Create a new buffer to display the health report
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.api.nvim_buf_set_option(buf, 'modifiable', false)
        vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')

        -- Open the buffer in the current window (full screen)
        vim.api.nvim_win_set_buf(0, buf)
        vim.api.nvim_buf_set_name(buf, 'AutoconfHealth')

        -- Set buffer-specific keymaps for easy navigation
        vim.keymap.set('n', 'q', '<cmd>bdelete<cr>', { buffer = buf, desc = 'Close AutoconfHealth' })
        vim.keymap.set('n', '<Esc>', '<cmd>bdelete<cr>', { buffer = buf, desc = 'Close AutoconfHealth' })
    end, {
        desc = 'Show Helix configuration health status'
    })
end

-- Function to create the SudoWrite command
function M.setup_sudo_write_command()
    vim.api.nvim_create_user_command("SudoWrite", function()
        require("autoconf.sys.core.sudo_write").write()
    end, {
        desc = "Write file with sudo privileges"
    })

    -- Convenient alias
    vim.api.nvim_create_user_command("W", function()
        require("autoconf.sys.core.sudo_write").write()
    end, {
        desc = "Write file with sudo (alias)"
    })
end

return M
