# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

autoconf.nvim is a Neovim plugin that provides Helix-like configuration capabilities through TOML files. It allows users to configure their editor settings, keymaps, LSP, and plugin behavior using `config.toml` and `languages.toml` files.

## Core Architecture

### Module Structure

The plugin follows a modular architecture with clear separation of concerns:

- **Core System (`lua/autoconf/sys/core/`)**:
  - `loader.lua` - TOML configuration file loading and parsing
  - `resolvers.lua` - Central resolver registry and keymap handling
  - `helpers.lua` - Configuration merging, nested resolution, and lifecycle management
  - `logger.lua` - Logging system for debugging configuration issues

- **Resolver System (`lua/autoconf/sys/resolvers/`)**:
  - `editor/` - Editor-specific resolvers (appearance, LSP, completion, etc.)
  - `command/` - Command resolvers for Helix-style keybinding commands
  - Each resolver handles specific configuration paths

- **Defaults System (`lua/autoconf/sys/defaults/`)**:
  - `base.lua` - Basic editor defaults and tree-sitter setup
  - `lsp.lua` - LSP configuration defaults
  - `tabs.lua` - Language-specific tab/indentation settings

### Key Concepts

1. **Hierarchical Resolver System**: Configuration paths are resolved using fallback from specific to general (e.g., `editor.line-number` falls back to `editor` resolver)

2. **TOML Configuration**: Uses custom TOML parser (`toml.lua`) supporting TOML v1.0.0 specification

3. **Plugin Dependencies**: Automatic dependency checking for required Neovim plugins

4. **Lifecycle Management**: Supports normal and late initialization for resolvers that need to run after plugin setup

## Common Development Tasks

### Adding New Resolvers

1. Create resolver function in appropriate `sys/resolvers/` subdirectory
2. Register resolver using `resolvers.define_resolver(path, function)`
3. For complex resolvers, use table format with `lifecycle` property for late initialization

### Adding Command Resolvers

1. Implement command logic in `sys/resolvers/command/`
2. Register using `resolvers.define_command_resolver(name, resolver)`
3. Commands can be functions, strings, or tables with mode-specific definitions

### Testing Configuration

- Use `:HelixHealth` command to check plugin dependencies and configuration status
- Enable debug logging with logger functions to trace resolver execution
- Check keymap resolution status through resolver registry

### Plugin Dependencies

Required plugins are registered in `init.lua` using `resolvers.register_plugin_dependency()`. The system automatically checks for plugin availability and provides health information.

## Configuration File Locations

The loader searches for TOML files in:
1. `vim.fn.stdpath("config")` (usually `~/.config/nvim/`)
2. `vim.fn.stdpath("config") .. "/lua"`
3. `vim.fn.stdpath("data") .. "/nvim"`

## Debugging

- Use `logger.debug_*` functions for tracing resolver execution
- Check `M.keymap_status` in resolvers for keymap binding success/failure
- Use `:HelixHealth` to diagnose plugin dependency issues

## Entry Points

- `plugin/init.lua` - Plugin initialization entry point
- `lua/autoconf/init.lua` - Main module with `init()` function
- Configuration loading happens in `sys/core/loader.lua`
- Resolver initialization in `sys/resolvers/init.lua`

## Important Files to Understand

1. `lua/autoconf/init.lua` - Main initialization flow and dependency registration
2. `lua/autoconf/sys/core/resolvers.lua` - Core resolver system and keymap handling
3. `lua/autoconf/sys/core/helpers.lua` - Configuration resolution logic
4. `lua/autoconf/toml.lua` - Custom TOML parser implementation