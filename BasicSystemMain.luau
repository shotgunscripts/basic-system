--Loads the bundled server module and installs the client loader.
--!strict

return function(LoaderScript: Instance?, Configuration: {[string]: any})
    local Module = script:WaitForChild("BasicSystem") :: ModuleScript
    local ServerScriptService = game:GetService("ServerScriptService")
    assert(not ServerScriptService:FindFirstChild("BasicSystem"), "Basic System is already installed in ServerScriptService.")
    Module.Parent = ServerScriptService

    local BasicSystem = require(Module) :: any
    BasicSystem:Load(Configuration)
    BasicSystem:LoadIncludedCommands()
    BasicSystem:LoadClientLoader()

    if LoaderScript then
        for _, Child in LoaderScript:GetChildren() do
            if Child:IsA("ModuleScript") then
                local Success, Error = xpcall(function()
                    require(Child)
                end, debug.traceback)
                if not Success then
                    warn(`{Child:GetFullName()} failed to load: {Error}`)
                end
            end
        end
    end

    print(`[BASIC SYSTEM] {BasicSystem.Version} loaded.`)
    return BasicSystem
end
