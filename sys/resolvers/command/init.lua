local resolvers = require("sys.core.resolvers")
local M = {}
-- Function to register all command resolvers
M.register_command_resolvers = function()
    -- Command resolvers for Helix commands (using separate command resolver registry)
    resolvers.define_command_resolver("goto_definition", function()
        return function()
            vim.lsp.buf.definition()
        end
    end)

    resolvers.define_command_resolver("goto_reference", function()
        return function()
            vim.lsp.buf.references()
        end
    end)

    resolvers.define_command_resolver("write", function()
        return function()
            vim.cmd("write")
        end
    end)

    resolvers.define_command_resolver("quit", function()
        return function()
            vim.cmd("quit")
        end
    end)

    resolvers.define_command_resolver("normal_mode", function()
        return function()
            vim.cmd("stopinsert")
        end
    end)

    -- Note: delete_selection and yank would need more complex implementations
    -- These are placeholders for now
    resolvers.define_command_resolver("delete_selection", function()
        return function()
            vim.cmd("normal! d")
        end
    end)

    resolvers.define_command_resolver("yank", function()
        return function()
            vim.cmd("normal! y")
        end
    end)
end

return M
