-- Neovim configuration with Helix-style TOML support
-- This init.lua integrates the Helix configuration layer

-- IMPORTANT: Set up Lua path first before any requires
local config_dir = vim.fn.stdpath("config")
package.path = package.path .. ";" .. config_dir .. "/?.lua;" .. config_dir .. "/?/init.lua"

-- Set up basic Neovim settings first
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Basic editor settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.termguicolors = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.completeopt = "menuone,noselect"

-- Indentation
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- File handling
vim.opt.undofile = true
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false

-- Load Helix-style configuration translator
-- This should be done early in the startup sequence
local helix_cfg_ok, helix_cfg = pcall(require, 'sys')

if helix_cfg_ok then
  -- Setup the Helix configuration layer
  local setup_ok, setup_err = pcall(helix_cfg.setup)
  
  if setup_ok then
    -- Setup user commands for managing Helix config
    helix_cfg.setup_commands()
    
    -- Create an autocmd to reload config when TOML files change
    vim.api.nvim_create_autocmd({"BufWritePost"}, {
      pattern = {"*/helix/*.toml", "*/.helix/*.toml"},
      callback = function()
        vim.notify("Helix config file changed, reloading...", vim.log.levels.INFO)
        helix_cfg.reload()
      end,
      desc = "Reload Helix config when TOML files change"
    })
    
    -- Defer language configuration until after plugin loading
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        -- Small delay to ensure plugins are loaded
        vim.defer_fn(function()
          helix_cfg.setup_languages_deferred()
        end, 100)
      end,
      desc = "Setup deferred Helix language configuration"
    })
    
  else
    vim.notify("Failed to setup Helix configuration: " .. tostring(setup_err), vim.log.levels.ERROR)
  end
else
  vim.notify("Helix configuration module not found: " .. tostring(helix_cfg), vim.log.levels.WARN)
end

-- Plugin management (placeholder - you can add your preferred plugin manager here)
-- Example with lazy.nvim:
--[[
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Essential plugins for Helix-style functionality
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({})
    end
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- LSP configuration will be handled by the Helix config layer
    end
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      -- Tree-sitter configuration will be handled by the Helix config layer
    end
  },
  {
    "stevearc/conform.nvim",
    config = function()
      -- Formatter configuration will be handled by the Helix config layer
    end
  },
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end
  },
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup()
    end
  },
})
--]]

-- Basic key mappings (these can be overridden by Helix config)
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Find buffers" })
vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "Help tags" })

-- Window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Buffer navigation
vim.keymap.set("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
vim.keymap.set("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })

-- Better up/down
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Clear search with <esc>
vim.keymap.set({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })

-- Save file
vim.keymap.set({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

-- Better indenting
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Move Lines
vim.keymap.set("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move down" })
vim.keymap.set("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move up" })
vim.keymap.set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
vim.keymap.set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })
vim.keymap.set("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
vim.keymap.set("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move up" })

-- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

-- LSP keymaps (will be set up when LSP attaches)
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    local opts = { buffer = ev.buf }
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
    vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts)
    vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts)
    vim.keymap.set("n", "<leader>wl", function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts)
    vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "<leader>f", function()
      vim.lsp.buf.format { async = true }
    end, opts)
  end,
})

-- Auto commands
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Create helix config directories if they don't exist
local helix_dir = config_dir .. "/helix"
vim.fn.mkdir(helix_dir, "p")

-- Print startup message
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if helix_cfg_ok then
      local status = helix_cfg.validate_config_files()
      local paths = helix_cfg.get_paths()
      
      print("Helix-style Neovim Configuration Loaded")
      print("=====================================")
      print("Use :HelixStatus to check configuration status")
      print("Use :HelixEdit [config|languages] to edit configuration files")
      print("Use :HelixReload to reload configuration")
      print("")
      
      if status.global_config or status.project_config then
        print("Configuration files found:")
        if status.global_config then
          print("  ✓ Global config: " .. paths.global.config)
        end
        if status.global_languages then
          print("  ✓ Global languages: " .. paths.global.languages)
        end
        if status.project_config then
          print("  ✓ Project config: " .. paths.project.config)
        end
        if status.project_languages then
          print("  ✓ Project languages: " .. paths.project.languages)
        end
      else
        print("No Helix configuration files found.")
        print("Create them with :HelixEdit config or :HelixEdit languages")
      end
    end
  end,
  once = true,
})
