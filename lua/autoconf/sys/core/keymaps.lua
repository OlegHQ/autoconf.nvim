-- Keymap resolution system
-- Extracted from resolvers.lua for better separation of concerns

local M = {}

local logger = require("autoconf.sys.core.logger")

-- Registry to track keymap resolution status
M.keymap_status = {}

-- Registry for keymaps that should be bound on LSP attach
M.on_lsp_attach_keymaps = {}

-- Command resolvers reference (set by init)
local command_resolvers = nil

--- Set the command resolvers reference
--- @param resolvers table The command_resolvers table from resolvers module
function M.set_command_resolvers(resolvers)
    command_resolvers = resolvers
end

--- Check if a command resolver exists
--- @param command_name string
--- @return boolean
local function has_command_resolver(command_name)
    return command_resolvers and command_resolvers[command_name] ~= nil
end

--- Get a command resolver
--- @param command_name string
--- @return any
local function get_command_resolver(command_name)
    return command_resolvers and command_resolvers[command_name]
end

-- Helper: Split string by separator
local function split(str, sep)
    local result = {}
    for part in string.gmatch(str, "([^" .. sep .. "]+)") do
        table.insert(result, part)
    end
    return result
end

-- Helper: Check if array contains value
local function has_value(array, value)
    for _, v in ipairs(array) do
        if v == value then
            return true
        end
    end
    return false
end

-- Mode translation table (Helix -> Neovim)
local MODE_MAP = {
    normal = "n",
    insert = "i",
    visual = "v",
    select = "s",
    command = "c",
    terminal = "t",
    visualselect = "x",
}

--- Translate Helix keys to Neovim format
--- @param keys string Raw key combo
--- @param has_space boolean Whether under space (leader) prefix
--- @return string Neovim-formatted keys
local function translate_keys(keys, has_space)
    -- Convert Helix key combos to Neovim format (C=Control, S=Shift, A=Alt)
    keys = keys:gsub("([CSA])%-([a-zA-Z])", "<%1-%2>")
    if has_space then
        keys = "<leader>" .. keys
    end
    return keys
end

--- Create keymap setter from command definition
--- @param nvim_mode string Neovim mode
--- @param keys string Key combo
--- @param command_def any Command definition
--- @return function Setter function
local function resolve_command_def(nvim_mode, keys, command_def)
    if type(command_def) == "string" or type(command_def) == "function" then
        return function() vim.keymap.set(nvim_mode, keys, command_def) end
    elseif type(command_def) == "table" then
        if command_def.per_mode ~= nil and command_def.per_mode[nvim_mode] ~= nil then
            return resolve_command_def(nvim_mode, keys, command_def.per_mode[nvim_mode])
        elseif command_def.cmd ~= nil then
            return function() vim.keymap.set(nvim_mode, keys, command_def.cmd, command_def.opts or {}) end
        elseif command_def.fn ~= nil then
            return function() vim.keymap.set(nvim_mode, keys, command_def.fn, command_def.opts or {}) end
        end
        error(string.format("invalid command definition: %s, %s", nvim_mode, keys))
    end
end

--- Attempt to bind a keymap
--- @param _ any Unused (kept for API compatibility)
--- @param keys string Raw key combo
--- @param mode string Helix mode name
--- @param command string|table Command name(s)
--- @param has_space boolean Whether under space prefix
--- @return boolean Success
function M.attempt_to_keymap(_, keys, mode, command, has_space)
    local key_path = "keys." .. mode .. "." .. keys

    -- Handle both string commands and array commands
    local command_list = {}
    local command_desc = ""

    if type(command) == "string" then
        command_list = { command }
        command_desc = command
    elseif type(command) == "table" then
        command_list = command
        command_desc = table.concat(command, " + ")
    else
        M.keymap_status[key_path] = {
            resolved = false,
            error = "Command must be a string or array, got " .. type(command),
            keys = keys,
            mode = mode,
            command = command
        }
        logger.keymap_error(key_path, "Command must be a string or array, got " .. type(command))
        return false
    end

    -- Check if all commands have command resolvers
    for _, cmd in ipairs(command_list) do
        if not has_command_resolver(cmd) then
            M.keymap_status[key_path] = {
                resolved = false,
                error = "Command '" .. tostring(cmd) .. "' has no command resolver",
                keys = keys,
                mode = mode,
                command = command
            }
            logger.keymap_error(key_path, "Command '" .. tostring(cmd) .. "' has no command resolver")
            return false
        end
    end

    -- Translate mode
    local nvim_mode = MODE_MAP[mode] or mode

    -- Get command definition
    local command_def
    if #command_list == 1 then
        command_def = get_command_resolver(command_list[1])
    else
        error("only single command is supported")
    end

    -- Translate keys
    keys = translate_keys(keys, has_space)

    -- Check if this is an LSP-attach command
    local is_on_lsp_attach_command = false
    if type(command_def) == "table" and command_def.on_lsp_attach then
        is_on_lsp_attach_command = true
    end

    -- Create the keymap setter
    local on_keymap = resolve_command_def(nvim_mode, keys, command_def)
    local set_keymap_fn = function()
        local success, err = pcall(on_keymap)

        -- Store the result
        M.keymap_status[key_path] = {
            resolved = success,
            error = err,
            keys = keys,
            mode = mode,
            nvim_mode = nvim_mode,
            command = command
        }

        if success then
            logger.keymap_success(key_path, command_desc)
        else
            logger.keymap_error(key_path, tostring(err))
        end
        return success
    end

    -- Execute or defer
    if is_on_lsp_attach_command then
        table.insert(M.on_lsp_attach_keymaps, set_keymap_fn)
    else
        set_keymap_fn()
    end
end

--- Check if a keymap was resolved
--- @param key_path string
--- @return boolean
function M.is_keymap_resolved(key_path)
    local status = M.keymap_status[key_path]
    return status and status.resolved or false
end

--- Get keymap status
--- @param key_path string
--- @return table|nil
function M.get_keymap_status(key_path)
    return M.keymap_status[key_path]
end

--- Check if a path is a keymap path (keys.mode.combo)
--- @param path string
--- @return boolean
function M.is_keymap_path(path)
    local parts = split(path, ".")
    if #parts < 3 then
        return false
    end
    if parts[1] ~= "keys" then
        return false
    end
    if parts[#parts] == "space" then
        return false
    end
    return true
end

--- Extract mode, keys, and space flag from a keymap path
--- @param full_path string
--- @return string mode
--- @return string keys
--- @return boolean has_space
function M.match_keymap_mode_keys(full_path)
    local parts = split(full_path, ".")
    local has_space = has_value(parts, "space")
    local mode = parts[2]
    local keys = parts[#parts]
    return mode, keys, has_space
end

return M
