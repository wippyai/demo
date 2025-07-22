local function llm_query(options)
    -- Get required modules
    local llm = require("llm")
    local json = require("json")
    
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

    -- Build prompt from history and current message using Wippy.LLM prompt builder
    local prompt = require("prompt")
    local builder = prompt.new()
    
    -- Add system message
    builder:add_system("You are a helpful AI assistant. Provide clear, concise, and helpful responses.")
    
    -- Add conversation history (skip the current message if it's already last in history)
    local should_add_current = true
    
    if #history > 0 then
        local last_msg = history[#history]
        if last_msg.role == "user" and last_msg.content == message then
            -- Current message is already in history, don't add it again
            should_add_current = false
        end
    end
    
    -- Add conversation history
    for _, msg in ipairs(history_to_add or history) do
        if msg.role == "user" then
            builder:add_user(msg.content)
        elseif msg.role == "assistant" then
            builder:add_assistant(msg.content)
        end
    end
    
    -- Add current message if it's not already in history
    if should_add_current then
        builder:add_user(message)
    end

    -- Configure generation parameters for Wippy.LLM
    local generation_options = {
        model = model,
        temperature = 0.7,
        max_tokens = 1000
    }
    
    -- Handle streaming vs non-streaming modes
    if stream and reply_to then
        -- For streaming, configure stream parameters
        generation_options.stream = {
            reply_to = reply_to,
            topic = "response"
        }
        
        -- Generate with streaming
        local response, err = llm.generate(builder, generation_options)
        
        if err then
            -- Send error to the requester
            if reply_to then
                process.send(reply_to, "response", {
                    error = err,
                    done = true
                })
            end
            return nil, err
        end
        
        if response and response.error then
            local error_msg = response.error_message or response.error
            if reply_to then
                process.send(reply_to, "response", {
                    error = error_msg,
                    done = true
                })
            end
            return nil, error_msg
        end
        
        -- For streaming, the LLM module handles sending chunks to reply_to
        -- We just return a success indicator
        return "streaming_initiated", nil
    else
        -- Non-streaming mode
        local response, err = llm.generate(builder, generation_options)
        
        if err then
            return nil, err
        end
        
        if response and response.error then
            return nil, response.error_message or response.error
        end
        
        -- Return the generated text
        return response and response.result or "", nil
    end
end

return {
    llm_query = llm_query
}
