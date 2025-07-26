local time = require("time")
local bapp = require("bapp")
local llm = require("llm")
local prompt = require("prompt")
local json = require("json")

function App()
    -- Create app with custom init commands
    local init_commands = {
        btea.commands.enter_alt_screen,
        btea.commands.hide_cursor
    }

    local app = bapp.new(init_commands)

    -- Chat state
    app.messages = {}  -- History of messages
    app.current_input = ""  -- Current user input
    app.input_mode = true   -- Are we in input mode
    app.streaming_response = ""  -- Current streaming response
    app.is_streaming = false     -- Is LLM currently streaming
    app.scroll_offset = 0        -- For scrolling through messages
    app.max_visible_lines = 20   -- Maximum visible message lines
    
    -- Model selection state
    app.model_selection_mode = false  -- Are we in model selection mode
    app.available_models = {}         -- List of available models
    app.selected_model = "claude-3-5-haiku"  -- Current selected model
    app.model_selection_index = 1     -- Index in model list
    app.models_loaded = false         -- Have we loaded models yet

    -- Setup streaming event listener
    app.llm_stream_channel = process.listen("llm_stream")

    -- Setup key bindings
    app.keys = bapp.create_keys({
        send = {
            keys = { "enter" },
            help = { key = "enter", desc = "send message" }
        },
        clear = {
            keys = { "ctrl+l" },
            help = { key = "^L", desc = "clear chat" }
        },
        scroll_up = {
            keys = { "page_up", "ctrl+u" },
            help = { key = "PgUp/^U", desc = "scroll up" }
        },
        scroll_down = {
            keys = { "page_down", "ctrl+d" },
            help = { key = "PgDn/^D", desc = "scroll down" }
        },
        quit = {
            keys = { "ctrl+x" },
            help = { key = "^X", desc = "quit" }
        },
        model_select = {
            keys = { "ctrl+t" },
            help = { key = "^T", desc = "select model" }
        },
        backspace = {
            keys = { "backspace" },
            help = { key = "⌫", desc = "delete char" }
        },
        nav_up = {
            keys = { "up" },
            help = { key = "↑", desc = "navigate up" }
        },
        nav_down = {
            keys = { "down" },
            help = { key = "↓", desc = "navigate down" }
        },
        escape = {
            keys = { "escape" },
            help = { key = "esc", desc = "cancel" }
        }
    })

    -- Define styles
    app.styles = {
        container = btea.style()
            :border(btea.borders.ROUNDED)
            :padding(1, 2)
            :foreground("#89B4FA")
            :background("#1E1E2E")
            :border_foreground("#89B4FA"),

        header = btea.style()
            :bold()
            :foreground("#CBA6F7")
            :padding(0, 1),

        chat_area = btea.style()
            :border(btea.borders.NORMAL)
            :padding(1)
            :foreground("#CDD6F4")
            :background("#181825")
            :border_foreground("#585B70"),

        user_message = btea.style()
            :foreground("#A6E3A1")
            :bold(),

        user_prefix = btea.style()
            :foreground("#A6E3A1")
            :bold(),

        assistant_message = btea.style()
            :foreground("#89B4FA"),

        assistant_prefix = btea.style()
            :foreground("#89B4FA")
            :bold(),

        streaming_message = btea.style()
            :foreground("#89B4FA")
            :italic(),

        system_message = btea.style()
            :foreground("#F38BA8")
            :italic(),

        system_prefix = btea.style()
            :foreground("#F38BA8")
            :bold(),

        input_area = btea.style()
            :border(btea.borders.NORMAL)
            :padding(0, 1)
            :foreground("#CDD6F4")
            :background("#181825")
            :border_foreground("#585B70"),

        input_prompt = btea.style()
            :foreground("#F9E2AF")
            :bold(),

        help = btea.style()
            :foreground("#94E2D5")
            :padding(0, 1),

        status = btea.style()
            :foreground("#F38BA8")
            :italic(),

        model_selector = btea.style()
            :border(btea.borders.ROUNDED)
            :padding(1)
            :foreground("#CDD6F4")
            :background("#181825")
            :border_foreground("#F9E2AF"),

        model_item = btea.style()
            :foreground("#CDD6F4")
            :padding(0, 1),

        model_item_selected = btea.style()
            :foreground("#1E1E2E")
            :background("#A6E3A1")
            :bold()
            :padding(0, 1),

        model_header = btea.style()
            :foreground("#F9E2AF")
            :bold()
            :padding(0, 1)
    }

    -- Helper functions
    function app:add_message(role, content)
        table.insert(self.messages, {
            role = role,
            content = content,
            timestamp = os.time()
        })
        -- Auto-scroll to bottom when new message added
        self.scroll_offset = math.max(0, #self.messages - self.max_visible_lines)
    end

    function app:clear_chat()
        self.messages = {}
        self.scroll_offset = 0
        self.current_input = ""
        self.streaming_response = ""
        self.is_streaming = false
    end

    function app:send_message()
        print("send_message called with input: '" .. self.current_input .. "'")
        
        if self.current_input == "" or self.is_streaming then
            print("send_message aborted - empty input or already streaming")
            return
        end

        local user_message = self.current_input
        self.current_input = ""
        
        print("Processing message: " .. user_message)

        -- Add user message to history
        self:add_message("user", user_message)
        print("Added user message to history")

        -- Start streaming response
        self.is_streaming = true
        self.streaming_response = ""
        print("Set streaming state to true")

        -- Send to LLM (this would be implemented based on your LLM setup)
        self:send_to_llm(user_message)
        print("Called send_to_llm")
    end

    function app:send_to_llm(user_message)
        print("send_to_llm started for message: " .. user_message)
        
        coroutine.spawn(function()
            print("Inside coroutine, building prompt...")
            
            -- Build conversation history for LLM
            local builder = prompt.new()
            builder:add_system("You are a helpful AI assistant. Be concise but informative.")
            print("Added system message to prompt")

            -- Add conversation history (keep last 10 messages for context)
            local start_idx = math.max(1, #self.messages - 10)
            for i = start_idx, #self.messages - 1 do -- -1 to exclude the current user message we just added
                local msg = self.messages[i]
                if msg.role == "user" then
                    builder:add_user(msg.content)
                    print("Added user message to context: " .. msg.content)
                elseif msg.role == "assistant" then
                    builder:add_assistant(msg.content)
                    print("Added assistant message to context: " .. msg.content)
                end
            end

            -- Add current user message
            builder:add_user(user_message)
            print("Added current user message to prompt")
            
            print("About to call llm.generate with model: " .. self.selected_model)

            -- Call LLM with streaming using selected model
            print("Attempting LLM call with prompt builder...")
            local response = llm.generate(builder, {
                model = self.selected_model,
                temperature = 0.7,
                max_tokens = 1000,
                stream = {
                    reply_to = process.pid(),
                    topic = "llm_stream"
                }
            })
            print("LLM call completed")

            -- Handle potential errors according to LLM guidelines
            if not response then
                local error_msg = "LLM returned nil response. Model '" .. self.selected_model .. "' may not exist or be configured properly."
                print("LLM nil response error: " .. error_msg)
                self.streaming_response = ""
                self.is_streaming = false
                self:add_message("system", "❌ " .. error_msg)
                self:upstream("stream_complete")
            elseif response.error then
                local error_msg = "LLM Error: " .. (response.error_message or tostring(response.error))
                print("LLM response error: " .. error_msg)
                self.streaming_response = ""
                self.is_streaming = false
                self:add_message("system", "❌ " .. error_msg)
                self:upstream("stream_complete")
            else
                print("LLM call successful, waiting for streaming responses...")
                if response.result then
                    -- Non-streaming response (fallback)
                    print("Received non-streaming response")
                    self:add_message("assistant", response.result)
                    self.streaming_response = ""
                    self.is_streaming = false
                    self:upstream("stream_complete")
                end
            end
        end)
    end

    function app:handle_llm_stream(chunk)
        print("Received streaming chunk - type: " .. type(chunk))
        if type(chunk) == "table" then
            local keys = {}
            for k, _ in pairs(chunk) do
                table.insert(keys, k)
            end
            print("Chunk keys: " .. table.concat(keys, ", "))
            if chunk.type then
                print("Chunk type: " .. chunk.type)
            end
            if chunk.text then
                print("Chunk text: '" .. chunk.text .. "'")
            end
        end
        
        if self.is_streaming then
            if chunk.type == "chunk" then
                print("Adding chunk content to streaming response")
                local content = chunk.content or ""
                self.streaming_response = self.streaming_response .. content
                self:upstream("stream_update")
            elseif chunk.type == "thinking" then
                print("Thinking process: " .. (chunk.content or ""))
                -- Could show thinking process in UI if desired
            elseif chunk.type == "done" then
                print("Streaming complete, adding final message")
                -- Streaming complete
                self:add_message("assistant", self.streaming_response)
                self.streaming_response = ""
                self.is_streaming = false
                self:upstream("stream_complete")
            elseif chunk.type == "error" then
                print("Streaming error: " .. (chunk.error and chunk.error.message or "Unknown error"))
                -- Handle streaming error
                local error_msg = chunk.error and chunk.error.message or "Unknown error"
                self.streaming_response = self.streaming_response .. "\n\n[Error: " .. error_msg .. "]"
                self:add_message("assistant", self.streaming_response)
                self.streaming_response = ""
                self.is_streaming = false
                self:upstream("stream_complete")
            else
                print("Unknown chunk type: " .. tostring(chunk.type))
            end
        else
            print("Received chunk but not in streaming mode")
        end
    end

    function app:handle_char_input(char)
        if not self.is_streaming and self.input_mode then
            self.current_input = self.current_input .. char
        end
    end

    function app:handle_backspace()
        if not self.is_streaming and self.input_mode and #self.current_input > 0 then
            self.current_input = self.current_input:sub(1, -2)
        end
    end

    function app:scroll_messages(direction)
        local max_scroll = math.max(0, #self.messages - self.max_visible_lines)
        if direction == "up" then
            self.scroll_offset = math.max(0, self.scroll_offset - 5)
        elseif direction == "down" then
            self.scroll_offset = math.min(max_scroll, self.scroll_offset + 5)
        end
    end

    function app:load_available_models()
        if self.models_loaded then
            return
        end
        
        coroutine.spawn(function()
            print("Loading available models...")
            
            -- Get models with generation capability
            local models = llm.available_models("generate")
            print("Found " .. (models and #models or 0) .. " models")
            print("Raw models response:", json.encode(models or {}))
            
            -- Always provide a good selection of popular models
            local popular_models = {
                {name = "claude-3-5-sonnet", title = "Claude 3.5 Sonnet", comment = "High-performance Claude model"},
                {name = "claude3-haiku", title = "Claude 3.5 Haiku", comment = "Fastest Claude model"},
                {name = "claude-4-sonnet", title = "Claude 4 Sonnet", comment = "Latest Claude model with thinking"},
                {name = "gpt-4o", title = "GPT-4o", comment = "Fast, intelligent GPT model"},
                {name = "gpt-4o-mini", title = "GPT-4o Mini", comment = "Affordable GPT model"},
                {name = "o3-mini", title = "O3 Mini", comment = "Fast reasoning model"},
                {name = "gemini-2.5-flash", title = "Gemini 2.5 Flash", comment = "Fast Google model"},
                {name = "gemini-1.5-pro", title = "Gemini 1.5 Pro", comment = "High-capability Google model"}
            }
            
            if models and #models > 0 then
                print("Using available models from LLM system")
                self.available_models = models
                print("Available models:")
                for i, model in ipairs(models) do
                    print("  " .. i .. ": " .. model.name .. " (" .. (model.title or "no title") .. ")")
                end
            else
                print("No configured models found, using popular model list")
                self.available_models = popular_models
            end
            
            -- Find current model index or use first model
            local found_index = 1
            for i, model in ipairs(self.available_models) do
                if model.name == self.selected_model then
                    found_index = i
                    break
                end
            end
            self.model_selection_index = found_index
            
            -- If our selected model wasn't found, use the first available model
            if found_index == 1 and self.available_models[1].name ~= self.selected_model then
                print("Selected model '" .. self.selected_model .. "' not found, using '" .. self.available_models[1].name .. "' instead")
                self.selected_model = self.available_models[1].name
            end
            
            self.models_loaded = true
            self:upstream("models_loaded")
        end)
    end

    function app:toggle_model_selection()
        if self.is_streaming then
            return -- Don't allow model selection while streaming
        end
        
        if not self.models_loaded then
            self:load_available_models()
        end
        
        self.model_selection_mode = not self.model_selection_mode
        if self.model_selection_mode then
            self.input_mode = false
        else
            self.input_mode = true
        end
    end

    function app:navigate_model_selection(direction)
        if not self.model_selection_mode or #self.available_models == 0 then
            return
        end
        
        if direction == "up" then
            self.model_selection_index = math.max(1, self.model_selection_index - 1)
        elseif direction == "down" then
            self.model_selection_index = math.min(#self.available_models, self.model_selection_index + 1)
        end
    end

    function app:select_current_model()
        if not self.model_selection_mode or #self.available_models == 0 then
            return
        end
        
        local selected = self.available_models[self.model_selection_index]
        if selected then
            self.selected_model = selected.name
            self:toggle_model_selection() -- Close model selection
        end
    end

    -- Load available models immediately on startup
    app:load_available_models()
    
    -- Add welcome message
    app:add_message("assistant", "Hello! I'm your AI assistant. How can I help you today?")

    -- Update handler
    local function update(self, msg)
        print("Update called with message type: " .. type(msg))
        if type(msg) == "table" then
            local keys = {}
            for k, _ in pairs(msg) do
                table.insert(keys, k)
            end
            print("Message keys: " .. table.concat(keys, ", "))
            if msg.string then
                print("Message string: " .. msg.string)
            end
            if msg.topic then
                print("Message topic: " .. msg.topic)
            end
        end
        
        -- Check for LLM stream messages using non-blocking select
        local result = channel.select({
            self.llm_stream_channel:case_receive(),
            default = true
        })
        
        if not result.default then
            print("Received LLM stream message")
            self:handle_llm_stream(result.value)
            return false
        end
        
        if msg.string == "stream_update" or msg.string == "stream_complete" or msg.string == "models_loaded" then
            -- Just trigger re-render for streaming updates and model loading
            return false
        elseif msg.key then
            print("Handling key message - key type: " .. tostring(msg.key.key_type))
            print("Key string: " .. tostring(msg.key.string))
            if self.model_selection_mode then
                -- Handle model selection navigation
                if self.keys.model_select:matches(msg) or self.keys.escape:matches(msg) then
                    self:toggle_model_selection()
                elseif self.keys.send:matches(msg) then
                    self:select_current_model()
                elseif self.keys.nav_up:matches(msg) or self.keys.scroll_up:matches(msg) then
                    self:navigate_model_selection("up")
                elseif self.keys.nav_down:matches(msg) or self.keys.scroll_down:matches(msg) then
                    self:navigate_model_selection("down")
                end
            elseif self.keys.quit:matches(msg) then
                return true -- signal quit
            else
                -- Normal chat mode
                if self.keys.model_select:matches(msg) then
                    print("Ctrl+T matched! Opening model selection")
                    self:toggle_model_selection()
                elseif self.keys.send:matches(msg) then
                    self:send_message()
                elseif self.keys.clear:matches(msg) then
                    self:clear_chat()
                elseif self.keys.scroll_up:matches(msg) then
                    self:scroll_messages("up")
                elseif self.keys.scroll_down:matches(msg) then
                    self:scroll_messages("down")
                elseif self.keys.backspace:matches(msg) then
                    self:handle_backspace()
                elseif msg.key.key_type == "runes" and msg.key.runes then
                    -- Handle regular character input
                    self:handle_char_input(msg.key.runes)
                end
            end
        end
        return false -- continue running
    end

    -- View rendering
    local function view(self)
        local content = {}

        -- Header with current model
        local header_text = "AI Chat Assistant"
        if self.selected_model then
            header_text = header_text .. " (" .. self.selected_model .. ")"
        end
        table.insert(content, self.styles.header:render(header_text))
        table.insert(content, "")

        -- Model selection overlay
        if self.model_selection_mode then
            local model_content = {}
            table.insert(model_content, self.styles.model_header:render("Select LLM Model:"))
            table.insert(model_content, "")
            
            if #self.available_models == 0 then
                table.insert(model_content, self.styles.model_item:render("Loading models..."))
            else
                for i, model in ipairs(self.available_models) do
                    local model_text = model.name
                    if model.title and model.title ~= model.name then
                        model_text = model_text .. " (" .. model.title .. ")"
                    end
                    if model.comment then
                        model_text = model_text .. " - " .. model.comment
                    end
                    
                    local style = (i == self.model_selection_index) and 
                                  self.styles.model_item_selected or 
                                  self.styles.model_item
                    
                    local prefix = (i == self.model_selection_index) and "▶ " or "  "
                    table.insert(model_content, style:render(prefix .. model_text))
                end
            end
            
            table.insert(model_content, "")
            table.insert(model_content, self.styles.help:render("↑/↓: navigate  |  enter: select  |  esc/^T: cancel"))
            
            local model_selector = self.styles.model_selector
                :width(math.min(80, self.window.width - 4))
                :height(math.min(#model_content + 4, self.window.height - 4))
                :render(table.concat(model_content, "\n"))
            
            return model_selector
        end

        -- Chat messages area
        local chat_lines = {}
        local visible_messages = {}

        -- Get visible messages based on scroll offset
        for i = self.scroll_offset + 1, math.min(#self.messages, self.scroll_offset + self.max_visible_lines) do
            table.insert(visible_messages, self.messages[i])
        end

        for _, message in ipairs(visible_messages) do
            if message.role == "user" then
                table.insert(chat_lines, self.styles.user_prefix:render("You: ") ..
                    self.styles.user_message:render(message.content))
            elseif message.role == "system" then
                table.insert(chat_lines, self.styles.system_prefix:render("System: ") ..
                    self.styles.system_message:render(message.content))
            else
                table.insert(chat_lines, self.styles.assistant_prefix:render("Assistant: ") ..
                    self.styles.assistant_message:render(message.content))
            end
            table.insert(chat_lines, "") -- Empty line between messages
        end

        -- Add streaming response if active
        if self.is_streaming and self.streaming_response ~= "" then
            table.insert(chat_lines, self.styles.assistant_prefix:render("Assistant: ") ..
                self.styles.streaming_message:render(self.streaming_response .. "▋"))
        end

        -- Ensure minimum height for chat area
        while #chat_lines < self.max_visible_lines do
            table.insert(chat_lines, "")
        end

        table.insert(content, self.styles.chat_area:render(table.concat(chat_lines, "\n")))
        table.insert(content, "")

        -- Input area
        local input_content = ""
        if self.is_streaming then
            input_content = self.styles.status:render("AI is responding... (streaming)")
        else
            input_content = self.styles.input_prompt:render("> ") .. self.current_input .. "▋"
        end

        table.insert(content, self.styles.input_area:render(input_content))
        table.insert(content, "")

        -- Help text
        local help_text = ""
        if self.is_streaming then
            help_text = "^X: quit"
        else
            help_text = "enter: send  |  ^T: model  |  ^L: clear  |  PgUp/PgDn: scroll  |  ^X: quit"
        end
        table.insert(content, self.styles.help:render(help_text))

        -- Scroll indicator
        if #self.messages > self.max_visible_lines then
            local scroll_info = string.format("(Showing %d-%d of %d messages)",
                self.scroll_offset + 1,
                math.min(#self.messages, self.scroll_offset + self.max_visible_lines),
                #self.messages)
            table.insert(content, self.styles.help:render(scroll_info))
        end

        return self.styles.container
            :width(self.window.width - 2)
            :height(self.window.height - 2)
            :render(table.concat(content, "\n"))
    end

    -- Run the app
    app:run(update, view)
end

return App
