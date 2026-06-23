-- Lightweight Remote Spy Alternative
-- Outputs directly to the Developer Console (F9) and logs to "RemoteSpy.txt"

local appendfile = appendfile or writefile or print
local format = string.format

-- Initialize or clear the log file safely
pcall(function()
    writefile("RemoteSpy.txt", "-- Headless RemoteSpy Log Initialized\n\n")
end)

-- Helper function to serialize arguments into a readable string
local function serializeArgs(args)
    local formatted = {}
    for i, v in pairs(args) do
        local typeStr = typeof(v)
        if typeStr == "string" then
            table.insert(formatted, format('"%s"', v))
        elseif typeStr == "Instance" then
            table.insert(formatted, v:GetFullName())
        else
            table.insert(formatted, tostring(v))
        end
    end
    return table.concat(formatted, ", ")
end

-- Main logging logic
local function logRemoteCall(method, remote, args)
    if not typeof(remote) == "Instance" then return end
    
    local remoteName = remote.Name
    local remotePath = remote:GetFullName()
    local argString = serializeArgs(args)
    
    -- Format the log line cleanly
    local logLine = format("[%s] Name: %s | Path: game.%s\nArgs: (%s)\n%s\n", 
        method:upper(), 
        remoteName, 
        remotePath, 
        argString,
        string.rep("-", 50)
    )
    
    -- Print to F9 Developer Console
    print(logLine)
    
    -- Append directly to the text file
    pcall(function()
        appendfile("RemoteSpy.txt", logLine)
    end)
end

-- Hook into the __namecall metamethod safely
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    
    if method == "FireServer" or method == "InvokeServer" or method == "fireServer" or method == "invokeServer" then
        local args = { ... }
        -- Run the logging side-effect inside a pcall to guarantee the game doesn't crash if an argument fails to stringify
        pcall(logRemoteCall, method, self, args)
    end
    
    return oldNamecall(self, ...)
end))

print("[RemoteSpy] Headless script active! Check your F9 Developer Console and your executor workspace folder for 'RemoteSpy.txt'.")
