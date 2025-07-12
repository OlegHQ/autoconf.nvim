## Parsing Helix TOML Configuration

**TOML Parser**: The implementation will use a Lua TOML parser (for example, `cjoudrey/toml.lua` or similar) to convert the Helix config files into Lua tables. This avoids writing a custom parser. The parser should preserve the nested table structure corresponding to Helix’s sections.

- After parsing, `config.toml` might produce a table like:

  ```lua
  {
    theme = "onedark",
    editor = {
      ["line-number"] = "relative",
      mouse = false,
      cursorline = false,
      auto_completion = true,
      path_completion = true,
      gutters = {"diff","diagnostics","line-numbers","spacer"},
      -- Subsections become nested tables:
      ["cursor-shape"] = { insert = "bar", normal = "block", select = "underline" },
      ["file-picker"] = { hidden = false, follow_symlinks = true, ... },
      ["auto-pairs"] = { ["("] = ")", ["{"] = "}", ... },  -- If auto-pairs configured as table
      -- If auto-pairs was just a boolean in [editor], it would appear as editor["auto-pairs"] = false.
      whitespace = {
        render = "all",
        characters = { space = "·", tab = "→", newline = "⏎", tabpad = "·" }
      },
      ["indent-guides"] = { render = true, character = "╎", skip_levels = 1 },
      lsp = { enable = true, display_messages = true, display_progress_messages = false, ... },
      -- etc. for other sections
    },
    keys = {
      normal = { ["C-s"] = ":w", ["a"] = "move_char_left", g = { a = "code_action" }, ... },
      insert = { ["A-x"] = "normal_mode", j = { k = "normal_mode" }, ... },
      select = { ... }
    }
  }
  ```

  And `languages.toml` parsing yields:

  ```lua
  {
    -- Possibly top-level keys like use-grammars, etc., then:
    language = {
      { name="rust", auto_format=false, indent={tab_width=4, unit="\t"}, language_servers={"rust-analyzer"} },
      { name="mylang", scope="source.mylang", file_types={"myl","mylang"},
        comment_tokens="#", block_comment_tokens={ start="/*", end="*/" },
        formatter={ command="mylang-formatter", args={"--stdin"} },
        language_servers={"mylang-lsp"}
      },
      -- ...more [[language]] entries
    },
    ["language-server"] = {
      ["mylang-lsp"] = { command = "mylang-lsp", args = {"--stdio"} },
      ["rust-analyzer"] = { command = "rust-analyzer" },  -- assuming this might not need config
      -- possibly config sub-tables if provided
    }
  }
  ```

  The **util module** will provide a `load_toml(file_path)` function to get such tables and then a `merge_tables(base, override)` to merge project into global. If any parse error occurs (malformed TOML, etc.), the util should catch it and notify the user (e.g. via `vim.notify()` or printing a message) and proceed with defaults for that file.

**Override Priority**: When merging, **project config overrides global config** on a per-key basis. For example, if global `config.toml` sets `editor.theme = "onedark"` but project’s `.helix/config.toml` sets `editor.theme = "gruvbox"`, the project’s choice wins. Keys not present in project config remain as set globally. This mirrors Helix’s “local config merges with configuration directory config”.

- If both global and project define an array (like `gutters` list or a list of language servers), the project’s list will replace the global one **unless** a smarter merge is needed. (One might consider merging arrays by union, but deterministic override is simpler and closer to user expectation that local config “replaces” when specified).
- For nested tables, merge deep: e.g. if project `editor.whitespace` only specifies `render="all"`, but global had custom `characters`, we want to keep global’s `characters` unless overridden. Implementation: iterate keys; if value is a table in both, recurse merge; otherwise, assign override.

**Built-in Defaults**: Helix has built-in default settings (e.g. `editor.auto-pairs` default to true with certain pairs, `editor.lsp.enable` default true, etc.). In our layer, Neovim itself has defaults or we may want to mimic Helix’s defaults where possible:

- If a setting is not specified in either global or project config, we can either **do nothing** (leaving Neovim at its own default), or explicitly set Neovim to Helix’s default if they differ and if emulating Helix out-of-the-box behavior is desired.
- For example, Helix’s default `editor.auto-pairs` is true, whereas Neovim by default does not auto-pair brackets. We likely should enable the autopairs plugin by default unless the user turns it off in config (to match Helix behavior). We will incorporate a table of Helix default values and apply them for any config key that remains unset after merging. This ensures the experience is consistent (though the user can always override by specifying in their config).
- Another example: Helix default `editor.line-number = "absolute"` (i.e., absolute line numbers). Neovim’s default is also absolute line numbers enabled (`number` on by default). We might still explicitly handle this setting for clarity.
- All default values and behaviors taken from Helix docs will be encoded in the Lua layer (e.g., if no `editor.cursorline` specified, default is false in Helix, and we won’t enable `vim.opt.cursorline` unless set to true).

By parsing and preparing the config data in this way, we have a structured representation of everything the user specified (or defaulted) using Helix’s schema, ready to feed into the mapping logic.
