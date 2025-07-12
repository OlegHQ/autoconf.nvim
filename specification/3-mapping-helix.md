## Mapping Helix `[editor]` Options to Neovim

The **`sys.config` module** will be responsible for applying the general editor settings found under the `[editor]` table and its sub-sections. It will contain mapping logic for each recognized config key. The implementation can use a dispatch table or conditional statements per key. Below is a breakdown of how each major Helix editor config corresponds to Neovim settings or plugin configurations:

- **Theme (`theme`):** If the top-level `theme` key is set in config.toml, the layer will attempt to apply a Neovim colorscheme of the same name. For example, `theme = "onedark"` would translate to `vim.cmd('colorscheme onedark')`. (It assumes the user has installed a matching Neovim theme plugin or it’s a built-in theme.) If the theme is not found, an error or warning is logged. This allows Helix users to set their theme in TOML as they did in Helix.

- **Line Numbers (`editor.line-number`):** Helix supports `"absolute"` or `"relative"` for line numbers (with relative showing distance from current line, and absolute when in insert mode). The Lua layer will set Neovim’s `number` and `relativenumber` options accordingly:

  - `"absolute"` -> `vim.wo.number = true`, `vim.wo.relativenumber = false`.
  - `"relative"` -> `vim.wo.number = true`, `vim.wo.relativenumber = true` (Neovim automatically shows absolute number on the current line when relativenumber is on, which aligns with Helix behavior of still showing absolute for current line).
  - If a user somehow specifies `"none"` or turns off line numbers via Helix config (Helix itself might not use `"none"` here, but possibly by removing `line-numbers` from gutters), the layer will set `vim.wo.number = false` to hide line numbers.
  - Additionally, Helix’s `[editor.gutters]` configuration can affect line numbers display (explained later under gutters), but the `line-number` style is handled here.

- **Cursor Line Highlight (`editor.cursorline`):** If Helix config has `cursorline = true` (Helix’s description: “Highlight all lines with a cursor”), set `vim.wo.cursorline = true` (Neovim highlights the current line). If false (default), ensure `cursorline` is off.

- **Mouse (`editor.mouse`):** Helix’s `mouse` option toggles mouse support (e.g., `mouse = false` in example). Map this to Neovim’s `'mouse'` option. If false, set `vim.o.mouse = ""` (empty string disables mouse in all modes). If true, set `vim.o.mouse = "a"` (enable in all modes) similar to Vim’s defaults.

- **Statusline (`editor.statusline`):** Helix allows a highly configurable status line, with sections for left, center, right, separators, and mode text overrides. In Neovim, achieving a similar statusline will likely involve a plugin (such as **lualine.nvim** or building a custom `statusline` string).

  - The Lua layer will interpret `editor.statusline.left/center/right` lists and the elements like `"mode"`, `"file-name"`, `"position"`, etc.. A recommended approach is to use the **lualine** plugin (if installed) and map these elements to lualine’s sections or components:

    - For example, Helix’s default left = `["mode","spinner"]` can map to lualine’s `mode` component and an LSP progress spinner (possibly provided by an extension or by custom function).
    - `center = ["file-name"]` could map to lualine’s center with filename.
    - `right = ["diagnostics","selections","position",...]` maps to lualine components: diagnostics (with counts), selection count (no direct equivalent in Neovim; might require a custom component to show number of visual selection or multiple cursors if using a plugin), cursor position (percentage through file, etc.).
    - The `separator` string (default `"│"`) can be applied if using a custom statusline (or possibly lualine separators).
    - Mode text overrides: Helix allows customizing the text for mode names (e.g. `editor.statusline.mode.normal = "NORMAL"` etc.). In Neovim, lualine by default displays "NORMAL", "INSERT", etc., but if the user has custom labels, we might reflect that by overriding how mode is displayed (lualine can be configured with custom mode names via its `component_format` or using an override table).

  - If lualine is not available, an alternative is to construct a `%statusline` using Neovim’s `'statusline'` option with `%` codes. This is more involved, so leveraging lualine’s existing capabilities is preferred.
  - This spec assumes we will integrate with lualine for ease. The `sys.config` module would import lualine and build a configuration table from Helix settings. If a user doesn’t care about exact statusline parity, they can ignore this section or we provide a reasonable default mapping of Helix elements to lualine components.


- **Cursor Shape (`editor.cursor-shape`):** Helix lets you set cursor shape per mode (e.g. block in normal, bar in insert, etc.). In Neovim, cursor shape in the terminal is controlled by the `'guicursor'` option. We will compose a `guicursor` string based on the Helix settings:

  - Map Helix’s `block`, `bar` (vertical) or `underline` to Neovim `guicursor` settings for each mode. For example, Helix config:

    ```toml
    [editor.cursor-shape]
    normal = "block"
    insert = "bar"
    select = "underline"
    ```

    would lead to:

    ```lua
    vim.o.guicursor = "n:block,i:ver25,v:underline"
    ```

    Here, “ver25” is a vertical bar (bar) of width 25% for insert mode (or we can use “ver” default thickness). `v:underline` means visual (select) mode uses underline. We also include `i:ver25` for insert (Neovim’s term for bar shape). We should include modes: normal (`n`), visual (`v`)/select, insert (`i`), etc. Helix only has normal/insert/select, but Neovim’s select mode is similar to visual so we map both. The default for modes not mentioned will remain whatever Neovim default is or we explicitly set them to something (Neovim default if `'guicursor'` is empty is a block cursor in all modes in terminal).

  - If Helix’s config sets any mode to `"hidden"`, we can set that mode in guicursor to `a:blinkon0` or an empty shape (though blinking off might not truly hide; a better approach might be to not modify if hidden since terminal cursor can’t truly disappear easily except some sequences).
  - If `'guicursor'` causes issues in some terminals (as noted in Neovim FAQ), the user can always override by disabling guicursor. Our layer will assume enabling it is fine for compatibility with Helix-like behavior.