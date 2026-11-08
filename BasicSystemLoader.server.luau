--Starts the locally bundled Basic System.
--!strict

local Root = script.Parent

local Success, Error = xpcall(function()
    local Settings = require(Root:WaitForChild("BasicSystemSettings") :: ModuleScript)
    local LoadBasicSystem = require(Root:WaitForChild("BasicSystemMain") :: ModuleScript)
    LoadBasicSystem(script, Settings)
end, debug.traceback)
if not Success then
    warn(`[BASIC SYSTEM] Failed to load: {Error}`)
end
