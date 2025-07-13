With packer.nvim

Using packer.nvim (this should probably be registered after lspconfig):

use({
  "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
  config = function()
    require("lsp_lines").setup()
  end,
})

#
Setup

When using this plug-in, the regular virtual text diagnostics becomes redundant. It is recommended to disable it:

-- Disable virtual_text since it's redundant due to lsp_lines.
vim.diagnostic.config({
  virtual_text = false,
})

#
Usage

This plugin's functionality can be disabled with:

vim.diagnostic.config({ virtual_lines = false })

And it can be re-enabled via:

vim.diagnostic.config({ virtual_lines = true })

To show virtual lines only for the current line's diagnostics:

vim.diagnostic.config({ virtual_lines = { only_current_line = true } })

If you don't want to highlight the entire diagnostic line, use:

vim.diagnostic.config({ virtual_lines = { highlight_whole_line = false } })

A helper is also provided to toggle, which is convenient for mappings:

vim.keymap.set(
  "",
  "<Leader>l",
  require("lsp_lines").toggle,
  { desc = "Toggle lsp_lines" }
)

#
Development

It would be nice to show connecting lines when there's relationship between diagnostics (as is the case with rust_analyzer). Or perhaps surface them via vim.lsp.buf.hover.
#
Licence

This project is licensed under the ISC licence. See LICENCE for more details.