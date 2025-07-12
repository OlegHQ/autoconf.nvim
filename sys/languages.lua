local M = {}

local util = require('sys.util')

-- Language server configurations
local lsp_configs = {}
local language_configs = {}

-- Apply language server configuration
local function apply_language_server(name, config)
  if not config then return end
  
  util.log("Configuring language server: " .. name)
  
  -- Store the config for later use when LSP is available
  lsp_configs[name] = {
    command = config.command,
    args = config.args or {},
    config = config.config or {},
    environment = config.environment or {},
    timeout = config.timeout,
  }
  
  -- If nvim-lspconfig is available, configure it
  local lspconfig_ok, lspconfig = pcall(require, 'lspconfig')
  if lspconfig_ok and lspconfig[name] then
    local setup_config = {
      cmd = config.command and vim.list_extend({config.command}, config.args or {}) or nil,
      settings = config.config or {},
      init_options = config.config or {},
    }
    
    -- Add environment variables if specified
    if config.environment and next(config.environment) then
      setup_config.cmd_env = config.environment
    end
    
    lspconfig[name].setup(setup_config)
    util.log("LSP server " .. name .. " configured via lspconfig")
  else
    util.log("LSP server " .. name .. " config stored for later setup")
  end
end

-- Apply language configuration
local function apply_language(lang_config)
  if not lang_config or not lang_config.name then
    util.log("Invalid language configuration", vim.log.levels.WARN)
    return
  end
  
  local name = lang_config.name
  util.log("Configuring language: " .. name)
  
  -- Store language config
  language_configs[name] = lang_config
  
  -- Set up file type detection
  if lang_config.file_types then
    for _, ext in ipairs(lang_config.file_types) do
      vim.filetype.add({
        extension = {
          [ext] = name
        }
      })
    end
  end
  
  -- Set up roots (for project detection)
  if lang_config.roots then
    -- This would typically be used by LSP for project root detection
    util.log("Language " .. name .. " roots: " .. vim.inspect(lang_config.roots))
  end
  
  -- Set up comment configuration
  if lang_config.comment_token then
    vim.api.nvim_create_autocmd("FileType", {
      pattern = name,
      callback = function()
        vim.bo.commentstring = lang_config.comment_token .. " %s"
      end
    })
  end
  
  -- Set up indentation
  if lang_config.indent then
    vim.api.nvim_create_autocmd("FileType", {
      pattern = name,
      callback = function()
        if lang_config.indent.tab_width then
          vim.bo.tabstop = lang_config.indent.tab_width
          vim.bo.shiftwidth = lang_config.indent.tab_width
        end
        if lang_config.indent.unit then
          vim.bo.shiftwidth = lang_config.indent.unit
        end
      end
    })
  end
  
  -- Set up language servers
  if lang_config.language_servers then
    for _, server_name in ipairs(lang_config.language_servers) do
      -- Associate this language with the server
      if lsp_configs[server_name] then
        util.log("Associating " .. name .. " with LSP server " .. server_name)
      end
    end
  end
  
  -- Set up formatters
  if lang_config.formatter then
    local formatter = lang_config.formatter
    util.log("Language " .. name .. " formatter: " .. vim.inspect(formatter))
    
    -- This would typically configure conform.nvim or similar
    vim.api.nvim_create_autocmd("FileType", {
      pattern = name,
      callback = function()
        -- Store formatter info for potential use by formatting plugins
        vim.b.helix_formatter = formatter
      end
    })
  end
  
  -- Set up auto-format
  if lang_config.auto_format ~= nil then
    vim.api.nvim_create_autocmd("FileType", {
      pattern = name,
      callback = function()
        vim.b.helix_auto_format = lang_config.auto_format
        
        if lang_config.auto_format then
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = 0,
            callback = function()
              -- Try LSP formatting first
              if vim.lsp.buf.format then
                vim.lsp.buf.format({ async = false })
              end
            end
          })
        end
      end
    })
  end
  
  -- Set up debugger
  if lang_config.debugger then
    util.log("Language " .. name .. " debugger: " .. vim.inspect(lang_config.debugger))
    -- This would typically configure nvim-dap
  end
  
  -- Set up grammar (for tree-sitter)
  if lang_config.grammar then
    util.log("Language " .. name .. " grammar: " .. lang_config.grammar)
    -- This would typically configure nvim-treesitter
  end
  
  -- Set up injection regex
  if lang_config.injection_regex then
    util.log("Language " .. name .. " injection regex: " .. lang_config.injection_regex)
  end
  
  -- Set up scope
  if lang_config.scope then
    util.log("Language " .. name .. " scope: " .. lang_config.scope)
  end
end

-- Main apply function
function M.apply(languages_config)
  if not languages_config or type(languages_config) ~= "table" then
    util.log("No language configuration to apply")
    return
  end
  
  util.log("Applying language configuration...")
  
  -- Apply language server configurations
  if languages_config["language-server"] then
    for name, config in pairs(languages_config["language-server"]) do
      apply_language_server(name, config)
    end
  end
  
  -- Apply language configurations
  if languages_config.language then
    for _, lang_config in ipairs(languages_config.language) do
      apply_language(lang_config)
    end
  end
  
  util.log("Language configuration applied")
end

-- Deferred application (for after plugin loading)
function M.apply_deferred(languages_config)
  if not languages_config or type(languages_config) ~= "table" then
    return
  end
  
  util.log("Applying deferred language configuration...")
  
  -- Re-attempt LSP server setup now that plugins should be loaded
  for name, config in pairs(lsp_configs) do
    local lspconfig_ok, lspconfig = pcall(require, 'lspconfig')
    if lspconfig_ok and lspconfig[name] and not lspconfig[name].manager then
      local setup_config = {
        cmd = config.command and vim.list_extend({config.command}, config.args) or nil,
        settings = config.config or {},
        init_options = config.config or {},
      }
      
      if config.environment and next(config.environment) then
        setup_config.cmd_env = config.environment
      end
      
      lspconfig[name].setup(setup_config)
      util.log("Deferred LSP server " .. name .. " configured")
    end
  end
  
  -- Configure formatters with conform.nvim if available
  local conform_ok, conform = pcall(require, 'conform')
  if conform_ok then
    local formatters_by_ft = {}
    
    for name, lang_config in pairs(language_configs) do
      if lang_config.formatter then
        local formatter = lang_config.formatter
        if type(formatter) == "string" then
          formatters_by_ft[name] = { formatter }
        elseif type(formatter) == "table" and formatter.command then
          -- Custom formatter configuration
          formatters_by_ft[name] = { formatter.command }
        end
      end
    end
    
    if next(formatters_by_ft) then
      conform.setup({
        formatters_by_ft = formatters_by_ft
      })
      util.log("Conform.nvim configured with Helix formatters")
    end
  end
  
  -- Configure tree-sitter if available
  local ts_ok, ts_configs = pcall(require, 'nvim-treesitter.configs')
  if ts_ok then
    local ensure_installed = {}
    
    for name, lang_config in pairs(language_configs) do
      if lang_config.grammar then
        table.insert(ensure_installed, lang_config.grammar)
      end
    end
    
    if #ensure_installed > 0 then
      ts_configs.setup({
        ensure_installed = ensure_installed,
        highlight = { enable = true },
        indent = { enable = true },
      })
      util.log("Tree-sitter configured with Helix grammars")
    end
  end
  
  util.log("Deferred language configuration applied")
end

-- Get language configuration for a specific language
function M.get_language_config(language)
  return language_configs[language]
end

-- Get LSP configuration for a specific server
function M.get_lsp_config(server)
  return lsp_configs[server]
end

-- Get all configured languages
function M.get_languages()
  return vim.tbl_keys(language_configs)
end

-- Get all configured LSP servers
function M.get_lsp_servers()
  return vim.tbl_keys(lsp_configs)
end

-- Validate language configuration
function M.validate_config(languages_config)
  if not languages_config or type(languages_config) ~= "table" then
    return false, "Languages configuration must be a table"
  end
  
  -- Validate language server configurations
  if languages_config["language-server"] then
    for name, config in pairs(languages_config["language-server"]) do
      if type(config) ~= "table" then
        return false, "Language server config must be a table: " .. name
      end
      
      if not config.command then
        util.log("Language server " .. name .. " missing command", vim.log.levels.WARN)
      end
    end
  end
  
  -- Validate language configurations
  if languages_config.language then
    if type(languages_config.language) ~= "table" then
      return false, "Language config must be a table"
    end
    
    for i, lang_config in ipairs(languages_config.language) do
      if type(lang_config) ~= "table" then
        return false, "Language config entry must be a table: " .. i
      end
      
      if not lang_config.name then
        return false, "Language config missing name: " .. i
      end
    end
  end
  
  return true
end

-- Add custom language configuration
function M.add_language(name, config)
  language_configs[name] = config
  apply_language(config)
  util.log("Added custom language configuration: " .. name)
end

-- Add custom LSP server configuration
function M.add_lsp_server(name, config)
  lsp_configs[name] = config
  apply_language_server(name, config)
  util.log("Added custom LSP server configuration: " .. name)
end

return M