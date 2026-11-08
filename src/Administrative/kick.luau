--Implementation of a command.
--!strict

local IncludedCommandUtil = require(script.Parent.Parent:WaitForChild("IncludedCommandUtil"))
local Types = require(script.Parent.Parent.Parent:WaitForChild("Types"))

return {
    Keyword = "kick",
    Category = "Administrative",
    Description = "Kicks players.",
    Arguments = {
        {
            Type = "basicSystemPlayers",
            Name = "Players",
            Description = "Players to kick.",
        },
        {
            Type = "string",
            Name = "Message",
            Description = "Kick message message.",
            Optional = true,
        },
    },
    ServerRun = function(CommandContext: Types.CmdrCommandContext, Players: {Player}, Message: string?)
        local Util = IncludedCommandUtil.ForContext(CommandContext)
        local Api = Util:GetServerApi()

        local Executor = CommandContext.Executor
        local MinimumLevel = Api.Configuration:GetCommandAdminLevel("Administrative", "kick")
        for _, Player in Players do
            if Player == Executor then
                Util:SendError("You can't kick yourself.")
                continue
            end
            if not Api.Authorization:CanModeratePlayer(Executor, Player, MinimumLevel) then
                Util:SendError("You can only kick players with a confirmed rank below yours.")
                continue
            end

            local FilteredMessage = Message and Api.Filter:FilterString(Message, Executor, Player)
            --Filtering may yield while a rank changes or a player leaves.
            if not Api.Authorization:CanModeratePlayer(Executor, Player, MinimumLevel) then continue end
            Player:Kick(FilteredMessage)
        end
    end,
}