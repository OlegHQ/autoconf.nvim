local logger = require("sys.core.logger")

local M = {}

M.filepicker = function(value)
    -- Check if Telescope is available
    local telescope_ok, telescope = pcall(require, "telescope")
    if not telescope_ok then
        logger.plugin_missing("telescope.nvim")
        return
    end

    -- Get current telescope config or create default
    local telescope_config = telescope.get_config and telescope.get_config() or {}
    local defaults = telescope_config.defaults or {}
    local pickers = telescope_config.pickers or {}
    local find_files_config = pickers.find_files or {}

    -- Build find command based on configuration
    local find_command = { "fd", "--type", "f", "--color", "never" }
    
    -- Handle hidden files
    if value.hidden == false then
        -- Exclude hidden files (Helix default true means ignore hidden, so false means exclude)
        table.insert(find_command, "--no-hidden")
    else
        -- Include hidden files
        table.insert(find_command, "--hidden")
    end

    -- Handle symlinks
    if value["follow-symlinks"] == false then
        -- Don't follow symlinks
        table.insert(find_command, "--no-follow")
    else
        -- Follow symlinks (default behavior)
        table.insert(find_command, "--follow")
    end

    -- Handle ignore files
    if value.parents == false then
        table.insert(find_command, "--no-ignore-parent")
    end
    
    if value.ignore == false then
        table.insert(find_command, "--no-ignore")
    end
    
    if value["git-ignore"] == false then
        table.insert(find_command, "--no-ignore-vcs")
    end
    
    if value["git-global"] == false then
        table.insert(find_command, "--no-global-ignore-file")
    end
    
    if value["git-exclude"] == false then
        table.insert(find_command, "--no-exclude")
    end

    -- Handle max depth
    if value["max-depth"] and type(value["max-depth"]) == "number" then
        table.insert(find_command, "--max-depth")
        table.insert(find_command, tostring(value["max-depth"]))
    end

    -- Configure telescope with our settings
    local new_config = {
        defaults = vim.tbl_deep_extend("force", defaults, {
            -- Additional default configurations can go here
        }),
        pickers = vim.tbl_deep_extend("force", pickers, {
            find_files = vim.tbl_deep_extend("force", find_files_config, {
                find_command = find_command,
                -- Handle deduplicate links - telescope doesn't show duplicates by default
                -- so we only need to handle if explicitly set to false
                follow = value["follow-symlinks"] ~= false,
            })
        })
    }

    -- Setup telescope with new configuration
    telescope.setup(new_config)
    
    logger.resolver_success("editor.file-picker", "configured with telescope.nvim")
end

-- Appearance-related functions will be moved here
return M
