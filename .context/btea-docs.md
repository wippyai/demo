# Btea Documentation
```
// Structure of documents
└── spec/
    └── btea/
        └── cmd.md
        └── help.md
        └── key_binding.md
        └── list.md
        └── msg.md
        └── paginator.md
        └── progress.md
        └── render_util.md
        └── spinner.md
        └── style.md
        └── table.md
        └── text_area.md
        └── text_input.md
        └── viewport.md
        └── zone.md

```
###  Path: `\spec\btea/cmd.md`

```md
# Bubble Tea Commands in Lua

## Overview

This specification defines how Bubble Tea commands are represented and used in Lua. Commands are operations that can be
executed to perform various terminal manipulations and control function. Typically, commands received from updated
models.

## Command Structure

Commands are represented as userdata objects with an `execute()` method. When executed, commands return messages that
can be processed by the application.

## Creating Commands

### Basic Command Creation

Commands are typically accessed through the `btea.commands` table:

```lua
local cmd = btea.commands.clear_screen
```

### Command Composition

Commands can be composed using two primary methods:

1. `btea.batch(commands)`: Executes commands in parallel
2. `btea.sequence(commands)`: Executes commands in sequence

Example:

```lua
local batch_cmd = btea.batch({ 
    btea.commands.clear_screen,
    btea.commands.show_cursor 
})

local seq_cmd = btea.sequence({ 
    btea.commands.enter_alt_screen,
    btea.commands.hide_cursor 
})
```

## Available Commands

### Screen Management

- `clear_screen`: Clears the terminal screen
- `enter_alt_screen`: Switches to alternate screen buffer
- `exit_alt_screen`: Returns to main screen buffer

### Mouse Control

- `enable_mouse_cell_motion`: Enables mouse movement tracking by cell
- `enable_mouse_all_motion`: Enables continuous mouse movement tracking
- `disable_mouse`: Disables all mouse tracking

### Cursor Control

- `hide_cursor`: Makes the cursor invisible
- `show_cursor`: Makes the cursor visible

### Paste Mode

- `enable_bracketed_paste`: Enables bracketed paste mode
- `disable_bracketed_paste`: Disables bracketed paste mode

### Focus Reporting

- `enable_report_focus`: Enables focus event reporting
- `disable_report_focus`: Disables focus event reporting

### Window Management

- `set_window_title(title)`: Sets the terminal window title

```lua
local cmd = btea.commands.set_window_title("My Application")
```

- `window_size`: Requests current window dimensions

### Program Control

- `quit`: Exits the application
- `suspend`: Suspends the application

## Command Execution

Commands can be executed using the `execute()` method:

```lua
local msg = cmd:execute()
```

The execute method returns a message that can be processed by the application. The message structure follows the format
defined in the Messages specification.

## Best Practices

1. **Command Composition**: Use `batch` for parallel operations and `sequence` for ordered operations
2. **Error Handling**: Always check for nil or error returns from command execution
3. **Resource Management**: Commands that enter alternate modes (like alt screen or mouse tracking) should have
   corresponding exit commands
4. **Message Processing**: Handle command messages appropriately in your application's update loop

## Example Usage

```lua
-- Initialize application with multiple commands
local init_cmds = btea.sequence({
    btea.commands.enter_alt_screen,
    btea.commands.hide_cursor,
    btea.commands.enable_mouse_cell_motion,
    btea.commands.set_window_title("My TUI App")
})

-- Cleanup commands for application exit
local cleanup_cmds = btea.sequence({
    btea.commands.show_cursor,
    btea.commands.disable_mouse,
    btea.commands.exit_alt_screen
})

-- Execute commands
local msg = init_cmds:execute()
```

## Integration with Event Loop

Commands are typically processed within an event loop or message handler:

```lua
while true do
    local msg = cmd:execute()
    if msg.type == "update" then
        -- Handle command response
    end
end
```

## Error Handling

1. Commands that fail to execute may return nil or an error message
2. Always validate command composition inputs
3. Handle cleanup commands in a finally block or equivalent

## Command Lifecycle

1. **Creation**: Command is created through btea.commands or composition
2. **Queueing**: Command is optionally queued with other commands
3. **Execution**: Command is executed via execute()
4. **Response**: Message is returned and processed
5. **Cleanup**: Any necessary cleanup commands are executed

## Recommended Command Handling Pattern

The recommended approach for handling commands in a Bubble Tea application is to process them in a separate coroutine.
This pattern provides better separation of concerns and prevents blocking the main application loop.

### Command Processor Setup

```lua
-- Create channels for communication
local cmd_channel = channel.new(128)  -- Buffer size of 128
local done = channel.new()            -- Signal channel for cleanup

-- Command processor coroutine
coroutine.spawn(function()
    while true do
        -- Use channel.select to handle multiple cases
        local result = channel.select {
            cmd_channel:case_receive(), -- Handle incoming commands
            done:case_receive()         -- Handle cleanup signal
        }

        if result.channel == done then
            -- Exit command processor
            break
        else 
            -- Process command from cmd_channel
            local cmd = result.value
            if cmd then
                local msg = cmd:execute()
                if msg then
                    -- Send message upstream if needed
                    upstream.send(msg)
                end
            end
        end
    end
end)

-- Main application loop
while true do
    local task, ok = inbox:receive() -- todo: task channel is subject to change
    if not ok then
        -- Signal command processor to shut down
        done:send(true)
        break
    end

    local msg = task:input()
    if type(msg) == "table" and msg.type == "update" then
        -- Handle input updates
        local cmd = input:update(msg)
        if cmd then
            -- Send command to processor
            cmd_channel:send(cmd)
        end

        -- Complete task
        task:complete("ok")
    end
end

-- Cleanup
done:close()
```

### Key Components:

1. **Command Channel**: A buffered channel for sending commands to the processor
2. **Done Channel**: A signal channel for clean shutdown
3. **Processor Coroutine**: A separate coroutine that handles command execution
4. **Channel Select**: Uses `channel.select` for handling multiple channel cases
5. **Cleanup Handling**: Proper shutdown sequence for the command processor

### Benefits:

1. Non-blocking command execution
2. Clean separation of concerns
3. Proper resource cleanup
4. Scalable command handling
5. Better error isolation

### Example Usage with Batch Commands:

```lua
-- Create a batch of commands
local batch = btea.sequence({ 
    input:focus(),
    btea.commands.set_window_title("My Window")
})

-- Send to command processor
cmd_channel:send(batch)
```

## Notes

- Command execution yields until the operation completes
- Some commands may require specific terminal capabilities
- Window title setting may not work in all terminal emulators
- Always ensure proper channel cleanup on application exit
```
###  Path: `\spec\btea/help.md`

```md
# Bubble Tea Help Component Specification

## Constructor

### btea.help(options: table) -> Help

Creates a new help component for displaying keyboard shortcuts and command documentation.

Options table fields:

- `width` (number, optional): Display width in characters
- `show_all` (boolean, optional): Show full help by default. Default: false
- `short_separator` (string, optional): Separator for short help view. Default: " • "
- `full_separator` (string, optional): Separator for full help view. Default: "    "
- `ellipsis` (string, optional): Truncation indicator. Default: "..."
- `styles` (table, optional): Style configuration containing:
    - `short_key` (Style): Style for keys in short help
    - `short_desc` (Style): Style for descriptions in short help
    - `short_separator` (Style): Style for separator in short help
    - `full_key` (Style): Style for keys in full help
    - `full_desc` (Style): Style for descriptions in full help
    - `full_separator` (Style): Style for separator in full help
    - `ellipsis` (Style): Style for truncation indicator

## Methods

### update(msg: table) -> Command|nil

Updates the help component state based on the received message. Returns a command if state changes, nil otherwise.

Message types supported:

- `window_resize`: Updates width/height
- `key`: Handles keyboard input

### view(keymap: table|KeyMap) -> string

Renders the help component with the provided keymap. The keymap can be either:

- A Lua table implementing the KeyMap interface
- A component that implements the KeyMap interface

### set_width(width: number) -> nil

Sets the display width in characters.

### set_show_all(show: boolean) -> nil

Toggles between short and full help display.

### set_styles(styles: table) -> nil

Sets the styles for help display. The styles table should contain:

- `short_key` (Style)
- `short_desc` (Style)
- `short_separator` (Style)
- `full_key` (Style)
- `full_desc` (Style)
- `full_separator` (Style)
- `ellipsis` (Style)

### set_separators(short_sep: string, full_sep: string) -> nil

Sets the separators for both help views.

- `short_sep`: Separator for short help view
- `full_sep`: Separator for full help view (defaults to "    ")

### set_ellipsis(ellipsis: string) -> nil

Sets the truncation indicator string.

### get_short_help(keymap: table|KeyMap) -> table

Returns an array of key bindings for short help from the provided keymap.

### get_full_help(keymap: table|KeyMap) -> table

Returns an array of binding groups for full help from the provided keymap.

## KeyMap Interface

A keymap can be implemented either as a Lua table or as a component.

### Table Implementation

```lua
{
    -- Return array of key bindings for short help
    short_help = function()
        return {
            binding1,
            binding2,
            -- ...
        }
    end,
    
    -- Return array of binding groups for full help
    full_help = function()
        return {
            {binding1, binding2},  -- First column
            {binding3, binding4},  -- Second column
            -- ...
        }
    end
}
```

Both `short_help` and `full_help` can also be direct tables instead of functions:

```lua
{
    short_help = {binding1, binding2},
    full_help = {
        {binding1, binding2},
        {binding3, binding4}
    }
}
```

### Component Integration

Components like viewport and text_input that implement the KeyMap interface can be passed directly to help methods:

```lua
local viewport = btea.viewport(...)
local help_text = help:view(viewport)
```

## Binding Format

Each binding in the keymap should be created using `btea.bind()`:

```lua
btea.bind({
    keys = {"key1", "key2"},  -- Array of key combinations
    help = {
        key = "display_key",  -- How the key should be displayed in help
        desc = "description"  -- Description of what the key does
    }
})
```

## Example Usage

```lua
-- Create help component with styling
local help = btea.help({
    width = 80,
    styles = {
        short_key = btea.style():foreground("#909090"):bold(),
        short_desc = btea.style():foreground("#B2B2B2"),
        short_separator = btea.style():foreground("#DDDADA"),
    }
})

-- Create keymap
local keymap = {
    bindings = {
        quit = btea.bind({
            keys = {"q", "ctrl+c"},
            help = {key = "q/ctrl+c", desc = "quit"}
        }),
        help = btea.bind({
            keys = {"?"},
            help = {key = "?", desc = "toggle help"}
        })
    },
    
    short_help = function(self)
        return {
            self.bindings.quit,
            self.bindings.help
        }
    end,
    
    full_help = function(self)
        return {
            {self.bindings.quit},  -- First column
            {self.bindings.help}   -- Second column
        }
    end
}

-- Update component
local cmd = help:update(msg)  -- Handle update message
local view = help:view(keymap)  -- Render help text
```
```
###  Path: `\spec\btea/key_binding.md`

```md
# Key Binding in Lua

## Overview

This specification defines how key bindings are represented and manipulated in Lua. Key bindings provide a way to map
keyboard input to actions and help text, with support for key combinations and modifiers.

## Key Binding Creation

Key bindings are created using the `btea.bind` constructor:

```lua
local binding = btea.bind {
    keys = {"up", "k"},           -- Single key or array of keys
    help = {
        key = "↑/k",             -- Display text for keys in help menu
        desc = "move up"         -- Description in help menu
    }
}
```

### Key Specification

Keys can be specified as strings in the following formats:

1. Single characters: `"a"`, `"b"`, `"c"`, etc.
2. Special keys: `"up"`, `"down"`, `"left"`, `"right"`, `"home"`, `"end"`, `"pgup"`, `"pgdown"`, `"tab"`, `"enter"`,
   `"esc"`
3. Control combinations: `"ctrl+c"`, `"ctrl+x"`, etc.
4. Alt combinations: `"alt+a"`, `"alt+b"`, etc.
5. Function keys: `"f1"` through `"f20"`
6. Spaces and special characters: `" "` (space), `"\\"`(backslash)

## Methods

### Enabling/Disabling

```lua
-- Enable or disable the binding
binding:set_enabled(true|false)

-- Check if binding is enabled
local is_enabled = binding:is_enabled()
```

### Help Information

```lua
-- Get help information
local help = binding:help()
-- Returns: { key = "display keys", desc = "description" }
```

### Key Matching

```lua
-- Check if a key message matches this binding
if msg.type == "key" and binding:matches(msg) then
    -- Handle matching key
end
```

## Common Key Combinations

```lua
-- Navigation
local up = btea.bind {
    keys = {"up", "k"},
    help = {key = "↑/k", desc = "up"}
}

-- Control combinations
local save = btea.bind {
    keys = {"ctrl+s"},
    help = {key = "^S", desc = "save"}
}

-- Alt combinations
local word = btea.bind {
    keys = {"alt+right", "alt+f"},
    help = {key = "M-→/f", desc = "word forward"}
}

-- Multiple alternatives
local quit = btea.bind {
    keys = {"q", "ctrl+c"}, 
    help = {key = "q/^C", desc = "quit"}
}
```

## Best Practices

1. **Consistent Help Text**
    - Use `↑` `→` `↓` `←` for arrows
    - Use `^X` for Control-X
    - Use `M-X` for Alt-X
    - Separate alternatives with `/`

2. **Key Selection**
    - Provide intuitive alternatives (e.g., both arrows and vim-style keys)
    - Use standard conventions when possible (ctrl+c for quit, etc.)
    - Consider cross-platform compatibility

3. **Help Descriptions**
    - Keep descriptions short and clear
    - Use consistent verbs (e.g., "move" vs "go")
    - Start with action verbs

## Example Usage

### Basic Binding Usage

```lua
-- Create a binding
local binding = btea.bind {
    keys = {"enter", "ctrl+m"},
    help = {key = "enter", desc = "confirm"}
}

-- Check key messages
function update(msg)
    if msg.type == "key" and binding:matches(msg) then
        -- Handle key press
        return "confirmed"
    end
end
```

### Key Groups

```lua
-- Define related bindings
local keys = {
    up = btea.bind {
        keys = {"up", "k"},
        help = {key = "↑/k", desc = "move up"}
    },
    down = btea.bind {
        keys = {"down", "j"},
        help = {key = "↓/j", desc = "move down"}
    },
    confirm = btea.bind {
        keys = {"enter"},
        help = {key = "enter", desc = "confirm"}
    },
    cancel = btea.bind {
        keys = {"esc"},
        help = {key = "esc", desc = "cancel"}
    }
}

-- Use in update function
function update(msg)
    if msg.type == "key" then
        if keys.up:matches(msg) then
            move_up()
        elseif keys.down:matches(msg) then
            move_down()
        elseif keys.confirm:matches(msg) then
            confirm_action()
        elseif keys.cancel:matches(msg) then
            cancel_action()
        end
    end
end
```

## Notes

- Key bindings are immutable once created
- Disabled bindings will not match any keys
- Help text is optional but recommended
- Keys are case-sensitive
- Order of keys in the keys array doesn't matter for matching
```
###  Path: `\spec\btea/list.md`

```md
# Bubble Tea List Component in Lua

## Overview

The List component provides a scrollable, filterable list of items with keyboard navigation, search functionality, and
customizable styling. It's designed for interactive terminal applications and supports both mouse and keyboard input.

## List Creation

A list is created using the `btea.list` constructor:

```lua
local list = btea.list {
    width = 80,                    -- Width in characters (required)
    height = 24,                   -- Height in characters (required)
    title = "My List",            -- Title text (optional)
    infinite_scrolling = false,    -- Enable infinite scrolling (optional)
    show_title = true,            -- Show the title bar (optional)
    show_filter = true,           -- Show the filter input (optional)
    show_status_bar = true,       -- Show the status bar (optional)
    show_pagination = true,       -- Show pagination dots (optional)
    show_help = true,             -- Show help text (optional)
    filtering_enabled = true,      -- Enable filtering (optional)
    item_name = "item",           -- Singular name for items (optional)
    item_name_plural = "items",   -- Plural name for items (optional)
    status_message_lifetime = 1,   -- Duration in seconds for status messages (optional)
    items = {},                   -- Initial items (optional)
}
```

## Items

Items in the list must implement the following interface:

```lua
local item = {
    -- Required
    filter_value = function(self)
        return "searchable text"  -- Text used for filtering
    end,
    
    -- Optional
    title = function(self)
        return "Item Title"
    end,
    
    description = function(self)
        return "Item Description"
    end
}
```

These can be provided either as:

1. Lua tables with the above functions
2. Userdata objects implementing the required methods

## Methods

### Core Methods

```lua
-- Update list state (returns cmd or nil)
local cmd = list:update(msg)

-- Get current view
local str = list:view()
```

### Item Management

```lua
-- Get all items
local items = list:items()

-- Set all items
local cmd = list:set_items(items_table)

-- Set item at index
local cmd = list:set_item(index, item)

-- Insert item at index
local cmd = list:insert_item(index, item)

-- Remove item at index
list:remove_item(index)

-- Get selected item
local item = list:selected_item()

-- Get highlight matches for item at index
local matches = list:matches_for_item(index)
```

### Navigation

```lua
-- Get cursor position
local pos = list:cursor()

-- Move cursor
list:cursor_up()
list:cursor_down()

-- Page navigation
list:prev_page()
list:next_page()

-- Select specific index
list:select(index)

-- Reset selection
list:reset_selected()
```

### Filtering

```lua
-- Enable/disable filtering
list:set_filtering_enabled(true|false)
local enabled = list:filtering_enabled()

-- Get filter state
local state = list:filter_state()
local value = list:filter_value()
local setting = list:setting_filter()
local filtered = list:is_filtered()

-- Reset filter
list:reset_filter()
```

### Display Control

```lua
-- Set dimensions
list:set_width(width)
list:set_height(height)

-- Get dimensions
local w = list:width()
local h = list:height()

-- Toggle visibility
list:set_show_title(true|false)
list:set_show_filter(true|false)
list:set_show_status_bar(true|false)
list:set_show_pagination(true|false)
list:set_show_help(true|false)

-- Get visibility states
local show = list:show_title()
local show = list:show_filter()
local show = list:show_status_bar()
local show = list:show_pagination()
local show = list:show_help()

-- Configure status bar
list:set_status_bar_item_name(singular, plural)

-- Disable quit shortcuts
list:disable_quit_keybindings()
```

### Spinner Control

```lua
-- Control loading spinner
local cmd = list:start_spinner()
list:stop_spinner()
local cmd = list:toggle_spinner()
```

### Status Messages

```lua
-- Show status message
local cmd = list:new_status_message("Message text")
```

## Styling

The list supports extensive styling through the `styles` configuration option. Available style elements include:

```lua
styles = {
    title_bar = style,                  -- Title bar style
    title = style,                      -- Title text style
    spinner = style,                    -- Loading spinner style
    filter_prompt = style,              -- Filter input prompt style
    filter_cursor = style,              -- Filter input cursor style
    status_bar = style,                 -- Status bar style
    status_empty = style,               -- Empty status style
    status_bar_active_filter = style,   -- Active filter indicator style
    status_bar_filter_count = style,    -- Filter match count style
    no_items = style,                   -- Empty list message style
    pagination = style,                 -- Pagination style
    help = style,                       -- Help text style
    active_pagination_dot = style,      -- Active page indicator style
    inactive_pagination_dot = style,    -- Inactive page indicator style
    arabic_pagination = style,          -- Numeric pagination style
    divider_dot = style,                -- Divider style
}
```

## Keyboard Control

The list supports customizable key bindings through the `keys` configuration option:

```lua
keys = {
    cursor_up = binding,              -- Move selection up
    cursor_down = binding,            -- Move selection down
    prev_page = binding,              -- Previous page
    next_page = binding,              -- Next page
    go_to_start = binding,            -- Go to first item
    go_to_end = binding,              -- Go to last item
    filter = binding,                 -- Start filtering
    clear_filter = binding,           -- Clear current filter
    cancel_while_filtering = binding, -- Cancel filter input
    accept_while_filtering = binding, -- Accept filter input
    show_full_help = binding,         -- Show help view
    close_full_help = binding,        -- Close help view
    quit = binding,                   -- Normal quit
    force_quit = binding,             -- Force quit
}
```

## Custom Delegates

The list supports custom item rendering through a delegate interface:

```lua
delegate = {
    -- Required
    height = function(self)
        return 1  -- Height in rows for each item
    end,
    
    spacing = function(self)
        return 1  -- Spacing between items
    end,
    
    render = function(self, model, index, item)
        return "rendered item"  -- String representation of item
    end,
    
    -- Optional
    update = function(self, msg, model)
        return cmd  -- Handle updates, return command if needed
    end,
    
    short_help = function(self)
        return {binding1, binding2}  -- Return array of key bindings
    end,
    
    full_help = function(self)
        return {{binding1, binding2}}  -- Return array of binding groups
    end
}
```

## Example Usage

### Basic List

```lua
local list = btea.list {
    width = 80,
    height = 24,
    title = "Todo List",
    items = {
        { title = "Task 1", filter_value = "task 1" },
        { title = "Task 2", filter_value = "task 2" },
    }
}

function update(msg)
    local cmd = list:update(msg)
    if cmd then
        return model, cmd
    end
    return model
end

function view()
    return list:view()
end
```

### Custom Styled List

```lua
local list = btea.list {
    width = 80,
    height = 24,
    styles = {
        title = btea.style():bold():foreground("#89B4FA"),
        title_bar = btea.style():background("#1E1E2E"),
        filter_prompt = btea.style():italic():foreground("#94E2D5")
    },
    delegate = {
        height = function() return 2 end,
        spacing = function() return 1 end,
        render = function(self, model, index, item)
            local style = btea.style():padding(0, 1)
            return style:render(item.title)
        end
    }
}
```

## Important Notes

1. The list uses zero-based indexing for consistency with Go implementation
2. All style objects should be created using btea.style()
3. Key bindings should be created using btea.bind
4. Commands returned from update() must be handled by the application
5. Filter functions operate on the filter_value() results from items
6. Status messages automatically expire after the configured lifetime
7. The spinner can be used to indicate background operations
8. Custom delegates must implement all required methods

## Best Practices

1. **Item Management**
    - Keep items lightweight
    - Implement filter_value() efficiently
    - Use appropriate data structures for large lists

2. **Performance**
    - Handle update commands promptly
    - Use appropriate list heights for viewport
    - Consider filtering performance with large datasets

3. **User Experience**
    - Provide clear status messages
    - Use consistent key bindings
    - Implement helpful delegates
    - Show loading states with spinner

4. **Styling**
    - Use consistent color schemes
    - Consider terminal capabilities
    - Test different viewport sizes
```
###  Path: `\spec\btea/msg.md`

```md
# Bubble Tea Message Types in Lua

## Overview

This specification defines how Bubble Tea messages are represented in Lua after conversion from Go. Each message is
converted into a Lua table with a specific structure based on its type.

## Message Structure

All messages are represented as Lua tables with a common base structure:

```lua
{
  type = "update",  -- Common base type for all messages
  -- Additional type-specific fields follow
}
```

## Key Messages

Key messages represent keyboard input events.

```lua
{
  type = "update",
  key = {
    type = "key",
    key_type = string,  -- See Key Types section
    alt = boolean,      -- Alt modifier state
    paste = boolean,    -- Paste mode flag
    string = string,    -- String representation
    runes = string,     -- Only present if key_type is "runes"
  }
}
```

### Key Types

The following key types are supported (string values):

1. Control Keys:
    - `"ctrl+@"` through `"ctrl+z"`
    - `"ctrl+\\"`, `"ctrl+]"`, `"ctrl+^"`, `"ctrl+_"`

2. Navigation Keys:
    - `"up"`, `"down"`, `"right"`, `"left"`
    - `"home"`, `"end"`
    - `"pgup"`, `"pgdown"`
    - `"tab"`, `"backspace"`, `"delete"`
    - `"insert"`, `"space"`, `"enter"`, `"esc"`
    - `"runes"` (for regular character input)

3. Shifted Variants:
    - `"shift+tab"`, `"shift+up"`, `"shift+down"`
    - `"shift+left"`, `"shift+right"`
    - `"shift+home"`, `"shift+end"`

4. Ctrl Variants:
    - `"ctrl+up"`, `"ctrl+down"`, `"ctrl+right"`, `"ctrl+left"`
    - `"ctrl+home"`, `"ctrl+end"`
    - `"ctrl+pgup"`, `"ctrl+pgdown"`

5. Ctrl+Shift Variants:
    - `"ctrl+shift+up"`, `"ctrl+shift+down"`
    - `"ctrl+shift+left"`, `"ctrl+shift+right"`
    - `"ctrl+shift+home"`, `"ctrl+shift+end"`

6. Function Keys:
    - `"f1"` through `"f20"`

## Mouse Messages

Mouse messages represent mouse input events.

```lua
{
  type = "update",
  mouse = {
    type = "mouse",
    x = number,        -- X coordinate
    y = number,        -- Y coordinate
    button = string,   -- See Mouse Buttons section
    action = string,   -- "press", "release", or "motion"
    alt = boolean,     -- Alt modifier state
    ctrl = boolean,    -- Ctrl modifier state
    shift = boolean,   -- Shift modifier state
  }
}
```

### Mouse Buttons

The following mouse button types are supported (string values):

- `"none"`: No button (motion events)
- `"left"`: Left mouse button
- `"middle"`: Middle mouse button
- `"right"`: Right mouse button
- `"wheel_up"`: Mouse wheel scroll up
- `"wheel_down"`: Mouse wheel scroll down
- `"wheel_left"`: Mouse wheel scroll left
- `"wheel_right"`: Mouse wheel scroll right
- `"backward"`: Browser back button
- `"forward"`: Browser forward button
- `"button10"`: Extended mouse button 10
- `"button11"`: Extended mouse button 11

## Window Size Messages

Window size messages represent terminal window dimension changes.

```lua
{
  type = "update",
  window_size = {
    type = "window_size",
    width = number,    -- Window width in columns
    height = number,   -- Window height in rows
  }
}
```

## Opaque Messages

For custom message types not covered above, messages are converted to an opaque format:

```lua
{
  type = "update",
  opaque = userdata,     -- Original Go message stored as userdata
  string = string,       -- String representation of message
}
```

## Error Handling

1. Unknown key types will return an error: "unknown key type: {type}"
2. Unknown mouse buttons will return an error: "unknown mouse button: {button}"

## Best Practices

1. Always check the message type before accessing type-specific fields
2. Handle unknown key types and mouse buttons gracefully
3. For opaque messages, use the string representation for display
4. Remember that alt/ctrl/shift modifiers are booleans
5. Use the string field for display/logging purposes when available
```
###  Path: `\spec\btea/paginator.md`

```md
# Bubble Tea Paginator in Lua

## Overview

This specification defines how paginator components are represented and used in Lua within the Bubble Tea framework. The
paginator provides functionality for handling pagination of content, including navigation and display of pagination
status.

## Important Note

The paginator uses zero-based indexing to maintain consistency with the Go implementation. This means:

- First page is 0
- Last page is (total_pages - 1)
- Navigation methods work with zero-based indices

## Paginator Creation

A paginator is created using the `btea.paginator` constructor:

```lua
local paginator = btea.paginator {
    type = btea.paginator_types.ARABIC,  -- Display type (ARABIC or DOTS)
    page = 0,                            -- Current page (0-based index)
    per_page = 10,                       -- Items per page
    total_pages = 5,                     -- Total number of pages (pages will be 0-4)
}
```

## Constants

### Display Types

```lua
btea.paginator_types.ARABIC  -- Numeric display (e.g., "1/5")
btea.paginator_types.DOTS    -- Visual indicator display
```

## Methods

### Navigation

```lua
-- Move to previous page (will not go below 0)
paginator:prev_page()

-- Move to next page (will not exceed total_pages - 1)
paginator:next_page()

-- Check position (returns true/false)
local is_first = paginator:on_first_page()  -- True if page is 0
local is_last = paginator:on_last_page()    -- True if on last available page

-- Get current page number (0-based)
local current = paginator:get_current_page()
```

### Configuration

```lua
-- Set display type
paginator:set_type(btea.paginator_types.DOTS)

-- Set total pages
paginator:set_total_pages(total)

-- Set items per page
paginator:set_per_page(amount)
```

### Page Data Helpers

```lua
-- Get number of items for current page
local items = paginator:items_on_page(total_items)

-- Get slice bounds for current page
local start_idx, end_idx = paginator:get_slice_bounds(total_length)
```

### Core Functions

```lua
-- Update paginator state (returns cmd or nil)
local cmd = paginator:update(msg)

-- Render pagination display
local str = paginator:view()
```

## Example Usage

### Basic List Pagination

```lua
-- Create model with paginator
local model = {
    items = {"item1", "item2", "item3", "item4", "item5"},
    paginator = btea.paginator {
        type = btea.paginator_types.ARABIC,
        per_page = 2
    }
}

-- Initialize total pages
model.paginator:set_total_pages(#model.items)

-- Get current page items
local function get_page_items(model)
    local start_idx, end_idx = model.paginator:get_slice_bounds(#model.items)
    local visible = {}
    
    -- Remember to adjust for Lua's 1-based array indexing
    for i = start_idx + 1, end_idx do
        table.insert(visible, model.items[i])
    end
    
    return visible
end

-- Update function
local function update(model, msg)
    local cmd = model.paginator:update(msg)
    return model, cmd
end

-- View function
local function view(model)
    local items = get_page_items(model)
    return table.concat(items, "\n") .. "\n" .. model.paginator:view()
end
```

### Dynamic Content Pagination

```lua
local search_results = {
    paginator = btea.paginator {
        type = btea.paginator_types.DOTS,
        per_page = 5
    },
    results = {},
    
    update_results = function(self, new_results)
        self.results = new_results
        self.paginator:set_total_pages(#new_results)
    end,
    
    get_page = function(self)
        local start_idx, end_idx = self.paginator:get_slice_bounds(#self.results)
        local page = {}
        for i = start_idx + 1, end_idx do
            table.insert(page, self.results[i])
        end
        return page
    end
}
```

## Best Practices

1. **Zero-Based Indexing**
    - Remember that page numbers are zero-based internally
    - Adjust array indices when accessing Lua tables (add 1 to slice bounds)
    - Use get_current_page() for logic rather than assumptions about page numbers

2. **Bounds Handling**
    - The paginator handles bounds checking internally
    - prev_page() won't go below 0
    - next_page() won't exceed (total_pages - 1)

3. **State Management**
    - Update total_pages when data changes
    - Check on_first_page() and on_last_page() for navigation logic
    - Use get_slice_bounds() for consistent page slicing

4. **Message Handling**
    - Always handle the cmd returned from update()
    - Test both keyboard and mouse navigation if supported
    - Consider update() return value for state changes

## Notes

- All page numbers are zero-based internally for consistency
- Lua table indexing still starts at 1, so adjust slice bounds accordingly
- Navigation methods handle bounds checking automatically
- Display type can be changed at runtime using set_type()
```
###  Path: `\spec\btea/progress.md`

```md
# Bubble Tea Progress Component in Lua

## Overview

This specification defines how progress bar components are represented and used in Lua within the Bubble Tea framework.
The progress component provides an animated progress bar with support for percentage-based tracking, gradients, and
customizable styling.

## Progress Creation

A progress bar is created using the `btea.progress` constructor:

```lua
local progress = btea.progress {
    width = 40,                    -- Optional: progress bar width
    show_percentage = true,        -- Optional: show percentage text (default true)
    fill_type = "gradient",        -- Optional: "gradient" or "solid"
    gradient = {                   -- Optional: custom gradient colors
        from = "#FF0000",         -- Start color
        to = "#00FF00"           -- End color
    },
    color = "#0000FF"             -- Optional: color for solid fill type
}
```

## Methods

### Core Methods

```lua
-- Update progress bar state
local cmd = progress:update(msg)

-- Render progress bar
local str = progress:view()

-- Render progress bar with specific percentage
local str = progress:view_as(0.75) -- Shows 75%
```

### Progress Control

```lua
-- Set exact progress percentage (0.0 to 1.0)
local cmd = progress:set_percent(0.5)    -- Set to 50%

-- Increment progress
local cmd = progress:incr_percent(0.1)   -- Increase by 10%

-- Decrement progress
local cmd = progress:decr_percent(0.1)   -- Decrease by 10%

-- Get current progress
local current = progress:percent()        -- Returns value between 0 and 1
```

### Configuration

```lua
-- Set progress bar width
progress:set_width(width)

-- Check animation state
local is_active = progress:is_animating()
```

## Animation and Behavior

1. The progress bar uses spring physics for smooth animations
2. Default spring configuration: tension = 30, friction = 2
3. Animations occur when:
    - Progress percentage changes
    - Width changes
    - Gradient or color updates

## Best Practices

1. **Progress Updates**
    - Use `set_percent` for absolute positions
    - Use `incr_percent`/`decr_percent` for relative changes
    - Values are automatically clamped between 0.0 and 1.0

2. **Performance**
    - Handle animation frame updates properly
    - Process update commands returned by modification methods
    - Consider width in relation to terminal size

3. **User Experience**
    - Use gradients for visual interest in longer operations
    - Show percentage for precise progress indication
    - Consider terminal color support when choosing colors

## Example Usage

### Basic Progress Bar

```lua
local function create_progress()
    return btea.progress {
        width = 40,
        show_percentage = true
    }
end

local function update(model, msg)
    if msg then
        -- Handle progress updates
        local cmd = model.progress:update(msg)
        if cmd then
            return model, cmd
        end
    end
    return model
end

local function view(model)
    return model.progress:view()
end
```

### Download Progress Example

```lua
local download_tracker = {
    progress = btea.progress {
        width = 60,
        fill_type = "gradient",
        gradient = {
            from = "#5A56E0",
            to = "#EE6FF8"
        }
    },
    
    -- Update progress based on bytes
    update_bytes = function(self, received, total)
        local percent = received / total
        return self.progress:set_percent(percent)
    end,
    
    -- Reset progress
    reset = function(self)
        return self.progress:set_percent(0)
    end
}
```

### Operation Progress with Phases

```lua
local operation = {
    progress = btea.progress {
        width = 40,
        fill_type = "solid",
        color = "#00FF00"
    },
    
    phases = {
        "Initializing",
        "Processing",
        "Finalizing"
    },
    current_phase = 1,
    
    -- Advance to next phase
    next_phase = function(self)
        self.current_phase = self.current_phase + 1
        local phase_progress = (self.current_phase - 1) / #self.phases
        return self.progress:set_percent(phase_progress)
    end
}
```

## Important Notes

1. Progress values are always normalized between 0.0 and 1.0
2. Animation commands must be handled by the application's update loop
3. The component uses Bubble Tea's frame messages for animation
4. Progress bars respect terminal color support
5. Width defaults to terminal width if not specified
6. Percentage display can be disabled for cleaner visuals
7. Custom gradients require valid color strings (hex format)
```
###  Path: `\spec\btea/render_util.md`

```md
# Bubble Tea Text Utilities in Lua

## Overview

This specification defines how text manipulation utilities are represented and used in Lua within the Bubble Tea
framework. These utilities provide functions for measuring text dimensions, joining text blocks, and applying styles to
specific characters.

## Module Structure

Text utilities are accessed through the `btea.text` namespace, which provides various functions grouped by purpose.

## Text Measurement

### Width Calculation

```lua
local width = btea.text.width(str)
```

Returns the cell width of characters in the string, properly handling:

- ANSI escape sequences (ignored in measurement)
- Wide characters (CJK, emojis, etc.)
- Multi-line strings (returns maximum line width)

### Height Calculation

```lua
local height = btea.text.height(str)
```

Returns the height of a string in cells by counting newline characters.

### Combined Dimension Calculation

```lua
local width, height = btea.text.size(str)
```

Returns both width and height in a single call.

### Maximum Dimension Functions

```lua
local max_width = btea.text.max_width(strings)
local max_height = btea.text.max_height(strings)
```

Takes a table of strings and returns the maximum width or height among them.

## Text Joining

### Position Constants

```lua
btea.text.position = {
    TOP = 0.0,
    CENTER = 0.5,
    BOTTOM = 1.0,
    LEFT = 0.0,
    RIGHT = 1.0
}
```

### Horizontal Joining

```lua
local result = btea.text.join_horizontal(position, str1, str2, ...)
```

Joins strings horizontally with alignment specified by position (0.0 - 1.0):

- 0.0 (TOP): Align at the top
- 0.5 (CENTER): Center vertically
- 1.0 (BOTTOM): Align at the bottom

Example:

```lua
local top_aligned = btea.text.join_horizontal(btea.text.position.TOP,
    "Block 1\nLine 2",
    "Block 2\nLine 2\nLine 3"
)
```

### Vertical Joining

```lua
local result = btea.text.join_vertical(position, str1, str2, ...)
```

Joins strings vertically with alignment specified by position (0.0 - 1.0):

- 0.0 (LEFT): Align to the left
- 0.5 (CENTER): Center horizontally
- 1.0 (RIGHT): Align to the right

Example:

```lua
local right_aligned = btea.text.join_vertical(btea.text.position.RIGHT,
    "Short line",
    "This is a longer line"
)
```

## Character Styling

### Style Specific Characters

```lua
local result = btea.text.style_runes(str, indices, matched_style, unmatched_style)
```

Applies different styles to specific characters in a string:

- `str`: Input string to style
- `indices`: Table of 0-based indices for characters to style
- `matched_style`: Style to apply to characters at specified indices
- `unmatched_style`: Style to apply to all other characters

Example:

```lua
local matched = btea.style():foreground("red")
local unmatched = btea.style():foreground("blue")

local result = btea.text.style_runes(
    "Hello World",
    {0, 4, 6},  -- Style 'H', 'o', 'W'
    matched,
    unmatched
)
```

## Best Practices

1. **Width Calculation**
    - Use `width()` instead of string length for proper character width handling
    - Account for zero-width ANSI sequences in styled text

2. **Text Joining**
    - Use position constants for common alignments
    - Use decimal positions (0-1) for fine-tuned control
    - Consider text block dimensions when choosing alignment

3. **Style Application**
    - Apply contrasting styles for better visibility
    - Validate character indices before styling
    - Consider terminal color support

## Error Handling

1. **Invalid Input**
    - Invalid position values (outside 0-1) may produce unexpected results
    - Invalid indices in style_runes are ignored
    - Non-string inputs will raise errors

2. **Style Objects**
    - Invalid style objects will raise type errors
    - Nil style objects are not allowed

## Text Sanitization

### Sanitize Control Characters

```lua
local clean = btea.text.sanitize_runes(str [, newline_repl [, tab_repl]])
```

Processes input string to handle control characters:

- Removes invalid UTF-8 sequences
- Removes control characters
- Optionally replaces newlines and tabs with custom strings
- Preserves all other valid characters

Parameters:

- `str`: Input string to sanitize
- `newline_repl`: (optional) String to replace newlines with, defaults to "\n"
- `tab_repl`: (optional) String to replace tabs with, defaults to 4 spaces

Example:

```lua
-- Basic usage - remove control chars
local text = btea.text.sanitize_runes("some\x00text\nwith\tcontrol\rchars")

-- Custom replacements
local html = btea.text.sanitize_runes(
    "Line 1\nLine 2\tIndented",
    "<br>",     -- Replace newlines with HTML breaks
    "&nbsp;&nbsp;"  -- Replace tabs with HTML spaces
)
```

## Example Usage

### Complex Text Layout

```lua
-- Create header with different styles
local header = btea.text.style_runes(
    "DASHBOARD",
    {0, 4, 8},
    btea.style():bold():foreground("red"),
    btea.style():foreground("blue")
)

-- Create two columns
local left_column = "Status: Active\nUsers: 150\nLoad: 75%"
local right_column = "CPU: 45%\nMem: 2.5GB\nDisk: 80%"

-- Join columns horizontally
local stats = btea.text.join_horizontal(
    btea.text.position.TOP,
    left_column,
    right_column
)

-- Join header and stats vertically
local dashboard = btea.text.join_vertical(
    btea.text.position.CENTER,
    header,
    stats
)
```

### Dynamic Width Handling

```lua
local items = {
    "Item 1",
    "A longer item 2",
    "Very long item 3"
}

-- Get maximum width for layout
local width = btea.text.max_width(items)

-- Create uniform width items
local formatted = {}
for _, item in ipairs(items) do
    local style = btea.style():width(width):padding(0, 1)
    table.insert(formatted, style:render(item))
end
```

## Notes

- Text measurement accounts for terminal-specific character widths
- Join operations preserve ANSI sequences and styling
- Style application works with multi-byte characters
- All operations are non-destructive and return new strings
```
###  Path: `\spec\btea/spinner.md`

```md
# Bubble Tea Spinner in Lua

## Overview

The spinner component provides an animated loading indicator that can be styled and customized. It supports multiple
animation types and configurable update intervals.

## Spinner Creation

Create a spinner using the `btea.spinner` constructor:

```lua
local spinner = btea.spinner {
    type = btea.spinners.LINE,     -- Animation type (optional, defaults to LINE)
    interval = "100ms"             -- Update interval (optional)
}
```

### Interval Format

The interval can be specified in several formats:

- Duration string: "100ms", "1s", "500ms"
- Numeric milliseconds: 100, 500
- Must be greater than 0

## Spinner Types

Available via `btea.spinners`:

```lua
btea.spinners.LINE       -- Simple line rotation (|/-\)
btea.spinners.DOT        -- Braille dot animation
btea.spinners.MINIDOT    -- Smaller dot animation
btea.spinners.JUMP       -- Jumping dot animation
btea.spinners.PULSE      -- Pulsing block animation
btea.spinners.POINTS     -- Moving dots
btea.spinners.GLOBE      -- Rotating earth animation
btea.spinners.MOON       -- Moon phases animation
btea.spinners.MONKEY     -- Cycling monkey animation
btea.spinners.METER      -- Progress meter animation
btea.spinners.HAMBURGER  -- Menu icon animation
btea.spinners.ELLIPSIS   -- Growing ellipsis animation
```

## Methods

### Core Functions

```lua
-- Get next animation frame
local cmd = spinner:tick()

-- Update spinner state, returns animation command if needed
local cmd = spinner:update(msg)

-- Get current spinner frame
local str = spinner:view()
```

### Configuration

```lua
-- Set spinner style
spinner:style(style)  -- style should be a btea.Style object

-- Set animation interval
spinner:set_interval("100ms")  -- accepts duration string or number
```

## Animation Control

The spinner animation is controlled through the update/tick cycle:

1. Initial animation is started with `tick()`
2. Each `update()` processes frame changes
3. The returned command should be executed to continue animation

```lua
-- Start animation
local cmd = spinner:tick()

-- In your update loop
function update(msg)
    local cmd = spinner:update(msg)
    if cmd then
        -- Execute command to continue animation
        return model, cmd
    end
    return model
end
```

## Example Usage

### Basic Loading Indicator

```lua
local model = {
    spinner = btea.spinner {
        type = btea.spinners.DOT,
        interval = "100ms"
    },
    loading = true
}

function update(msg)
    if model.loading then
        local cmd = model.spinner:update(msg)
        if cmd then
            return model, cmd
        end
    end
    return model
end

function view()
    if model.loading then
        return model.spinner:view() .. " Loading..."
    end
    return "Done!"
end

-- Start animation
return model, model.spinner:tick()
```

### Styled Spinner

```lua
local spinner = btea.spinner {
    type = btea.spinners.POINTS
}

-- Apply styling
local style = btea.style()
    :foreground("#89B4FA")
    :bold()
spinner:style(style)
```

## Best Practices

1. **Animation Control**
    - Always handle the command returned from update()
    - Start animation with tick()
    - Chain commands if needed using btea.sequence

2. **Interval Management**
    - Use appropriate intervals (100ms is typical)
    - Validate interval values (must be > 0)
    - Consider performance impact of very short intervals

3. **Error Handling**
    - Validate interval format when setting
    - Handle invalid spinner types gracefully
    - Check for nil commands in update cycle

4. **State Management**
    - Track animation state (active/inactive)
    - Clean up animations when no longer needed
    - Coordinate multiple spinners if needed

## Notes

- All spinner types are predefined and cannot be modified at runtime
- Intervals affect CPU usage - use appropriate values
- Style changes affect all frames of the animation
- Animation continues until explicitly stopped or component is unmounted
```
###  Path: `\spec\btea/style.md`

```md
# Lip Gloss Style Binding in Lua

## Overview

This specification defines how Lip Gloss style objects are represented and manipulated in Lua. Each style object is a
userdata that encapsulates configuration for terminal text rendering, including colors, formatting, and layout
properties. All style modification methods are immutable – they return a new style object without altering the original.

## Style Object Structure

A style object is created via the constructor:

```lua
local style = btea.style()
```

Internally, the style object provides a set of methods that mirror the Lip Gloss API, enabling expressive, chainable
style modifications.

## Available Methods

Each style object supports the following methods:

### render(string)

Renders the given string using the style's configuration.

```lua
local styledText = style:render("Hello, world!")
```

### foreground(color)

Sets the foreground (text) color. Accepts ANSI codes or hexadecimal color strings.

```lua
local newStyle = style:foreground("#FAFAFA")
```

### background(color)

Sets the background color.

```lua
local newStyle = style:background("#7D56F4")
```

### bold()

Enables bold text.

```lua
local newStyle = style:bold()
```

### italic()

Enables italic text.

```lua
local newStyle = style:italic()
```

### underline()

Enables underlined text.

```lua
local newStyle = style:underline()
```

### strikethrough()

Enables strikethrough formatting.

```lua
local newStyle = style:strikethrough()
```

### faint()

Enables faint text styling.

```lua
local newStyle = style:faint()
```

### blink()

Enables blinking text.

```lua
local newStyle = style:blink()
```

### reverse()

Enables reverse video mode.

```lua
local newStyle = style:reverse()
```

### padding(top, right, bottom, left)

Sets the padding around the rendered text. The function accepts one to four numerical arguments, following CSS shorthand
conventions:

- `padding(2)` sets uniform padding.
- `padding(2, 4)` sets vertical and horizontal padding.
- `padding(1, 4, 2)` sets top, horizontal, and bottom.
- `padding(2, 4, 3, 1)` sets top, right, bottom, and left respectively.

```lua
local newStyle = style:padding(2, 4, 2, 4)
```

### margin(top, right, bottom, left)

Sets the margin around the rendered text. It follows the same shorthand as `padding`.

```lua
local newStyle = style:margin(1, 2, 1, 2)
```

### border(borderStyle)

Sets the border style using one of the predefined border types. Valid values for `borderStyle` are:

- `"normal"`
- `"rounded"`
- `"thick"`
- `"double"`

```lua
local newStyle = style:border("rounded")
```

### custom_border(borderTable)

Allows the user to specify a custom border via a Lua table. The table may include any of the following keys to define
individual border segments (all keys are optional):

- `top`
- `bottom`
- `left`
- `right`
- `top_left`
- `top_right`
- `bottom_left`
- `bottom_right`

```lua
local custom = {
  top = "─",
  bottom = "─",
  left = "│",
  right = "│",
  top_left = "┌",
  top_right = "┐",
  bottom_left = "└",
  bottom_right = "┘",
}

local newStyle = style:custom_border(custom)
```

### width(number)

Sets the minimum width (in cells) for the rendered output.

```lua
local newStyle = style:width(24)
```

### height(number)

Sets the minimum height (in cells) for the rendered output.

```lua
local newStyle = style:height(32)
```

### align(alignment)

Sets text alignment within the available width. Use the provided alignment constants:

- `align.LEFT`
- `align.CENTER`
- `align.RIGHT`

```lua
local newStyle = style:align(align.CENTER)
```

### inline(boolean)

Forces the style to render on a single line, ignoring margins, padding, and borders.

```lua
local newStyle = style:inline(true)
```

### max_width(number)

Constrains the rendered output to a maximum width.

```lua
local newStyle = style:max_width(80)
```

### max_height(number)

Constrains the rendered output to a maximum height.

```lua
local newStyle = style:max_height(10)
```

### tab_width(number)

Sets the number of spaces for converting tab characters. A value of 0 removes tabs entirely, while a special constant (
e.g., `lipgloss.NoTabConversion`) can leave tabs intact.

```lua
local newStyle = style:tab_width(4)
```

### copy()

Creates and returns a deep copy of the style object.

```lua
local copyStyle = style:copy()
```

### inherit(otherStyle)

Inherits unset properties from another style object, combining configurations.

```lua
local combinedStyle = style:inherit(otherStyle)
```

## Constants

The binding provides constants for alignment:

```lua
align = {
  LEFT = 0,
  CENTER = 1,
  RIGHT = 2,
}
```

Predefined border style strings are also provided:

- `"normal"`
- `"rounded"`
- `"thick"`
- `"double"`

## Best Practices

1. **Immutable Operations:** Each method returns a new style object. Use the returned object for further modifications.
2. **Method Chaining:** Since operations are immutable, you can chain methods for concise configuration:

    ```lua
    local styled = lipgloss.style()
      :foreground("#FAFAFA")
      :background("#7D56F4")
      :bold()
      :padding(2, 4)
      :width(22)
    ```
3. **Separation of Concerns:** Define your styles separately from your rendering logic to maintain clean, modular code.

## Error Handling

- **Invalid Inputs:** Passing invalid color strings, border style values, or incorrect keys for custom borders may
  trigger runtime errors. Validate inputs where necessary.
- **Alignment Values:** Use only the provided alignment constants to ensure expected behavior.

## Example Usage

```lua
local style = lipgloss.style()
  :foreground("#FAFAFA")
  :background("#7D56F4")
  :bold()
  :padding(2, 4)
  :width(22)

local customBorder = {
  top = "─",
  bottom = "─",
  left = "│",
  right = "│",
  topleft = "┌",
  topright = "┐",
  bottomleft = "└",
  bottomright = "┘",
}

local styledWithBorder = style:custom_border(customBorder)
print(styledWithBorder:render("Hello, kitty"))
```

In this example, a style is created with bold text, specified foreground and background colors, padding, and a set
width, then a custom border is applied and used to render a string.

## Conclusion

This specification outlines the available methods and best practices for working with Lip Gloss style objects in Lua. By
following these guidelines, developers can effectively manage and apply terminal styling in their Lua applications,
including the ability to define custom borders when needed.
```
###  Path: `\spec\btea/table.md`

```md
# Bubble Tea Table Widget in Lua

## Overview

The table widget provides a way to display tabular data with customizable columns, rows, cursor navigation, and styles.
The widget supports basic interaction (moving the selection, scrolling, etc.) and is fully configurable through Lua.
Under the hood it leverages a Bubble Tea model, so you can update and render it in your application.

## Table Creation

A table widget is created with the `btea.table` constructor. The constructor accepts a Lua table of options. The
supported options include:

- **cols**: A list of column definitions. Each column is represented by a Lua table with:
    - `title` (string): The header text.
    - `width` (number): The column width.
- **rows**: A list of rows. Each row is a Lua table (array) of strings.
- **width**: (number) Sets the overall viewport width.
- **height**: (number) Sets the viewport height (excluding header height).
- **focused**: (boolean) Determines whether the table is in focus (enabling selection/movement).
- **styles**: A Lua table defining the styles for different table parts. It should include:
    - `header`: A btea.Style instance to style the header row.
    - `cell`: A btea.Style instance to style each cell.
    - `selected`: A btea.Style instance for the selected row.

### Example:

```lua
local tablewidget = btea.table {
  cols = {
    { title = "ID", width = 10 },
    { title = "Name", width = 20 },
    { title = "Status", width = 15 },
  },
  rows = {
    {"1", "Alice", "Active"},
    {"2", "Bob", "Inactive"},
    {"3", "Carol", "Active"},
  },
  width = 60,
  height = 20,
  focused = true,
  styles = {
    header   = btea.style():bold():foreground("#FFFFFF"):background("#7D56F4"),
    cell     = btea.style():foreground("#C0CAF5"),
    selected = btea.style():bold():foreground("#89B4FA"):background("#2E2E3E"),
  },
}
```

## Style Creation

Styles are created with `btea.style()`. The style binding allows you to chain transformations such as `:bold()`,
`:foreground()`, and `:background()`. For example:

```lua
local header_style = btea.style()
    :bold()
    :foreground("#FFFFFF")
    :background("#7D56F4")

local cell_style = btea.style()
    :foreground("#C0CAF5")

local selected_style = btea.style()
    :bold()
    :foreground("#89B4FA")
    :background("#2E2E3E")
```

## Methods

### Content Management

- **Setting Rows and Columns**
    - `tablewidget:set_rows(rows)`  
      Sets the table rows. _rows_ must be a Lua table where each element is a table of strings.
    - `tablewidget:set_columns(cols)`  
      Sets the table columns. _cols_ must be a Lua table where each element is a table with keys `"title"` and
      `"width"`.

- **Retrieving Data**
    - `local rows = tablewidget:get_rows()`  
      Returns the current rows as a Lua table of tables.
    - `local cols = tablewidget:get_columns()`  
      Returns the current columns as a Lua table of column definitions.

### Navigation and Selection

- **Cursor Control**
    - `tablewidget:set_cursor(n)`  
      Sets the selected row index (zero-based). The cursor will be clamped to valid row indices.
    - `local idx = tablewidget:cursor()`  
      Returns the current cursor index (zero-based).

- **Movement**
    - `tablewidget:move_up([n])`  
      Moves the selection up by _n_ rows (default is 1). Won't move past the first row.
    - `tablewidget:move_down([n])`  
      Moves the selection down by _n_ rows (default is 1). Won't move past the last row.
    - `tablewidget:goto_top()`  
      Moves the selection to the first row (index 0).
    - `tablewidget:goto_bottom()`  
      Moves the selection to the last row.
    - `local row = tablewidget:selected_row()`  
      Returns the currently selected row as a Lua table, or nil if no row is selected.

### Focus Management

- **Focusing and Blurring**
    - `tablewidget:focus()`  
      Puts the table in focus for user input handling.
    - `tablewidget:blur()`  
      Removes focus from the table.

### Rendering

- **Display and Help**
    - `local s = tablewidget:view()`  
      Returns the current rendered view of the table.
    - `local help = tablewidget:help_view()`  
      Returns a help text showing available key bindings.

### Dimension Configuration

- **Viewport Adjustments**
    - `tablewidget:set_width(n)`  
      Sets the viewport width. Must be called after table creation if not set in options.
    - `tablewidget:set_height(n)`  
      Sets the viewport height. Must be called after table creation if not set in options.
    - `local width = tablewidget:width()`  
      Returns the current viewport width.
    - `local height = tablewidget:height()`  
      Returns the current viewport height.

### Data Parsing

- **Creating Rows from a String**
    - `tablewidget:from_values(value, [separator])`  
      Parses a multi-line string into rows. Each line becomes a row, split by the separator.
        - _value_: String containing the data (rows separated by newline)
        - _separator_: Field delimiter (defaults to comma if not provided)

### Update Handling

The table widget implements the Bubble Tea update pattern:

```lua
function on_update(msg)
    local cmd = tablewidget:update(msg)
    -- Handle any returned command if needed
end
```
```
###  Path: `\spec\btea/text_area.md`

```md
Below is the complete TEXT AREA spec in Lua with snake_case variable names and **all** key bindings detailed:

---

# Bubble Tea Text Area Specification in Lua

This document defines the interface and usage patterns for the text_area component in btea. The text_area is a multiline
input widget that supports a variety of configuration options and methods to control behavior and appearance.

---

## Creating a Text Area

Instantiate a new text_area using the `btea.text_area` Lua constructor. The constructor accepts a table of options:

```lua
local text_area = btea.text_area({
  prompt = "> ",                      -- Optional prompt displayed before user input
  placeholder = "type something...",  -- Placeholder text when empty
  value = "",                         -- Initial content
  width = 50,                         -- Display width
  height = 10,                        -- Display height
  char_limit = 200,                   -- Maximum characters allowed
  show_line_numbers = true,           -- Display line numbers along the side
  focused_style = {                   -- Styling for focused state (table or btea.Style userdata)
      base = my_base_style,
      cursor_line = my_cursor_line_style,
      cursor_line_number = my_cursor_line_number_style,
      end_of_buffer = my_end_buffer_style,
      line_number = my_line_number_style,
      placeholder = my_placeholder_style,
      prompt = my_prompt_style,
      text = my_text_style,
  },
  blurred_style = {                   -- Styling when not focused
      base = my_base_style,
      cursor_line = my_cursor_line_style,
      cursor_line_number = my_cursor_line_number_style,
      end_of_buffer = my_end_buffer_style,
      line_number = my_line_number_style,
      placeholder = my_placeholder_style,
      prompt = my_prompt_style,
      text = my_text_style,
  },
  key_map = {                         -- Custom key bindings (all available bindings are listed below)
      character_forward         = btea.bind({ keys = {"right", "ctrl+f"} }),
      character_backward        = btea.bind({ keys = {"left", "ctrl+b"} }),
      word_forward              = btea.bind({ keys = {"alt+right", "alt+f"} }),
      word_backward             = btea.bind({ keys = {"alt+left", "alt+b"} }),
      delete_character_backward = btea.bind({ keys = {"backspace", "ctrl+h"} }),
      delete_character_forward  = btea.bind({ keys = {"delete", "ctrl+d"} }),
      insert_newline            = btea.bind({ keys = {"enter"} }),
      -- Additional bindings can be added here if needed.
  }
})
```

---

## Methods

The text_area component provides the following methods (all using snake_case):

### update

Updates the text_area state based on an incoming message (typically from the Bubble Tea update loop). It returns a
command (if any) to be executed.

```lua
local command = text_area:update(msg)
if command then
  -- Execute the command as needed.
end
```

### view

Renders the current state of the text_area to a string for display:

```lua
local view_str = text_area:view()
```

### set_value

Directly sets or updates the text_area's value:

```lua
text_area:set_value("new text content")
```

### value

Retrieves the current content of the text_area:

```lua
local current_value = text_area:value()
```

### focus and blur

Manages the focus state to start or stop capturing keyboard events:

```lua
-- To focus (this may return a command to be executed)
local focus_command = text_area:focus()
if focus_command then
  -- Execute the focus command as required.
end

-- To blur (remove focus from the text_area)
text_area:blur()
```

---

## Message Handling

In your update loop, pass incoming messages (e.g., key events) to the text_area:

```lua
function update(msg)
  local command = text_area:update(msg)
  if command then
    return command  -- Return or process the command accordingly
  end
  -- Continue with additional update logic...
end
```

---

## Styling

Styles for the text_area are configured via the `focused_style` and `blurred_style` options. Each style should provide
the following fields (each field is expected to be a btea.Style userdata):

- `base`
- `cursor_line`
- `cursor_line_number`
- `end_of_buffer`
- `line_number`
- `placeholder`
- `prompt`
- `text`

Define your style values (using snake_case variable names) and pass them as part of the configuration when constructing
the text_area.

---

## Custom Key Bindings

The text_area supports several key bindings. These bindings can be overridden by supplying a `key_map` table with custom
bindings. The full list of available key bindings is as follows:

- **character_forward**:  
  Moves the cursor one character forward.  
  *Default keys*: `"right"`, `"ctrl+f"`

- **character_backward**:  
  Moves the cursor one character backward.  
  *Default keys*: `"left"`, `"ctrl+b"`

- **word_forward**:  
  Moves the cursor forward by one word.  
  *Default keys*: `"alt+right"`, `"alt+f"`

- **word_backward**:  
  Moves the cursor backward by one word.  
  *Default keys*: `"alt+left"`, `"alt+b"`

- **delete_character_backward**:  
  Deletes the character behind the cursor.  
  *Default keys*: `"backspace"`, `"ctrl+h"`

- **delete_character_forward**:  
  Deletes the character ahead of the cursor.  
  *Default keys*: `"delete"`, `"ctrl+d"`

- **insert_newline**:  
  Inserts a newline at the current cursor position (useful for multi-line input).  
  *Default key*: `"enter"`

These bindings can be fully customized as shown in the creation example above.

---

## Example Usage

Below is a complete example showing how to integrate and use the text_area component:

```lua
-- Define your styles (assumed to be valid btea.Style userdata)
local my_base_style            = btea.style():foreground("#FFFFFF")
local my_cursor_line_style     = btea.style():background("#333333")
local my_cursor_line_number_style = btea.style():foreground("#00FF00")
local my_end_buffer_style      = btea.style():foreground("#666666")
local my_line_number_style     = btea.style():foreground("#999999")
local my_placeholder_style     = btea.style():italic(true)
local my_prompt_style          = btea.style():bold(true)
local my_text_style            = btea.style()

-- Create a text_area with basic options and full key bindings.
local text_area = btea.text_area({
  prompt = "> ",
  placeholder = "type your message...",
  width = 60,
  height = 5,
  char_limit = 250,
  show_line_numbers = true,
  focused_style = {
      base = my_base_style,
      cursor_line = my_cursor_line_style,
      cursor_line_number = my_cursor_line_number_style,
      end_of_buffer = my_end_buffer_style,
      line_number = my_line_number_style,
      placeholder = my_placeholder_style,
      prompt = my_prompt_style,
      text = my_text_style,
  },
  blurred_style = {
      base = my_base_style,
      cursor_line = my_cursor_line_style,
      cursor_line_number = my_cursor_line_number_style,
      end_of_buffer = my_end_buffer_style,
      line_number = my_line_number_style,
      placeholder = my_placeholder_style,
      prompt = my_prompt_style,
      text = my_text_style,
  },
  key_map = {
      character_forward         = btea.bind({ keys = {"right", "ctrl+f"} }),
      character_backward        = btea.bind({ keys = {"left", "ctrl+b"} }),
      word_forward              = btea.bind({ keys = {"alt+right", "alt+f"} }),
      word_backward             = btea.bind({ keys = {"alt+left", "alt+b"} }),
      delete_character_backward = btea.bind({ keys = {"backspace", "ctrl+h"} }),
      delete_character_forward  = btea.bind({ keys = {"delete", "ctrl+d"} }),
      insert_newline            = btea.bind({ keys = {"enter"} }),
  }
})

-- Example update loop:
function update(msg)
  local command = text_area:update(msg)
  if command then
    -- Process the returned command, if any.
    return command
  end
  -- Additional update logic can be added here.
end

-- Example view/render function:
function view()
  return text_area:view()
end
```

---

## Notes

- **Command Integration:** The `update`, `focus`, and other methods may return Bubble Tea commands which must be
  executed within your application loop.
- **Styling Conversion:** Lua tables provided for styles are internally converted into lipgloss.Style values. Ensure
  your style definitions meet the expected format.
- **Key Bindings:** Custom key bindings should be supplied as btea.Binding userdata objects. The complete set of
  available bindings is shown above.

This specification provides a comprehensive overview of the text_area component, including all key bindings and methods,
using snake_case for variables and function names.
```
###  Path: `\spec\btea/text_input.md`

```md
# Text Input Integration Guide

## Basic Usage

The most basic usage of text input in Lua looks like this:

```lua
-- Create a new text input instance
local input = btea.text_input({
    prompt = "> ",                    -- Optional prompt prefix
    placeholder = "Enter text...",    -- Optional placeholder text
    value = "",                       -- Initial value
})

-- Focus the input to receive keyboard events
-- Returns a command if focus state changes
local cmd = input:focus()

-- Basic update function
function update(msg)
    if msg.type == "update" then
        -- Update input state and get any commands
        -- Returns a command if input state changes (e.g., suggestion accepted)
        local cmd = input:update(msg)
        if cmd then
            return cmd
        end
    end
end

-- Render the input
-- Returns a string representation of the current input state
function view()
    return input:view()
end
```

## Core Methods

```lua
-- Focus the input for keyboard events
-- @return tea.Cmd|nil Command if focus state changes
input:focus()

-- Remove focus from input
-- @return nil
input:blur()

-- Update input state based on message
-- @param msg table Tea message (key events, etc.)
-- @return tea.Cmd|nil Command if state changes
input:update(msg)

-- Get string representation of current state
-- @return string Rendered input view
input:view()

-- Reset input to initial state
-- @return nil
input:reset()

-- Get current input value
-- @return string Current text value
input:value()

-- Set input value
-- @param value string New text value
-- @return nil
input:set_value(value)
```

## Advanced Configuration

Text input supports various configuration options:

```lua
local input = btea.text_input({
    -- Basic options
    prompt = "$ ",                    -- Prompt prefix
    placeholder = "Type command...",  -- Placeholder text
    value = "",                       -- Initial value
    
    -- Styling
    prompt_style = btea.style():foreground("#00FF00"):bold(),     -- Prompt style
    text_style = btea.style():foreground("#FFFFFF"),              -- Input text style
    placeholder_style = btea.style():foreground("#666666"),       -- Placeholder text style
    completion_style = btea.style():foreground("#888888"),        -- Suggestion style
    cursor_style = btea.style():foreground("#FFFF00"),           -- Cursor style
    
    -- Input constraints
    char_limit = 100,           -- Maximum character limit (nil for no limit)
    width = 40,                 -- Display width (horizontal scroll if content exceeds)
    
    -- Input mode
    echo_mode = "password",     -- "normal", "password", or "none"
    echo_character = "*",       -- Character to show in password mode
    blink_speed = "500ms",      -- Cursor blink interval (as duration string)
    
    -- Validation
    validate = function(value)
        if #value < 3 then
            return "Input must be at least 3 characters"
        end
        return nil  -- Return nil for valid input
    end,
    
    -- Autocomplete
    show_suggestions = true,    -- Enable/disable suggestions
    suggestions = {             -- List of suggestion strings
        "help",
        "status",
        "quit",
        "clear",
    }
})
```

## Configuration Methods

```lua
-- Set new placeholder text
-- @param text string New placeholder
-- @return nil
input:set_placeholder(text)

-- Set new prompt text
-- @param text string New prompt
-- @return nil
input:set_prompt(text)

-- Set character limit
-- @param limit number|nil Maximum characters (nil for no limit)
-- @return nil
input:set_char_limit(limit)

-- Set display width
-- @param width number Maximum display width
-- @return nil
input:set_width(width)

-- Update component style
-- @param type string "prompt", "text", "placeholder", "completion", or "cursor"
-- @param style Style New style to apply
-- @return nil
input:set_style(type, style)

-- Set new validation function
-- @param fn function(value: string) -> string|nil
-- @return nil
input:set_validate(fn)

-- Set suggestion list
-- @param suggestions table List of suggestion strings
-- @return nil
input:set_suggestions(suggestions)

-- Get current suggestions
-- @return table List of current suggestions
input:get_suggestions()
```

## Cursor Control Methods

```lua
-- Get current cursor position
-- @return number Zero-based cursor position
input:position()

-- Set cursor position
-- @param pos number New cursor position (clamped to text bounds)
-- @return nil
input:set_cursor(pos)

-- Move cursor to start
-- @return nil
input:cursor_start()

-- Move cursor to end
-- @return nil
input:cursor_end()
```

## Validation Methods

```lua
-- Check if current value is valid
-- @return boolean True if valid
input:is_valid()

-- Get current validation error if any
-- @return string|nil Error message or nil if valid
input:error()
```

## Key Bindings

Text input comes with default key bindings that can be customized:

```lua
-- Create custom key bindings
local bindings = {
    -- Navigation
    character_forward = btea.bind({
        keys = {"right", "ctrl+f"},
        help = {key = "→/^F", desc = "move forward"}
    }),
    character_backward = btea.bind({
        keys = {"left", "ctrl+b"},
        help = {key = "←/^B", desc = "move backward"}
    }),
    
    -- Word navigation
    word_forward = btea.bind({
        keys = {"alt+right", "alt+f"},
        help = {key = "M-→/M-F", desc = "word forward"}
    }),
    word_backward = btea.bind({
        keys = {"alt+left", "alt+b"},
        help = {key = "M-←/M-B", desc = "word backward"}
    }),
    
    -- Deletion
    delete_character_backward = btea.bind({
        keys = {"backspace", "ctrl+h"},
        help = {key = "⌫/^H", desc = "delete backward"}
    }),
    delete_character_forward = btea.bind({
        keys = {"delete", "ctrl+d"},
        help = {key = "⌦/^D", desc = "delete forward"}
    }),
    delete_word_backward = btea.bind({
        keys = {"alt+backspace", "alt+h"},
        help = {key = "M-⌫/M-H", desc = "delete word backward"}
    }),
    delete_word_forward = btea.bind({
        keys = {"alt+delete", "alt+d"},
        help = {key = "M-⌦/M-D", desc = "delete word forward"}
    }),
    delete_before_cursor = btea.bind({
        keys = {"ctrl+u"},
        help = {key = "^U", desc = "delete to start"}
    }),
    delete_after_cursor = btea.bind({
        keys = {"ctrl+k"},
        help = {key = "^K", desc = "delete to end"}
    }),
    
    -- Line navigation
    line_start = btea.bind({
        keys = {"home", "ctrl+a"},
        help = {key = "⇱/^A", desc = "line start"}
    }),
    line_end = btea.bind({
        keys = {"end", "ctrl+e"},
        help = {key = "⇲/^E", desc = "line end"}
    }),
    
    -- Clipboard
    paste = btea.bind({
        keys = {"ctrl+v", "ctrl+y"},
        help = {key = "^V/^Y", desc = "paste"}
    }),
    
    -- Completion
    accept_suggestion = btea.bind({
        keys = {"tab"},
        help = {key = "⇥", desc = "complete"}
    }),
    next_suggestion = btea.bind({
        keys = {"down", "ctrl+n"},
        help = {key = "↓/^N", desc = "next suggestion"}
    }),
    prev_suggestion = btea.bind({
        keys = {"up", "ctrl+p"},
        help = {key = "↑/^P", desc = "previous suggestion"}
    })
}
```

## State Behavior

1. Focus State
    - Methods that modify input only work when focused
    - Unfocused input still displays but doesn't process input
    - Focus/blur triggers command for state updates

2. Cursor Behavior
    - Cursor position clamped to text bounds
    - Word navigation stops at word boundaries
    - Selection not supported in current version

3. Validation States
    - Validation runs on every text change
    - Invalid state shows error but allows continued input
    - Error cleared when input becomes valid

4. Event Processing
    - Key events processed in update() when focused
    - Suggestion selection via keys generates command
    - Clipboard paste handled via paste binding

## Best Practices

1. **Error Handling**
    - Always validate input before processing
    - Show clear error messages when validation fails
    - Handle edge cases (empty input, maximum length, etc.)

2. **User Experience**
    - Use appropriate styles for different states (normal, error, disabled)
    - Provide meaningful placeholders
    - Show completion suggestions when relevant
    - Use consistent key bindings

3. **Integration**
    - Keep input state in your model
    - Handle special keys appropriately
    - Process commands returned from update()
    - Clean up resources when done (blur input)

4. **Styling**
    - Use consistent colors and styles
    - Make sure error states are visible
    - Style placeholder text appropriately
    - Consider terminal color support

5. **Performance**
    - Avoid expensive validation on every keystroke
    - Consider debouncing rapid input
    - Be mindful of suggestion list size
    - Clean up event listeners when removing input

## Common Patterns

### Form Input

```lua
local form = {
    username = btea.text_input({
        prompt = "Username: ",
        validate = function(v) return #v >= 3 end
    }),
    password = btea.text_input({
        prompt = "Password: ",
        echo_mode = "password",
        validate = function(v) return #v >= 8 end
    })
}
```

### Command Input

```lua
local cmd_input = btea.text_input({
    prompt = "$ ",
    show_suggestions = true,
    suggestions = {"help", "status", "quit"},
    validate = function(cmd)
        local valid_commands = {help = true, status = true, quit = true}
        if not valid_commands[cmd] then
            return "Unknown command"
        end
        return nil
    end
})
```

### Search Input

```lua
local search = btea.text_input({
    prompt = "🔍 ",
    placeholder = "Search...",
    key_map = {
        -- Override enter to perform search
        submit = btea.bind({
            keys = {"enter"},
            help = {key = "⏎", desc = "search"}
        })
    }
})
```
```
###  Path: `\spec\btea/viewport.md`

```md
# Bubble Tea Viewport in Lua

## Overview

This specification defines how viewport components are represented and used in Lua within the Bubble Tea framework. The
viewport provides a scrollable view for content that's larger than the available screen space, with support for both
keyboard and mouse-based scrolling.

## Viewport Creation

A viewport is created using the `btea.viewport` constructor:

```lua
local viewport = btea.viewport {
    width = 40,                     -- Required: viewport width
    height = 20,                    -- Required: viewport height
    content = "Multi-line text...", -- Optional: initial content
    mouse_wheel_enabled = true,     -- Optional: enable mouse wheel
    mouse_wheel_delta = 3,          -- Optional: lines per scroll
    high_performance = false,       -- Optional: performance mode
    style = some_style             -- Optional: viewport styling (must be a btea style object)
}
```

## Methods

### Content Management

```lua
-- Set viewport content
viewport:set_content("New content...")

-- Get content information
local total = viewport:total_lines()     -- Total number of lines
local visible = viewport:visible_lines() -- Currently visible lines
```

### Scrolling Control

```lua
-- Basic scrolling
viewport:line_up(n)       -- Scroll up n lines (n is required)
viewport:line_down(n)     -- Scroll down n lines (n is required)
viewport:page_up()        -- Scroll up one page
viewport:page_down()      -- Scroll down one page
viewport:half_page_up()   -- Scroll up half page
viewport:half_page_down() -- Scroll down half page

-- Direct positioning
viewport:scroll_to_top()    -- Scroll to the beginning
viewport:scroll_to_bottom() -- Scroll to the end
viewport:set_y_offset(n)    -- Set precise scroll position
```

### Position Information

```lua
-- Get current position
local offset = viewport:y_offset()        -- Current scroll position
local percent = viewport:scroll_percent() -- Scroll percentage (0-100)

-- Check position
local at_top = viewport:at_top()       -- True if at the beginning
local at_bottom = viewport:at_bottom()  -- True if at the end
```

### Configuration

```lua
-- Adjust dimensions
viewport:set_width(width)   -- Set viewport width
viewport:set_height(height) -- Set viewport height

-- Mouse control
viewport:enable_mouse(true|false)        -- Enable/disable mouse wheel
viewport:mouse_wheel_delta(lines)        -- Set lines per wheel event

-- Styling
viewport:set_style(style)   -- Set viewport style (must be a btea style object)
```

### Core Functions

```lua
-- Get dimensions
local w = viewport:width()  -- Get current width
local h = viewport:height() -- Get current height

-- Update viewport state
local cmd = viewport:update(msg)

-- Render viewport
local str = viewport:view()
```

## Best Practices

1. **Content Management**
    - Update content only when necessary
    - Consider content width when setting viewport dimensions
    - Handle multi-byte characters properly

2. **Performance**
    - Use high performance mode for large content
    - Update dimensions on window resize
    - Cache rendered content when possible

3. **User Experience**
    - When using line_up/line_down, always provide the number of lines
    - Handle both keyboard and mouse input properly
    - Consider enabling mouse wheel for easier navigation

4. **Styling**
    - Only use valid btea style objects for styling
    - Apply styles thoughtfully to maintain readability
    - Consider terminal color support

## Example Usage

### Basic Viewport

```lua
local function create_viewport()
    local style = btea.style()
        :foreground("#FFFFFF")
        :background("#000000")
        
    return btea.viewport {
        width = 40,
        height = 20,
        style = style,
        mouse_wheel_enabled = true,
        mouse_wheel_delta = 3
    }
end

local function update(model, msg)
    if msg then
        -- Handle viewport updates
        local cmd = model.viewport:update(msg)
        if cmd then
            return model, cmd
        end
    end
    return model
end

local function view(model)
    return model.viewport:view()
end
```

### Log Viewer Pattern

```lua
local log_viewer = {
    viewport = btea.viewport {
        width = 80,
        height = 24,
        high_performance = true,
        mouse_wheel_enabled = true
    },
    
    -- Add new log entry
    append = function(self, entry)
        local current = self.viewport:view() -- Get current content
        self.viewport:set_content(current .. entry .. "\n")
        if self:at_bottom() then
            self.viewport:scroll_to_bottom()
        end
    end,
    
    -- Check if viewing latest entries
    at_bottom = function(self)
        return self.viewport:at_bottom()
    end,
    
    -- Auto-scroll to new entries
    auto_scroll = true
}
```

## Important Notes

1. The `line_up` and `line_down` methods require a line count parameter. Omitting it will result in an error.
2. Mouse wheel support requires both `mouse_wheel_enabled = true` and terminal mouse support.
3. Scroll percentage is returned as a number from 0 to 100, not 0 to 1.
4. Style objects must be valid btea style objects created with `btea.style()`.
5. The viewport's high performance mode is recommended for large content or frequent updates.
6. When setting content, the viewport maintains its scroll position unless explicitly changed.
7. Mouse wheel events automatically respect the configured `mouse_wheel_delta` value.
```
###  Path: `\spec\btea/zone.md`

```md
# Bubble Tea Zone Component Specification in Lua

This document defines the interface and usage patterns for the zone component in btea. Zones allow tracking and
interacting with specific regions in the terminal UI.

## Basic Concepts

Zones are regions in your terminal UI that can:

- Track their position and boundaries
- Detect mouse interactions
- Support nested and overlapping regions
- Maintain unique identifiers

## Creating and Managing Zones

Create a zone manager to track interactive regions:

```lua
local manager = btea.zone_manager()

-- Enable/disable zone tracking
manager:set_enabled(true)  -- or false

-- Check if zones are enabled
local enabled = manager:is_enabled()
```

## Core Operations

### Marking Zones

Mark content with a zone to make it interactive:

```lua
local marked = manager:mark("button-1", "Click Me!")
```

### Generating Unique IDs

To avoid ID conflicts between components:

```lua
local prefix = manager:new_prefix()

-- Use prefix when marking zones
local marked = manager:mark(prefix .. "button-1", "Click Me!")
```

### Scanning Content

The root component must scan the final view to process zone markers:

```lua
local final_view = manager:scan(view_content)
```

### Retrieving Zone Info

Get information about a marked zone:

```lua
local zone_info = manager:get("button-1")
```

## Zone Info Methods

The zone_info object provides several methods:

```lua
-- Check if a mouse event is within zone boundaries
if zone_info:in_bounds(msg.mouse) then
    -- Handle interaction
end

-- Get relative position of mouse within zone
local x, y = zone_info:pos(msg.mouse)

-- Check if zone info exists
if zone_info:is_zero() then
    -- Handle unknown zone
end
```

## Complete Example

Here's a complete example of using zones in a component:

```lua
local M = {}

function M.initial()
    return {
        manager = btea.zone_manager(),
        prefix = nil,
        items = {"Item 1", "Item 2", "Item 3"},
        selected = nil
    }
end

function M.init(model)
    model.prefix = model.manager:new_prefix()
    return model
end

function M.update(model, msg)
    if msg.mouse then
        for i, item in ipairs(model.items) do
            local zone_id = model.prefix .. "item-" .. i
            if model.manager:get(zone_id):in_bounds(msg.mouse) then
                model.selected = i
                break
            end
        end
    end
    return model
end

function M.view(model)
    local output = {}
    
    for i, item in ipairs(model.items) do
        local zone_id = model.prefix .. "item-" .. i
        local style = i == model.selected and "reverse" or "normal"
        local marked = model.manager:mark(zone_id, style(item))
        table.insert(output, marked)
    end
    
    -- Root component must scan the final output
    return model.manager:scan(table.concat(output, "\n"))
end

return M
```

## Best Practices

1. **Zone IDs**
    - Use unique prefixes for components
    - Make IDs descriptive and structured
    - Consider hierarchical naming for nested components

2. **Performance**
    - Only mark regions that need interaction
    - Clear unused zones when components unmount
    - Consider disabling zones when not needed

3. **Mouse Handling**
    - Check bounds before processing clicks
    - Use relative positioning for precise interactions
    - Consider z-index when zones overlap

4. **Integration**
    - Scan only at the root component
    - Clean up managers when closing app
    - Pass manager instance to child components that need it

## Common Patterns

### Clickable List

```lua
local function make_list(items, manager, prefix)
    local output = {}
    for i, item in ipairs(items) do
        local marked = manager:mark(prefix .. i, item)
        table.insert(output, marked)
    end
    return table.concat(output, "\n")
end
```

### Interactive Grid

```lua
local function make_grid(grid, manager, prefix)
    local output = {}
    for y, row in ipairs(grid) do
        local row_output = {}
        for x, cell in ipairs(row) do
            local id = string.format("%s_%d_%d", prefix, x, y)
            table.insert(row_output, manager:mark(id, cell))
        end
        table.insert(output, table.concat(row_output, " "))
    end
    return table.concat(output, "\n")
end
```

### Nested Components

```lua
local function parent_view(model)
    local output = {
        model.manager:mark("header", header_view()),
        model.manager:mark("sidebar", sidebar_view()),
        model.manager:mark("main", main_view())
    }
    -- Only scan at root
    return model.manager:scan(table.concat(output, "\n"))
end
```

## Notes

- Zone markers are automatically removed during scanning
- Zones persist until cleared or manager is disabled
- Mouse events only register for marked regions
- Scanning should happen only once at the root level
- Zone coordinates use 0-based indexing
```