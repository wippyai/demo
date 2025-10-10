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

    -- Fetch current todo to get completed status
    local select_query = sql.builder.select("id", "completed")
        :from("todos")
        :where("id = ?", tonumber(id))
        :limit(1)

    local select_executor = select_query:run_with(db)
    local todos, err = select_executor:query()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({error = "Query failed: " .. err})
        return
    end

    if not todos or #todos == 0 then
        res:set_status(http.STATUS.NOT_FOUND)
        res:write_json({error = "Todo not found"})
        return
    end

    -- Toggle completed status
    local current_completed = todos[1].completed
    local new_completed = current_completed == 1 and 0 or 1

    -- Update the todo
    local update_query = sql.builder.update("todos")
        :set_map({
            completed = new_completed,
            updated_at = sql.as.int(os.time())
        })
        :where("id = ?", tonumber(id))

    local update_executor = update_query:run_with(db)
    local result, err = update_executor:exec()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({error = "Update failed: " .. err})
        return
    end

    -- Fetch the updated todo
    local fetch_query = sql.builder.select("id", "title", "description", "completed", "priority", "category", "due_date", "created_at", "updated_at")
        :from("todos")
        :where("id = ?", tonumber(id))
        :limit(1)

    local fetch_executor = fetch_query:run_with(db)
    local updated_todos, err = fetch_executor:query()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({error = "Failed to fetch updated todo: " .. err})
        return
    end

    -- Return updated todo
    res:set_status(http.STATUS.OK)
    res:write_json(updated_todos[1])
end

return {
    handler = handler
}
