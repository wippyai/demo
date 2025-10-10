local http = require("http")
local sql = require("sql")

local function handler()
    local req = http.request()
    local res = http.response()

    -- Get database connection
    local db, err = sql.get("app:db")
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({error = "Database connection failed: " .. err})
        return
    end

    -- Build query with optional filters
    local query = sql.builder.select("id", "title", "description", "completed", "priority", "category", "due_date", "created_at", "updated_at")
        :from("todos")

    -- Filter by completed status
    local completed = req:query("completed")
    if completed then
        local completed_int = tonumber(completed)
        if completed_int == 0 or completed_int == 1 then
            query = query:where(sql.builder.eq({completed = completed_int}))
        end
    end

    -- Filter by category
    local category = req:query("category")
    if category and category ~= "" then
        query = query:where(sql.builder.eq({category = category}))
    end

    -- Filter by priority
    local priority = req:query("priority")
    if priority then
        local priority_int = tonumber(priority)
        if priority_int and priority_int >= 1 and priority_int <= 3 then
            query = query:where(sql.builder.eq({priority = priority_int}))
        end
    end

    -- Order by created_at descending (newest first)
    query = query:order_by("created_at DESC")

    -- Execute query
    local executor = query:run_with(db)
    local todos, err = executor:query()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({error = "Query failed: " .. err})
        return
    end

    -- Return results
    res:set_status(http.STATUS.OK)
    res:write_json(todos or {})
end

return {
    handler = handler
}
