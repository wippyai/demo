# Documentation
```
// Structure of documents
└── .wippy/
    └── wippy/
        └── actor@01984114-d1ea-74ae-b4e3-6548d6e05a10/
            ├── module-actor-0.0.10/
            │   └── README.md
            │   └── docs/
            │       └── actor.spec.md
        └── llm@01984114-d135-7c72-9da0-f685194c4e8c/
            ├── module-llm-0.0.10/
            │   └── README.md
            │   └── docs/
            │       └── llm.spec.md
        └── migration@01984114-e585-7da1-b6ab-ea45ca51ddc6/
            ├── module-migration-0.0.10/
            │   └── README.md
            │   └── docs/
            │       └── migration.spec.md
        └── security@01978c92-7d02-7b4a-95df-55b57cfe80b7/
            ├── module-security-0.0.7/
            │   └── README.md
        └── terminal@01978c92-9604-7b59-a66f-00ba24eb67d9/
            ├── module-terminal-0.0.7/
            │   └── README.md
        └── test@0197e530-927f-75f5-995c-b6f5e0dd32f9/
            ├── module-test-0.0.8/
            │   └── README.md
            │   └── docs/
            │       └── test.spec.md
        └── usage@0197ef87-b8de-73a6-a83b-6fdecdf9d6e1/
            └── module-usage-0.0.9/
                └── README.md

```
###  Path: `\.wippy\wippy\actor@01984114-d1ea-74ae-b4e3-6548d6e05a10\module-actor-0.0.10/README.md`

```md
<p align="center">
    <a href="https://wippy.ai" target="_blank">
        <picture>
            <source media="(prefers-color-scheme: dark)" srcset="https://github.com/wippyai/.github/blob/main/logo/wippy-text-dark.svg?raw=true">
            <img width="30%" align="center" src="https://github.com/wippyai/.github/blob/main/logo/wippy-text-light.svg?raw=true" alt="Wippy logo">
        </picture>
    </a>
</p>
<h1 align="center">Actor Module</h1>
<div align="center">

[![Latest Release](https://img.shields.io/github/v/release/wippyai/module-actor?style=flat-square)][releases-page]
[![License](https://img.shields.io/github/license/wippyai/module-actor?style=flat-square)](LICENSE)
[![Documentation](https://img.shields.io/badge/Wippy-Documentation-brightgreen.svg?style=flat-square)][wippy-documentation]

</div>

> [!NOTE]
> This repository is read-only.
> The code is generated from the [wippyai/framework][wippy-framework] repository.

[wippy-documentation]: https://docs.wippy.ai
[releases-page]: https://github.com/wippyai/module-actor/releases
[wippy-framework]: https://github.com/wippyai/framework

```
###  Path: `\.wippy\wippy\actor@01984114-d1ea-74ae-b4e3-6548d6e05a10\module-actor-0.0.10\docs/actor.spec.md`

```md
# Actor Library for Wippy Runtime

The Actor Library provides a simple and flexible way to build processes using the actor model pattern in the Wippy Runtime environment. This guide explains how to use the library effectively.

## Basic Usage

### Creating an Actor

```lua
local actor = require("actor")

local function run()
    -- Initial state
    local state = {
        pid = process.pid(),
        count = 0
    }
    
    -- Create the actor with state and handlers
    local my_actor = actor.new(state, {
        -- Topic handler
        message = function(state, msg)
            state.count = state.count + 1
            print("Received message:", msg)
            
                            -- You can respond if the message includes a reply_to
            if msg.reply_to then
                process.send(msg.reply_to, "response", {
                    status = "ok",
                    count = state.count
                })
            end
        end,
        
        -- Cancellation handler
        __on_cancel = function(state)
            print("Process received cancel signal")
            return actor.exit({ status = "shutdown" })
        end
    })
    
    -- Run the actor loop
    return my_actor.run()
end

return { run = run }
```

### Handler Types

There are several types of handlers you can define:

1. **Topic Handlers**: Named functions that handle specific message topics
2. **Special Handlers**:
    - `__init`: Called when the actor starts
    - `__on_cancel`: Handles process cancellation
    - `__on_event`: Handles all system events (exit, cancel, link_down)
    - `__default`: Catches messages with topics that don't have specific handlers

## Working with Custom Channels

### Registering Channels

The actor library allows you to register custom channels:

```lua
-- Inside a handler or during initialization
local time = require("time")

-- Create a timer channel
local timer = time.ticker("1s")

-- Register the channel with a handler
state.register_channel(timer, function(state, value, ok)
    if ok then
        -- Timer fired
        state.count = state.count + 1
        print("Timer fired, count:", state.count)
    else
        -- Timer channel closed
        print("Timer channel closed")
    end
end)
```

### Unregistering Channels

You can manually unregister channels when needed:

```lua
-- Unregister a channel
state.unregister_channel(timer)
```

Note: Channels are automatically unregistered when they close.

## Handler Management

You can dynamically add and remove topic handlers at runtime:

```lua
-- Add a new topic handler
state.add_handler("new_topic", function(state, payload)
    print("Handling new topic:", payload)
    return { status = "processed" }
end)

-- Remove a topic handler
state.remove_handler("old_topic")
```

## Custom Process Implementation

The actor library supports custom process implementations:

```lua
-- Custom process implementation
local custom_process = {
    inbox = function() return my_custom_inbox() end,
    events = function() return my_custom_events() end,
    send = function(dest, topic, payload) return my_custom_send(dest, topic, payload) end,
    pid = function() return my_custom_pid() end,
    event = my_custom_event_types
}

-- Create actor with custom process
local my_actor = actor.new(state, handlers, custom_process)
```

## Common Patterns

### Request-Response Pattern

```lua
-- Handler for request
request = function(state, msg)
    -- Process request
    local result = process_request(msg.data)
    
    -- Send response if reply_to is provided
    if msg.reply_to then
        process.send(msg.reply_to, "response", {
            status = "ok",
            result = result
        })
    end
end
```

### Working with Timers

```lua
local time = require("time")

-- In your initialization handler
__init = function(state)
    -- Create and register a timer
    local timer = time.ticker("5s")
    state.register_channel(timer, function(state, _, ok)
        if ok then
            print("Periodic task running...")
            perform_periodic_task(state)
        end
    end)
end
```

### Using the Registry

```lua
-- Register process name for easy discovery
process.registry.register("my_service")

-- Inside a handler to send to a registered process
process.send("my_service", "message", payload)
```

## Advanced Patterns

### Supervision

```lua
-- Use trap_links to handle child process failures
process.set_options({ trap_links = true })

-- Spawn a linked child process
local child_pid = process.spawn_linked("app:child", "system:processes", args)

-- Handle link down events
__on_event = function(state, event)
    if event.kind == process.event.LINK_DOWN then
        print("Child process down:", event.from)
        -- Restart child process
        state.child_pid = process.spawn_linked("app:child", "system:processes", args)
    end
end
```

### Graceful Shutdown

```lua
__on_cancel = function(state)
    -- Perform cleanup
    cleanup_resources(state)
    
    -- Cancel any child processes
    if state.child_pid then
        process.cancel(state.child_pid, "2s")
    end
    
    -- Wait for child processes to clean up
    time.sleep("1s")
    
    -- Exit with result
    return actor.exit({ status = "shutdown_complete" })
end
```

## Exit Handling

The actor can be explicitly exited from any handler using `actor.exit()`:

```lua
shutdown = function(state, msg)
    -- Perform cleanup
    cleanup_resources(state)
    
    -- Return a result with actor.exit
    return actor.exit({ status = "shutdown", reason = msg.reason })
end
```

## Implementation Details

### Channel Selection

The library uses Wippy's channel selection mechanism to efficiently handle messages from multiple sources:

1. The actor's inbox for regular message passing
2. System events channel for process events
3. Any registered custom channels

The select mechanism automatically rebuilds when channels are added or removed.
```
###  Path: `\.wippy\wippy\llm@01984114-d135-7c72-9da0-f685194c4e8c\module-llm-0.0.10/README.md`

```md
<p align="center">
    <a href="https://wippy.ai" target="_blank">
        <picture>
            <source media="(prefers-color-scheme: dark)" srcset="https://github.com/wippyai/.github/blob/main/logo/wippy-text-dark.svg?raw=true">
            <img width="30%" align="center" src="https://github.com/wippyai/.github/blob/main/logo/wippy-text-light.svg?raw=true" alt="Wippy logo">
        </picture>
    </a>
</p>
<h1 align="center">LLM Module</h1>
<div align="center">

[![Latest Release](https://img.shields.io/github/v/release/wippyai/module-llm?style=flat-square)][releases-page]
[![License](https://img.shields.io/github/license/wippyai/module-llm?style=flat-square)](LICENSE)
[![Documentation](https://img.shields.io/badge/Wippy-Documentation-brightgreen.svg?style=flat-square)][wippy-documentation]

</div>

> [!NOTE]
> This repository is read-only.
> The code is generated from the [wippyai/framework][wippy-framework] repository.

[wippy-documentation]: https://docs.wippy.ai
[releases-page]: https://github.com/wippyai/module-llm/releases
[wippy-framework]: https://github.com/wippyai/framework

```
###  Path: `\.wippy\wippy\llm@01984114-d135-7c72-9da0-f685194c4e8c\module-llm-0.0.10\docs/llm.spec.md`

```md
# LLM Library Specification and Usage Guide

This document specifies the standard input and output formats for the LLM functions in our system, as well as providing practical examples of how to use the library.

## 1. Overview

The LLM library provides a unified interface for working with large language models from various providers (OpenAI, Anthropic, Google, etc.). Key features include:

- Text generation with various models
- Tool/function calling capabilities
- Structured output generation
- Embedding generation
- Model discovery and capability filtering

## 2. Basic Text Generation

### Example: Simple String Prompt

```lua
local llm = require("llm")

-- Generate text with a simple string prompt
local response = llm.generate("What are the three laws of robotics?", {
    model = "gpt-4o"
})

-- Access the response content
print(response.result)

-- Access token usage information
print("Used " .. response.tokens.total_tokens .. " tokens")
```

### Example: Using Prompt Builder

```lua
local llm = require("llm")
local prompt = require("prompt")

-- Create a prompt builder for more complex prompts
local builder = prompt.new()
builder:add_system("You are a helpful AI assistant specializing in physics.")
builder:add_user("Explain how black holes work in simple terms.")

-- Generate text using the prompt builder
local response = llm.generate(builder, {
    model = "claude-3-5-haiku",
    temperature = 0.7,
    max_tokens = 500
})

print(response.result)
```

## 3. Prompt Builder Usage

The prompt builder provides a flexible way to construct complex prompts with different message types:

```lua
local prompt = require("prompt")

-- Create a new prompt builder
local builder = prompt.new()

-- Add system message (instructions for the model)
builder:add_system("You are an expert programmer specializing in Lua.")

-- Add user message (the query or instruction)
builder:add_user("Write a function to calculate Fibonacci numbers recursively.")

-- Add previous assistant message (for conversation context)
builder:add_assistant("Here's a simple recursive implementation of the Fibonacci function:")

-- Add developer message (instructions that won't be shown to end users)
builder:add_developer("Include detailed comments and optimize for readability.")

-- Add a message with custom role and content
builder:add_message(
    prompt.ROLE.USER,
    {
        {
            type = "text",
            text = "How can I make this more efficient?"
        }
    }
)

-- Add a message with an image (for multimodal models)
builder:add_message(
    prompt.ROLE.USER,
    {
        prompt.text("What's in this image?"),
        prompt.image("https://example.com/image.jpg", "A diagram")
    }
)

-- Get all messages from the builder
local messages = builder:get_messages()

-- Use the builder with the LLM library
local response = llm.generate(builder, { model = "gpt-4o" })
```

## 4. Tool Calling

Tools allow the model to call functions to access external data or perform operations.

### Example: Weather Tool

```lua
local llm = require("llm")
local prompt = require("prompt")

-- Create a prompt
local builder = prompt.new()
builder:add_user("What's the weather in Tokyo right now?")

-- Generate with tool access
local response = llm.generate(builder, {
    model = "gpt-4o",
    tool_ids = { "system:weather" },  -- Reference to pre-registered tools
    temperature = 0
})

-- Check if there are tool calls in the response
if response.tool_calls then
    for _, tool_call in ipairs(response.tool_calls) do
        print("Tool: " .. tool_call.name)
        print("Arguments: " .. require("json").encode(tool_call.arguments))
        
        -- Here you would handle the tool call by executing the actual function
        -- and then continue the conversation with the result
    end
end
```

### Example: Custom Tool Schema

```lua
local llm = require("llm")

-- Define a calculator tool schema
local calculator_tool = {
    name = "calculate",
    description = "Perform mathematical calculations",
    schema = {
        type = "object",
        properties = {
            expression = {
                type = "string",
                description = "The mathematical expression to evaluate"
            }
        },
        required = { "expression" }
    }
}

-- Generate with custom tool schema
local response = llm.generate("What is 125 * 16?", {
    model = "claude-3-5-haiku",
    tool_schemas = {
        ["test:calculator"] = calculator_tool
    }
})
```

## 5. Structured Output

Generate JSON-structured responses directly with a defined schema.

**Important Note for OpenAI Models:**
For OpenAI models, all properties must be included in the `required` array, even if they are conceptually optional. For optional parameters, you should use a union type combining the actual type with "null", for example: `type = {"string", "null"}`. Additionally, `additionalProperties = false` is mandatory for OpenAI schemas.

### Example: Weather Schema

```lua
local llm = require("llm")

-- Define a weather information schema
local weather_schema = {
    type = "object",
    properties = {
        temperature = {
            type = "number",
            description = "Temperature in celsius"
        },
        condition = {
            type = "string",
            description = "Weather condition (sunny, cloudy, rainy, etc.)"
        },
        humidity = {
            type = {"number", "null"},
            description = "Humidity percentage (if available)"
        },
    },
    required = { "temperature", "condition", "humidity" },
    additionalProperties = false
}

-- Generate structured output
local response = llm.structured_output(
    weather_schema, 
    "What's the weather like today in New York?", 
    { model = "gpt-4o" }
)

-- Access structured data directly
print("Temperature: " .. response.result.temperature)
print("Condition: " .. response.result.condition)
if response.result.humidity ~= nil then
    print("Humidity: " .. response.result.humidity .. "%")
end
```

## 6. Generating Embeddings

Embeddings represent text as vectors for semantic search and analysis.

### Example: Single Text Embedding

```lua
local llm = require("llm")

-- Generate an embedding for a single text
local text = "The quick brown fox jumps over the lazy dog."
local response = llm.embed(text, {
    model = "text-embedding-3-large"
})

-- Access the embedding vector
print("Vector dimensions: " .. #response.result)
print("First few values: " .. table.concat({
    response.result[1],
    response.result[2],
    response.result[3]
}, ", "))
```

### Example: Multiple Text Embeddings

```lua
local llm = require("llm")

-- Generate embeddings for multiple texts
local texts = {
    "The quick brown fox jumps over the lazy dog.",
    "Machine learning is a subfield of artificial intelligence."
}

local response = llm.embed(texts, {
    model = "text-embedding-3-large",
    dimensions = 1536  -- Optionally specify dimensions
})

-- Access the embedding vectors
print("Number of embeddings: " .. #response.result)
print("Dimensions of first embedding: " .. #response.result[1])
```

## 7. Model Discovery

Find and filter available models based on capabilities.

### Example: Listing Available Models

```lua
local llm = require("llm")

-- Get all available models
local all_models = llm.available_models()
print("Total models: " .. #all_models)

-- Get models with specific capabilities
local generate_models = llm.available_models(llm.CAPABILITY.GENERATE)
local tool_models = llm.available_models(llm.CAPABILITY.TOOL_USE)
local embed_models = llm.available_models(llm.CAPABILITY.EMBED)

print("Models supporting generation: " .. #generate_models)
print("Models supporting tool use: " .. #tool_models)
print("Models supporting embeddings: " .. #embed_models)

-- Get models grouped by provider
local providers = llm.models_by_provider()
for provider_name, provider in pairs(providers) do
    print(provider_name .. ": " .. #provider.models .. " models")
end
```

### Error Types

The LLM library defines the following error types:

```lua
llm.ERROR_TYPE = {
    INVALID_REQUEST = "invalid_request",       -- Malformed request or invalid parameters
    AUTHENTICATION = "authentication_error",   -- Invalid API key or authentication failed
    RATE_LIMIT = "rate_limit_exceeded",        -- Provider rate limit exceeded
    SERVER_ERROR = "server_error",             -- Provider server error
    CONTEXT_LENGTH = "context_length_exceeded", -- Input exceeds model's context length
    CONTENT_FILTER = "content_filter",         -- Content filtered by provider safety systems
    TIMEOUT = "timeout_error",                 -- Request timed out
    MODEL_ERROR = "model_error"                -- Invalid model or model unavailable
}
```

### Finish/Stop Reason Types

Text generation uses these finish reason constants:

```lua
llm.FINISH_REASON = {
    STOP = "stop",               -- Normal completion
    LENGTH = "length",           -- Reached max tokens
    CONTENT_FILTER = "filtered", -- Content filtered by provider
    TOOL_CALL = "tool_call",     -- Model made a tool/function call
    ERROR = "error"              -- Other error
}
```

### Example: Error Handling Methods

```lua
local llm = require("llm")

-- Option 1: Using response.error
local response = llm.generate("Hello", {
    model = "nonexistent-model"
})

if response and response.error then
    print("Error type: " .. response.error)
    print("Error message: " .. response.error_message)
    
    -- Handle specific error types
    if response.error == llm.ERROR_TYPE.MODEL_ERROR then
        print("Invalid model specified")
    elseif response.error == llm.ERROR_TYPE.AUTHENTICATION then
        print("Authentication failed - check API key")
    elseif response.error == llm.ERROR_TYPE.CONTEXT_LENGTH then
        print("Input is too long for this model")
    end
end

-- Option 2: Using the second return value
local response, err = llm.generate("Hello", {
    model = "nonexistent-model"
})

if err then
    print("Error: " .. err)
else
    print(response.result)
end
```

## 9. Comprehensive Examples

### Complete Conversation Flow with Tools

This example demonstrates a complete conversation flow with tool calling:

```lua
local llm = require("llm")
local prompt = require("prompt")

-- Define a weather tool schema
local weather_tool = {
    name = "get_weather",
    description = "Get weather information for a location",
    schema = {
        type = "object",
        properties = {
            location = {
                type = "string",
                description = "The city or location"
            },
            units = {
                type = "string",
                enum = { "celsius", "fahrenheit" },
                default = "celsius"
            }
        },
        required = { "location" }
    }
}

-- Start a conversation
local builder = prompt.new()
builder:add_system("You are a helpful assistant that can answer questions and use tools.")
builder:add_user("What's the weather like in Paris today?")

-- First LLM call - expect a tool call
local response = llm.generate(builder, {
    model = "gpt-4o",
    tool_schemas = {
        ["weather:current"] = weather_tool
    }
})

-- Check for tool calls
if response.tool_calls and #response.tool_calls > 0 then
    local tool_call = response.tool_calls[1]
    
    -- Simulate executing the tool
    local tool_result = {
        temperature = 22,
        condition = "sunny",
        humidity = 65,
        wind_speed = 10
    }
    
    -- Add the tool call and result to the conversation
    builder:add_function_call(
        tool_call.name,
        tool_call.arguments,
        tool_call.id
    )
    
    builder:add_function_result(
        tool_call.name, 
        require("json").encode(tool_result),
        tool_call.id
    )
    
    -- Continue the conversation with the tool result
    local final_response = llm.generate(builder, {
        model = "gpt-4o"
    })
    
    print("Final response: " .. final_response.result)
end
```

### Using Different Model Capabilities

```lua
local llm = require("llm")
local prompt = require("prompt")

-- Create a prompt that requires reasoning
local builder = prompt.new()
builder:add_user("Solve this step by step: If a train travels at 60 mph for 2.5 hours, then slows down to 40 mph for 1.5 hours, what is the total distance traveled?")

-- Use Claude 3.7 with thinking capabilities
local response = llm.generate(builder, {
    model = "claude-3-7-sonnet",
    thinking_effort = 80,  -- High thinking effort (0-100)
    temperature = 0        -- Deterministic output
})

-- Access thinking process if available
if response.thinking then
    print("Thinking process: " .. response.thinking)
end

print("Answer: " .. response.result)

-- Token usage breakdown
print("Prompt tokens: " .. response.tokens.prompt_tokens)
print("Completion tokens: " .. response.tokens.completion_tokens)
print("Thinking tokens: " .. (response.tokens.thinking_tokens or 0))
print("Total tokens: " .. response.tokens.total_tokens)
```

### Using Local Models

```lua
local llm = require("llm")

-- Generate text using a locally hosted model
local response = llm.generate("Explain quantum computing in simple terms", {
    model = "local-QwQ-32B-Q4_K_M",  -- This model runs locally via LM Studio
    provider_options = {  -- Override default provider options if needed
        base_url = "http://localhost:5000/v1",  -- Custom endpoint
        api_key_env = "LOCAL_API_KEY"           -- Different API key variable
    }
})

print(response.result)
```

## 10. Input and Output Format Reference

### Generate Function Input Format

```lua
{
    -- Core parameters
    model = "claude-3-7-sonnet",          -- Required: The model to use
    
    -- Content can be:
    -- 1. A string prompt
    -- 2. A prompt builder object
    -- 3. A table of messages
    -- 4. Any object that has a get_messages() function
    
    -- Thinking capabilities (for models with thinking support)
    thinking_effort = 0,                  -- Optional: 0-100, for models with thinking capability
    
    -- Tool configuration (for tool calling only)
    tool_ids = {"system:weather", "tools:calculator"}, -- Optional: List of tool IDs to use
    tool_schemas = { ... },               -- Optional: Tool definitions matching tool_resolver format
    tool_call = "auto",                   -- Optional: "auto", "any", tool-name (forced)
    
    -- Streaming configuration
    stream = {                            -- Optional: For streaming responses
        reply_to = "process-id",          -- Required for streaming: Process ID to send chunks to
        topic = "llm_response",           -- Optional: Topic name for streaming messages
    },

    -- Provider override options (primarily for local models)
    provider_options = {                  -- Optional: Override model provider settings
        base_url = "http://localhost:1234/v1",  -- API endpoint for local models
        api_key_env = "OPENAI_API_KEY",         -- Environment variable for API key
        -- Any other provider-specific options
    },
    
    -- Generation parameters (model specific)
    temperature = 0.7,                    -- Optional: Controls randomness (0-1)
    top_p = 0.9,                          -- Optional: Nucleus sampling parameter
    top_k = 40,                           -- Optional: Top-k filtering
    max_tokens = 1024,                    -- Optional: Maximum tokens to generate
    -- Other provider-specific options
    
    timeout = 120                         -- Optional: Request timeout in seconds (default: 120)
}
```

### Generate Function Output Format

```lua
{
    -- Success case
    result = "Generated text response",    -- String: The generated text
    
    -- Tool calls (if the model made tool calls)
    tool_calls = {                         -- Table: Array of tool calls (if any)
        {
            id = "call_123",               -- String: Unique ID for this tool call
            name = "get_weather",          -- String: Name of the tool to call
            arguments = {                  -- Table: Arguments for the tool
                location = "New York",
                units = "celsius"
            }
        }
    },
    
    -- Token usage information
    tokens = {
        prompt_tokens = 56,                -- Number: Tokens used in the prompt
        completion_tokens = 142,           -- Number: Tokens generated in the response
        thinking_tokens = 25,              -- Number: Tokens used for reasoning (if applicable)
        cache_read_tokens = 0,             -- Number: Tokens read from cache
        cache_write_tokens = 0,            -- Number: Tokens written to cache
        total_tokens = 223                 -- Number: Total tokens used
    },
    
    -- Additional information
    metadata = {                           -- Table: Provider-specific metadata
        request_id = "req_123abc",
        processing_ms = 350,
        -- Other provider-specific metadata
    },
    
    -- Usage record
    usage_record = {                       -- Table: Usage tracking information
        user_id = "user123",
        model_id = "claude-3-7-sonnet",
        prompt_tokens = 56,
        completion_tokens = 142,
        -- Additional usage details
    },
    
    finish_reason = "stop",                -- String: Why generation stopped (stop, length, content_filter, tool_call)
    
    -- Error case (mutually exclusive with success case)
    error = "model_error",                 -- String: Error type constant from llm.ERROR_TYPE
    error_message = "Model not found",     -- String: Human-readable error message
}
```

### Embeddings Function Input Format

```lua
{
    -- Required parameters
    model = "text-embedding-3-large",      -- String: The embedding model to use
    input = "Text to embed",               -- String, Array of strings, or Table with string values    
    
    dimensions = 1536,                     -- Number: Dimensions for the embedding output (model-specific)
    
    timeout = 60,                           -- Number: Request timeout in seconds (default: 60)
    
    -- Provider override options (if needed)
    provider_options = {                  -- Optional: Override model provider settings
        base_url = "http://localhost:1234/v1",
        api_key_env = "OPENAI_API_KEY",
    },
}
```

### Embeddings Function Output Format

```lua
{
    -- Success case (for both single input and multiple inputs)
    result = {                             -- Float array or array of float arrays
        -- For single input: A vector of floats
        [1] = 0.0023,
        [2] = -0.0075,
        -- ... more dimensions
        
        -- For multiple inputs: An array of vectors
        -- [1] = {0.0023, -0.0075, ...},
        -- [2] = {0.0118, 0.0240, ...},
    },
    
    -- Token usage information
    tokens = {
        prompt_tokens = 8,                 -- Number: Tokens used for the input text
        total_tokens = 8                   -- Number: Equal to prompt_tokens for embeddings
    },
    
    -- Additional metadata (if provided by the API)
    metadata = {
        request_id = "req_abc123",         -- String: Provider-specific request identifier
        processing_ms = 45,                -- Number: Processing time in milliseconds
    },
    
    -- Error case (mutually exclusive with success case)
    error = "model_error",                 -- String: Error type constant from llm.ERROR_TYPE
    error_message = "Model not found"      -- String: Human-readable error message
}
```

## 11. Config File Example

The LLM models are defined in a YAML configuration file. Here's an example of how a model is configured:

```yaml
entries:
  - name: claude-3-7-sonnet
    kind: registry.entry
    meta:
      name: claude-3-7-sonnet
      type: llm.model
      title: Claude 3.7 Sonnet
      comment: Anthropic's most intelligent model with extended thinking capabilities
      capabilities:
        - tool_use
        - vision
        - thinking
        - caching
        - generate
    max_tokens: 200000
    handlers:
      call_tools: wippy.llm.claude:tool_calling
      generate: wippy.llm.claude:text_generation
      structured_output: wippy.llm.claude:structured_output
    output_tokens: 8192
    pricing:
      input: 3
      output: 15
    provider_model: claude-3-7-sonnet-20250219
    
  - name: local-QwQ-32B-Q4_K_M
    kind: registry.entry
    meta:
      name: local-QwQ-32B-Q4_K_M
      type: llm.model
      title: 'Local: QwQ-32B'
      comment: Locally hosted LM Studio model (QwQ-32B, 32 billion parameter model)
      capabilities:
        - generate
        - tool_use
    max_tokens: 4096
    handlers:
      call_tools: wippy.llm.openai:tool_calling
      generate: wippy.llm.openai:text_generation
      structured_output: wippy.llm.openai:structured_output
    output_tokens: 4096
    pricing:
      cached_input: 0
      input: 0
      output: 0
    provider_model: qwq-32b
    provider_options:
      base_url: http://localhost:1234/v1
      api_key_env: OPENAI_API_KEY
```

For local models, the `provider_options` field is particularly important as it specifies how to connect to the locally running model server.
```
###  Path: `\.wippy\wippy\migration@01984114-e585-7da1-b6ab-ea45ca51ddc6\module-migration-0.0.10/README.md`

```md
<p align="center">
    <a href="https://wippy.ai" target="_blank">
        <picture>
            <source media="(prefers-color-scheme: dark)" srcset="https://github.com/wippyai/.github/blob/main/logo/wippy-text-dark.svg?raw=true">
            <img width="30%" align="center" src="https://github.com/wippyai/.github/blob/main/logo/wippy-text-light.svg?raw=true" alt="Wippy logo">
        </picture>
    </a>
</p>
<h1 align="center">Migration Module</h1>
<div align="center">

[![Latest Release](https://img.shields.io/github/v/release/wippyai/module-migration?style=flat-square)][releases-page]
[![License](https://img.shields.io/github/license/wippyai/module-migration?style=flat-square)](LICENSE)
[![Documentation](https://img.shields.io/badge/Wippy-Documentation-brightgreen.svg?style=flat-square)][wippy-documentation]

</div>

> [!NOTE]
> This repository is read-only.
> The code is generated from the [wippyai/framework][wippy-framework] repository.


The migration module provides a complete database schema management system for Wippy applications. It handles creating, executing, and tracking database migrations with support for multiple database engines and rollback capabilities.

The module consists of several components:
- **Core DSL** - Domain-specific language for defining migrations with `migration()`, `database()`, `up()`, and `down()` functions
- **Repository** - Tracks applied migrations in a `_migrations` table with timestamps and descriptions
- **Registry** - Discovers migration files from the registry system based on database targets and tags
- **Runner** - High-level API for executing pending migrations, rolling back changes, and checking status
- **Migration API** - Main interface for running individual migration definitions with transaction support

Key features include:
- Transaction-based execution ensures migrations are applied atomically
- Cross-database support for PostgreSQL, SQLite, and MySQL with engine-specific implementations
- Automatic migration tracking and duplicate detection
- Forward and backward migration support with rollback capabilities
- Registry integration for discovering migrations by target database and tags
- Isolated execution environment with proper error handling and cleanup

The module is used by the bootloader during application startup and can be used programmatically for database schema management tasks.


[wippy-documentation]: https://docs.wippy.ai
[releases-page]: https://github.com/wippyai/module-migration/releases
[wippy-framework]: https://github.com/wippyai/framework

```
###  Path: `\.wippy\wippy\migration@01984114-e585-7da1-b6ab-ea45ca51ddc6\module-migration-0.0.10\docs/migration.spec.md`

```md
# Database Migration Guide for AI Systems

## Overview

This guide outlines the best practices for creating and managing database migrations in a structured, reliable way. As
an AI system tasked with writing database migrations, following these patterns will ensure consistent, maintainable, and
reversible database schema changes.

## Migration Architecture

The migration system is built on several core components:

1. **Migration Core**: Provides the DSL (Domain-Specific Language) for defining migrations
2. **Migration Repository**: Tracks which migrations have been applied in the database
3. **Migration Runner**: Handles discovery and execution of migrations
4. **SQL Module**: Provides the underlying database access layer

## Migration Structure

### Core Components

Each migration consists of:

1. **Description**: A concise, meaningful description of what the migration does
2. **Database Type**: The specific database engine (SQLite, PostgreSQL, MySQL)
3. **Up Migration**: Forward operation that applies the schema change
4. **Down Migration**: Rollback operation that reverts the schema change
5. **Post-Migration Tasks** (optional): Additional operations after the main migration

### Migration Template

```lua
local function define_migration()
    migration("Description of what this migration does", function()
        -- Define database-specific implementation
        database("sqlite", function()
            -- Define forward migration
            up(function(db)
                -- SQL or code to apply changes
                -- The `db` parameter is a transaction object, not a connection
                return db:execute([[
                    CREATE TABLE example (
                        id INTEGER PRIMARY KEY,
                        name TEXT NOT NULL
                    )
                ]])
            end)
            
            -- Define rollback
            down(function(db)
                -- SQL or code to revert changes
                db:execute("DROP TABLE IF EXISTS example")
                
                
            end)
            
            -- Optional post-migration tasks
            after(function(db)
                -- Additional operations after successful migration
                -- The `db` parameter is the same transaction object
            end)
        end)
        
        -- You can define implementations for multiple database types
        database("postgres", function()
            -- PostgreSQL-specific implementation
        end)
    end)
end

-- Return the migration function
return require("migration").define(define_migration)
```

## Understanding the SQL Transaction Interface

In migration functions (`up`, `down`, and `after`), the `db` parameter is a **transaction object**, not a direct
database connection. This is crucial to understand as:

1. The transaction automatically rolls back if any error occurs
2. You must return an error explicitly to trigger a rollback
3. All operations in the migration run in a single transaction

### Key Transaction Methods

```lua
-- Execute a SQL query that returns rows
local rows, err = db:query(sql_query[, params])
-- Parameters:
--   sql_query (string): SQL query to execute (SELECT, etc.)
--   params (table, optional): Array of parameter values to bind
-- Returns on success: table of result rows, nil
-- Returns on error: nil, error message

-- Execute a SQL statement that modifies data
local result, err = db:execute(sql_statement[, params])
-- Parameters:
--   sql_statement (string): SQL statement (CREATE, ALTER, INSERT, etc.)
--   params (table, optional): Array of parameter values to bind
-- Returns on success: result table, nil
--   result.rows_affected: Number of rows affected
--   result.last_insert_id: Last insert ID (if available)
-- Returns on error: nil, error message

-- Prepare a SQL statement
local stmt, err = db:prepare(sql_query)
-- Parameters: sql_query (string) - SQL query to prepare
-- Returns on success: statement object, nil
-- Returns on error: nil, error message
```

### Binding Parameters

Always use parameterized queries to prevent SQL injection:

```lua
-- CORRECT: Using parameters (question mark placeholders)
db:execute("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT)")
db:execute("INSERT INTO users (name) VALUES (?)", {"John"})

-- INCORRECT: String concatenation (vulnerable to SQL injection)
local name = "John"
db:execute("INSERT INTO users (name) VALUES ('" .. name .. "')")
```

Parameter binding works like an ordered array:

```lua
-- The parameters array maps to the question marks in order
db:execute("INSERT INTO users (name, email, age) VALUES (?, ?, ?)", 
           {"John", "john@example.com", 30})
```

## Best Practices

### 1. Descriptive Naming

Use clear, descriptive names that indicate exactly what the migration does:

```lua
migration("Create users table with authentication fields", function()
    -- Migration code
end)
```

### 2. Atomic Changes

Each migration should perform a single logical operation:

✅ **Good**: Create a table, Add a column, Create an index  
❌ **Avoid**: Multiple unrelated schema changes in one migration

### 3. Complete Rollbacks

Always provide a thorough `down` function that fully reverses the migration:

```lua
up(function(db)
    db:execute("ALTER TABLE users ADD COLUMN email TEXT")
end)

down(function(db)
    db:execute("ALTER TABLE users DROP COLUMN email")
end)
```

### 4. Transaction Safety

All migrations run in transactions, which means:

- All changes in a migration succeed or fail together
- Some DDL operations may implicitly commit in certain databases
- Return errors explicitly to trigger a rollback:

```lua
up(function(db)
    local result, err = db:execute("CREATE TABLE users (...)")
    if err then
         error(err)
    end
    
    result, err = db:execute("CREATE INDEX idx_user_email ON users(email)")
    if err then
          error(err)
    end
end)
```

### 5. Database-Specific Code

Provide separate implementations for each database type:

```lua
database("sqlite", function()
    up(function(db)
        -- SQLite implementation
        db:execute("CREATE TABLE users (id INTEGER PRIMARY KEY, ...)")
    end)
end)

database("postgres", function()
    up(function(db)
        -- PostgreSQL implementation
        db:execute("CREATE TABLE users (id SERIAL PRIMARY KEY, ...)")
    end)
end)
```

### 6. Error Handling

Return errors clearly for better diagnostics:

```lua
up(function(db)
    local success, err = db:execute([[
        CREATE TABLE users (
            id INTEGER PRIMARY KEY,
            username TEXT NOT NULL UNIQUE
        )
    ]])
    
    if err then
          error(err)
    end
end)
```

### 7. Idempotent Migrations

When possible, make migrations that can be applied multiple times without error:

```lua
up(function(db)
    db:execute("CREATE TABLE IF NOT EXISTS users (...)")
end)
```

## Common Migration Patterns

### Creating Tables

```lua
up(function(db)
    db:execute([[
        CREATE TABLE products (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            price REAL NOT NULL,
            created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
    ]])
end)

down(function(db)
    db:execute("DROP TABLE IF EXISTS products")
end)
```

### Adding Columns

```lua
up(function(db)
    db:execute("ALTER TABLE products ADD COLUMN description TEXT")
end)

down(function(db)
    -- SQLite doesn't support DROP COLUMN directly
    -- For SQLite, you might need a more complex migration
    -- For other databases:
    db:execute("ALTER TABLE products DROP COLUMN description")
end)
```

### Creating Indexes

```lua
up(function(db)
     db:execute("CREATE INDEX idx_products_name ON products(name)")
end)

down(function(db)
     db:execute("DROP INDEX IF EXISTS idx_products_name")
end)
```

### Seeding Data

```lua
up(function(db)
    -- Insert multiple rows
     db:execute([[
        INSERT INTO roles (name) VALUES 
        ('admin'), ('user'), ('guest')
    ]])
end)

down(function(db)
     db:execute("DELETE FROM roles WHERE name IN ('admin', 'user', 'guest')")
end)
```

### Using Prepared Statements

For multiple similar operations:

```lua
up(function(db)
    -- Create prepared statement
    local stmt, err = db:prepare("INSERT INTO users (name, email) VALUES (?, ?)")
    if err then
          error(err)
    end
    
    -- Execute for multiple rows
    local users = {
        {"Alice", "alice@example.com"},
        {"Bob", "bob@example.com"},
        {"Charlie", "charlie@example.com"}
    }
    
    for _, user in ipairs(users) do
        local result, err = stmt:execute(user)
        if err then
              error(err)
        end
    end
end)
```

### Complex Schema Changes

For SQLite, which has limited ALTER TABLE support:

```lua
up(function(db)
    -- Start transaction (already in a transaction, but shown for clarity)
    
    -- 1. Create temporary table with new schema
    local result, err = db:execute([[
        CREATE TABLE users_new (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT NOT NULL,  -- New column
            created_at INTEGER NOT NULL
        )
    ]])
    if err then   error(err) end
    
    -- 2. Copy data from old table to new table
    result, err = db:execute([[
        INSERT INTO users_new (id, name, created_at)
        SELECT id, name, created_at FROM users
    ]])
    if err then   error(err) end
    
    -- 3. Drop old table
    result, err = db:execute("DROP TABLE users")
    if err then   error(err) end
    
    -- 4. Rename new table to old table name
    result, err = db:execute("ALTER TABLE users_new RENAME TO users")
    if err then   error(err) end
    
    return true
end)
```

## Testing Migrations

Before finalizing any migration:

1. Test the `up` migration to ensure it applies correctly
2. Test the `down` migration to verify it properly rolls back changes
3. Verify that running `up` followed by `down` returns the database to its original state
4. Check that running `up` twice (with proper error handling) doesn't break the system

## Troubleshooting

Common issues to watch for:

- **Syntax errors**: Ensure SQL is compatible with the target database version
- **Missing dependencies**: Make sure referenced tables/columns exist
- **Constraint violations**: Check if data meets new constraints
- **Transaction limitations**: Be aware of operations that can't be in transactions
- **Permission issues**: Verify the database user has appropriate permissions

## Database-Specific Considerations

### SQLite

- Limited ALTER TABLE support (can't drop columns directly)
- INTEGER PRIMARY KEY is autoincrement
- Transaction behavior differs from other databases

### PostgreSQL

- Use SERIAL for auto-incrementing integers
- Has rich constraint and index options
- Supports schema namespaces

### MySQL/MariaDB

- InnoDB engine needed for transactions
- AUTO_INCREMENT requires PRIMARY KEY
- Case sensitivity depends on collation

By following these guidelines, you'll create robust, maintainable database migrations that can be confidently applied
and rolled back when needed.
```
###  Path: `\.wippy\wippy\security@01978c92-7d02-7b4a-95df-55b57cfe80b7\module-security-0.0.7/README.md`

```md
<p align="center">
    <a href="https://wippy.ai" target="_blank">
        <picture>
            <source media="(prefers-color-scheme: dark)" srcset="https://github.com/wippyai/.github/blob/main/logo/wippy-text-dark.svg?raw=true">
            <img width="30%" align="center" src="https://github.com/wippyai/.github/blob/main/logo/wippy-text-light.svg?raw=true" alt="Wippy logo">
        </picture>
    </a>
</p>
<h1 align="center">Security Module</h1>
<div align="center">

[![Latest Release](https://img.shields.io/github/v/release/wippyai/module-security?style=flat-square)][releases-page]
[![License](https://img.shields.io/github/license/wippyai/module-security?style=flat-square)](LICENSE)
[![Documentation](https://img.shields.io/badge/Wippy-Documentation-brightgreen.svg?style=flat-square)][wippy-documentation]

</div>

> [!NOTE]
> This repository is read-only.
> The code is generated from the [wippyai/framework][wippy-framework] repository.

[wippy-documentation]: https://docs.wippy.ai
[releases-page]: https://github.com/wippyai/module-security/releases
[wippy-framework]: https://github.com/wippyai/framework

```
###  Path: `\.wippy\wippy\terminal@01978c92-9604-7b59-a66f-00ba24eb67d9\module-terminal-0.0.7/README.md`

```md
<p align="center">
    <a href="https://wippy.ai" target="_blank">
        <picture>
            <source media="(prefers-color-scheme: dark)" srcset="https://github.com/wippyai/.github/blob/main/logo/wippy-text-dark.svg?raw=true">
            <img width="30%" align="center" src="https://github.com/wippyai/.github/blob/main/logo/wippy-text-light.svg?raw=true" alt="Wippy logo">
        </picture>
    </a>
</p>
<h1 align="center">Terminal Module</h1>
<div align="center">

[![Latest Release](https://img.shields.io/github/v/release/wippyai/module-terminal?style=flat-square)][releases-page]
[![License](https://img.shields.io/github/license/wippyai/module-terminal?style=flat-square)](LICENSE)
[![Documentation](https://img.shields.io/badge/Wippy-Documentation-brightgreen.svg?style=flat-square)][wippy-documentation]

</div>

> [!NOTE]
> This repository is read-only.
> The code is generated from the [wippyai/framework][wippy-framework] repository.

[wippy-documentation]: https://docs.wippy.ai
[releases-page]: https://github.com/wippyai/module-terminal/releases
[wippy-framework]: https://github.com/wippyai/framework

```
###  Path: `\.wippy\wippy\test@0197e530-927f-75f5-995c-b6f5e0dd32f9\module-test-0.0.8/README.md`

```md
<p align="center">
    <a href="https://wippy.ai" target="_blank">
        <picture>
            <source media="(prefers-color-scheme: dark)" srcset="https://github.com/wippyai/.github/blob/main/logo/wippy-text-dark.svg?raw=true">
            <img width="30%" align="center" src="https://github.com/wippyai/.github/blob/main/logo/wippy-text-light.svg?raw=true" alt="Wippy logo">
        </picture>
    </a>
</p>
<h1 align="center">Test Module</h1>
<div align="center">

[![Latest Release](https://img.shields.io/github/v/release/wippyai/module-test?style=flat-square)][releases-page]
[![License](https://img.shields.io/github/license/wippyai/module-test?style=flat-square)](LICENSE)
[![Documentation](https://img.shields.io/badge/Wippy-Documentation-brightgreen.svg?style=flat-square)][wippy-documentation]

</div>

> [!NOTE]
> This repository is read-only.
> The code is generated from the [wippyai/framework][wippy-framework] repository.

[wippy-documentation]: https://docs.wippy.ai
[releases-page]: https://github.com/wippyai/module-test/releases
[wippy-framework]: https://github.com/wippyai/framework

```
###  Path: `\.wippy\wippy\test@0197e530-927f-75f5-995c-b6f5e0dd32f9\module-test-0.0.8\docs/test.spec.md`

```md
# Lua Test Framework Documentation

## Overview

This test framework provides a BDD-style testing solution for Lua applications. It includes support for test suites,
individual test cases, various assertion types, lifecycle hooks, and a powerful mocking system.

Every test must be a valid function, read appropriate documentation.

## Getting Started

### Basic Test Structure

```lua
-- Import the test framework
local test = require("test")

-- Define your test cases
local function define_tests()
    describe("My Test Suite", function()
        it("should perform a basic test", function()
            local result = 1 + 1
            expect(result).to_equal(2)
        end)
        
        it("should handle another case", function()
            expect("hello").to_be_type("string")
        end)
    end)
end

-- Run the tests
return test.run_cases(define_tests)
```

### Running Tests

To run tests, call `test.run_cases(define_tests_fn)` with a function that defines your tests. This returns a function
that can be called with options:

```lua
local runner = test.run_cases(define_tests)
local results = runner({
    pid = process.pid,  -- Process ID for messaging
    ref_id = "my-test", -- Optional reference ID
    topic = "test:update" -- Optional custom topic
})
```

## Writing Tests

### Test Suites and Cases

```lua
describe("Suite Name", function()
    -- Test cases go here
    it("should do something", function()
        -- Test logic
    end)
    
    it("should do something else", function()
        -- More test logic
    end)
    
    -- Skip a test
    it_skip("not ready yet", function()
        -- This test will be skipped
    end)
end)
```

### Assertions

The framework provides many assertion methods through the `expect` function:

```lua
-- Basic equality
expect(value).to_equal(expected)
expect(value).not_to_equal(unexpected)

-- Truth testing
expect(value).to_be_true()
expect(value).to_be_false()

-- Nil checks
expect(value).to_be_nil()
expect(value).not_to_be_nil()

-- Type checking
expect(value).to_be_type("string")

-- String pattern matching
expect("test string").to_match("^test")

-- Table assertions
expect(table).to_contain(expected_value)
expect(table).to_have_key(key_name)

-- Error message checking
local response = function_that_returns_error()
expect(response.error_message).to_contain("expected error text")
```

## Lifecycle Hooks

You can define hooks that run before or after tests:

```lua
describe("Suite with hooks", function()
    before_all(function()
        -- Runs once before all tests in this suite
        setup_database()
    end)
    
    after_all(function()
        -- Runs once after all tests in this suite
        cleanup_database()
    end)
    
    before_each(function()
        -- Runs before each test
        reset_state()
    end)
    
    after_each(function()
        -- Runs after each test
        clear_cache()
    end)
    
    it("test with hooks", function()
        -- Test code
    end)
end)
```

## Mocking System

The framework includes a powerful mocking system for replacing functions during tests.

### Basic Mocking

```lua
-- Mock a function on an object
mock(object, "method_name", function(...)
    -- Replacement implementation
    return mock_result
end)

-- Mock using a string path (for global objects)
mock("process.send", function(pid, topic, payload)
    -- Replacement implementation
    return true
end)

-- Restore a specific mock
restore_mock(object, "method_name")
-- Or by string path
restore_mock("process.send")

-- Restore all mocks (done automatically at the end of each test)
restore_all_mocks()
```

### Tracking Mock Calls

A common pattern is to track calls to a mocked function:

```lua
it("should call the right function", function()
    local calls = {}
    
    mock(object, "method", function(arg1, arg2)
        table.insert(calls, {arg1, arg2})
        return true
    end)
    
    -- Call code that should use the mocked function
    some_function()
    
    -- Verify the mock was called with expected arguments
    expect(#calls).to_equal(1)
    expect(calls[1][1]).to_equal("expected_arg1")
end)
```

## Effective Debugging Strategies

### Troubleshooting Failing Tests

When tests fail, use these strategies to diagnose the issue:

```lua
it("should work correctly", function()
    -- Add debug prints with descriptive labels
    print("DEBUG: Starting test 'should work correctly'")
    
    -- Log important state information
    print("DEBUG: Initial state:", json.encode(some_state))
    
    -- Track function execution
    local original_func = module.function_name
    mock(module, "function_name", function(...)
        print("DEBUG: function_name called with args:", json.encode({...}))
        return original_func(...)
    end)
    
    -- Log assertions before making them
    local result = complex_operation()
    print("DEBUG: Operation result:", json.encode(result))
    expect(result.status).to_equal("success")
})
```

### Isolating Components

When testing complex modules, isolate the component under test:

```lua
it("should validate inputs correctly", function()
    -- Mock dependencies to isolate the component being tested
    mock(dependency, "validate", function() return true end)
    mock(logger, "log", function() end)
    
    -- Now the test focuses only on the target component's logic
    local result = component.process_input("test")
    expect(result.success).to_be_true()
end)
```

### Progressive Mocking

For complex test scenarios, apply mocks progressively:

```lua
it("should handle a complex workflow", function()
    -- First, test with minimal mocking
    local result1 = workflow.start("task")
    print("DEBUG: Initial result:", json.encode(result1))
    
    -- If failing, add more mocks to isolate the issue
    mock(database, "query", function() return {row1={}, row2={}} end)
    local result2 = workflow.start("task")
    print("DEBUG: Result with DB mock:", json.encode(result2))
    
    -- Continue adding mocks until the failure point is identified
    mock(api_client, "request", function() return {status=200, data={}} end)
    local result3 = workflow.start("task")
    print("DEBUG: Result with DB and API mocks:", json.encode(result3))
})
```

## Advanced Mocking Techniques

### Mocking Module Exports

When testing modules that export functions, use this pattern:

```lua
-- Module structure designed for testability
local my_module = {}

function my_module.validate_data(data)
    -- Validation logic
end

function my_module.process_data(data)
    if not my_module.validate_data(data) then
        return nil, "Invalid data"
    end
    -- Processing logic
end

return my_module

-- In tests:
it("should process data without validation", function()
    -- Mock the validation function to always return true
    mock(my_module, "validate_data", function() return true end)
    
    -- Now we can test process_data without validation interference
    local result = my_module.process_data({invalid_data=true})
    expect(result).not_to_be_nil()
})
```

### Mocking Internal Functions

To mock internal functions during tests:

```lua
-- Module with internal functions
local function _private_function(arg)
    -- Internal logic
end

local module = {}
function module.public_function(arg)
    return _private_function(arg)
end

-- Expose private functions for testing
if _ENV.TEST_MODE then
    module._private_function = _private_function
end

return module

-- In tests:
local TEST_MODE = true
local module = require("module")

it("should allow mocking internal functions", function()
    mock(module, "_private_function", function() return "mocked" end)
    expect(module.public_function()).to_equal("mocked")
})
```

### Mocking Environment Variables

Test different environment configurations:

```lua
it("should respect environment settings", function()
    local original_get = env.get
    mock(env, "get", function(key)
        if key == "API_TIMEOUT" then
            return "5000"
        end
        return original_get(key)
    end)
    
    expect(client.get_timeout()).to_equal(5000)
})
```

## Test Organization Best Practices

### Grouping Related Tests

Organize tests for better readability and focus:

```lua
describe("User Module", function()
    describe("Authentication", function()
        it("should login valid users", function() end)
        it("should reject invalid credentials", function() end)
    end)
    
    describe("Profile Management", function()
        it("should update user profiles", function() end)
        it("should validate profile data", function() end)
    end)
})
```
```
###  Path: `\.wippy\wippy\usage@0197ef87-b8de-73a6-a83b-6fdecdf9d6e1\module-usage-0.0.9/README.md`

```md
<p align="center">
    <a href="https://wippy.ai" target="_blank">
        <picture>
            <source media="(prefers-color-scheme: dark)" srcset="https://github.com/wippyai/.github/blob/main/logo/wippy-text-dark.svg?raw=true">
            <img width="30%" align="center" src="https://github.com/wippyai/.github/blob/main/logo/wippy-text-light.svg?raw=true" alt="Wippy logo">
        </picture>
    </a>
</p>
<h1 align="center">Usage Module</h1>
<div align="center">

[![Latest Release](https://img.shields.io/github/v/release/wippyai/module-usage?style=flat-square)][releases-page]
[![License](https://img.shields.io/github/license/wippyai/module-usage?style=flat-square)](LICENSE)
[![Documentation](https://img.shields.io/badge/Wippy-Documentation-brightgreen.svg?style=flat-square)][wippy-documentation]

</div>

> [!NOTE]
> This repository is read-only.
> The code is generated from the [wippyai/framework][wippy-framework] repository.

[wippy-documentation]: https://docs.wippy.ai
[releases-page]: https://github.com/wippyai/module-usage/releases
[wippy-framework]: https://github.com/wippyai/framework

```