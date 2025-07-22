local llm = require("llm")
local json = require("json")

local function llm_query(options)
    -- Default options
    local opts = options or {}
    local message = opts.message or ""
    local history = opts.history or {}
    local model = opts.model or "gpt-4o-mini"
    local stream = opts.stream or false
    local reply_to = opts.reply_to
    
    if not message or message == "" then
        return nil, "Empty message provided"
    end

    -- Build prompt from history and current message
    local prompt = require("prompt")
    local builder = prompt.new()
    
    -- Add system message
    builder:add_system("You are a helpful AI assistant. Provide clear, concise, and helpful responses.")
    
    -- Add conversation history
    for _, msg in ipairs(history) do
        if msg.role == "user" then
            builder:add_user(msg.content)
        elseif msg.role == "assistant" then
            builder:add_assistant(msg.content)
        end
    end
    
    -- Add current message (don't add if it's already in history)
    local should_add_current = true
    if #history > 0 then
        local last_msg = history[#history]
        if last_msg.role == "user" and last_msg.content == message then
            should_add_current = false
        end
    end
    
    if should_add_current then
        builder:add_user(message)
    end

    -- Configure generation parameters
    local generation_options = {
        model = model,
        temperature = 0.7,
        max_tokens = 1000
    }
    
    -- Add streaming configuration if needed
    if stream and reply_to then
        generation_options.stream = {
            reply_to = reply_to,
            topic = "response"
        }
    end

    -- Generate response
    local response, err = llm.generate(builder, generation_options)
    
    if err then
        return nil, err
    end
    
    if response.error then
        return nil, response.error_message or response.error
    end
    
    return response.result, nil
end

return {
    llm_query = llm_query
}
