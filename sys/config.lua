local M = {}

local util = require('sys.util')

-- Mapping from Helix editor options to Neovim options
local editor_mappings = {
  -- Basic editor settings
  scrolloff = "scrolloff",
  mouse = function(value) 
    if value then vim.opt.mouse = "a" else vim.opt.mouse = "" end
  end,
  middle_click_paste = function(value)
    if not value then vim.opt.mouse = vim.opt.mouse:get():gsub("a", "") end
  end,
  scroll_lines = "scroll",
  shell = "shell",
  line_number = function(value)
    if value == "absolute" then
      vim.opt.number = true
      vim.opt.relativenumber = false
    elseif value == "relative" then
      vim.opt.number = false
      vim.opt.relativenumber = true
    else
      vim.opt.number = false
      vim.opt.relativenumber = false
    end
  end,
  cursorline = "cursorline",
  cursorcolumn = "cursorcolumn",
  gutters = function(gutters)
    -- Handle gutter configuration
    -- This would typically configure sign column, line numbers, etc.
    if type(gutters) == "table" then
      for _, gutter in ipairs(gutters) do
        if gutter == "diagnostics" then
          vim.opt.signcolumn = "yes"
        elseif gutter == "line-numbers" then
          vim.opt.number = true
        elseif gutter == "spacer" then
          -- Handle spacer gutter
        end
      end
    end
  end,
  auto_completion = function(value)
    -- This would typically be handled by completion plugins
    util.log("Auto completion setting: " .. tostring(value))
  end,
  auto_format = function(value)
    -- This would typically be handled by formatting plugins
    util.log("Auto format setting: " .. tostring(value))
  end,
  auto_save = function(value)
    if value then
      vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI"}, {
        callback = function()
          if vim.bo.modified and vim.bo.buftype == "" then
            vim.cmd("silent! write")
          end
        end
      })
    end
  end,
  idle_timeout = function(value)
    vim.opt.updatetime = value
  end,
  completion_timeout = function(value)
    -- Would be handled by completion plugin configuration
    util.log("Completion timeout setting: " .. tostring(value))
  end,
  preview_completion_insert = function(value)
    -- Would be handled by completion plugin configuration
    util.log("Preview completion insert setting: " .. tostring(value))
  end,
  completion_trigger_len = function(value)
    -- Would be handled by completion plugin configuration
    util.log("Completion trigger length setting: " .. tostring(value))
  end,
  completion_replace = function(value)
    -- Would be handled by completion plugin configuration
    util.log("Completion replace setting: " .. tostring(value))
  end,
  auto_info = function(value)
    -- Would be handled by LSP/completion plugin configuration
    util.log("Auto info setting: " .. tostring(value))
  end,
  true_color = function(value)
    vim.opt.termguicolors = value
  end,
  undercurl = function(value)
    if value then
      vim.opt.t_Cs = "\27[4:3m"
      vim.opt.t_Ce = "\27[4:0m"
    end
  end,
  rulers = function(rulers)
    if type(rulers) == "table" and #rulers > 0 then
      vim.opt.colorcolumn = table.concat(rulers, ",")
    elseif type(rulers) == "number" then
      vim.opt.colorcolumn = tostring(rulers)
    end
  end,
  bufferline = function(value)
    -- Would typically be handled by bufferline plugins
    util.log("Bufferline setting: " .. tostring(value))
  end,
  color_modes = function(value)
    -- Custom color mode handling
    util.log("Color modes setting: " .. tostring(value))
  end,
}

-- Handle cursor shape configuration
local function apply_cursor_shape(cursor_shape)
  if not cursor_shape then return end
  
  local shape_map = {
    block = "block",
    bar = "ver25",
    underline = "hor20",
  }
  
  if cursor_shape.normal then
    vim.opt.guicursor = vim.opt.guicursor:get() .. ",n-v-c:" .. (shape_map[cursor_shape.normal] or "block")
  end
  if cursor_shape.insert then
    vim.opt.guicursor = vim.opt.guicursor:get() .. ",i-ci:" .. (shape_map[cursor_shape.insert] or "ver25")
  end
  if cursor_shape.select then
    vim.opt.guicursor = vim.opt.guicursor:get() .. ",s:" .. (shape_map[cursor_shape.select] or "block")
  end
end

-- Handle file picker configuration
local function apply_file_picker(file_picker)
  if not file_picker then return end
  
  -- This would typically configure telescope or other file picker plugins
  util.log("File picker configuration would be applied here")
  
  if file_picker.hidden then
    util.log("File picker hidden files: " .. tostring(file_picker.hidden))
  end
  if file_picker.follow_symlinks then
    util.log("File picker follow symlinks: " .. tostring(file_picker.follow_symlinks))
  end
  if file_picker.deduplicate_links then
    util.log("File picker deduplicate links: " .. tostring(file_picker.deduplicate_links))
  end
  if file_picker.parents then
    util.log("File picker parents: " .. tostring(file_picker.parents))
  end
  if file_picker.ignore then
    util.log("File picker ignore: " .. tostring(file_picker.ignore))
  end
  if file_picker.git_ignore then
    util.log("File picker git ignore: " .. tostring(file_picker.git_ignore))
  end
  if file_picker.git_global then
    util.log("File picker git global: " .. tostring(file_picker.git_global))
  end
  if file_picker.git_exclude then
    util.log("File picker git exclude: " .. tostring(file_picker.git_exclude))
  end
end

-- Handle auto-pairs configuration
local function apply_auto_pairs(auto_pairs)
  if not auto_pairs then return end
  
  -- This would typically configure autopairs plugins
  util.log("Auto pairs configuration would be applied here")
  
  for char, pair_char in pairs(auto_pairs) do
    util.log("Auto pair: " .. char .. " -> " .. pair_char)
  end
end

-- Handle search configuration
local function apply_search(search)
  if not search then return end
  
  if search.smart_case ~= nil then
    vim.opt.smartcase = search.smart_case
  end
  if search.wrap_around ~= nil then
    vim.opt.wrapscan = search.wrap_around
  end
end

-- Handle whitespace configuration
local function apply_whitespace(whitespace)
  if not whitespace then return end
  
  if whitespace.render then
    local render = whitespace.render
    local listchars = {}
    
    if render.space then
      table.insert(listchars, "space:" .. render.space)
    end
    if render.nbsp then
      table.insert(listchars, "nbsp:" .. render.nbsp)
    end
    if render.tab then
      table.insert(listchars, "tab:" .. render.tab)
    end
    if render.newline then
      table.insert(listchars, "eol:" .. render.newline)
    end
    
    if #listchars > 0 then
      vim.opt.list = true
      vim.opt.listchars = table.concat(listchars, ",")
    end
  end
  
  if whitespace.characters then
    local chars = whitespace.characters
    local listchars = {}
    
    if chars.space then
      table.insert(listchars, "space:" .. chars.space)
    end
    if chars.nbsp then
      table.insert(listchars, "nbsp:" .. chars.nbsp)
    end
    if chars.tab then
      table.insert(listchars, "tab:" .. chars.tab)
    end
    if chars.newline then
      table.insert(listchars, "eol:" .. chars.newline)
    end
    
    if #listchars > 0 then
      vim.opt.list = true
      vim.opt.listchars = table.concat(listchars, ",")
    end
  end
end

-- Handle indent configuration
local function apply_indent(indent)
  if not indent then return end
  
  if indent.tab_width then
    vim.opt.tabstop = indent.tab_width
    vim.opt.shiftwidth = indent.tab_width
  end
  if indent.unit then
    vim.opt.shiftwidth = indent.unit
  end
end

-- Handle statusline configuration
local function apply_statusline(statusline)
  if not statusline then return end
  
  -- This would typically configure statusline plugins like lualine
  util.log("Statusline configuration would be applied here")
  
  if statusline.left then
    util.log("Statusline left: " .. vim.inspect(statusline.left))
  end
  if statusline.center then
    util.log("Statusline center: " .. vim.inspect(statusline.center))
  end
  if statusline.right then
    util.log("Statusline right: " .. vim.inspect(statusline.right))
  end
  if statusline.separator then
    util.log("Statusline separator: " .. statusline.separator)
  end
  if statusline.mode then
    util.log("Statusline mode: " .. vim.inspect(statusline.mode))
  end
end

-- Handle LSP configuration
local function apply_lsp(lsp)
  if not lsp then return end
  
  -- This would typically configure LSP settings
  util.log("LSP configuration would be applied here")
  
  if lsp.enable ~= nil then
    util.log("LSP enable: " .. tostring(lsp.enable))
  end
  if lsp.display_messages ~= nil then
    util.log("LSP display messages: " .. tostring(lsp.display_messages))
  end
  if lsp.auto_signature_help ~= nil then
    util.log("LSP auto signature help: " .. tostring(lsp.auto_signature_help))
  end
  if lsp.display_inlay_hints ~= nil then
    util.log("LSP display inlay hints: " .. tostring(lsp.display_inlay_hints))
  end
  if lsp.display_signature_help_docs ~= nil then
    util.log("LSP display signature help docs: " .. tostring(lsp.display_signature_help_docs))
  end
  if lsp.snippets ~= nil then
    util.log("LSP snippets: " .. tostring(lsp.snippets))
  end
  if lsp.goto_definition_inline ~= nil then
    util.log("LSP goto definition inline: " .. tostring(lsp.goto_definition_inline))
  end
end

-- Main apply function
function M.apply(editor_config)
  if not editor_config or type(editor_config) ~= "table" then
    util.log("No editor configuration to apply")
    return
  end
  
  util.log("Applying editor configuration...")
  
  -- Apply basic editor settings
  for key, value in pairs(editor_config) do
    local mapping = editor_mappings[key]
    
    if mapping then
      if type(mapping) == "string" then
        -- Direct vim option mapping
        vim.opt[mapping] = value
      elseif type(mapping) == "function" then
        -- Custom function mapping
        mapping(value)
      end
    else
      -- Handle special sections
      if key == "cursor-shape" then
        apply_cursor_shape(value)
      elseif key == "file-picker" then
        apply_file_picker(value)
      elseif key == "auto-pairs" then
        apply_auto_pairs(value)
      elseif key == "search" then
        apply_search(value)
      elseif key == "whitespace" then
        apply_whitespace(value)
      elseif key == "indent" then
        apply_indent(value)
      elseif key == "statusline" then
        apply_statusline(value)
      elseif key == "lsp" then
        apply_lsp(value)
      else
        util.log("Unknown editor setting: " .. key, vim.log.levels.WARN)
      end
    end
  end
  
  util.log("Editor configuration applied")
end

return M