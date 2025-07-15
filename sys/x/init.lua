local cfg = {
    editor = {

    },
    languages = {
        fennel = {},
        c = {},
        cucumber = { formatter = "prettier" },
        swift = { lsp = "sourcekit", formatter = "swiftformat" },
        ocaml = { lsp = "ocamllsp", formatter = "ocamlformat" },
        python = { lsp = "pyright", formatter = "black", tab = { width = 4, expand = true } },
        typescript = { lsp = "ts_ls", formatter = "biome", tab = { width = 4, expand = false } },
        mojo = { formatter = "mojo_format", lsp = "mojo", tab = { width = 4, expand = true } },
        javascript = { lsp = "ts_ls", formatter = "biome" },
        go = { lsp = "gopls", formatter = { "goimports", "gofmt" } },
        rust = {}
    },
    features = { ["nvim-treesitter"] = true, Comment = true, telescope = true, ["nvim-cmp"] = true, conform = true, ["nvim-lspconfig"] = true, gitsigns = true },
    themes = { ["catppuccin-latte"] = true }
}

local function feature(name)
    local f = cfg.features
    if f then
        return f[name]
    else
        return false
    end
end

-- setup_tabs(cfg.languages, default_lang_settings)
if feature("gitsigns") then
    local gitsigns = require("gitsigns")
    return gitsigns.setup()
else
    return nil
end
