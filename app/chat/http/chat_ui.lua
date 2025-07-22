local http = require("http")

local function handler()
    local res = http.response()
    if not res then
        return nil, "Failed to get HTTP response"
    end

    -- HTML content with embedded CSS and JavaScript
    local html_content = [[
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Wippy Chat</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .chat-container {
            width: 90%;
            max-width: 800px;
            height: 80vh;
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }

        .chat-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            text-align: center;
            position: relative;
        }

        .chat-header h1 {
            font-size: 1.5rem;
            font-weight: 600;
        }

        .session-info {
            font-size: 0.8rem;
            opacity: 0.8;
            margin-top: 5px;
        }

        .connection-status {
            position: absolute;
            top: 20px;
            right: 20px;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            background: #ff4757;
            transition: background 0.3s ease;
        }

        .connection-status.connected {
            background: #2ed573;
        }

        .chat-messages {
            flex: 1;
            overflow-y: auto;
            padding: 20px;
            background: #f8f9fa;
        }

        .message {
            margin-bottom: 15px;
            display: flex;
            align-items: flex-start;
        }

        .message.user {
            justify-content: flex-end;
        }

        .message.assistant {
            justify-content: flex-start;
        }

        .message-content {
            max-width: 70%;
            padding: 12px 16px;
            border-radius: 18px;
            word-wrap: break-word;
            position: relative;
        }

        .message.user .message-content {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-bottom-right-radius: 6px;
        }

        .message.assistant .message-content {
            background: white;
            color: #333;
            border: 1px solid #e1e8ed;
            border-bottom-left-radius: 6px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
        }

        .message-time {
            font-size: 0.75rem;
            opacity: 0.6;
            margin-top: 4px;
        }

        .typing-indicator {
            display: none;
            align-items: center;
            margin-bottom: 15px;
        }

        .typing-indicator.show {
            display: flex;
        }

        .typing-dots {
            display: flex;
            align-items: center;
            padding: 12px 16px;
            background: white;
            border: 1px solid #e1e8ed;
            border-radius: 18px;
            border-bottom-left-radius: 6px;
        }

        .typing-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: #667eea;
            margin: 0 2px;
            animation: typing 1.5s infinite;
        }

        .typing-dot:nth-child(1) { animation-delay: 0s; }
        .typing-dot:nth-child(2) { animation-delay: 0.2s; }
        .typing-dot:nth-child(3) { animation-delay: 0.4s; }

        @keyframes typing {
            0%, 60%, 100% { transform: translateY(0); opacity: 0.4; }
            30% { transform: translateY(-10px); opacity: 1; }
        }

        .chat-input {
            padding: 20px;
            background: white;
            border-top: 1px solid #e1e8ed;
            display: flex;
            gap: 10px;
        }

        .input-field {
            flex: 1;
            padding: 12px 16px;
            border: 2px solid #e1e8ed;
            border-radius: 25px;
            outline: none;
            font-size: 1rem;
            transition: border-color 0.3s ease;
        }

        .input-field:focus {
            border-color: #667eea;
        }

        .input-field:disabled {
            background: #f1f3f4;
            cursor: not-allowed;
        }

        .send-button {
            padding: 12px 24px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 25px;
            cursor: pointer;
            font-size: 1rem;
            font-weight: 600;
            transition: transform 0.2s ease, box-shadow 0.2s ease;
        }

        .send-button:hover:not(:disabled) {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
        }

        .send-button:disabled {
            opacity: 0.6;
            cursor: not-allowed;
            transform: none;
        }

        .error-message {
            background: #ff4757;
            color: white;
            padding: 10px;
            text-align: center;
            margin: 10px 20px;
            border-radius: 8px;
            display: none;
        }

        .error-message.show {
            display: block;
        }

        /* Scrollbar styling */
        .chat-messages::-webkit-scrollbar {
            width: 6px;
        }

        .chat-messages::-webkit-scrollbar-track {
            background: #f1f1f1;
        }

        .chat-messages::-webkit-scrollbar-thumb {
            background: #c1c1c1;
            border-radius: 3px;
        }

        .chat-messages::-webkit-scrollbar-thumb:hover {
            background: #a8a8a8;
        }

        /* Mobile responsiveness */
        @media (max-width: 768px) {
            .chat-container {
                width: 95%;
                height: 90vh;
                border-radius: 10px;
            }

            .message-content {
                max-width: 85%;
            }

            .chat-header {
                padding: 15px;
            }

            .chat-header h1 {
                font-size: 1.3rem;
            }
        }
    </style>
</head>
<body>
    <div class="chat-container">
        <div class="chat-header">
            <h1>Wippy Chat</h1>
            <div class="session-info">AI-Powered Assistant</div>
            <div class="connection-status" id="connectionStatus"></div>
        </div>

        <div class="error-message" id="errorMessage"></div>

        <div class="chat-messages" id="chatMessages">
            <div class="message assistant">
                <div class="message-content">
                    Hello! I'm your AI assistant. How can I help you today?
                    <div class="message-time" id="welcomeTime"></div>
                </div>
            </div>
        </div>

        <div class="typing-indicator" id="typingIndicator">
            <div class="typing-dots">
                <div class="typing-dot"></div>
                <div class="typing-dot"></div>
                <div class="typing-dot"></div>
            </div>
        </div>

        <div class="chat-input">
            <input 
                type="text" 
                class="input-field" 
                id="messageInput" 
                placeholder="Type your message..."
                autocomplete="off"
            >
            <button class="send-button" id="sendButton">Send</button>
        </div>
    </div>

    <script>
        class WippyChat {
            constructor() {
                this.sessionToken = null;
                this.isConnected = false;
                this.isWaiting = false;
                
                // DOM elements
                this.messagesContainer = document.getElementById('chatMessages');
                this.messageInput = document.getElementById('messageInput');
                this.sendButton = document.getElementById('sendButton');
                this.connectionStatus = document.getElementById('connectionStatus');
                this.typingIndicator = document.getElementById('typingIndicator');
                this.errorMessage = document.getElementById('errorMessage');
                
                this.initializeChat();
                this.setupEventListeners();
                this.setWelcomeTime();
            }

            setWelcomeTime() {
                const welcomeTime = document.getElementById('welcomeTime');
                if (welcomeTime) {
                    welcomeTime.textContent = new Date().toLocaleTimeString();
                }
            }

            async initializeChat() {
                try {
                    const response = await fetch('/api/v1/chat/session', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        }
                    });

                    if (!response.ok) {
                        throw new Error(`Failed to create session: ${response.status}`);
                    }

                    const data = await response.json();
                    this.sessionToken = data.session;
                    this.setConnected(true);
                    this.showSuccess('Connected to chat session');
                } catch (error) {
                    console.error('Failed to initialize chat:', error);
                    this.showError('Failed to connect to chat. Please refresh the page.');
                    this.setConnected(false);
                }
            }

            setupEventListeners() {
                this.sendButton.addEventListener('click', () => this.sendMessage());
                this.messageInput.addEventListener('keypress', (e) => {
                    if (e.key === 'Enter' && !e.shiftKey) {
                        e.preventDefault();
                        this.sendMessage();
                    }
                });

                // Auto-resize input field
                this.messageInput.addEventListener('input', (e) => {
                    e.target.style.height = 'auto';
                    e.target.style.height = Math.min(e.target.scrollHeight, 120) + 'px';
                });
            }

            async sendMessage() {
                const message = this.messageInput.value.trim();
                if (!message || this.isWaiting || !this.sessionToken) {
                    return;
                }

                // Add user message to chat
                this.addMessage('user', message);
                this.messageInput.value = '';
                this.messageInput.style.height = 'auto';

                // Show typing indicator
                this.setWaiting(true);
                this.showTyping(true);

                try {
                    const response = await fetch(`/api/v1/chat/message?session=${encodeURIComponent(this.sessionToken)}&message=${encodeURIComponent(message)}`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        }
                    });

                    if (!response.ok) {
                        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
                    }

                    // Handle streaming response
                    const reader = response.body.getReader();
                    const decoder = new TextDecoder();
                    let assistantMessage = '';
                    let messageElement = null;

                    while (true) {
                        const { done, value } = await reader.read();
                        if (done) break;

                        const chunk = decoder.decode(value, { stream: true });
                        const lines = chunk.split('\n');

                        for (const line of lines) {
                            if (!line.trim()) continue;

                            try {
                                const data = JSON.parse(line);
                                
                                if (data.text) {
                                    assistantMessage += data.text;
                                    
                                    // Create or update message element
                                    if (!messageElement) {
                                        this.showTyping(false);
                                        messageElement = this.addMessage('assistant', '');
                                    }
                                    
                                    // Update message content with streaming text
                                    const contentElement = messageElement.querySelector('.message-content');
                                    const timeElement = contentElement.querySelector('.message-time');
                                    contentElement.innerHTML = this.formatMessage(assistantMessage) + 
                                        `<div class="message-time">${new Date().toLocaleTimeString()}</div>`;
                                }

                                if (data.done) {
                                    break;
                                }
                            } catch (parseError) {
                                console.warn('Failed to parse JSON line:', line, parseError);
                            }
                        }
                    }

                    // If no message was created, show a fallback
                    if (!messageElement && !assistantMessage) {
                        this.showTyping(false);
                        this.addMessage('assistant', 'I received your message but had trouble responding. Please try again.');
                    }

                } catch (error) {
                    console.error('Failed to send message:', error);
                    this.showTyping(false);
                    this.showError('Failed to send message. Please try again.');
                    this.addMessage('assistant', 'Sorry, I encountered an error. Please try sending your message again.');
                } finally {
                    this.setWaiting(false);
                }
            }

            addMessage(type, content) {
                const messageDiv = document.createElement('div');
                messageDiv.className = `message ${type}`;

                const contentDiv = document.createElement('div');
                contentDiv.className = 'message-content';
                contentDiv.innerHTML = this.formatMessage(content) + 
                    `<div class="message-time">${new Date().toLocaleTimeString()}</div>`;

                messageDiv.appendChild(contentDiv);
                
                // Insert before typing indicator
                this.messagesContainer.insertBefore(messageDiv, this.typingIndicator);
                this.scrollToBottom();

                return messageDiv;
            }

            formatMessage(text) {
                // Basic HTML escaping and formatting
                return text
                    .replace(/&/g, '&amp;')
                    .replace(/</g, '&lt;')
                    .replace(/>/g, '&gt;')
                    .replace(/\n/g, '<br>')
                    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
                    .replace(/\*(.*?)\*/g, '<em>$1</em>');
            }

            setConnected(connected) {
                this.isConnected = connected;
                this.connectionStatus.className = connected ? 'connection-status connected' : 'connection-status';
                this.sendButton.disabled = !connected || this.isWaiting;
                this.messageInput.disabled = !connected;
            }

            setWaiting(waiting) {
                this.isWaiting = waiting;
                this.sendButton.disabled = waiting || !this.isConnected;
                this.messageInput.disabled = waiting || !this.isConnected;
                this.sendButton.textContent = waiting ? 'Sending...' : 'Send';
            }

            showTyping(show) {
                this.typingIndicator.className = show ? 'typing-indicator show' : 'typing-indicator';
                if (show) {
                    this.scrollToBottom();
                }
            }

            showError(message) {
                this.errorMessage.textContent = message;
                this.errorMessage.className = 'error-message show';
                setTimeout(() => {
                    this.errorMessage.className = 'error-message';
                }, 5000);
            }

            showSuccess(message) {
                console.log('Success:', message);
                // Could add a success notification UI here
            }

            scrollToBottom() {
                setTimeout(() => {
                    this.messagesContainer.scrollTop = this.messagesContainer.scrollHeight;
                }, 100);
            }
        }

        // Initialize chat when page loads
        document.addEventListener('DOMContentLoaded', () => {
            new WippyChat();
        });
    </script>
</body>
</html>
    ]]

    -- Set content type as plain string instead of using http.CONTENT.HTML
    res:set_content_type("text/html; charset=utf-8")
    res:write(html_content)
end

return { handler = handler }
