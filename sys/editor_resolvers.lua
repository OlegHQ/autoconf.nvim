-- Editor-specific resolver implementations
-- This file contains resolvers for editor-specific configuration options

-- Import logger
local logger = require("sys.logger")

-- Function to register editor-specific resolvers
local function register_editor_resolvers(resolvers)
    -- Scrolloff resolver - Number of lines of padding around the edge of the screen when scrolling
    resolvers.define_resolver("editor.scrolloff", function(value)
        -- Validate that the value is a number
        if type(value) ~= "number" then
            logger.resolver_error("editor.scrolloff", "must be a number, got: " .. type(value))
            return
        end
        
        -- Validate that the value is non-negative
        if value < 0 then
            logger.resolver_error("editor.scrolloff", "must be non-negative, got: " .. tostring(value))
            return
        end
        
        -- Set the scrolloff option
        vim.opt.scrolloff = value
        
        logger.resolver_success("editor.scrolloff", tostring(value) .. " lines")
    end)
    
    -- Default yank register resolver - Default register used for yank/paste
    resolvers.define_resolver("editor.default-yank-register", function(value)
        -- Validate that the value is a string
        if type(value) ~= "string" then
            logger.resolver_error("editor.default-yank-register", "must be a string, got: " .. type(value))
            return
        end
        
        -- Validate that the value is a valid register name
        if not value:match("^[a-zA-Z0-9\"*+%-]$") then
            logger.resolver_error("editor.default-yank-register", "must be a valid register name, got: " .. value)
            return
        end
        
        -- Set the default register by configuring clipboard
        if value == "+" then
            vim.opt.clipboard = "unnamedplus"
        elseif value == "*" then
            vim.opt.clipboard = "unnamed"
        elseif value == "\"" then
            vim.opt.clipboard = ""
        else
            -- For other registers, we'll set it as the default
            vim.opt.clipboard = ""
            vim.g.default_yank_register = value
        end
        
        logger.resolver_success("editor.default-yank-register", "set to register '" .. value .. "'")
    end)
    
    -- Middle click paste resolver - Middle click paste support
    resolvers.define_resolver("editor.middle-click-paste", function(value)
        -- Validate that the value is a boolean
        if type(value) ~= "boolean" then
            logger.resolver_error("editor.middle-click-paste", "must be a boolean, got: " .. type(value))
            return
        end
        
        -- Configure middle-click paste behavior
        if value then
            -- Enable middle-click paste
            vim.keymap.set({'n', 'v'}, '<MiddleMouse>', '<MiddleMouse>', { desc = 'Middle click paste' })
            vim.keymap.set('i', '<MiddleMouse>', '<C-r>*', { desc = 'Middle click paste in insert mode' })
        else
            -- Disable middle-click paste by mapping to nothing
            vim.keymap.set({'n', 'v', 'i'}, '<MiddleMouse>', '<Nop>', { desc = 'Disable middle click paste' })
        end
        
        logger.resolver_success("editor.middle-click-paste", value and "enabled" or "disabled")
    end)
    
    -- Scroll lines resolver - Number of lines to scroll per scroll wheel step
    resolvers.define_resolver("editor.scroll-lines", function(value)
        -- Validate that the value is a number
        if type(value) ~= "number" then
            logger.resolver_error("editor.scroll-lines", "must be a number, got: " .. type(value))
            return
        end
        
        -- Validate that the value is positive
        if value <= 0 then
            logger.resolver_error("editor.scroll-lines", "must be positive, got: " .. tostring(value))
            return
        end
        
        -- Set scroll wheel behavior
        vim.opt.scroll = value
        
        -- Configure scroll wheel mappings for precise control
        vim.keymap.set({'n', 'v'}, '<ScrollWheelUp>', '<C-y>', { desc = 'Scroll up' })
        vim.keymap.set({'n', 'v'}, '<ScrollWheelDown>', '<C-e>', { desc = 'Scroll down' })
        
        -- Set the number of lines to scroll
        vim.cmd(string.format('set scroll=%d', value))
        
        logger.resolver_success("editor.scroll-lines", tostring(value) .. " lines per scroll step")
    end)
end

return {
    register_editor_resolvers = register_editor_resolvers
}
