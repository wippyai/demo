local http = require("http")

local function handler()
    local res = http.response()
    if not res then
        return nil, "Failed to get HTTP response"
    end

    -- Minimal HTML for testing
    local html_content = [[<!DOCTYPE html>
<html>
<head>
    <title>Wippy Chat - Simple</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .container { max-width: 600px; margin: 0 auto; }
        .messages { border: 1px solid #ccc; height: 400px; overflow-y: auto; padding: 10px; margin-bottom: 10px; }
        .input-area { display: flex; gap: 10px; }
        #messageInput { flex: 1; padding: 10px; }
        #sendButton { padding: 10px 20px; }
        .message { margin: 10px 0; padding: 8px; border-radius: 5px; }
        .user { background: #e3f2fd; text-align: right; }
        .assistant { background: #f5f5f5; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Wippy Chat</h1>
        <div id="messages" class="messages">
            <div class="message assistant">Hello! How can I help you?</div>
        </div>
        <div class="input-area">
            <input type="text" id="messageInput" placeholder="Type your message...">
            <button id="sendButton">Send</button>
        </div>
        <div id="status" style="margin-top: 10px; color: #666;"></div>
    </div>

    <script>
        let sessionToken = null;

        // Initialize session
        fetch('/api/v1/chat/session', { method: 'POST' })
            .then(r => r.json())
            .then(data => {
                sessionToken = data.session;
                document.getElementById('status').textContent = 'Connected to session';
            })
            .catch(e => {
                document.getElementById('status').textContent = 'Failed to connect: ' + e.message;
            });

        // Send message
        function sendMessage() {
            const input = document.getElementById('messageInput');
            const message = input.value.trim();
            if (!message || !sessionToken) return;

            // Add user message
            const messages = document.getElementById('messages');
            messages.innerHTML += `<div class="message user">${message}</div>`;
            input.value = '';

            // Send to server
            fetch(`/api/v1/chat/message?session=${encodeURIComponent(sessionToken)}&message=${encodeURIComponent(message)}`, { method: 'POST' })
                .then(response => {
                    const reader = response.body.getReader();
                    let assistantDiv = document.createElement('div');
                    assistantDiv.className = 'message assistant';
                    assistantDiv.textContent = '';
                    messages.appendChild(assistantDiv);

                    function readChunk() {
                        return reader.read().then(({ done, value }) => {
                            if (done) return;
                            
                            const text = new TextDecoder().decode(value);
                            const lines = text.split('\\n');
                            
                            for (const line of lines) {
                                if (!line.trim()) continue;
                                try {
                                    const data = JSON.parse(line);
                                    if (data.text) {
                                        assistantDiv.textContent += data.text;
                                    }
                                } catch (e) {}
                            }
                            
                            messages.scrollTop = messages.scrollHeight;
                            return readChunk();
                        });
                    }
                    
                    return readChunk();
                })
                .catch(e => {
                    messages.innerHTML += `<div class="message assistant">Error: ${e.message}</div>`;
                });
        }

        document.getElementById('sendButton').addEventListener('click', sendMessage);
        document.getElementById('messageInput').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') sendMessage();
        });
    </script>
</body>
</html>]]

    -- Set content type directly as string
    res:set_content_type("text/html")
    res:write(html_content)
end

return { handler = handler }
