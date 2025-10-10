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

    -- Delete the todo
    local delete_query = sql.builder.delete("todos")
        :where("id = ?", tonumber(id))

    local delete_executor = delete_query:run_with(db)
    local result, err = delete_executor:exec()
    if err then
        res:set_status(http.STATUS.INTERNAL_ERROR)
        res:write_json({error = "Delete failed: " .. err})
        return
    end

    -- Return success with no content
    res:set_status(http.STATUS.NO_CONTENT)
end

return {
    handler = handler
}
