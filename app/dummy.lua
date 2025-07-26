-- Dummy process for token refresh service override
-- This process does nothing but satisfies the process service requirement

function run()
    -- Do nothing, just keep the process alive
    while true do
        time.sleep(3600) -- Sleep for 1 hour
    end
end

return { run = run } 