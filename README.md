# autoconf.nvim

A Neovim plugin that provides Helix-like configuration capabilities, allowing you to manage your editor configuration through TOML files and apply custom keymaps.

## Features

- **TOML-based Configuration**: Manage your Neovim settings through `config.toml` and `languages.toml`
- **Custom Keymaps**: Define and apply custom keybindings in a Helix-like style
- **Plugin Management**: Automatic handling of plugin dependencies
- **Modular Architecture**: Easily extendable with custom resolvers and commands
- **Editor Integration**: Seamless integration with Neovim's native features and plugins

## Installation

1. Clone this repository into your Neovim configuration directory:

   ```bash
   git clone https://github.com/your-repo/neovim-helix-configurator ~/.config/nvim
   ```

2. Install the required plugins using your preferred plugin manager.

3. Create your `config.toml` and `languages.toml` files in the `.config/nvim` directory.

## Configuration

### config.toml

The main configuration file where you can define:

- Editor settings
- Keybindings
- Plugin configurations
- Custom commands

Example:

```toml
[editor]
line_number = true
cursorline = true
theme = "onedark"

[keys.normal]
"gd" = "goto_definition"
"gr" = "goto_reference"
```

### languages.toml

Language-specific configurations including:

- LSP settings
- Formatting options
- Syntax highlighting

Example:

```toml
[[language]]
name = "rust"
lsp = "rust-analyzer"
formatter = "rustfmt"

[[language]]
name = "python"
lsp = "pyright"
formatter = "black"
```

You can also use the extended table format to pass custom LSP configuration options:

```toml
[[language]]
name = "fsharp"
lsp = { server = "fsautocomplete", cmd = ["dotnet", "fsautocomplete", "--background-service-enabled"] }
formatter = "fantomas"

[[language]]
name = "lua"
lsp = {
    server = "lua_ls",
    settings = { Lua = { diagnostics = { globals = ["vim"] } } }
}
formatter = "stylua"
```

The table format supports any lspconfig options including:
- `cmd` - Custom command to start the LSP server
- `settings` - Server-specific settings
- `init_options` - Initialization options
- `root_dir` - Custom root directory function
- And any other options supported by nvim-lspconfig

## Keymap System

The plugin implements a powerful keymap system that:

- Supports multiple modes (normal, insert, visual, etc.)
- Allows for complex key combinations
- Provides automatic conversion from Helix-style keybindings to Neovim keymaps

Example keymap configuration:

```toml
[keys.normal]
"C-s" = "save"
"C-f" = "file_picker"
"S-w" = "window.split"
```

## Plugin Dependencies

The plugin requires these dependencies to be installed:

- `lualine.nvim` (Statusline)
- `nvim-autopairs` (Auto-pairing)
- `nvim-lspconfig` (LSP configuration)
- `nvim-cmp` (Completion)
- `telescope.nvim` (File picker)
- `nvim-treesitter` (Syntax highlighting)
- `gitsigns.nvim` (Git integration)
- `conform.nvim` (Formatting)
- `bufferline.nvim` (Buffer management)
- `hop.nvim` (Navigation)

## Custom Resolvers

The plugin supports custom resolvers for:

- Editor settings
- Keybindings
- Plugin configurations
- Language-specific settings

Example resolver implementation:

```lua
resolvers.define_resolver("editor.line-number", function(value)
    vim.opt.number = value
    vim.opt.relativenumber = value
end)
```

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a new branch for your feature
3. Submit a pull request

## License

## Credits

TOML parsing is provided by [lua-toml](https://github.com/jonstoler/lua-toml) by Jonathan Stoler (Copyright © 2017)
MIT License - See LICENSE for details
