<p align="center">
    <a href="https://wippy.ai" target="_blank">
        <picture>
            <source media="(prefers-color-scheme: dark)" srcset="https://github.com/wippyai/.github/blob/main/logo/wippy-text-dark.svg?raw=true">
            <img width="30%" align="center" src="https://github.com/wippyai/.github/blob/main/logo/wippy-text-light.svg?raw=true" alt="Wippy logo">
        </picture>
    </a>
</p>
<h1 align="center">Demo application</h1>
<div align="center">

[![License](https://img.shields.io/github/license/wippyai/app?style=flat-square)](LICENSE)
[![Documentation](https://img.shields.io/badge/documentation-online-brightgreen.svg?style=flat-square)][documentation]

</div>

See Wippy in action with our demo application.

[documentation]: https://docs.wippy.ai
[releases-page]: https://github.com/wippyai/app/releases

# Demo Application

This is a demo application showcasing various features of the Wippy Runtime system.

## Overview

The demo application includes:

- **HTTP API endpoints** - Various REST endpoints for system information, file browsing, and utilities
- **Chat system** - A session-based chat system with encryption
- **Snake game** - A terminal-based Snake game using Bubble Tea
- **Process management** - Actor-based process management with lifecycle controls

## Configuration Fixes Applied

The following issues were identified and fixed:

### 1. Missing Dependencies
- **Fixed**: Removed incorrect `wippy.lib` dependency that was trying to fetch a non-existent remote module
- **Fixed**: Added local `bapp` component for Bubble Tea applications
- **Fixed**: Corrected `wippy.test` reference to use proper namespace
- **Fixed**: Added missing `heap` service (in-memory store)

### 2. Namespace Issues
- **Fixed**: Updated snake game to use local `app:bapp` component instead of remote dependency
- **Fixed**: Added proper module dependencies for btea applications

### 3. HTTP Endpoints
- **Fixed**: Uncommented all HTTP endpoints that were disabled
- **Fixed**: Ensured proper router configuration for all endpoints

### 4. Service Dependencies
- **Fixed**: Added proper dependency chain for services
- **Fixed**: Corrected service host references

## Available Endpoints

### System Information
- `GET /api/v1/hello` - Hello World endpoint
- `GET /api/v1/pid` - Get current function PID
- `GET /api/v1/time/local` - Get local system time
- `GET /api/v1/system/env` - Get system environment variables
- `GET /api/v1/registry/dump` - Dump registry contents

### File System
- `GET /api/v1/fs/browse` - Browse filesystem directories

### LLM Integration
- `GET /api/v1/tools/list` - List available LLM tools
- `GET /api/v1/models/list` - List available LLM models

### Chat System
- `POST /api/v1/chat/session` - Create new chat session
- `POST /api/v1/chat/message` - Send message to session

### Utilities
- `GET /api/v1/time/ticker` - Stream timer ticks

## Services

### Core Services
- **gateway** (`:8082`) - Main HTTP gateway
- **api** - API router for v1 endpoints
- **terminal** - Terminal host for Bubble Tea apps
- **processes** - Process execution host
- **heap** - In-memory data store

### Chat Services
- **session_manager.service** - Manages chat sessions
- **session_manager** - Chat session manager process
- **session** - Individual chat session process

### Game Services
- **game.service** - Snake game service
- **game** - Snake game process

## Running the Demo

### Prerequisites
1. **Build the runtime** (if not already built):
   ```bash
   # From the runtime directory
   go build -o bin/runner cmd/runner/main.go
   ```

2. **Start the runtime** with the demo application:
   ```bash
   # From the runtime directory
   ./bin/runner ../demo/app
   ```

### Testing the Application

1. **Test basic endpoints**:
   ```bash
   # Hello World
   curl http://localhost:8082/api/v1/hello
   
   # Get current time
   curl http://localhost:8082/api/v1/time/local
   
   # Get function PID
   curl http://localhost:8082/api/v1/pid
   ```

2. **Test system information**:
   ```bash
   # Get environment variables
   curl http://localhost:8082/api/v1/system/env
   
   # Browse registry
   curl http://localhost:8082/api/v1/registry/dump
   ```

3. **Test LLM integration**:
   ```bash
   # List available tools
   curl http://localhost:8082/api/v1/tools/list
   
   # List available models
   curl http://localhost:8082/api/v1/models/list
   ```

4. **Test chat system**:
   ```bash
   # Create a new session
   curl -X POST http://localhost:8082/api/v1/chat/session
   
   # Send a message (replace SESSION_ID with actual session ID)
   curl -X POST http://localhost:8082/api/v1/chat/message \
     -H "Content-Type: application/json" \
     -d '{"session_id": "SESSION_ID", "message": "Hello!"}'
   ```

5. **Play the Snake game**:
   - The game will start automatically in the terminal
   - Use arrow keys or WASD to move
   - Press 'r' to restart, 'q' to quit

## Architecture

### Namespace Structure
- `app` - Main application namespace
- `app.http.handlers` - HTTP endpoint handlers
- `app.service.chat` - Chat service components
- `app.snake` - Snake game components

### Dependencies
- `wippy.actor` - Actor pattern library
- `wippy.llm` - LLM integration library
- `wippy.test` - Testing framework
- `app.bapp` - Local Bubble Tea wrapper library

### Process Model
The demo uses the actor pattern for process management:
- **Session Manager** - Manages chat session lifecycle
- **Session Processes** - Individual chat sessions
- **Game Process** - Snake game running in terminal

## Troubleshooting

### Common Issues

1. **Port already in use**:
   - Change the port in `app/_index.yaml` under `gateway.addr`

2. **Missing dependencies**:
   - Ensure all wippy components are available in the runtime
   - Check that component versions are compatible

3. **Terminal issues**:
   - Ensure terminal supports Bubble Tea applications
   - Check terminal size requirements for the snake game

4. **Module not found errors**:
   - The demo now uses local components instead of remote dependencies
   - All required components are included in the demo directory

### Validation

The demo configuration has been tested and validated:
- ✅ All YAML files have correct syntax
- ✅ All dependencies are properly resolved
- ✅ All services start successfully
- ✅ All HTTP endpoints are functional

## Development

### Adding New Endpoints

1. Create a new Lua function in `app/http/`
2. Add the function definition to `app/http/_index.yaml`
3. Add the endpoint definition to `app/http/_index.yaml`

### Adding New Services

1. Create a new directory under `app/`
2. Add `_index.yaml` with service configuration
3. Update dependencies in main `app/_index.yaml`

### Testing

The demo includes test endpoints that can be used to verify functionality:
- `GET /api/v1/hello` - Basic connectivity test
- `GET /api/v1/pid` - Process ID test
- `GET /api/v1/time/local` - Time service test
- `GET /api/v1/registry/dump` - Registry access test
