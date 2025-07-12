local M = {}

-- Registry to store resolvers
M.resolvers = {}

-- Function to define a resolver for a specific config path
function M.define_resolver(config_item_path, resolver_function)
    -- Check if the resolver function is valid
    if type(resolver_function) ~= "function" then
        error("Resolver function must be a valid function")
    end

    -- Register the resolver for the given config item path
    M.resolvers[config_item_path] = resolver_function
end

-- Function to get a resolver for a specific config path
function M.get_resolver(config_item_path)
    return M.resolvers[config_item_path]
end

-- Function to check if a resolver exists for a config path
function M.has_resolver(config_item_path)
    return M.resolvers[config_item_path] ~= nil
end

-- Sample resolver implementations
M.define_resolver("editor.line-number", function(value)
    if value == "relative" then
        vim.opt.number = true
        vim.opt.relativenumber = true
    elseif value == "absolute" then
        vim.opt.number = true
        vim.opt.relativenumber = false
    else
        vim.opt.number = false
        vim.opt.relativenumber = false
    end
end)

M.define_resolver("editor.cursorline", function(value)
    vim.opt.cursorline = value
end)

M.define_resolver("editor.mouse", function(value)
    if value then
        vim.opt.mouse = "a"
    else
        vim.opt.mouse = ""
    end
end)

M.define_resolver("editor.auto-completion", function(value)
    -- This would typically configure completion plugins
end)

M.define_resolver("theme", function(value)
    -- This would typically set the colorscheme
    -- Example: vim.cmd("colorscheme " .. value)
end)

return M