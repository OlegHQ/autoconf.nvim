- **Auto Pairs (`editor.auto-pairs`):** Helix auto-inserts matching brackets/quotes by default (auto-pairs true) and allows customizing the pairs. In Neovim, we will likely use a plugin like **nvim-autopairs** or **mini.pairs** to handle bracket auto-completion:

  - If `auto-pairs` is `false` in Helix config, do **not** enable any auto-pair plugin (or disable it if it was loaded). If using nvim-autopairs, we can conditionally skip its setup or call `require("nvim-autopairs").setup{ disable_filetype = { ... } }` for all if false (or simply not load the plugin via plugin manager condition).
  - If `auto-pairs` is a table in the config (as in Helix’s example customizing specific pairs), we configure the autopair plugin to use exactly those pairs:

    - e.g. Helix config specifying only certain pairs means we should disable all default pairs and add those. With nvim-autopairs, one can provide custom rules; mini.pairs can be given a configuration table.
    - If the user lists `(` = `)`, `{` = `}`, `[` = `]`, etc., we add rules for those pairs. If they omit quotes, we ensure quotes are not auto-closed (remove default rule for them).
    - If `auto-pairs = true` or not present (default true), we enable the plugin with its default set (which typically covers ` () {} [] "" '' ```). This matches Helix’s default pairs of  `(){}\[]''""\`\`\`\`
      .

  - The `sys.config` module will orchestrate this, possibly by calling a function from an autopairs integration. It must run after the plugin is available. If using lazy-loading, we might trigger loading autopairs plugin at this time.

- **Whitespace Rendering (`editor.whitespace`):** Helix can render invisible chars like spaces, tabs, etc., with custom symbols. Neovim uses the `'list'` option and `'listchars'` setting for similar functionality.

  - `whitespace.render`: can be `"all"` or `"none"` or a table of specific categories.

    - If set to `"all"`, we turn on `vim.o.list = true` and set `listchars` to show all types: space, tab, non-breaking space, end-of-line, and trailing space indicators.
    - If `"none"`, we set `vim.o.list = false` (no visible whitespace).
    - If a table (with subkeys `space`, `tab`, `nbsp`, `nnbsp`, `newline` each set to `"all"` or `"none"`), we fine-tune:

      - e.g. if `space = "all"`, show normal spaces; if `space = "none"`, do not mark spaces.
      - If `tab = "all"`, show tabs; etc. Since Neovim’s `'listchars'` can selectively not define a certain category if we don’t want to show it, we implement by constructing `listchars` string accordingly. For any category marked `"none"`, we omit that category (meaning those will not be visually marked).

  - `whitespace.characters`: If provided, use these symbols for rendering:

    - Helix example: `space = "·"`, `tab = "→"`, `newline = "⏎"`, `tabpad = "·"`, etc..
    - Map to Neovim listchars options:

      - `space` -> `listchars:space:·`
      - `nbsp` (non-breaking space) -> `listchars:nbsp:⍽` (for instance, Helix uses ⍽ for NBSP).
      - `tab` and `tabpad`: In Neovim, `listchars:tab:xy` uses first char `x` for tab head and `y` for tab fill. If Helix gives a `tab` symbol and a `tabpad`, we combine them (e.g. tab = "→", tabpad = "·" gives `tab:→·`). If only `tab` is given and no `tabpad`, we might repeat the char or use a default fill.
      - `newline` -> `eol:⏎` in listchars.
      - We also might want to set `trail` (trailing space) marker. Helix doesn’t explicitly list `trail` in config; by showing spaces, trailing spaces would show the same symbol. We can optionally set `listchars:trail:…` or same as space marker.

    - If the user doesn’t specify characters, we can use some sensible defaults (similar to Helix’s defaults: dot for space, etc., or Neovim’s default which is usually just `tab:>~` and trailing space as `-`).

  - Implementation: After processing `render` and `characters`, we build a single `vim.o.listchars` string. Then if overall any category is to be shown, ensure `vim.o.list = true`. If all are none, set `vim.o.list = false`.

- **Indent Guides (`editor.indent-guides`):** Helix can show vertical lines for indent levels. Neovim doesn’t have this natively, but there are plugins (e.g. **indent-blankline.nvim**). Our layer will integrate with such a plugin:

  - If `indent-guides.render = true`, we enable indent-blankline plugin. Set its character to the specified `character` (default `"│"` in Helix, example custom `"╎"` given). The plugin’s config `char` can be set accordingly.
  - `skip-levels`: Helix uses this to skip drawing guides for first N indent levels. If provided (e.g. 1), and if indent-blankline supports (it has `indent_level` or maybe we can simulate by disabling indent guides for top-level), we configure it. If plugin doesn’t support exactly, we might ignore or find a workaround (like not showing indent for indent level 1 by injecting highlight same as background).
  - If `render = false` (default), we do nothing (no indent lines). If the plugin is installed, it might draw by default; so ensure to disable plugin unless config says true (e.g. lazy-load indent-blankline only when needed).

- **Gutters (`editor.gutters`):** Helix has a flexible gutter model (combination of diff, diagnostics, line numbers, spacer). Neovim’s signcolumn and number column provide similar functionality but with less flexibility in ordering.

  - Helix default gutter layout: `["diagnostics", "spacer", "line-numbers", "spacer", "diff"]`. This means: leftmost gutter diagnostics, then a spacer, then line numbers, spacer, then diff on the far right.
  - Neovim always shows line numbers to the left of text, and signs (for diagnostics, vcs, etc.) in the signcolumn at the far left. We cannot reorder them freely (Neovim doesn’t support a gutter on the right side for diff). As a compromise:

    - If the user specifies any form of gutter layout that excludes line-numbers, we will disable `number` option (no line number column). If line-numbers is included, we enable line numbers as configured by `editor.line-number`.
    - For diagnostics and diff:

      - We interpret “diagnostics” gutter as the desire to see diagnostic signs (e.g. error/warning icons) in a gutter. Neovim’s LSP (or diagnostic system) uses the signcolumn for this by default. If “diagnostics” is present in the layout, we ensure that the signcolumn is on (e.g. `vim.wo.signcolumn = "yes"` or `"auto"`). If “diagnostics” is **not** in the layout, perhaps the user doesn’t want inline signs – in that case we could set `signcolumn = "no"` to hide the sign column entirely, and rely on virtual text or statusline for diagnostics counts. But hiding signcolumn also hides diff signs and any other signs. Helix’s model can hide diagnostics signs but still show diff (since diff was at right gutter).
      - “diff” gutter in Helix shows Git diff markers (added/removed lines). In Neovim, **gitsigns.nvim** places signs in the signcolumn (colored indicators). If the user wants diff, we will enable gitsigns. If the user excludes diff from gutters, we might not enable gitsigns plugin (or turn it off).
      - However, since Neovim has only one sign column, if both diagnostics and diff are enabled, both will appear there (possibly overlapping if both try to place sign on same line; in practice, Neovim can show multiple signs per line by widening the signcolumn, or gitsigns may choose not to show certain signs if it conflicts). By default, Neovim will stack signs or use multiple columns as needed if `signcolumn = "auto:2"` etc. We might set `vim.wo.signcolumn = "yes:2"` to allow two columns if both diff and diagnostics are on.

    - “spacer” gutter entries in Helix are for spacing/padding; in Neovim we can’t easily insert blank gutters arbitrarily, so spacers are essentially ignored. The layout order can’t be fully respected; we approximate by ensuring required columns are shown. (Line numbers will always appear left of text after sign columns in Neovim).
    - We document this limitation: the order of gutters can’t be changed in Neovim (signs will always be left of number column if both are present). Our layer will do its best: if Helix layout begins with diagnostics then spacer then numbers, that matches Neovim’s natural order (signs then numbers). If Helix had diff at far right, we cannot replicate that – diff signs will also appear in the left sign column. The important part is respecting on/off: i.e., include or exclude certain categories.

  - **Gutter sub-sections**: Helix allows `[editor.gutters.line-numbers]` to set `min-width`. Neovim equivalent is the `'numberwidth'` option (minimum width of number column). We will set `vim.o.numberwidth` to the specified integer if provided.

    - `[editor.gutters.diagnostics]` and `[editor.gutters.diff]` have no configurable options in Helix (they’re placeholders), so nothing to map except presence/absence.
    - We ignore `[editor.gutters.spacer]` since no options and it’s just a layout filler.

  - In summary, our layer will:

    - Read the gutter layout list (either from `editor.gutters = [...]` or `editor.gutters.layout`). Determine booleans: want_line_nums, want_diagnostics, want_diff.
    - Set `number` option on/off accordingly.
    - Configure signcolumn:

      - If neither diagnostics nor diff are wanted, set `signcolumn = "no"`.
      - If at least one is wanted, set `signcolumn = "yes"` (or auto). If both are wanted, consider `yes:2` to allow two signs.

    - Activate plugins:

      - If want_diff (gitsigns) is true, require and setup `gitsigns.nvim` (if not already). Use its default signs (text could be `|` or similar, which match Helix diff markers). If want_diff is false, do not load gitsigns (or if loaded by other means, configure it to not attach).
      - Diagnostics signs are handled by Neovim’s built-in LSP diagnostics; they will show if signcolumn is on and if there are diagnostics. If user turned diagnostics gutter off, we might disable signcolumn entirely or set diagnostic signs to none by `vim.diagnostic.config({signs=false})` to prevent even if signcolumn is used for diff.

    - Note any conflict: if user wants diff but not diagnostics, we still need signcolumn for diff signs – so we would set signcolumn on but also ensure diagnostic signs are off (we can call `vim.diagnostic.config({ signs = false })` globally if that’s the intent).
    - If user wants diagnostics but not diff, load diagnostics but skip gitsigns. If both, load both.

- **Soft Wrap (`editor.soft-wrap`):** Helix supports soft-wrapping long lines at window or at a specified text width, with a wrap indicator symbol.

  - `soft-wrap.enable`: If true, we enable soft wrapping in Neovim by setting `vim.wo.wrap = true`. If false, `wrap = false` (no soft wrapping; long lines extend).
  - `wrap-indicator`: Helix uses a symbol (default "↪") to mark wrapped line continuation. In Neovim, the equivalent is the `'showbreak'` option. We set `vim.o.showbreak` to the given string (e.g. "↪ " if user didn’t customize, or "" if they explicitly hide it as in example).
  - `max-wrap` and `max-indent-retain`: These control wrapping behavior in Helix (not wrapping too early or keeping indent). Neovim does not have directly analogous settings. However, Neovim has `'breakindent'` and `'breakindentopt'` which can indent wrapped lines to maintain visual indent. We can consider enabling `vim.o.breakindent = true` if indent retention is desired.

    - If `max-indent-retain` is specified (e.g. 40 by default, or 0 in example), it might indicate how much indent to carry. We could map this to `vim.o.breakindentopt = "shift:40"` or similar (there is a `shift:` option for breakindent to keep a certain indent). If 0, maybe we don’t indent wrapped lines at all.
    - `max-wrap`: Helix’s concept is complex (free space at line end to avoid breaking words too early). Neovim doesn’t have a direct concept. We might not implement this; or we could simulate by enabling `'linebreak'` which at least breaks lines at word boundaries (so words aren’t split unless they exceed width). Possibly set `vim.o.linebreak = true` when soft-wrap is enabled to avoid mid-word breaks, which somewhat addresses the spirit of max-wrap.

  - `wrap-at-text-width`: If true, Helix wraps lines at the `text-width` value instead of the full window. Neovim’s approach to wrap is always at window boundary; to wrap at a fixed column, one would have to set some kind of margin. One trick: we could set the window width for that buffer or use `colorcolumn` to visually indicate the limit. But actual wrapping still happens at window edge in normal `wrap`.

    - Another approach: if the user sets `text-width` (discussed below) and wants wrap at that, we might simply set `vim.o.textwidth` and perhaps enable an autowrap for text (but that auto-inserts line breaks, which is not “soft”).
    - This is a difficult mapping; we might not fully implement it beyond documentation that Neovim cannot soft wrap at an arbitrary column (only at window edge or actual breaks).
    - We can partially satisfy it by: if wrap-at-text-width is true, set `vim.o.linebreak = true` and ensure a `colorcolumn` at textwidth to signal the boundary.

  - **Text Width (`editor.text-width`)**: Helix has `editor.text-width` default (maybe 80) used for wrapping and reflow. We can map this to `vim.o.textwidth` for Neovim (which is used by formatting commands like `gq` for line wrapping on hard wrap). Setting `vim.o.textwidth` to the Helix value allows `:fmt` or formatting plugin to wrap at that length. We also can use it for colorcolumn: we can set `vim.o.colorcolumn = tostring(textwidth)` to show a ruler at that column, which helps users visualize it (especially if wrap-at-text-width false but they still have a desired maximum).

    - If Helix’s `wrap-at-text-width` is true and textwidth is N, the user expects soft wrapping at N. As noted, we might not enforce that automatically, but colorcolumn at N plus linebreak on might approximate the effect (they’ll see lines beyond N visually separated or something).

  - The config layer should note that _Neovim cannot exactly mimic Helix’s soft wrap at textwidth without inserting line breaks_, which we won’t do implicitly. We will implement the closest reasonable approximation.

- **Smart Tab (`editor.smart-tab`):** Helix’s smart-tab feature repurposes the Tab key for navigation vs insertion depending on context. Implementing this in Neovim requires checking the content left of cursor on Tab press:

  - If `smart-tab.enable = true` (default in Helix), we will create mappings for `<Tab>` in Insert and possibly Normal mode that perform logic:

    - In Insert mode: if left of cursor is only whitespace, insert a Tab character or equivalent indentation; if there is non-whitespace to the left, instead of inserting a tab, trigger some navigation (Helix’s `move_parent_node_end` – likely jump out of current syntax block). We can’t easily compute “parent syntax node end” without tree-sitter. A simpler heuristic: if in insert at end of word, pressing Tab could jump to end of next word or skip an auto-pair? This is tricky. We might integrate with **nvim-treesitter** to replicate `move_parent_node_end` (which likely jumps the cursor to after the current syntax node, e.g., closing a bracket block).
    - In Normal mode: Helix’s smart-tab binding might not be as relevant (likely mainly an insert mode feature). But example in Helix docs suggests if user enjoys smart-tab, they add keybindings for Tab in various modes to do `move_parent_node_end`. We could mirror that: map `<Tab>` in normal mode to a Lua function that uses treesitter to jump to next scope end.

  - `supersede-menu`: Helix allows Tab to not cycle completion menu and always do smart-tab if true. In Neovim, if using a completion plugin, Tab often cycles suggestions. To enforce smart-tab priority, we’d have to customize the completion plugin’s mapping. This might be beyond our layer’s direct control. At most, we can document that if smart-tab supersede is true, users might want to change their cmp mapping to not use Tab for completion. If we integrate deeply, we could remove the `<Tab>` mapping in nvim-cmp (if present) when this is true, so that our mapping takes precedence.
  - Smart-tab is a complex feature. For the scope of initial implementation, we might implement a basic version:

    - Insert mode `<Tab>`: if preceding character is whitespace, insert a tab or appropriate indent; if not, leave as is (or do nothing, letting it insert a tab which will just add whitespace – not exactly Helix’s behavior, but safe). If we have time and treesitter, implement actual move to end-of-scope.
    - We can mark this feature as partially implemented or a candidate for future enhancement (especially the context-aware movement).

  - If `smart-tab.enable = false`, we simply don’t create any special mapping; Tab in insert will just insert a tab/space as usual, and in normal mode whatever default (which is to jump to next jump point in Vim, typically).

- **Inline Diagnostics (`editor.inline-diagnostics`):** Helix can display diagnostics (LSP errors/warnings) directly inline in the text after the offending line, with certain conditions (min severity for current line vs others). Neovim’s analogue is **virtual text** for diagnostics (text displayed at end-of-line).

  - `inline-diagnostics.cursor-line` / `other-lines`: These are set to a severity level or `"disable"`. For example, user might set `cursor-line = "error"` and `other-lines = "warning"`, meaning:

    - On the line with the cursor, show even hints or above? Actually if “error”, likely means show errors (severity error) on cursor line, nothing if only warnings (since error is highest requirement). If “disable”, show nothing.
    - On other lines, show only warnings or above.
      Helix default is both “disable” (so no inline diagnostics at all by default).

  - In Neovim, we can configure `vim.diagnostic.config({ virtual_text = ... })`. This config can accept either a boolean or a table with `severity` filter. However, it’s global or per-namespace, not easily per-line.

    - A plausible implementation:

      - If both cursor-line and other-lines are set to the same threshold, we simply enable virtual_text globally with that severity limit. e.g. if both are "warning", do `vim.diagnostic.config({ virtual_text = { severity = { min = vim.diagnostic.severity.WARN } } })`. Then all warnings/errors are shown inline for all lines.
      - If they differ (common case: user wants fewer on other lines, more on current line), we need dynamic behavior:

        - We can set global diagnostic virtual_text to the stricter of the two (e.g. show only errors globally for others). Then, implement an autocommand on CursorHold or CursorMoved that, when on a new line, temporarily shows diagnostics on that line if they meet the cursor-line threshold.
        - Concretely: if `cursor-line = "error"` and `other-lines = "disable"`, we would disable global virtual_text entirely, but on CursorHold on a line that has an error, manually display that error in virtual text. This requires using Neovim’s API: e.g. `vim.diagnostic.show()` with `virtual_text = true` for just that line or place an extmark with the message. We’d also need to clear it when leaving the line or if severity no longer qualifies.
        - This is complex. Another approach: Always show at least errors inline (lowest common denominator), and for cursor line, maybe open a floating window for details or just rely on the standard hover.

      - Since implementing per-line behavior is advanced, initially we might opt for a simpler approach:

        - If either value is not "disable", enable virtual text for the minimum of the two severities. So if cursor-line = info (very low) and other-lines = warning, we choose warning globally (so other lines show warning+, cursor line will also show warning+ but not info-level if any). This doesn’t exactly meet spec but is a compromise.
        - Document that fine differentiation is not fully supported yet.

      - If both are "disable" (default), we set `vim.diagnostic.config({ virtual_text = false })` to not show any inline virtual text, which matches Helix default (no inline, just use signs or hover).

  - `prefix-len`: Helix adds a certain number of “─” dashes as a prefix before inline diagnostic text. In Neovim, the virtual text prefix can be configured (e.g. `vim.diagnostic.config({ virtual_text = { prefix = "─" } })` for one dash). If prefix-len is, say, 1 or 2, we can repeat the dash that many times for the prefix string. We will implement that so the inline text visually offsets from code by that prefix. For example, prefix-len = 1 -> prefix "─", prefix-len = 3 -> prefix "───".
  - `max-wrap`: Helix’s inline diagnostics can wrap if too long. Neovim will by default put the diagnostic text on one line as virtual text (truncated if very long). We can’t easily wrap it to next line as part of the same virtual text (Neovim’s virtual text doesn’t do multi-line). We will ignore `max-wrap` or treat it as not applicable.
  - `max-diagnostics`: Helix can limit number of diagnostics shown per line inline. Neovim’s diagnostic config can limit how many virtual text items? Not directly; usually all diagnostics on that line get concatenated in the virtual text. We could implement a filter to only show, say, the first diagnostic if needed. This is an edge case; likely skip in initial version (or use it to decide whether to show multiple issues or just one – we can choose to only show the highest severity diagnostic per line, which is often the case by default with `severity_sort`).
  - In summary, we implement inline diagnostics as best-effort:

    - If user wants some inline diagnostics, enable Neovim’s `virtual_text` for diagnostics with a severity filter.
    - Potentially add an autocmd to refine behavior for cursor line (future enhancement).
    - Apply a prefix using prefix-len.
    - Document any differences from Helix (like no per-line toggling, etc.).

To manage all these mappings, the `sys.config` module can use a structure like:

```lua
local M = {}

-- Example pseudo-implementation:
function M.apply(editorCfg)
  if editorCfg["line-number"] then
    set_line_numbers(editorCfg["line-number"])
  end
  if editorCfg.cursorline ~= nil then
    vim.wo.cursorline = editorCfg.cursorline
  end
  if editorCfg.mouse ~= nil then
    vim.o.mouse = editorCfg.mouse and "a" or ""
  end
  ...
  if editorCfg.statusline then
    setup_statusline(editorCfg.statusline)
  end
  if editorCfg.lsp then
    configure_lsp_settings(editorCfg.lsp)
  end
  if editorCfg["cursor-shape"] then
    configure_cursor_shape(editorCfg["cursor-shape"])
  end
  if editorCfg["file-picker"] then
    configure_file_picker(editorCfg["file-picker"])
  end
  if editorCfg["auto-pairs"] ~= nil then
    configure_autopairs(editorCfg["auto-pairs"])
  end
  if editorCfg.whitespace then
    configure_whitespace(editorCfg.whitespace)
  end
  if editorCfg["indent-guides"] then
    configure_indent_guides(editorCfg["indent-guides"])
  end
  if editorCfg.gutters then
    configure_gutters(editorCfg.gutters, editorCfg["gutters.line-numbers"])
  end
  if editorCfg["soft-wrap"] then
    configure_soft_wrap(editorCfg["soft-wrap"], editorCfg["text-width"])
  end
  if editorCfg["smart-tab"] then
    configure_smart_tab(editorCfg["smart-tab"])
  end
  if editorCfg["inline-diagnostics"] then
    configure_inline_diagnostics(editorCfg["inline-diagnostics"])
  end
  -- And so on for any other sections
end

return M
```

Each helper like `configure_whitespace` or `configure_gutters` will implement the logic described above. This separation keeps the code manageable and allows adding new config keys easily (just add a new handler for that section).

**Error Handling**: If an unknown key is present in `[editor]`, the system can log a warning: e.g. “Unrecognized editor setting: editor.foobar – ignoring.” This might happen if Helix adds new options that our layer doesn’t yet support. The goal is to **not** crash or stop on unknown entries, simply skip them. The util module could provide a logging function for such warnings, possibly only in verbose mode to not spam the user.
