local time = require("time")
local bapp = require("bapp")
local llm = require("llm")
local prompt = require("prompt")

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
            keys = { "ctrl+c", "esc" },
            help = { key = "^C/esc", desc = "quit" }
        },
        backspace = {
            keys = { "backspace" },
            help = { key = "⌫", desc = "delete char" }
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
            :italic()
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
        if self.current_input == "" or self.is_streaming then
            return
        end

        local user_message = self.current_input
        self.current_input = ""

        -- Add user message to history
        self:add_message("user", user_message)

        -- Start streaming response
        self.is_streaming = true
        self.streaming_response = ""

        -- Send to LLM (this would be implemented based on your LLM setup)
        self:send_to_llm(user_message)
    end

    function app:send_to_llm(user_message)
        coroutine.spawn(function()
            -- Build conversation history for LLM
            local builder = prompt.new()
            builder:add_system("You are a helpful AI assistant. Be concise but informative.")

            -- Add conversation history (keep last 10 messages for context)
            local start_idx = math.max(1, #self.messages - 10)
            for i = start_idx, #self.messages - 1 do -- -1 to exclude the current user message we just added
                local msg = self.messages[i]
                if msg.role == "user" then
                    builder:add_user(msg.content)
                elseif msg.role == "assistant" then
                    builder:add_assistant(msg.content)
                end
            end

            -- Add current user message
            builder:add_user(user_message)

            -- Call LLM with streaming
            local response = llm.generate(builder, {
                model = "claude-3-5-haiku", -- You can make this configurable
                temperature = 0.7,
                max_tokens = 1000,
                stream = {
                    reply_to = process.pid(),
                    topic = "llm_stream"
                }
            })

            -- Handle potential errors
            if response and response.error then
                self.streaming_response = "Error: " .. (response.error_message or response.error)
                self:add_message("assistant", self.streaming_response)
                self.streaming_response = ""
                self.is_streaming = false
                self:upstream("stream_complete")
            end
        end)
    end

    function app:handle_llm_stream(chunk)
        if self.is_streaming then
            if chunk.type == "content" then
                self.streaming_response = self.streaming_response .. chunk.text
                self:upstream("stream_update")
            elseif chunk.type == "done" then
                -- Streaming complete
                self:add_message("assistant", self.streaming_response)
                self.streaming_response = ""
                self.is_streaming = false
                self:upstream("stream_complete")
            elseif chunk.type == "error" then
                -- Handle streaming error
                self.streaming_response = self.streaming_response .. "\n\n[Error: " .. (chunk.error or "Unknown error") .. "]"
                self:add_message("assistant", self.streaming_response)
                self.streaming_response = ""
                self.is_streaming = false
                self:upstream("stream_complete")
            end
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

    -- Add welcome message
    app:add_message("assistant", "Hello! I'm your AI assistant. How can I help you today?")

    -- Update handler
    local function update(self, msg)
        if msg.string == "stream_update" or msg.string == "stream_complete" then
            -- Just trigger re-render for streaming updates
            return false
        elseif msg.topic == "llm_stream" then
            -- Handle LLM streaming response
            self:handle_llm_stream(msg.payload)
            return false
        elseif msg.key then
            if self.keys.quit:matches(msg) then
                return true -- signal quit
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
        return false -- continue running
    end

    -- View rendering
    local function view(self)
        local content = {}

        -- Header
        table.insert(content, self.styles.header:render("AI Chat Assistant"))
        table.insert(content, "")

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
            help_text = "^C/esc: quit"
        else
            help_text = "enter: send  |  ^L: clear  |  PgUp/PgDn: scroll  |  ^C/esc: quit"
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
