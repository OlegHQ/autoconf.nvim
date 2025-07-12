-- Editor-specific resolver implementations
-- This file contains resolvers for editor-specific configuration options

-- Function to register editor-specific resolvers
local function register_editor_resolvers(resolvers)
    -- Scrolloff resolver - Number of lines of padding around the edge of the screen when scrolling
    resolvers.define_resolver("editor.scrolloff", function(value)
        -- Validate that the value is a number
        if type(value) ~= "number" then
            print("editor.scrolloff must be a number, got: " .. type(value))
            return
        end
        
        -- Validate that the value is non-negative
        if value < 0 then
            print("editor.scrolloff must be non-negative, got: " .. tostring(value))
            return
        end
        
        -- Set the scrolloff option
        vim.opt.scrolloff = value
        
        print("Scrolloff set to: " .. tostring(value) .. " lines")
    end)
end

return {
    register_editor_resolvers = register_editor_resolvers
}
