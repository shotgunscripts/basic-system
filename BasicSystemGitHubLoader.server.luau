--!strict

--Use your public GitHub owner/repo and the branch containing Basic-System.server.json.
local Repository = "YOUR-USERNAME/YOUR-REPO"
local Ref = "main"

local Root = script.Parent
local ServerScriptService = game:GetService("ServerScriptService")

local Success, StartupError = xpcall(function()
    assert(not ServerScriptService:FindFirstChild("BasicSystem"), "Basic System is already running in this server.")

    local Settings = require(Root:WaitForChild("BasicSystemSettings") :: ModuleScript)
    local Main = Root:WaitForChild("BasicSystemMain") :: ModuleScript
    local Core = Main:WaitForChild("BasicSystem")
    local Runtime = require(Core:WaitForChild("GitHubRuntime") :: ModuleScript)

    Runtime.Load(Repository, Ref)
    local LoadBasicSystem = require(Main)
    LoadBasicSystem(script, Settings)
    print("[BASIC SYSTEM] Server code loaded from GitHub.")
end, debug.traceback)

if not Success then
    warn(`[BASIC SYSTEM] GitHub startup failed: {StartupError}`)
end
