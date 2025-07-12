## Extensibility and Maintenance

The configuration layer is designed to be **extensible**:

- New Helix config keys or sections can be added by implementing their mapping in the appropriate module. The code is organized by concern (editor vs keys vs languages).
- The mapping tables (for keys, for commands, for options) are easily modifiable. For instance, to support a newly introduced Helix command, a developer can add it to the `helix_to_vim_cmd` or mapping dictionary in `sys.keys`.
- If a new plugin needs to be integrated, one can create a new module or extend `sys.languages` or `sys.config`. For example, if we want to integrate a hypothetical Helix `[editor.minimap]` to a Neovim minimap plugin, we can add code in `sys.config.apply` to check for `editor.minimap` and call that plugin’s setup.
- The system should isolate plugin-specific code, so if a plugin is not installed, it either safely does nothing or warns. For instance, if `Comment.nvim` is not found but user provided `comment-tokens`, we could try to set `commentstring` as fallback. We can detect plugin presence with `pcall(require, 'Comment')` etc., and degrade gracefully.
- **Configuration Overrides**: If a user wants to override something via Lua after this layer runs, they can. We will load this layer before user’s own init.lua fully finishes (assuming they follow our recommended bootstrap). The user could still in their init.lua after calling `helix_cfg.setup()` put additional Vimscript or Lua to tweak settings. This might override what our layer set – which is fine and provides flexibility if needed.
- **Testing and Debugging**: Provide a verbose mode where the layer can log what it’s doing (which keys set, which LSP started, etc.). This could be triggered by an env variable or a global flag in config. This helps maintain and extend because one can see that, e.g., a particular Helix config didn’t get applied and then add support.

**Error Handling**:

- We’ve mentioned unknown keys being warned and skipped. Similarly, if a plugin integration fails (e.g. user doesn’t have conform.nvim but defined a formatter), we warn: “Formatter defined for X but conform.nvim not installed; skipping.” This nudges the user to either install plugin or remove that setting.
- If TOML parse fails entirely (syntax error in config file), we catch and report: “Failed to parse config.toml: \[error] – No Helix config applied.” Then perhaps continue with default Neovim behavior. This ensures a bad config doesn’t leave Neovim in a half-initialized broken state – it would just not apply those settings.
- If an LSP server command is not found (executing `cmd` fails), Neovim’s LSP will log error; we can also hook `on_exit` to detect if it failed to start and inform user to check installation.

## Example Usage

Finally, to illustrate how a developer would use this system, consider an example Helix-style configuration and its effects:

Suppose the user creates the following **`~/.config/nvim/helix/config.toml`:**

```toml
theme = "gruvbox"

[editor]
line-number = "relative"
cursorline = true
mouse = true
auto-completion = false
path-completion = false

[editor.cursor-shape]
normal = "block"
insert = "bar"
select = "underline"

[editor.statusline]
left = ["mode", "file-name"]
right = ["diagnostics", "position", "file-type"]
separator = " | "
mode.normal = "NORMAL"
mode.insert = "INSERT"
mode.select = "VISUAL"

[editor.auto-pairs]
"(" = ")"
"[" = "]"
"{" = "}"

[editor.whitespace]
render = "all"
[editor.whitespace.characters]
space = "·"
tab = "→ "
newline = "¶"

[editor.gutters]
layout = ["diagnostics", "line-numbers", "spacer"]
[editor.gutters.line-numbers]
min-width = 4

[editor.soft-wrap]
enable = true
wrap-indicator = "↩ "

[editor.inline-diagnostics]
cursor-line = "error"
other-lines = "warning"
prefix-len = 2

[keys.normal]
C-s = ":w"
g = { d = "diagnostics_panel" }

[keys.insert]
"jk" = "normal_mode"
```

And **`~/.config/nvim/helix/languages.toml`:**

```toml
[[language]]
name = "lua"
file-types = ["lua"]
language-servers = ["lua_ls"]
formatter = { command = "stylua", args = ["-"] }
auto-format = true
comment-tokens = "--"
block-comment-tokens = { start = "--[[", end = "]]" }
indent = { tab-width = 2, unit = "  " }

[[language]]
name = "markdown"
file-types = ["md"]
auto-format = false  # disable LSP/formatter on save
soft-wrap = { enable = true }
```

Given this configuration, the Lua-based layer will do the following:

- **Global Settings Applied**:

  - Set colorscheme to "gruvbox".
  - Enable relative line numbers (`number` on, `relativenumber` on).
  - Enable highlighting of the current line (`cursorline`) in all windows.
  - Enable mouse support in Neovim (set `mouse=a`).
  - Disable automatic completion popup and path suggestions: since `auto-completion=false` and `path-completion=false`, if using nvim-cmp, the layer would configure it to not autocomplete (e.g. `cmp.setup { completion = { autocomplete = false } }`) and remove the path source from the source list. The user will then only get completion when pressing a manual trigger (like <Ctrl-Space> if set).
  - Configure cursor shapes: Normal mode block, Insert mode bar, Visual mode underline by setting `'guicursor'` accordingly.
  - Configure the statusline via lualine (or native): left section shows mode and filename, right shows diagnostics count, cursor position, and file type. The sections will be separated by `" | "`. The mode labels for normal/insert/visual are overridden to “NORMAL/INSERT/VISUAL” instead of defaults.
  - Auto-pairs: Only basic brackets () \[] {} are auto-closed. The layer will enable _nvim-autopairs_ with only those pairs. Quotes will **not** be auto-closed because they weren’t listed (so typing `"` will not insert another `"` automatically, matching the user’s config).
  - Whitespace: All whitespace will be rendered visible. Spaces will appear as “·”, tabs as “→” followed by a space (the user put "→ " presumably to show an arrow and then a space for the tab fill), and newline at EOL as “¶”. The layer sets `listchars` to `space:·,tab:→\ ,eol:¶` (where `\ ` is a literal space character for tab fill) and enables `list` mode.
  - Gutters: Diagnostics and line-numbers are shown, but diff signs are omitted (since layout didn’t include "diff"). So:

    - The signcolumn will be shown (for diagnostics signs). Gitsigns will not be enabled at startup.
    - Line number column is shown with a minimum width of 4 (`numberwidth=4`).
    - After the number column, Neovim by default has no further gutter; “spacer” is just ignored.

  - Soft wrap: Enabled globally, so `wrap` is on for all buffers. The `showbreak` string is set to "↩ " to indicate wrapped line continuation. Long lines will wrap at window edge (since wrap-at-text-width not explicitly true, they wrap at window width). We also set `linebreak=true` so wrapping happens at word boundaries when possible. The `↩ ` will appear at the start of each wrapped line segment.
  - Inline diagnostics:

    - For all buffers, enable virtual text for diagnostics with severity >= “warning” by default (because other-lines = "warning"). So warnings and errors appear inline on all lines.
    - Additionally, on the line where the cursor is, we want to also show “error” level (which is already >= warning, so it’s covered) – but since cursor-line threshold is “error”, this implies perhaps that we _don’t_ want to show warnings on the cursor line unless they are errors. This is tricky: with the above, warnings would show everywhere, which might exceed the intention. To interpret config strictly: show only error diagnostics on cursor line (hiding warnings on that line until you move away), but show warnings on other lines. Our layer cannot easily hide a warning only on the current line, so as a simplification, we’ll show warnings on all lines (including current). This is a slight deviation. (We might note this limitation in documentation.)
    - The prefix for virtual text is set to two “─” characters (since prefix-len=2), so an inline error might appear as “── Error: <msg>” in a dim highlight.
    - If the user’s current line has a warning and no errors, ideally Helix wouldn’t show it, but our implementation will show it due to Neovim limitations. Future improvements could refine this by dynamically hiding it on the current line.

  - The above global settings happen once on startup.

- **Keybindings Mapped**:

  - Normal mode:

    - `<C-s>` is mapped to save the file (`:w`).
    - `g d` is mapped to “diagnostics_panel”. We need to interpret that command: Suppose we decide `diagnostics_panel` should open a quickfix list or Telescope diagnostics. If we have no built-in mapping for “diagnostics_panel”, our layer might warn “Unknown command diagnostics_panel for key g+d”. If we anticipated it, we could map it to Neovim’s `vim.diagnostic.open_float()` or a Trouble.nvim toggle. Let’s assume unknown, so we warn. (A developer extending could map `diagnostics_panel` to, say, Trouble plugin’s diagnostics view or quickfix.) For now, we skip it, meaning `gd` remains its normal behavior (which is go to definition by default in LSP – interestingly `gd` might then do something else by default).
    - We did set `g` prefix though with `d` in it. Actually, better: we _should not_ create a mapping for bare `g` because we have a specific `gd`. Vim by default has `gd` for go to definition. Our user intended `gd` to open diagnostics panel. If we override `gd`, we shadow the LSP go-to-def. That might be fine if user wanted it. But likely “diagnostics_panel” is a Helix command to show diagnostics, they wanted that on gd. So yes, we would override `gd` to some diagnostics list. If we have Telescope, we could do `vim.keymap.set('n', 'gd', '<Cmd>Telescope diagnostics<CR>')` for example. (This illustrates the layer might need knowledge of some Helix commands to map them to popular Neovim actions or require the user to adjust.)

  - Insert mode:

    - `"jk"` is mapped to exit insert (Esc). So when the user types j followed by k quickly, Neovim will return to Normal mode.

  - We preserve any other default keys (like we didn’t specify anything for `<C-o>` normal, so it remains as default “open a line below” in Vim? Actually `<C-o>` in normal in Vim is used to do one normal command in insert, not relevant here).
  - Since `auto-completion` was false, presumably we also removed the typical `<Tab>` mapping in insert mode that cycling suggestions might have had (if using nvim-cmp) – but user didn’t explicitly map Tab to something else here, so Tab in insert will insert a tab or spaces as per indent settings (which for Lua is 2 spaces expandtab).

- **Language-Specific Effects**:

  - **Lua**:

    - On opening a Lua file, the layer sees filetype "lua". It sets up `lua_ls` LSP via nvim-lspconfig, using default cmd (since Helix likely has built-in command for it or we rely on lspconfig's default which is fine if lua-language-server is installed). The server attaches to Lua buffers providing completions, diagnostics, etc.
    - The formatter `stylua` is registered with Conform. On save of Lua files, the layer will run `stylua` to format the code. It constructs command `stylua -` (reads from stdin). Because `auto-format = true`, the BufWritePre autocmd triggers Conform to format the buffer. If stylua is not found in PATH, Conform will show an error notification on save (and user should install it or Mason could be used).
    - Comment.nvim is configured for Lua: line comment string `--` and block comment string `--[[ %s ]]` (though Helix gave block-comment-tokens, we use them). Actually Helix gave start="--\[\[" and end="]]", so our mapping would set Comment.ft for 'lua' to `{ '--%s', '--[%s]--' }`. Wait, the correct usage: For Lua, line is `--`, block is `--[[ content ]]`. In Vim's commentstring, block comment would be `--[[%s]]`. We will do:

      ```lua
      ft.set('lua', { '--%s', '--[[%s]]' })
      ```

      This means `gc` on a line uses `--`, and `gb` on a visual selection uses the long form.

    - Indentation: indent unit is 2 spaces, so we set `shiftwidth=2`, `tabstop=2`, `expandtab=true` for Lua files. This matches typical Lua style.
    - The combination of disabling auto-completion globally means even though lua_ls provides completions, they won’t pop up automatically. The user would press e.g. `<C-x><C-o>` or something to complete (unless they mapped a key).
    - If the user triggers a code action (like pressing `ga` if they mapped it to code action as above), it will bring up LSP code actions from lua_ls.

  - **Markdown**:

    - No LSP server is set up because none listed.
    - auto-format false, so we ensure not to format on save. If the user had an LSP or a formatter, it wouldn’t run due to the flag.
    - soft-wrap enabled for markdown via language override. So even if globally wrap was enabled already, we might ensure linebreak as well specifically. But global already turned on wrap for all files, so maybe this override is redundant. If global hadn’t, this would turn it on for markdown only.
    - We might also consider markdown typically might want different comment string (like HTML comments, but user didn’t specify comment-tokens for markdown; if they did, we’d set those).
    - Indent not specified, so likely default (maybe 4 spaces or whatever Neovim’s default).
    - They didn’t specify `text-width` for markdown, but commonly might want 80. If they had, we’d set colorcolumn=80 and maybe something. Not here though.

  - The system would output to the user (via notifications or messages) any issues encountered:

    - If `diagnostics_panel` command was not recognized, a warning: “Helix command 'diagnostics_panel' not mapped (no Neovim equivalent found).”
    - If any plugin was missing (say Comment.nvim not installed, we'd warn that comment-tokens for lua won’t apply).
    - Ideally, no errors in this scenario given everything set.

This example demonstrates how a Helix user can write config in TOML, and the Neovim config layer interprets and applies it. The user sees:

- Gruvbox theme and relative line numbers in Neovim, just as they had in Helix.
- Statusline with mode and file info, etc. If using lualine, it shows "NORMAL" or "INSERT" explicitly as set.
- In insert mode, typing `jk` returns to normal (like a common Vim mapping, configured through Helix keys).
- When editing Lua, the code auto-formats on save with stylua, and `--` comments toggle correctly. Insert mode doesn’t pop up completions automatically, matching `auto-completion=false`.
- Neovim’s behavior in various respects (wrap, whitespace chars, etc.) matches what the user set according to Helix’s paradigm.

## Conclusion

The above specification provides a comprehensive blueprint for implementing the Lua-based Helix configuration layer. By following it, a developer can create a system such that Neovim reads Helix-style `config.toml` and `languages.toml` and configures itself accordingly. All major Helix `[editor]` configurations have been mapped to Neovim options or plugin settings (with citations from Helix documentation confirming their meaning), key remappings are translated to `vim.keymap.set()` calls, and language-specific settings drive LSP, commenting, formatting, and other behaviors. The design emphasizes completeness and maintainability, allowing users to enjoy Helix’s configuration style while leveraging Neovim’s ecosystem.
