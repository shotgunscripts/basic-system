--Implementation of a command.
--!strict

local Types = require(script.Parent.Parent.Parent:WaitForChild("Types"))

return {
    Keyword = "rocket",
    Category = "FunCommands",
    Description = "Adds a rocket to a set of players.",
    Arguments = {
        {
            Type = "basicSystemPlayers",
            Name = "Players",
            Description = "Players to give a rocket to.",
        },
    },
    ServerRun = function(CommandContext: Types.CmdrCommandContext, Players: {Player})
        for _, Player in Players do
            if Player.Character then
                local HumanoidRootPart = Player.Character:FindFirstChild("HumanoidRootPart") :: Part
                if HumanoidRootPart and not HumanoidRootPart:FindFirstChild("BasicSystemRocket") then
                    local BasicSystemRocket = Instance.new("Part")
                    BasicSystemRocket.Name = "BasicSystemRocket"
                    BasicSystemRocket.Material = Enum.Material.SmoothPlastic
                    BasicSystemRocket.CanCollide = false
                    BasicSystemRocket.Size = Vector3.new(1, 2, 2)
                    BasicSystemRocket.Parent = HumanoidRootPart
                    
                    local Mesh = Instance.new("SpecialMesh")
                    Mesh.MeshType = Enum.MeshType.FileMesh
                    Mesh.MeshId = "rbxassetid://2251534"
                    Mesh.Scale = Vector3.new(0.5, 0.5, 0.5)
                    Mesh.Parent = BasicSystemRocket
                    
                    local Weld = Instance.new("Weld")
                    Weld.Part0 = HumanoidRootPart
                    Weld.Part1 = BasicSystemRocket
                    Weld.C1 = CFrame.new(0, -0.8, 0.4) * CFrame.Angles(-math.pi / 2, 0, 0)
                    Weld.Parent = BasicSystemRocket
                    
                    local Fire = Instance.new("Fire")
                    Fire.Heat = 0
                    Fire.Parent = BasicSystemRocket
                    
                    local BodyVelocity = Instance.new("BodyVelocity")
                    BodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
                    BodyVelocity.Velocity = Vector3.new(0, 75, 0)
                    BodyVelocity.Parent = BasicSystemRocket
                end
            end
        end
    end,
}