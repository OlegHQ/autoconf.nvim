local M = {}

local util = require('sys.util')

-- Helix command to Neovim command mappings
local command_mappings = {
  -- Movement commands
  move_char_left = "h",
  move_char_right = "l",
  move_line_up = "k",
  move_line_down = "j",
  move_next_word_start = "w",
  move_prev_word_start = "b",
  move_next_word_end = "e",
  move_next_long_word_start = "W",
  move_prev_long_word_start = "B",
  move_next_long_word_end = "E",
  goto_line_start = "0",
  goto_first_nonwhitespace = "^",
  goto_line_end = "$",
  goto_file_start = "gg",
  goto_file_end = "G",
  page_up = "<C-b>",
  page_down = "<C-f>",
  half_page_up = "<C-u>",
  half_page_down = "<C-d>",
  
  -- Selection commands
  select_all = "ggVG",
  extend_char_left = "vh",
  extend_char_right = "vl",
  extend_line_up = "vk",
  extend_line_down = "vj",
  extend_next_word_start = "vw",
  extend_prev_word_start = "vb",
  extend_next_word_end = "ve",
  extend_line_below = "V",
  extend_line_above = "Vk",
  
  -- Editing commands
  insert_mode = "i",
  append_mode = "a",
  open_below = "o",
  open_above = "O",
  normal_mode = "<Esc>",
  delete_selection = "d",
  delete_char_backward = "X",
  delete_char_forward = "x",
  delete_word_backward = "db",
  delete_word_forward = "dw",
  yank = "y",
  yank_line = "yy",
  paste_after = "p",
  paste_before = "P",
  undo = "u",
  redo = "<C-r>",
  
  -- Search commands
  search = "/",
  search_next = "n",
  search_prev = "N",
  search_selection = "*",
  
  -- File operations
  file_picker = function() return "<cmd>Telescope find_files<cr>" end,
  buffer_picker = function() return "<cmd>Telescope buffers<cr>" end,
  symbol_picker = function() return "<cmd>Telescope lsp_document_symbols<cr>" end,
  workspace_symbol_picker = function() return "<cmd>Telescope lsp_workspace_symbols<cr>" end,
  diagnostics_picker = function() return "<cmd>Telescope diagnostics<cr>" end,
  
  -- LSP commands
  goto_definition = function() return "<cmd>lua vim.lsp.buf.definition()<cr>" end,
  goto_declaration = function() return "<cmd>lua vim.lsp.buf.declaration()<cr>" end,
  goto_type_definition = function() return "<cmd>lua vim.lsp.buf.type_definition()<cr>" end,
  goto_implementation = function() return "<cmd>lua vim.lsp.buf.implementation()<cr>" end,
  goto_reference = function() return "<cmd>Telescope lsp_references<cr>" end,
  hover = function() return "<cmd>lua vim.lsp.buf.hover()<cr>" end,
  signature_help = function() return "<cmd>lua vim.lsp.buf.signature_help()<cr>" end,
  rename_symbol = function() return "<cmd>lua vim.lsp.buf.rename()<cr>" end,
  code_action = function() return "<cmd>lua vim.lsp.buf.code_action()<cr>" end,
  format = function() return "<cmd>lua vim.lsp.buf.format()<cr>" end,
  
  -- Window management
  window_left = "<C-w>h",
  window_right = "<C-w>l",
  window_up = "<C-w>k",
  window_down = "<C-w>j",
  window_close = "<C-w>c",
  window_split_horizontal = "<C-w>s",
  window_split_vertical = "<C-w>v",
  
  -- Buffer management
  buffer_next = "<cmd>bnext<cr>",
  buffer_previous = "<cmd>bprev<cr>",
  buffer_close = "<cmd>bdelete<cr>",
  
  -- Save and quit
  write = "<cmd>write<cr>",
  write_quit = "<cmd>wq<cr>",
  quit = "<cmd>quit<cr>",
  quit_all = "<cmd>qall<cr>",
  force_quit = "<cmd>quit!<cr>",
  force_quit_all = "<cmd>qall!<cr>",
  
  -- Miscellaneous
  command_mode = ":",
  shell = "<cmd>terminal<cr>",
  increment = "<C-a>",
  decrement = "<C-x>",
  
  -- Custom commands that might need special handling
  no_op = "<Nop>",
}

-- Convert Helix command to Neovim command
local function convert_command(helix_cmd)
  if type(helix_cmd) == "string" then
    local mapping = command_mappings[helix_cmd]
    if mapping then
      if type(mapping) == "function" then
        return mapping()
      else
        return mapping
      end
    else
      -- If no direct mapping, try to pass through as-is
      util.log("Unknown Helix command: " .. helix_cmd, vim.log.levels.WARN)
      return helix_cmd
    end
  elseif type(helix_cmd) == "table" then
    -- Handle complex commands (sequences, etc.)
    if helix_cmd[1] then
      -- Array-like table, treat as sequence
      local commands = {}
      for _, cmd in ipairs(helix_cmd) do
        table.insert(commands, convert_command(cmd))
      end
      return table.concat(commands, "")
    else
      -- Object-like table, might be a complex command
      util.log("Complex command not yet supported: " .. vim.inspect(helix_cmd), vim.log.levels.WARN)
      return "<Nop>"
    end
  else
    util.log("Invalid command type: " .. type(helix_cmd), vim.log.levels.ERROR)
    return "<Nop>"
  end
end

-- Apply key mappings for a specific mode
local function apply_mode_keys(mode, keys)
  if not keys or type(keys) ~= "table" then
    return
  end
  
  local vim_mode = util.helix_mode_to_vim(mode)
  
  for key_sequence, command in pairs(keys) do
    local vim_key = util.helix_key_to_vim(key_sequence)
    local vim_command = convert_command(command)
    
    if vim_command and vim_command ~= "<Nop>" then
      vim.keymap.set(vim_mode, vim_key, vim_command, {
        desc = "Helix: " .. tostring(command),
        silent = true,
        noremap = true,
      })
      util.log("Mapped " .. vim_key .. " -> " .. vim_command .. " in mode " .. vim_mode)
    else
      util.log("Skipping invalid mapping: " .. key_sequence .. " -> " .. tostring(command), vim.log.levels.WARN)
    end
  end
end

-- Handle special key sequences that might need preprocessing
local function preprocess_key_sequence(key_seq)
  -- Handle special Helix key notations
  local processed = key_seq
  
  -- Convert common Helix patterns
  processed = processed:gsub("C%-", "<C-")
  processed = processed:gsub("A%-", "<M-")
  processed = processed:gsub("S%-", "<S-")
  
  -- Handle space key
  processed = processed:gsub("space", "<Space>")
  
  -- Handle function keys
  processed = processed:gsub("F(%d+)", "<F%1>")
  
  return processed
end

-- Apply all key mappings
function M.apply(keys_config)
  if not keys_config or type(keys_config) ~= "table" then
    util.log("No key configuration to apply")
    return
  end
  
  util.log("Applying key mappings...")
  
  -- Clear existing Helix keymaps (optional, might want to make this configurable)
  -- This would require tracking which keymaps we've set
  
  -- Apply mappings for each mode
  for mode, mode_keys in pairs(keys_config) do
    if type(mode_keys) == "table" then
      util.log("Applying " .. mode .. " mode key mappings")
      apply_mode_keys(mode, mode_keys)
    else
      util.log("Invalid key configuration for mode: " .. mode, vim.log.levels.WARN)
    end
  end
  
  util.log("Key mappings applied")
end

-- Get current key mappings (for debugging)
function M.get_mappings()
  local mappings = {}
  
  for _, mode in ipairs({"n", "i", "v", "x", "s", "o", "t", "c"}) do
    mappings[mode] = vim.api.nvim_get_keymap(mode)
  end
  
  return mappings
end

-- Clear Helix key mappings
function M.clear_helix_mappings()
  -- This would require tracking which mappings we've set
  -- For now, just log that this functionality is needed
  util.log("Clear Helix mappings functionality not yet implemented", vim.log.levels.WARN)
end

-- Validate key configuration
function M.validate_keys(keys_config)
  if not keys_config or type(keys_config) ~= "table" then
    return false, "Keys configuration must be a table"
  end
  
  local valid_modes = {
    normal = true,
    insert = true,
    select = true,
    visual = true,
  }
  
  for mode, mode_keys in pairs(keys_config) do
    if not valid_modes[mode] then
      util.log("Unknown key mode: " .. mode, vim.log.levels.WARN)
    end
    
    if type(mode_keys) ~= "table" then
      return false, "Mode keys must be a table for mode: " .. mode
    end
    
    for key_seq, command in pairs(mode_keys) do
      if type(key_seq) ~= "string" then
        return false, "Key sequence must be a string: " .. tostring(key_seq)
      end
      
      if type(command) ~= "string" and type(command) ~= "table" then
        return false, "Command must be a string or table: " .. tostring(command)
      end
    end
  end
  
  return true
end

-- Export command mappings for external use
function M.get_command_mappings()
  return command_mappings
end

-- Add custom command mapping
function M.add_command_mapping(helix_cmd, nvim_cmd)
  command_mappings[helix_cmd] = nvim_cmd
  util.log("Added custom command mapping: " .. helix_cmd .. " -> " .. tostring(nvim_cmd))
end

return M