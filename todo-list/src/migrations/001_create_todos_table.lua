local function define_migration()
    migration("Create todos table with all necessary fields", function()
        database("sqlite", function()
            up(function(db)
                -- Create todos table
                local _, err = db:execute([[
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
                    )
                ]])
                if err then error(err) end

                -- Create index on completed field
                _, err = db:execute("CREATE INDEX idx_todos_completed ON todos(completed)")
                if err then error(err) end

                -- Create index on priority field
                _, err = db:execute("CREATE INDEX idx_todos_priority ON todos(priority)")
                if err then error(err) end

                -- Create index on category field
                _, err = db:execute("CREATE INDEX idx_todos_category ON todos(category)")
                if err then error(err) end

                -- Create index on due_date field
                _, err = db:execute("CREATE INDEX idx_todos_due_date ON todos(due_date)")
                if err then error(err) end
            end)

            down(function(db)
                db:execute("DROP TABLE IF EXISTS todos")
            end)
        end)
    end)
end

return require("migration").define(define_migration)
