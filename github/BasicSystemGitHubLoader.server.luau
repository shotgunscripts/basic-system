--Fetches the server code from the configured GitHub repository.
--!strict

local Root = script.Parent
local ServerScriptService = game:GetService("ServerScriptService")

local Success, Error = xpcall(function()
    assert(not ServerScriptService:FindFirstChild("BasicSystem"), "Basic System is already running in this server.")
    local GitHub = require(Root:WaitForChild("BasicSystemGitHubSettings") :: ModuleScript)
    local Settings = require(Root:WaitForChild("BasicSystemSettings") :: ModuleScript)
    local Main = Root:WaitForChild("BasicSystemMain") :: ModuleScript
    local Core = Main:WaitForChild("BasicSystem")
    local Runtime = require(Core:WaitForChild("GitHubRuntime") :: ModuleScript)

    Runtime.Load(GitHub.Repository, GitHub.Ref)
    local LoadBasicSystem = require(Main)
    LoadBasicSystem(script, Settings)
    print("[BASIC SYSTEM] Server code loaded from GitHub.")
end, debug.traceback)
if not Success then
    warn(`[BASIC SYSTEM] GitHub startup failed: {Error}`)
end
