-- Lifecycle management for resolver execution
local M = {}

--- Lifecycle phases for resolvers
M.Lifecycle = {
    LATE = "LATE",
    NORMAL = "NORMAL",
}

-- Private storage for late-init resolvers
local late_init_queue = {}

--- Queue a resolver for late initialization
--- @param path string The config path
--- @param resolver function The resolver function
--- @param value any The value to pass to the resolver
function M.queue_late_init(path, resolver, value)
    table.insert(late_init_queue, {
        path = path,
        resolver = resolver,
        value = value,
    })
end

--- Execute all queued late-init resolvers
function M.execute_late_init()
    for _, item in ipairs(late_init_queue) do
        item.resolver(item.value)
    end
end

--- Clear the late-init queue (useful for testing or reloading)
function M.clear_queue()
    late_init_queue = {}
end

--- Get count of queued late-init resolvers
--- @return number
function M.get_queue_count()
    return #late_init_queue
end

--- Unwrap a resolver definition to get function and lifecycle
--- @param resolver function|table
--- @return function resolver_fn
--- @return string lifecycle
function M.unwrap_resolver(resolver)
    if type(resolver) == "function" then
        return resolver, M.Lifecycle.NORMAL
    end
    return resolver.resolver, resolver.lifecycle or M.Lifecycle.NORMAL
end

return M
