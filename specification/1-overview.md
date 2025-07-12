## Overview and Goals

This specification describes a **Lua-based configuration layer** for Neovim that allows users to configure Neovim using Helix editor’s TOML configuration model. The goal is to support Helix-style `config.toml` and `languages.toml` files (including key remappings) and translate them 1:1 into Neovim’s native settings and plugin configurations. By doing so, former Helix users or those who prefer Helix’s declarative config can configure Neovim **without writing Lua code**. Key objectives include:

- **Complete Coverage of Helix Options:** All `[editor]` sections from Helix’s config (and sub-sections like `statusline`, `lsp`, `auto-pairs`, `whitespace`, etc.) are recognized and mapped to Neovim equivalents. Helix’s key binding remaps (from `[keys.mode]` sections) are converted into Neovim keymaps. Language-specific settings in `languages.toml` (LSP servers, comment strings, formatters, etc.) are applied via Neovim’s LSP and relevant plugins.
- **Seamless Bootstrapping:** The configuration layer’s Lua modules reside under `~/.config/nvim/sys/*.lua` and are loaded by `init.lua`. On startup, Neovim will parse the Helix-style TOML files and apply settings before or during plugin initialization as needed.
- **Override Hierarchy:** Support both global config (in the user’s config directory) and project-specific config (`.helix/config.toml` and `.helix/languages.toml` in a project). The project config, if present, merges with and overrides the global config, similar to Helix’s behavior. This ensures project-specific tweaks take priority.
- **Extensibility:** The system is designed for easy extension. New Helix config keys or new plugins can be integrated by adding mapping logic in one place without breaking the overall system. The Lua modules are organized logically so future additions (e.g. additional plugins or new Helix options) can be made with minimal changes.
- **Robustness:** Graceful handling of errors or unsupported settings. If a configuration key or section has no clear Neovim equivalent, the system will warn or safely ignore it. Parsing errors in TOML or missing plugins are caught and reported, so they do not break Neovim startup.

By achieving the above, a user can take a Helix `config.toml` and `languages.toml` (potentially even their existing Helix config files) and drop them into their Neovim config directory, and the Neovim experience will respect those settings as if they were configured in Lua.

## File Structure and Bootstrapping Logic

**Configuration Files**: The user will place Helix-style TOML files in a designated location (for example, `~/.config/nvim/helix/config.toml` and `~/.config/nvim/helix/languages.toml`). These mirror Helix’s own config files. Optionally, the system can also look for actual Helix config in `~/.config/helix/` to allow reuse of an existing Helix config. Project-specific overrides will be looked for in the project’s `.helix/` directory (i.e. a local `config.toml` or `languages.toml` inside a `.helix` folder).

**Lua Module Layout**: All implementation resides under `~/.config/nvim/sys/` as Lua modules. The proposed module structure is:

- **`sys/init.lua`** – Entry point for the Helix config layer. It is required by Neovim’s `init.lua`. This module bootstraps the process: it loads the TOML files, merges configurations, and invokes specific modules to apply settings.
- **`sys/config.lua`** – Handles **global editor settings** from `config.toml`. This includes top-level keys (like `theme`) and the `[editor]` table and its subsections. It maps Helix editor options to Neovim vim options or calls plugin setups for UI-related settings.
- **`sys/keys.lua`** – Handles **key remappings** from the `[keys.*]` sections in `config.toml`. It translates Helix keybinding definitions into calls to `vim.keymap.set()` in the appropriate modes.
- **`sys/languages.lua`** – Handles **language-specific settings** from `languages.toml`. This module configures LSP servers (via nvim-lspconfig), comment strings (via Comment.nvim), formatters (via conform.nvim), git integration (via gitsigns.nvim), indentation, and any other per-language behavior.
- **`sys/util.lua`** – Utility functions used across the modules. For example, a TOML parsing function, deep-merge logic for tables, conversion helpers (like translating Helix key notation to Vim key notation), and logging/warnings for unsupported settings.

Neovim’s `init.lua` should load the Helix config layer early in the startup sequence, before or alongside plugin initialization:

```lua
-- init.lua (excerpt)
-- Load Helix-style configuration translator
local helix_cfg = require('sys')
helix_cfg.setup()
```

The `sys/init.lua` (exposed as the `sys` module) provides a `setup()` function. This function will:

1. **Locate and Parse Config Files**: Determine paths for global and project `config.toml` and `languages.toml`. For example, global paths might be `~/.config/nvim/helix/config.toml` and `~/.config/nvim/helix/languages.toml`. Project path is `.helix/config.toml` relative to the current working directory (if present). Use the TOML parser to read these files into Lua tables (e.g. `global_config`, `global_lang`, `project_config`, `project_lang`). If files are missing, treat as empty.
2. **Merge Configurations**: Merge project tables into global tables to produce a final effective config. The merge should override individual settings from the global config with those from the project config (if specified). Merging rules:

   - For simple keys (strings, booleans, numbers), the project value overrides the global value.
   - For table sections, perform a **deep merge**: project sub-keys override or add to global sub-keys. (E.g. if global `[editor]` has some settings and project `[editor]` has others, combine them, overriding conflicts.)
   - For list-like tables (e.g. the `gutters = [ ... ]` array or lists of language servers), it might be clearer to let the project config **replace** the list if it provides one. (Alternatively, merging lists could concatenate unique entries, but for simplicity, replacement is safer unless a special merge rule is needed.)
   - For key mappings (`[keys]` sections), merge such that project keybindings override global ones if they map the same key sequence in the same mode. New mappings in project are appended. (This requires comparing keys: if a key combo is defined in both, use project’s command.)
   - For `languages.toml`, merging means: combine the list of language definitions. If a project defines a language with the same name as global, override that language’s settings fields individually. Similarly, merge/override entries under `[language-server.<name>]`.

3. **Apply Settings**: Call the respective submodules to apply each part of the configuration:

   - `sys.config.apply(editor_config_table)` – apply general editor settings.
   - `sys.keys.apply(keymaps_table)` – define key mappings.
   - `sys.languages.apply(lang_table)` – configure languages (LSP, formatters, etc.).

4. Ensure that these are done in correct order. For example, some editor settings (like theme or UI options) should be set early. LSP and plugin configurations should run after plugins are loaded (the config layer can be loaded as part of `init.lua` but may need to defer certain setup until the relevant plugins are available; e.g. using plugin-specific setup calls).

**Bootstrapping Example**: The `sys/init.lua` might do something like:

```lua
local M = {}
function M.setup()
  local cfg = require('sys.util').load_helix_config()      -- parse TOML files
  require('sys.config').apply(cfg.editor)                  -- apply [editor] settings
  require('sys.keys').apply(cfg.keys)                      -- apply [keys] mappings
  require('sys.languages').apply(cfg.languages)            -- apply languages.toml
end
return M
```

Where `load_helix_config()` would implement steps 1 and 2 (file loading and merging), returning a consolidated table with sub-tables like `editor`, `keys`, `languages`.
