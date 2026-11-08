--Implementation of a command.
--!strict

local Players = game:GetService("Players")

local IncludedCommandUtil = require(script.Parent.Parent:WaitForChild("IncludedCommandUtil"))
local Types = require(script.Parent.Parent.Parent:WaitForChild("Types"))

return {
    Keyword = "ban",
    Category = "Administrative",
    Description = "Bans players.",
    Arguments = {
        {
            Type = "basicSystemPlayers",
            Name = "Players",
            Description = "Players to ban.",
        },
        {
            Type = "string",
            Name = "Message",
            Description = "Ban message.",
            Optional = true,
        },
    },
    ServerLoad = function(Api: Types.BasicSystemApiServer)
        --Connect kicking players on entry.
        Players.PlayerAdded:Connect(function(Player: Player)
            local BanData = Api.CommandData.BannedUserIds[Player.UserId]
            if BanData then
                if BanData[1] == true then
                    Player:Kick()
                else
                    Player:Kick(BanData[1])
                end
            end
        end)

        --Add the configuration bans.
        Api.CommandData.BannedUserIds = {}
        for UserId, Reason in Api.Configuration.BannedUsers do
            Api.CommandData.BannedUserIds[UserId] = {Reason, "NAME NOT FETCHED", "NAME NOT FETCHED"}
            task.spawn(function()
                pcall(function()
                    local Name = Players:GetNameFromUserIdAsync(UserId)
                    Api.CommandData.BannedUserIds[UserId][2] = string.lower(Name)
                    Api.CommandData.BannedUserIds[UserId][3] = Name
                end)
            end)
        end
    end,
    ServerRun = function(CommandContext: Types.CmdrCommandContext, Players: {Player}, Message: string?)
        local Util = IncludedCommandUtil.ForContext(CommandContext)
        local Api = Util:GetServerApi()

        local Executor = CommandContext.Executor
        local MinimumLevel = Api.Configuration:GetCommandAdminLevel("Administrative", "ban")
        for _, Player in Players do
            if Player == Executor then
                Util:SendError("You can't ban yourself.")
                continue
            end
            if not Api.Authorization:CanModeratePlayer(Executor, Player, MinimumLevel) then
                Util:SendError("You can only ban players with a confirmed rank below yours.")
                continue
            end

            local FilteredMessage = Message and Api.Filter:FilterString(Message, Executor, Player)
            --Filtering may yield while a rank changes or a player leaves.
            if not Api.Authorization:CanModeratePlayer(Executor, Player, MinimumLevel) then continue end
            Api.CommandData.BannedUserIds[Player.UserId] = {FilteredMessage or true, string.lower(Player.Name), Player.Name}
            Player:Kick(FilteredMessage)
        end
    end,
}