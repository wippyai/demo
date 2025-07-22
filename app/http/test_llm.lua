local http = require("http")
local json = require("json")
local funcs = require("funcs")

local function handler()
    local req = http.request()
    local res = http.response()
    
    if not req or not res then
        return nil, "Failed to get HTTP context"
    end

    -- Get message from query parameter or body
    local message = req:query("message") or req:body()
    
    if not message or message == "" then
        res:set_status(400)
        res:write_json({
            error = "Missing 'message' parameter"
        })
        return
    end

    -- Test LLM integration
    local response, err = funcs.new():call("app.funcs.openai:llm_query", {
        message = message,
        model = "gpt-4o-mini",
        stream = false
    })

    if err then
        res:set_status(500)
        res:write_json({
            error = "LLM error: " .. tostring(err)
        })
        return
    end

    -- Return successful response
    res:set_content_type("application/json")
    res:write_json({
        message = message,
        response = response or "No response received",
        model = "gpt-4o-mini"
    })
end

return { handler = handler }
