## Language Configuration Integration (`languages.toml`)

The `sys.languages` module will take the parsed `languages.toml` (merged global+project) and configure Neovim’s LSP and related plugins accordingly. This involves:

### LSP Servers (`language-servers` table and `language.language-servers`)

Helix `languages.toml` defines language server commands in a `[language-server.<name>]` table and associates them to languages via each `[[language]]` entry’s `language-servers` list. We will use **nvim-lspconfig** to setup these servers.

- **Iterate Language Entries**: For each `[[language]]` in the parsed `languages` list:

  - Determine the Neovim filetypes that correspond. Helix’s `file-types` field (a list of extensions or glob patterns) helps identify file names, but Neovim determines `&filetype` usually by extension or modeline. We will map Helix’s `name` to a Vim filetype string when possible:

    - Often the `name` is the lowercase language name (e.g. "python", "rust", "html"). Many times Neovim’s filetype is identical or very close. We might maintain a small mapping if needed (for example, Helix uses "csharp" vs Neovim uses "cs" or "csharp"? Actually Neovim filetype for C# is "cs" or "csharp"? If mismatched, we fix).
    - Helix’s `file-types` array could also directly list an extension like "toml" which matches Neovim filetype "toml". If a glob is given (like "Makefile"), Helix would apply that language; Neovim likely sets filetype "make" for Makefile via its detection. So for our purpose, it’s enough to gather possible filetype names:

      - If Helix `name` is known in Neovim, use it.
      - If not sure, take the first `file-types` entry if it’s a simple extension and use that as filetype (Neovim’s filetype for extension "myl" might or might not exist; if not, user may have created an ftdetect for it).
      - We could also look at Helix’s `scope` (like `source.mylang` in example), but that’s not directly useful for Neovim.

    - We might ask Neovim’s runtime if any filetype is known for one of the extensions by reading its filetype detection (this is complex; better to rely on user having filetype plugin).

  - **LSP Setup**: For each language’s `language-servers` list:

    - Each entry can be either a string (just server name) or a table with `name` and `only-features`/`except-features` filters. We will ignore the features filtering in initial implementation (Neovim by default will enable all features the server provides; selective disabling might require custom handlers, which is advanced). We can note that future work could interpret only/except to disable certain LSP capabilities.
    - We get the server name(s). e.g. `"rust-analyzer"` or a custom like `"efm-lsp-prettier"` in Helix example.
    - Check if this server is defined in the `[language-server]` table (the command and config). If yes, retrieve that info.
    - Use nvim-lspconfig’s setup:

      - If the server name corresponds to a known lspconfig server (like "rust_analyzer" vs Helix name "rust-analyzer" with hyphen; lspconfig uses underscore for Rust Analyzer). We may need to translate hyphen names to the lspconfig key (which is often same without hyphen or with underscores).
      - If not a built-in lspconfig (like Helix allows custom server definitions like "mylang-lsp"), we can still use lspconfig’s generic `:new_client` or simply ignore if we don’t have a handler. Better approach: require the server by name via lspconfig; if it errors (not installed), we can call `vim.notify` to warn user to install that LSP (via Mason or system).
      - Provide the `cmd` and settings:

        - If Helix’s `[language-server.name]` has `command` and `args`, we combine into `cmd = { <command>, unpack(args) }` for lspconfig.
        - If `environment` is provided, set those env vars for the server process. lspconfig allows setting `on_new_config` or `cmd_env`.
        - If `config` table is provided, that typically goes into LSP initialization options (`settings` field in lspconfig). We take the Helix `config` and pass it as `settings = config` in setup (or `init_options` as appropriate if those are init options).
        - If Helix’s config has nested `config.format` options for the server, we ensure they are included in settings (e.g. Helix example passing formatting options to TS server).
        - If `required-root-patterns` is given, we can use lspconfig’s `root_dir` function to search for those files. We will create a `root_dir = util.root_pattern(unpack(required-root-patterns))`. This ensures the server only starts when those files (e.g. package.json, etc.) are present, mimicking Helix behavior.

      - Attach the server to appropriate filetypes: supply `filetypes = {list of nvim filetypes for this language}` in lspconfig setup if needed. By default lspconfig has its own list, but for custom servers or if user extended to new extensions, override or append.
      - If Helix `language-servers` had multiple servers for one language (like in TypeScript example using both TSServer and efm), we will set up both. They will both attach to the buffers of that filetype. We cannot prioritize features easily without custom config; but e.g. if efm is just a formatter, it will respond only to formatting requests. We might not implement the only/exclude features logic now, so both just run.
      - If `editor.lsp.enable` was false globally, we skip all the above (don’t setup any servers).

  - Possibly integrate with **mason.nvim**: If the user has Mason (LSP installer) and the server is not present, we could trigger Mason to auto-install. That’s an optional enhancement. At minimum, warn if `require('lspconfig')[server]` fails.

- **Project vs Global LSP Config**: If the project’s `.helix/languages.toml` overrides a server’s command or adds a server:

  - Our merged config will reflect that (project might have `[language-server.rust-analyzer] command = "rust-analyzer"` pointing to a wrapper script, etc.). We use the merged result, so project’s version is used.
  - If project disables a server for a language by not listing it or adding `language-servers = []`, we should respect that and not start it (global might have one, but project override none, so skip).
  - If project adds `only-features` for a server for that project, since we aren’t implementing feature filtering fully, that might be ignored currently.

- **Workspace (root) settings**: Helix `languages.toml` has `roots` (markers to detect workspace) and `workspace-lsp-roots` (overrides per project). For each server, lspconfig has a default root detection. We can override it:

  - If Helix language entry has `roots = ["Cargo.toml", ...]`, use those in the `root_dir` function as well (like `util.root_pattern("Cargo.toml", ...)`).
  - If `workspace-lsp-roots` is set in project config (they mention it should only be in .helix config and it overrides the config.toml’s setting), ensure we use that for root detection for that language’s LSP instead. Maybe simpler: if present, prefer those patterns in root_dir for that language’s servers.
  - If none provided, lspconfig’s default root finder is used.

### Comments (`comment-tokens` and `block-comment-tokens`)

Helix per-language config specifies how to comment lines in that language (line comment string and block comment delimiters). We integrate this with **Comment.nvim** (or Vim’s `commentstring` option).

- For each language entry, if `comment-tokens` is present:

  - If it’s a string (single line comment prefix, e.g. "#" or "//"), or an array (multiple line comment styles, with first used for toggling), we will use the first token as the line comment leader.
  - If `block-comment-tokens` present:

    - It might be a table `{ start="/*", end="*/" }` or an array of such tables (the first pair being primary).
    - Use the first start/end pair for block comment.

  - We then configure _Comment.nvim_ for that filetype:

    - Using its API: `require('Comment.ft').set(ft, {line, block})`. For example, for filetype "mylang", if `comment-tokens = "//"` and `block-comment-tokens = { start="/*", end="*/" }`, we do:

      ```lua
      local ft = require('Comment.ft')
      ft.set('mylang', { '//%s', '/*%s*/' })
      ```

      This registers both line and block comment strings.

    - If only line token given and no block, we call `ft.set('mylang', '#%s')`.
    - If an array of line tokens is given, the first is used for toggling. Others could be recognized by Comment.nvim if we also set them? The plugin doesn’t natively handle multiple comment styles per filetype aside from using context perhaps. We might just ignore additional ones, or use context-commentstring plugin if needed (likely overkill).

  - Alternatively, simply set `vim.bo.commentstring` in an autocmd for that filetype:

    - But `commentstring` holds only one format at a time (line or block). Comment.nvim’s advanced set function is better since it allows both.

  - We should ensure this runs after Comment.nvim is loaded. If using lazy loading, our code might cause the plugin to load by requiring it.
  - If user doesn’t have Comment.nvim, we could fallback to setting `commentstring` for the filetype (which would at least let `gc` mapping in commentary or similar work if they use another plugin).
  - Example: Helix’s default for Rust is line `//` and block `/* */`. Helix might list both. Our layer will set those for `filetype = rust`.
  - **Edge cases**: Helix sometimes lists multiple comment tokens for documentation vs normal (like in C++ `["//", "///", "//!"]`). We will just use `//` as the main. Helix uses others to also recognize those strings as comments for toggling/uncomment. We won’t attempt that level (uncommenting `///` vs `//` – Comment.nvim by default will uncomment any recognized pattern that matches commentstring, so if it’s `//%s` it might also remove `//` from `///` incorrectly by removing only two slashes. That’s a nuance but beyond scope).

### Formatters (`formatter` and `auto-format`)

Helix language config can specify an external formatter for a language and whether to auto-format on save. We will use **conform.nvim** to manage formatters.

- **Defining Formatters**: For each language with a `formatter` field:

  - Helix gives a `command` and `args` for the formatter, which reads from stdin and writes to stdout (they require formatters support stdin).
  - We register a new formatter with Conform:

    ```lua
    require("conform").formatters[formatter_name] = {
      command = "...",
      args = { ... },
      stdin = true,
    }
    ```

    Where `formatter_name` could be something like `"mylang-formatter"` or we can use the language name as part of key. Perhaps use `language.name` as key (like "mylang_formatter") to avoid collisions.
    If environment variables are given in Helix’s `language-server.env` or not (formatters typically not in LSP table, but if they had environment in config? Unlikely; we can ignore or user can incorporate in command).

  - **Multiple formatters**: Helix allows one formatter per language in config. If for some reason multiple, we could register multiple, but typically one.

- **Assigning Formatters to Filetype**: Conform’s `formatters_by_ft` config will be used:

  - Determine the Neovim filetype(s) for that Helix language (same as we did for LSP). Then do:

    ```lua
    conform_setup_options.formatters_by_ft[filetype] = { formatter_name }
    ```

    If there’s already an entry (maybe from previous language with same filetype; unlikely unless languages share filetype like c and c++ both “c” maybe?), then append, or ideally each filetype one config. If conflict, last wins or user config needed.

  - If the Helix language also had LSP servers that support formatting, Helix rule is: if `formatter` is defined, it takes precedence over LSP formatting. To implement:

    - In conform, we can set `lsp_format = "fallback"` for that filetype, meaning use LSP only if no other formatters. But since we have an external, it will always run and LSP will not, achieving precedence.
    - If no external formatter but LSP is present and user didn’t disable auto-format, we want to use LSP formatting. We can handle that by either:

      - If Conform supports adding an entry like `formatters_by_ft[filetype] = {}`, and then use `lsp_format = "prefer"` to always use LSP. Another approach: we could simply not list any external for that ft and configure Conform’s `format_on_save` to call LSP via fallback. But Conform can do it elegantly:
      - We can do `conform_setup_options.formatters_by_ft[filetype] = { lsp_format = "prefer" }`. It’s not a real formatter name, but as per Conform’s docs, `formatters_by_ft` is a table where you can include the `lsp_format` key in the list (they demonstrated it with rust example).
      - If that doesn’t work, alternative: we don’t use Conform for purely LSP formatting. Instead, set up an autocmd on `BufWritePre` for that filetype that calls `vim.lsp.buf.format()` if `auto-format` is true and external is not defined. However, since we’re already using Conform, we prefer one system.

    - Implementation approach: Build a table `formatters_by_ft` as we parse languages:

      - If `lang.formatter` exists: add custom formatter name to list.
      - If no external but we know language has LSP (we set up lspconfig for it) and if `auto-format` is true (or not set meaning default true in Helix except where explicitly false):
        add a special entry to indicate LSP formatting. Perhaps Conform might allow `'lsp'` string if we define something, or simply we do not add an entry but later handle format on save differently.

    - We might actually decide to not overcomplicate Conform usage: We can instruct Conform to be used mainly for external formatters, and use a separate mechanism for LSP formatting on save:

      - For languages with external formatters, use Conform (since it can run external commands nicely).
      - For languages without external but with LSP, use Neovim’s native LSP formatting on save (via an autocommand).
      - This is simpler logically.

    - But Conform’s benefit is it also handles LSP formatting nicely (like piecewise diff).

      - Actually, Conform can integrate LSP if we specify in `formatters_by_ft` something like `{ "null-ls", lsp_format = "fallback" }`. However, it expects real formatters. Possibly they added direct LSP integration by that `lsp_format` attribute only.

    - For this spec, we propose:

      - Use Conform for external formatters.
      - For LSP formatting, if `auto-format` is true and no external, set up an autocmd:

        ```lua
        vim.api.nvim_create_autocmd("BufWritePre", {
          pattern = <filetype(s)>,
          callback = function()
            vim.lsp.buf.format({ async = false })  -- synchronous format on save
          end
        })
        ```

        or use Conform’s `format_on_save` with lsp, but consider time.

      - If both external and LSP are present, by Helix logic, external runs (we’ll not call LSP format on save in that case).
      - If auto-format is false, do nothing for that language (user can still manually format).

  - Helix default `auto-format` is true for most (meaning format on save), and users explicitly set false to disable. We will treat unspecified as true. Possibly provide a global toggle as well if Helix had one (not sure, but each language has its own flag).

- **Format on Save**: The `sys.languages` module will coordinate enabling format-on-save for filetypes:

  - It can accumulate a list of filetypes that need auto-format on save.
  - After setting up Conform’s formatters, call `require("conform").setup{ formatters_by_ft = ..., format_on_save = { pattern = ..., timeout_ms = ..., lsp_format = ... } }`.

    - Conform can take a pattern (like `*` or filetype filter) for format on save. We could just do global `format_on_save = { lsp_format = "false" }` and rely on the by_ft settings to pick up whichever (not exactly, might need to supply a pattern).
    - Or simpler, skip using Conform’s built-in auto format and just use our own autocmd. But Conform’s doc suggests using its `format_on_save` option is straightforward.
    - If we trust Conform to handle it, we might do:

      ```lua
      require("conform").setup({
        formatters_by_ft = {...},
        format_on_save = {
          -- for each ft in list we built where autoformat true
          pattern = { "*.py", "*.rs", "*.lua", ... },  -- but specifying patterns might be unwieldy; instead we can supply a function for bufnr
          timeout_ms = 1000,
          lsp_format = "false"  -- or "fallback" depending on how we integrate LSP.
        }
      })
      ```

      Actually, `format_on_save` can be a function that returns options per buffer, so we could check `vim.bo.filetype` and decide if that ft’s language has auto-format.

    - Might be easier: just use our own autocmd logic:

      - If external exists (Conform formatter), we call `require("conform").format({bufnr=buf})` on save.
      - If external not exists but we want LSP, call `vim.lsp.buf.format()`.
      - This way, we have full control per filetype.

- **Fallback to LSP formatting**: If user does not set a formatter and doesn’t disable auto-format (so presumably wants LSP to format), we ensure LSP actually supports formatting. If not, nothing happens (Conform would warn no formatters, or our autocmd might call `vim.lsp.buf.format()` which will do nothing if server not formatting capable).

  - Possibly integrate with Conform’s `lsp_format = "fallback"` for those filetypes just so Conform could unify approach. But given complexity, a custom autocmd is fine.

- **Example**: Suppose `languages.toml` contains:

  ```toml
  [[language]]
  name = "python"
  language-servers = ["pyright"]
  formatter = { command = "black", args = ["-q", "-"] }
  auto-format = true

  [[language]]
  name = "cpp"
  language-servers = ["clangd"]
  auto-format = false
  ```

  - For Python, we define a formatter "python_black" with command black. We set Conform’s formatters_by_ft\["python"] = { "python_black", lsp_format = "fallback" } or just {"python_black"} and handle LSP fallback ourselves. Because Helix provided a formatter, by their logic, we don’t want clangd’s formatting even if it had one.
    Actually in Python example, LSP (pyright) doesn’t format, only black. So fine.
  - For C++: no external, LSP clangd can format. But auto-format = false, so we do not autoformat on save at all. The user can manually format if needed via `:lua vim.lsp.buf.format()` if they want.
  - If auto-format was true with clangd and no external, we would attach a BufWritePre to call clangd formatting on save.

- **Project Override**: If project languages.toml says for a language `auto-format = false` (like Helix example for rust to disable), it should override global true and we skip enabling format on save for that language in that project context.

### Indentation

Helix languages can specify indent preferences:

- `indent = { tab-width = N, unit = "  " or "\t" }`.

  - `tab-width` is the number of spaces per indent level (or how many columns a tab represents).
  - `unit` is the actual characters inserted for one indent level (either spaces or a tab character).

- We apply these to Neovim as buffer-local settings for the corresponding filetypes:

  - `vim.bo.shiftwidth = N` (indent size for >>, autoindent, etc.).
  - `vim.bo.tabstop = N` (so that a tab character is visually N columns).
  - If `unit` is spaces (like `"  "` meaning two spaces, which should correspond with N=2 presumably), then `vim.bo.expandtab = true` (use spaces on hitting Tab).
  - If `unit` is "\t" (a tab char), then `expandtab = false` (use actual tab char). In that case, often `tabstop` equals `shiftwidth` equals N ensures alignment.
  - If `unit` is something weird like 4 spaces but N given is 8, or vice versa, the config might be inconsistent; we assume user config is logical (unit of N spaces implies tab-width N).
  - If only `tab-width` given but no unit, maybe assume tabs? Helix always expects both though.

- Implementation:

  - We can create an autocommand for each relevant filetype that sets these options when a buffer of that type is opened (FileType event).
  - Or since our layer runs at startup, for any already open buffers we set them immediately (though typically config runs before files opened).
  - Example: for "rust" Helix built-in uses 4 and "\t"? Actually not sure, but if it did, we set Neovim’s rust ft to tabstop=4, expandtab=false.

### Misc Language Settings

Other per-language Helix options and how to handle:

- `diagnostic-severity`: minimal severity to show diagnostics. This could override global threshold for that language.

  - We can leverage `vim.diagnostic.config({ severity_sort = true, severity = { min = X } }, bufnr)` for that file’s buffer. This can be done on LSP attach or FileType.
  - If user sets “warning”, then don’t show hints/info for that language.

- `soft-wrap`: Helix allows overriding the editor’s soft-wrap per language. If present, we could apply the same `wrap` and `linebreak` settings buffer-locally for that filetype. e.g., if global soft-wrap is off but a specific language sets `soft-wrap.enable = true`, then enable `wrap` for that filetype’s buffers.
- `text-width`: can be per language too. We’d apply buffer-local `textwidth` or colorcolumn accordingly.
- `path-completion`: can override editor.path-completion for a language. If, say, global path-completion off but enable for one language, we could configure the completion plugin to include or exclude the path source for that filetype. If using nvim-cmp, we can set up filetype-specific sources in cmp setup (there’s an option to configure per filetype sources).
- `persistent-diagnostic-sources`: Helix uses this to treat certain diagnostics specially (probably Helix-specific optimization). Neovim doesn’t have an equivalent concept exposed; we’ll ignore this.

For any such per-language override, our approach is:

- On `FileType` event for that language’s filetype, apply the settings (unless already applied by global).
- We might prepare a table of filetype -> settings to apply, built from languages config.
- Then one loop to create one autocommand per filetype (or a single autocmd for multiple patterns grouped by similar settings).

**Git Integration**:

- Helix diff gutter shows git changes; we handled that via gitsigns based on gutter layout globally. There’s no per-language diff setting in Helix config (diff gutter is global UI).
- Helix doesn’t specify in languages anything for git except maybe in grammar or nothing. So nothing further per language for git.

**Additional Plugins**:

- If the user has other Neovim plugins that could benefit from Helix config, we ensure extensibility:

  - For example, if user later adds a snippet plugin, they might want to configure it via Helix’s config (maybe Helix’s snippet config or keys).
  - Our design allows adding new mapping logic in the respective module easily. E.g. adding support for a hypothetical `[editor.snippets]` section to configure a snippet engine, we’d create a function in `sys.config` to apply that.

- Another example: Helix’s `grammar` sections (for tree-sitter grammars). We might ignore these as Neovim’s treesitter is managed via `nvim-treesitter` plugin. But an extension could use that to auto-install or update grammar parsers using `:TSInstall` for languages listed. This is out-of-scope for initial, but plausible future extension (ensuring grammar sources maybe done by user manually or separate plugin like `nvim-treesitter`).
- **Project-specific commands**: Helix allows per project `language-servers` modifications and such. We cover that by reading project file. No explicit mention needed beyond merging logic.
