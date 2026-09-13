local logger = require("autoconf.sys.core.logger")

local M = {}

-- This is a translation map, not a second defaults/type schema. Workbench
-- validates the translated Lua config against its authoritative schema.
local toml_fields = {
  enable = "enabled",
  sidebar = {
    position = "position",
    width = "width",
    views = "views",
    ["follow-active-file"] = "follow_active_file",
  },
  search = {
    ["debounce-ms"] = "debounce_ms",
    ["max-results"] = "max_results",
    hidden = "hidden",
    ignored = "ignored",
    ["follow-symlinks"] = "follow_symlinks",
  },
  preview = { enable = "enabled", ["max-bytes"] = "max_bytes" },
  session = { persist = "persist", ["max-results-history"] = "max_results_history" },
}

local active_handles = {}

local function is_object(value)
  if type(value) ~= "table" then return false end
  for key in pairs(value) do if type(key) ~= "string" then return false end end
  return true
end

local function is_dense_array(value)
  if type(value) ~= "table" then return false end
  local count, maximum = 0, 0
  for key in pairs(value) do
    if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then return false end
    count = count + 1
    maximum = math.max(maximum, key)
  end
  return count == maximum
end

local function config_error(path, message)
  return nil, { code = "invalid_config", path = path, message = path .. " " .. message }
end

local function translate_table(value, mapping, path)
  if not is_object(value) then return config_error(path, "must be a table") end
  local result = {}
  for key, item in pairs(value) do
    local target = mapping[key]
    if target == nil then return config_error(path .. "." .. tostring(key), "is not a supported workbench TOML key") end
    if type(target) == "table" then
      local translated, err = translate_table(item, target, path .. "." .. key)
      if not translated then return nil, err end
      result[key] = translated
    else
      if type(item) == "table" and target == "views" and is_dense_array(item) then
        result[target] = vim.deepcopy(item)
      elseif type(item) == "table" then
        return config_error(path .. "." .. key, "must be a scalar or list value")
      else
        result[target] = vim.deepcopy(item)
      end
    end
  end
  return result
end

function M.translate(config)
  return translate_table(config, toml_fields, "editor.workbench")
end

function M.is_supported_path(path)
  local prefix = "editor.workbench."
  if type(path) ~= "string" or path:sub(1, #prefix) ~= prefix then return false end
  local mapping = toml_fields
  local remainder = path:sub(#prefix + 1)
  local parts = {}
  for part in remainder:gmatch("[^%.]+") do parts[#parts + 1] = part end
  if #parts == 0 then return false end
  for index, part in ipairs(parts) do
    local target = mapping[part]
    if target == nil then return false end
    if index == #parts then return type(target) == "string" end
    if type(target) ~= "table" then return false end
    mapping = target
  end
  return false
end

local function completion_adapter(completion)
  local function state()
    local status = completion.status()
    return status, status.effective or "unknown"
  end
  return {
    scope = "global",
    capabilities = function()
      local _, runtime = state()
      local unavailable = runtime:find("unavailable", 1, true) or runtime:find("failed", 1, true)
      local pending = runtime:find("pending", 1, true)
      return {
        available = not unavailable,
        state = unavailable and "unavailable" or (pending and "pending" or "ready"),
        reason = unavailable and runtime or (pending and "Blink setup is deferred; the completion policy remains live" or nil),
      }
    end,
    get = function()
      local status, runtime = state()
      local value = status.requested.auto_completion
      return { requested = value, effective = value, provenance = "autoconf", runtime_state = runtime }
    end,
    set = function(value)
      if completion.auto_completion(value) ~= true then return false, "Autoconf rejected completion setting" end
      return true
    end,
  }
end

local function formatting_adapter(formatting)
  return {
    scope = "global",
    capabilities = function()
      local status = formatting.auto_format_status()
      return { available = status.state == "ready", state = status.state }
    end,
    get = function()
      local status = formatting.auto_format_status()
      return { requested = status.requested, effective = status.effective, provenance = "autoconf" }
    end,
    set = function(value)
      if formatting.auto_format(value) ~= true then return false, "Autoconf rejected format-on-save setting" end
      return true
    end,
  }
end

local function diagnostics_adapter(diagnostics)
  return {
    scope = "global",
    capabilities = diagnostics.inline_diagnostics_capabilities,
    get = function()
      local status = diagnostics.inline_diagnostics_status()
      return { requested = status.requested, effective = status.effective, provenance = "autoconf" }
    end,
    set = function(value)
      if diagnostics.inline_diagnostics({ enabled = value }) ~= true then return false, "Autoconf rejected inline-diagnostics setting" end
      return true
    end,
  }
end

local function adapters()
  return {
    completion = completion_adapter(require("autoconf.sys.resolvers.editor.completion")),
    formatting = formatting_adapter(require("autoconf.sys.resolvers.editor.formatting")),
    diagnostics = diagnostics_adapter(require("autoconf.sys.resolvers.editor.diagnostics")),
  }
end

local adapter_order = { "completion", "formatting", "diagnostics" }

function M.configure(config)
  local translated, translate_error = M.translate(config)
  if not translated then
    logger.resolver_error("editor.workbench", translate_error.message)
    return false
  end

  local workbench_ok, workbench = pcall(require, "workbench")
  if not workbench_ok then
    logger.resolver_error("editor.workbench", "workbench plugin is unavailable: " .. tostring(workbench))
    return false
  end
  local normalized, validation_error = workbench.validate_config(translated)
  if not normalized then
    logger.resolver_error("editor.workbench", validation_error.message or "workbench configuration is invalid")
    return false
  end

  local current = workbench.get_status()
  if current.reason == "not_setup" then
    local initialized, initialize_error = workbench.setup({})
    if not initialized then
      logger.resolver_error("editor.workbench", initialize_error and initialize_error.message or "workbench initialization failed")
      return false
    end
  end

  local candidates = {}
  local available_adapters = adapters()
  for _, id in ipairs(adapter_order) do
    local adapter = available_adapters[id]
    local handle, register_error = workbench.register_setting_adapter(id, adapter, { replace = true })
    if not handle then
      for index = #candidates, 1, -1 do candidates[index]:dispose() end
      logger.resolver_error("editor.workbench", register_error and register_error.message or "could not register editor setting adapter " .. id)
      return false
    end
    candidates[#candidates + 1] = handle
  end

  local configured, configure_error = workbench.setup(normalized, { source = "autoconf.toml", replace_source = true })
  if not configured then
    for index = #candidates, 1, -1 do candidates[index]:dispose() end
    logger.resolver_error("editor.workbench", configure_error and configure_error.message or "workbench setup failed")
    return false
  end
  for _, handle in ipairs(active_handles) do handle:dispose() end
  active_handles = candidates
  logger.resolver_success("editor.workbench", "validated config and registered completion, formatting, and diagnostics adapters")
  return true
end

return M
