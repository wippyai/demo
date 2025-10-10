local http = require("http")
local sql = require("sql")

local function handler()
    local req = http.request()
    local res = http.response()

    -- Parse JSON body
    local body, err = req:body_json()
    if err then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({error = "Invalid JSON: " .. err})
        return
    end

    -- Validate required fields
    if not body.title or body.title == "" then
        res:set_status(http.STATUS.BAD_REQUEST)
        res:write_json({error = "Title is required"})
        return
    end

    -- Get database connection
    local db, err = sql.get("app:db")
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({error = "Database connection failed: " .. err})
        return
    end

    -- Prepare data with defaults
    local now = sql.as.int(os.time())
    local priority = body.priority or 1
    local completed = body.completed or 0

    -- Validate priority range
    if priority < 1 or priority > 3 then
        priority = 1
    end

    -- Validate completed value
    if completed ~= 0 and completed ~= 1 then
        completed = 0
    end

    -- Build insert query
    local query = sql.builder.insert("todos")
        :set_map({
            title = body.title,
            description = body.description or sql.as.null(),
            completed = completed,
            priority = priority,
            category = body.category or sql.as.null(),
            due_date = body.due_date and sql.as.int(body.due_date) or sql.as.null(),
            created_at = now,
            updated_at = now
        })

    -- Execute insert
    local executor = query:run_with(db)
    local result, err = executor:exec()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({error = "Insert failed: " .. err})
        return
    end

    -- Fetch the created todo
    local new_id = result.last_insert_id
    local select_query = sql.builder.select("id", "title", "description", "completed", "priority", "category", "due_date", "created_at", "updated_at")
        :from("todos")
        :where("id = ?", new_id)
        :limit(1)

    local select_executor = select_query:run_with(db)
    local todos, err = select_executor:query()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({error = "Failed to fetch created todo: " .. err})
        return
    end

    -- Return created todo
    res:set_status(http.STATUS.CREATED)
    res:write_json(todos[1])
end

return {
    handler = handler
}
