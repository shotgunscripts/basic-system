--Tests the Serialization class.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Serialization = require(ReplicatedStorage.Packages.BasicSystem.BasicSystem.IncludedCommands.Local.Resources.Serialization)

return function()
    describe("Serialization", function()
        it("should have the needed serializers.", function()
            Serialization:CheckSerializers()
        end)
    end)
end