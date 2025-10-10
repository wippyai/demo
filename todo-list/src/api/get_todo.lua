local http = require("http")
local sql = require("sql")

local function handler()
    local req = http.request()
    local res = http.response()

    -- Get todo ID from URL parameter
    local id = req:param("id")
    if not id then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({error = "Missing todo ID"})
        return
    end

    -- Get database connection
    local db, err = sql.get("app:db")
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({error = "Database connection failed: " .. err})
        return
    end

    -- Query for specific todo
    local query = sql.builder.select("id", "title", "description", "completed", "priority", "category", "due_date", "created_at", "updated_at")
        :from("todos")
        :where("id = ?", tonumber(id))
        :limit(1)

    local executor = query:run_with(db)
    local todos, err = executor:query()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({error = "Query failed: " .. err})
        return
    end

    -- Check if todo exists
    if not todos or #todos == 0 then
        res:set_status(http.STATUS.NOT_FOUND)
        res:write_json({error = "Todo not found"})
        return
    end

    -- Return the todo
    res:set_status(http.STATUS.OK)
    res:write_json(todos[1])
end

return {
    handler = handler
}
