## Key Remapping Translation (`[keys]` sections)

Helix uses TOML sections like `[keys.normal]`, `[keys.insert]`, `[keys.select]` (and further minor mode nesting) for one-way key remapping. Our `sys.keys` module will translate these into Neovim keymaps using `vim.keymap.set()`.

**Parsing Helix Keymap Structure**: After TOML parsing, the `keys` table might look like this:

```lua
keys = {
  normal = {
    ["C-s"] = ":w",
    ["C-o"] = ":open ~/.config/helix/config.toml",
    ["a"] = "move_char_left",
    ["w"] = "move_line_up",
    ["C-S-esc"] = "extend_line",
    ["g"] = { a = "code_action" },
    ["ret"] = {"open_below", "normal_mode"},
    ["A-x"] = "@x<A-d>"
  },
  insert = {
    ["A-x"] = "normal_mode",
    ["j"] = { k = "normal_mode" }
  },
  select = {
    -- possibly similar structure if any
  }
}
```

This corresponds to examples from Helix docs. We also support nested “minor modes” under these, e.g. `[keys.normal.g]` is another way Helix represents multi-key sequences. The TOML parser will merge `[keys.normal] g = { a = "code_action" }` into the structure as shown (where `normal.g = { a = "code_action" }`). Alternatively, we might need to manually traverse for nested sections:

- Helix keys can be hierarchical: e.g. `[keys.normal.g] a = "code_action"` is equivalent to in TOML `[keys.normal] g = { a = "code_action" }` as shown by their example. We should ensure that our TOML parser captures the nested structure. If not, we might have to do a second pass merging keys like `normal.g` into `normal` table.

**Key Notation Conversion**: Helix’s key syntax differs slightly from Vim’s:

- Helix uses `C-` for Ctrl, `A-` for Alt (which in Neovim corresponds to `Alt` often being mapped to `<M->` meta). It uses `S-` for Shift in combinations, and special names like `"ret"` for Enter, `"tab"`, `"backspace"`, etc..

- We need to convert these to Vim notation:

  - `C-x` -> `<C-x>`
  - `A-x` -> `<A-x>` (in Neovim, `<A-x>` is typically how Alt+X is represented since Alt is usually Meta).
  - `S-tab` – in Neovim, shifted special keys can be tricky (`<S-Tab>` might be recognized in GUI, but in terminal it’s often same as `<Tab>` code). We will still map it as `<S-Tab>` and assume terminal supports it or leave it to user’s terminal settings.
  - Named keys:

    - `"ret"` -> `<CR>` (Carriage Return).
    - `"space"` -> `<Space>`.
    - `"backspace"` -> `<BS>`.
    - `"del"` -> `<Del>`.
    - `"left"`/`"right"`/`"up"`/`"down"` -> `<Left>` etc.
    - `"home"` -> `<Home>`, `"end"` -> `<End>`, `"pageup"` -> `<PageUp>`, `"pagedown"` -> `<PageDown>`.
    - `"esc"` -> `<Esc>`.
    - Helix also has notation for `"-"` (literal dash vs as part of a chord – but they note `A--` is not valid, must use A-minus). We need to handle if user wrote `"A-minus"` to mean Alt + '-' or similar.
    - We should create a mapping dictionary for all special names to Vim’s angle-bracket notation.

- Compound keys:

  - Helix allows mapping sequences like `g a` or `j k` by nesting tables: e.g. `["g"] = { a = "code_action" }` or `[keys.insert] j = { k = "normal_mode" }` to map “jk” in insert to escape. We need to flatten these to Vim keymap expressions:

    - A mapping of `jk` in insert mode to `<Esc>` should be set as: `vim.keymap.set('i', 'jk', '<Esc>', opts)`.
    - So our code must detect when a value is a table (meaning a prefix mapping).
    - We can recursively traverse: In `[keys.normal]`, see key "g" has value table `{ a = "code_action" }`. That means we map "ga" in normal mode. Similarly, "j" in insert with subkey "k" means "jk".
    - The algorithm: for each entry in `keys.normal` (for example):

      - If the value is a string or list, it’s a final command mapping for the key sequence accumulated so far.
      - If the value is a table, it indicates a prefix; we need to iterate its subkeys, adding the prefix key to the sequence.

    - We likely should do a depth-first traversal to build full key sequences.

  - Also note Helix supports mapping Alt/Ctrl in the second part of a chord, e.g. `"+" as a minor mode prefix with keys inside:contentReference[oaicite:89]{index=89}. Our parsing covers that since `normal\["+"] = { m = "\:run-shell-command make", ... }\` would be present.
  - We must ensure to wrap multi-key sequences properly:

    - Possibly by temporarily using `vim.keymap.set` with `remap=false` (non-recursive) and `nowait=true` for prefix to avoid delays, though `vim.keymap.set` can handle prefix mappings normally.
    - Actually, in Vim, creating a mapping for a prefix alone (like `g` with no action) isn’t needed; you directly map "ga". But if we want to ensure no built-in binds conflict, we might do `vim.keymap.set('n', 'g', '<Nop>', { remap=false })` to reserve it if necessary. However, Helix’s approach is one-way remap and typically you’d override whole sequence at once.
    - Implementation: we can just map full sequences like "ga", "jk", etc. The recursion will naturally produce the full combination.

- **Commands vs Motions vs Macros**:

  - If the mapping target (value) starts with a colon `:` in Helix, it’s a “typable command” (like `:w` for write). We should map that to an ex command in Neovim. For example, `":w"` can map to `<Cmd>write<CR>` in Neovim (which avoids leaving normal mode). So `vim.keymap.set('n', '<C-s>', '<Cmd>w<CR>')` to save on Ctrl+S in normal mode.
  - If the target is a known Helix “static command” like `"move_char_left"` or `"extend_line"`, we need to decide how to handle it:

    - Some static commands correspond to simple motions or actions in Vim. For instance, `"move_char_left"` is effectively pressing `h` (move cursor left). We can map that key to the actual movement in Vim: e.g. in normal mode, mapping `a` to `h` (if user remapped as in example). Better to use the actual action: `vim.keymap.set('n', 'a', 'h', {remap=false})` so it moves left. Likewise, `move_line_up` corresponds to `k` (cursor up a line), so map `w` to `k`. We can maintain a dictionary of common Helix static commands to Vim motions:

      - `move_char_left` -> `h`
      - `move_char_right` -> `l`
      - `move_line_up` -> `k`
      - `move_line_down` -> `j`
      - etc., including ones for word, paragraph, etc., if needed.

    - Some static commands may not have direct equivalents or might be more complex (like `extend_line` which in Helix might extend selection to end of line – in Vim normal mode `Shift-$` could be something, but we’d need to think if the user is in visual or normal? Helix’s `extend_line` likely means in select mode extend selection through line; in Vim if in visual mode, pressing `$` extends to EOL. If mapping in normal mode, maybe they intend it to start a visual selection to end of line? Hard to know from context).

      - We may not support all static commands. For those unmapped, we could issue a warning “Cannot translate Helix command X for key Y” and skip that mapping.

    - Alternatively, if the user has LSP configured and Helix static commands include things like `code_action`, we might map to an appropriate Neovim command:

      - Helix’s `code_action` static command triggers an LSP code action menu. In Neovim, the equivalent is `vim.lsp.buf.code_action()` or calling Telescope’s code actions picker. We can map that accordingly (e.g. to a Lua function or `<Cmd>lua vim.lsp.buf.code_action()<CR>`).
      - `open_below` likely means open a new line below (like O in normal mode in Vim, or `o`?), or open a split? Actually Helix has `open_below` to open a new line below cursor and insert mode (like Vim’s `o`). So map it to `o` in normal mode.
      - `normal_mode` command means exit to normal mode (like pressing Escape). So in insert mode, mapping `jk` to `normal_mode` we do `'<Esc>'`.
      - `clipboard-yank` (`:clipboard-yank` in example) might correspond to copying to system clipboard. Vim’s way: `"+y` for yank, or we map to `<Cmd>%y+<CR>` if we interpret context. Helix had `cly = ":clipboard-yank"` in a reddit snippet. That’s harder but perhaps skip or require user to have implemented separate.

    - The key translator module could include a mapping of Helix commands to either Vim keys or Vim ex commands or Lua calls, where possible. A small sample mapping:

      ```lua
      local helix_to_vim_cmd = {
        move_char_left = 'h',
        move_char_right = 'l',
        move_line_up = 'k',
        move_line_down = 'j',
        extend_line = '$',            -- in visual mode, $ extends to EOL; in normal it just moves cursor, but Helix might treat it in selection mode.
        scroll_up = '<C-u>',          -- maybe half-page up
        scroll_down = '<C-d>',
        open_below = 'o',
        open_above = 'O',
        normal_mode = '<Esc>',
        -- Helix has also text object selects, etc., which we likely skip.
      }
      local helix_to_vim_func = {
        code_action = function() vim.lsp.buf.code_action() end,
        hover = function() vim.lsp.buf.hover() end,
        -- etc, if needed for LSP or other interactive commands
      }
      ```

      The keys module when encountering a mapping value:

      - If it starts with ":" and is quoted as a string, treat as a Helix “typable command”. Some of these correspond to ex commands (`:w` = write, `:open file` = maybe edit a file). We can directly take the string after `:` and attempt to execute an equivalent:

        - `:w` -> `<Cmd>write<CR>`
        - `:q` -> `<Cmd>quit<CR>`
        - `:open <file>` -> this is Helix command to open a file. In Neovim, we can map to `<Cmd>edit <file><CR>` for a fixed file path like in the example (`C-o = ":open ~/.config/helix/config.toml"` would become `vim.keymap.set('n', '<C-o>', '<Cmd>edit ~/.config/helix/config.toml<CR>')`).
        - We need to strip the leading colon for known ones and prepend `<Cmd>` and append `<CR>`.

      - If it is a macro starting with "@": e.g. `"@x<A-d>"` in example (Alt-x then Alt-d macro to delete line). Helix macro means a sequence of keys to replay. We can convert a simple macro to a series of Vim keys by mapping to `feedkeys` or just a literal key sequence string:

        - In the example, Alt-x to select whole line and delete without yank was shown. It’s complex to analyze macros generally. Perhaps simplest is to ignore macros or require user to write them differently. But maybe small macros can be handled:
        - For instance, `@x` might mean press `x` (delete char) – but with Alt-d appended, it's unclear without full Helix context. This might be too much to handle automatically.

      - If none of the above (just a static command name or known function), use `helix_to_vim_cmd` or `helix_to_vim_func`:

        - If found in `helix_to_vim_cmd` (like movement commands), map to that keys string in normal mode.
        - If found in `helix_to_vim_func` (like `code_action`), create a mapping to call that function. e.g. `vim.keymap.set('n', 'ga', function() vim.lsp.buf.code_action() end)`.

      - If completely unknown, skip and maybe warn.

- **Modes and `vim.keymap.set`**:

  - For `[keys.normal]`, mode is `"n"` (normal + operator-pending maybe). For `[keys.insert]`, mode `"i"`. For `[keys.select]`, Helix’s select mode corresponds to Visual mode in Vim (since Helix’s select is like visual selection), so mode `"x"` (visual and select). Possibly also include `"s"` for select-mode if distinguishing, but Vim’s select mode is rarely used; we can just map to visual mode.
  - If Helix had `[keys.view]` or others (not sure if Helix has separate “view mode” aside from normal? Possibly not), we’d map accordingly (view could map to normal or a subset).
  - Use `vim.keymap.set(mode, key, result, opts)` with `noremap` (non-recursive) by default. Unless the user perhaps wants to map to an existing mapping (but Helix likely expects non-recursive).
  - We should include `silent=true` in opts for most to avoid echoing commands (especially for `<Cmd>`).
  - Also consider `nowait=true` if needed for certain sequences to avoid timeout delays, but it’s usually fine.

**Conflicts and Order**:

- If the user remaps a key that Neovim or plugins already map, our mapping should override because we set it after plugin setups typically. Using `vim.keymap.set` after plugins are loaded will ensure ours wins (unless plugin keeps a higher precedence mapping like expr or something, but generally).
- We should be careful that some keys in Helix default may conflict with Vim defaults. For example, Helix uses `C-s` for save, but in terminal Vim, Ctrl-S may freeze terminal (XOFF). We might advise user to ensure terminal forwards Ctrl-S or use a different combo.
- The system can allow the user to combine Helix config with manual Lua config if needed – but that’s user’s choice.

**Example Key Translation**:

- Helix: `[keys.normal] C-s = ":w"` -> Neovim: `<C-s>` in normal mode triggers write: `vim.keymap.set('n', '<C-s>', '<Cmd>write<CR>', { silent=true })`.
- Helix: `[keys.insert] j = { k = "normal_mode" }` -> Neovim: map `'jk'` in insert mode to escape: `vim.keymap.set('i', 'jk', '<Esc>', { silent=true })`.
- Helix: `[keys.normal] g = { a = "code_action" }` (or `[keys.normal.g] a = "code_action"`) -> Neovim: map `'ga'` in normal mode to LSP code action: `vim.keymap.set('n', 'ga', function() vim.lsp.buf.code_action() end, { silent=true })`.
- Helix: `[keys.normal] "ret" = ["open_below", "normal_mode"]`. Value is an array `["open_below","normal_mode"]` meaning a sequence of two commands: open below then switch to normal mode. We can simulate this by mapping Enter to do the two actions: in Vim, `<Cmd>startinsert<CR>` would open below? Actually, `open_below` in Helix means open a new line below and stay in normal mode? Or it might actually open a line and drop to insert (like Vim `o`). If Helix required explicitly then `normal_mode` after suggests Helix’s `open_below` might put you in insert mode and they want to leave insert to normal immediately. In Vim, `o` opens new line and enters insert, so to mimic `open_below` + `normal_mode`, we could map Enter to do `o<Esc>` (open new line, then escape to normal). So `vim.keymap.set('n', '<CR>', 'o<Esc>', {})`.
- Helix: `[keys.normal] "C-S-esc" = "extend_line"` (Ctrl+Shift+Esc). In Neovim, `<C-S-Esc>` might not be recognized in terminal. We can attempt mapping `<C-S-Esc>` to something like `V$` (visual-line to end-of-line) if extend_line means extend selection to end. Or if in normal, maybe it means start visual to end of line. We guess and implement accordingly.

The `sys.keys.apply(keys_table)` function will implement the above logic. We will ensure it is called **after** general settings and likely after LSP is configured (so that `vim.lsp.buf.code_action()` etc. exist, though those exist after LSP attaches, but our mapping can call it regardless; or if not attached, it will just do nothing). Also, if using a completion plugin that maps Tab, and we remap Tab for smart-tab or something, we might need to ensure our remap either overrides or we adjust plugin config.

We should also consider **mode-specific behavior**: Helix’s mappings might also want to apply in operator-pending mode (for motions). `vim.keymap.set('n', ...)` covers normal and operator-pending by default (since operator-pending is considered part of normal mode mapping context if using `vim.keymap.set`). Visual mode mappings would require `'v'` if needed separately from normal.

**Validation**: We will likely not implement all Helix commands, but we should ensure the common ones (movements, editing commands, LSP triggers) are handled. The system can print a list of any key mappings it couldn’t translate for the user to address manually if needed.
