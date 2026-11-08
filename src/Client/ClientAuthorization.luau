--Handles users being authorized on the client.
--!strict

local Players = game:GetService("Players")
local Types = require(script.Parent:WaitForChild("Types"))
local Authorization = require(script.Parent:WaitForChild("Common"):WaitForChild("Authorization")) :: Types.Authorization

local ClientAuthorization = {}
ClientAuthorization.__index = ClientAuthorization
setmetatable(ClientAuthorization, Authorization)

export type ClientAuthorization = {
    AdminLevels: {[string]: number},
} & typeof(setmetatable({}, ClientAuthorization)) & Types.Authorization



--[[
Creates a client authorization instance.
--]]
function ClientAuthorization.new(Configuration: Types.Configuration, BasicSystemRemotes: Folder): ClientAuthorization
    local self = setmetatable(Authorization.new(Configuration) :: Types.Authorization, ClientAuthorization) :: ClientAuthorization
    local AuthorizationEvents = BasicSystemRemotes:WaitForChild("AuthorizationEvents") :: Folder
    local GetAdminLevels = AuthorizationEvents:WaitForChild("GetAdminLevels") :: RemoteFunction
    local AdminLevelChanged = AuthorizationEvents:WaitForChild("AdminLevelChanged") :: RemoteEvent
    local JoinedDuringSnapshot = self.AdminLevels

    AdminLevelChanged.OnClientEvent:Connect(function(UserId: number, AdminLevel: number)
        self.AdminLevels[tostring(UserId)] = AdminLevel
        local Player = Players:GetPlayerByUserId(UserId)
        if Player then
            self.AdminLevelChanged:Fire(Player)
        end
    end)
    local Snapshot = GetAdminLevels:InvokeServer()
    for UserId, AdminLevel in JoinedDuringSnapshot do
        Snapshot[UserId] = AdminLevel
    end
    self.AdminLevels = Snapshot
    Players.PlayerRemoving:Connect(function(Player: Player)
        self.AdminLevels[tostring(Player.UserId)] = nil
    end)
    return self
end



return ClientAuthorization