-- Bulletproof Remote Spy
-- Outputs directly to the Developer Console (F9) and logs to "RemoteSpy.txt"

local appendfile = appendfile or writefile or print
local format = string.format

-- Initialize or clear the log file safely
pcall(function()
    if type(writefile) == "function" then
        writefile("RemoteSpy.txt", "-- Headless RemoteSpy Log Initialized\n\n")
    end
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
    if typeof(remote) ~= "Instance" then return end
    
    local logLine = format("[%s] Name: %s | Path: game.%s\nArgs: (%s)\n%s\n", 
        method:upper(), 
        remote.Name, 
        remote:GetFullName(), 
        serializeArgs(args),
        string.rep("-", 50)
    )
    
    -- Print to F9 Developer Console
    print(logLine)
    
    -- Append directly to the text file
    pcall(function()
        if type(appendfile) == "function" then
            appendfile("RemoteSpy.txt", logLine)
        end
    end)
end

-- Safely set up the hook function
local oldNamecall

local function namecallHook(self, ...)
    -- Safely get the method being called
    local method = ""
    if type(getnamecallmethod) == "function" then
        method = getnamecallmethod()
    end
    
    if method == "FireServer" or method == "InvokeServer" or method == "fireServer" or method == "invokeServer" then
        pcall(logRemoteCall, method, self, { ... })
    end
    
    return oldNamecall(self, ...)
end

-- Bypass anti-cheat detection only if newcclosure is supported by Xeno
local finalHook = type(newcclosure) == "function" and newcclosure(namecallHook) or namecallHook

-- Inject the hook using the best available method
if type(hookmetamethod) == "function" then
    oldNamecall = hookmetamethod(game, "__namecall", finalHook)
else
    -- Fallback to raw metatable modification if hookmetamethod is nil
    local gm = getrawmetatable(game)
    oldNamecall = gm.__namecall
    
    -- Bypass read-only protection safely
    pcall(function()
        if type(setreadonly) == "function" then 
            setreadonly(gm, false)
        elseif type(make_writeable) == "function" then 
            make_writeable(gm) 
        end
    end)
    
    gm.__namecall = finalHook
    
    -- Restore read-only protection
    pcall(function()
        if type(setreadonly) == "function" then 
            setreadonly(gm, true)
        elseif type(make_readonly) == "function" then 
            make_readonly(gm) 
        end
    end)
end

print("[RemoteSpy] Bulletproof script active! Execute your custom game mechanics and check F9 / RemoteSpy.txt for the captured network data.")
