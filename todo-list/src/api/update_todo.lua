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

    -- Parse JSON body
    local body, err = req:body_json()
    if err then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({error = "Invalid JSON: " .. err})
        return
    end

    -- Get database connection
    local db, err = sql.get("app:db")
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({error = "Database connection failed: " .. err})
        return
    end

    -- Check if todo exists
    local check_query = sql.builder.select("id")
        :from("todos")
        :where("id = ?", tonumber(id))
        :limit(1)

    local check_executor = check_query:run_with(db)
    local existing, err = check_executor:query()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({error = "Query failed: " .. err})
        return
    end

    if not existing or #existing == 0 then
        res:set_status(http.STATUS.NOT_FOUND)
        res:write_json({error = "Todo not found"})
        return
    end

    -- Build update data
    local update_data = {
        updated_at = sql.as.int(os.time())
    }

    if body.title ~= nil then
        if body.title == "" then
            res:set_status(http.STATUS.BAD_REQUEST)
            res:write_json({error = "Title cannot be empty"})
            return
        end
        update_data.title = body.title
    end

    if body.description ~= nil then
        update_data.description = body.description ~= "" and body.description or sql.as.null()
    end

    if body.completed ~= nil then
        local completed = body.completed
        if completed ~= 0 and completed ~= 1 then
            completed = 0
        end
        update_data.completed = completed
    end

    if body.priority ~= nil then
        local priority = body.priority
        if priority < 1 or priority > 3 then
            priority = 1
        end
        update_data.priority = priority
    end

    if body.category ~= nil then
        update_data.category = body.category ~= "" and body.category or sql.as.null()
    end

    if body.due_date ~= nil then
        update_data.due_date = body.due_date and sql.as.int(body.due_date) or sql.as.null()
    end

    -- Build and execute update query
    local update_query = sql.builder.update("todos")
        :set_map(update_data)
        :where("id = ?", tonumber(id))

    local update_executor = update_query:run_with(db)
    local result, err = update_executor:exec()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({error = "Update failed: " .. err})
        return
    end

    -- Fetch the updated todo
    local select_query = sql.builder.select("id", "title", "description", "completed", "priority", "category", "due_date", "created_at", "updated_at")
        :from("todos")
        :where("id = ?", tonumber(id))
        :limit(1)

    local select_executor = select_query:run_with(db)
    local todos, err = select_executor:query()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({error = "Failed to fetch updated todo: " .. err})
        return
    end

    -- Return updated todo
    res:set_status(http.STATUS.OK)
    res:write_json(todos[1])
end

return {
    handler = handler
}
