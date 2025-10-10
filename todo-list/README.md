# TODO List Demo

A full-stack TODO list application demonstrating Wippy Runtime capabilities for building RESTful APIs with SQLite database and modern frontend integration.

## What This Demo Shows

This project demonstrates:

- **RESTful API implementation** - Complete CRUD operations with proper HTTP methods
- **SQLite database integration** - Using `db.sql.sqlite` with migrations
- **Frontend integration** - Serving static files with SPA mode
- **HTTP routing** - Setting up API routers with CORS middleware
- **Database migrations** - Automatic schema management on startup

## Features

- Create, read, update, and delete tasks
- Task priorities (low, medium, high)
- Categories and tags
- Due dates with visual indicators
- Filter by status, category, and priority
- Real-time UI updates with HTMX

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/todos` | List all todos (supports filters) |
| `GET` | `/api/v1/todos/:id` | Get single todo |
| `POST` | `/api/v1/todos` | Create new todo |
| `PUT` | `/api/v1/todos/:id` | Update todo |
| `PATCH` | `/api/v1/todos/:id/toggle` | Toggle completion status |
| `DELETE` | `/api/v1/todos/:id` | Delete todo |

### Query Parameters for GET /api/v1/todos
- `completed` - filter by status (0 or 1)
- `category` - filter by category
- `priority` - filter by priority (1-3)

## Project Structure

```
src/
├── _index.yaml              # Main config: HTTP service, routers, database
├── api/                     # API handlers (Lua)
│   ├── _index.yaml          # Endpoint registration
│   ├── get_todos.lua
│   ├── get_todo.lua
│   ├── create_todo.lua
│   ├── update_todo.lua
│   ├── toggle_todo.lua
│   └── delete_todo.lua
├── migrations/              # Database migrations
│   ├── _index.yaml
│   └── 001_create_todos_table.lua
├── deps/                    # Wippy components
│   └── _index.yaml
└── env/                     # Environment configuration
    └── _index.yaml

public/                      # Static frontend files
├── index.html              # Bootstrap 5 + HTMX UI
├── css/
└── js/
```

## Database Schema

```sql
CREATE TABLE todos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT,
    completed INTEGER NOT NULL DEFAULT 0,
    priority INTEGER NOT NULL DEFAULT 1,
    category TEXT,
    due_date INTEGER,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);
```

## Running the Project

```bash
cd todo-list
wippy run
```

Open http://localhost:8080 in your browser.

## Key Configuration

See `src/_index.yaml` for the main configuration:

- **`app:gateway`** - HTTP server on port 8080
- **`app:api`** - API router with `/api/v1/` prefix and CORS
- **`app:db`** - SQLite database (`.wippy/app.db`)
- **`app:frontend`** - Static file serving with SPA mode

The migration runs automatically on startup.

## API Examples

### Create a todo
```bash
curl -X POST http://localhost:8080/api/v1/todos \
  -H "Content-Type: application/json" \
  -d '{"title": "Learn Wippy", "priority": 2}'
```

### Get all active todos
```bash
curl http://localhost:8080/api/v1/todos?completed=0
```

### Toggle completion
```bash
curl -X PATCH http://localhost:8080/api/v1/todos/1/toggle
```