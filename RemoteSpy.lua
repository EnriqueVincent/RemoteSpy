-- Ultimate Fallback RemoteSpy
-- Outputs directly to Developer Console (F9) and logs to "RemoteSpy.txt"

local appendfile = appendfile or writefile or print
local format = string.format

-- Initialize log file
pcall(function()
    if type(writefile) == "function" then
        writefile("RemoteSpy.txt", "-- Headless RemoteSpy Log Initialized\n\n")
    end
end)

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

local function logRemoteCall(method, remote, args)
    if typeof(remote) ~= "Instance" then return end
    
    local logLine = format("[%s] Name: %s | Path: game.%s\nArgs: (%s)\n%s", 
        method:upper(), remote.Name, remote:GetFullName(), serializeArgs(args), string.rep("-", 50))
    
    print(logLine)
    
    pcall(function()
        if type(appendfile) == "function" then 
            appendfile("RemoteSpy.txt", logLine .. "\n") 
        end
    end)
end

-- Hooking Logic cascade
local success = false

if type(hookmetamethod) == "function" then
    -- Method 1: Modern Metatable Hook
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = type(getnamecallmethod) == "function" and getnamecallmethod() or ""
        if method == "FireServer" or method == "InvokeServer" then
            pcall(logRemoteCall, method, self, { ... })
        end
        return oldNamecall(self, ...)
    end)
    success = true

elseif type(getrawmetatable) == "function" then
    -- Method 2: Legacy Metatable Hook
    local gm = getrawmetatable(game)
    local oldNamecall = gm.__namecall
    
    pcall(function() 
        if type(setreadonly) == "function" then setreadonly(gm, false) 
        elseif type(make_writeable) == "function" then make_writeable(gm) end 
    end)
    
    gm.__namecall = function(self, ...)
        local method = type(getnamecallmethod) == "function" and getnamecallmethod() or ""
        if method == "FireServer" or method == "InvokeServer" then
            pcall(logRemoteCall, method, self, { ... })
        end
        return oldNamecall(self, ...)
    end
    
    pcall(function() 
        if type(setreadonly) == "function" then setreadonly(gm, true) 
        elseif type(make_readonly) == "function" then make_readonly(gm) end 
    end)
    success = true

elseif type(hookfunction) == "function" then
    -- Method 3: Direct Function Hooking (Bypasses Metatable)
    local RE = Instance.new("RemoteEvent")
    local RF = Instance.new("RemoteFunction")
    
    local oldFire
    oldFire = hookfunction(RE.FireServer, function(self, ...)
        pcall(logRemoteCall, "FireServer", self, { ... })
        return oldFire(self, ...)
    end)
    
    local oldInvoke
    oldInvoke = hookfunction(RF.InvokeServer, function(self, ...)
        pcall(logRemoteCall, "InvokeServer", self, { ... })
        return oldInvoke(self, ...)
    end)
    success = true
end

if success then
    print("[RemoteSpy] Successfully injected! Listening for remote traffic...")
else
    warn("[RemoteSpy] FATAL ERROR: Your executor lacks hookmetamethod, getrawmetatable, AND hookfunction. Remote tracking is completely unsupported in this environment.")
end
