--!strict

local IncludedCommandUtil = require(script.Parent.Parent:WaitForChild("IncludedCommandUtil"))
local Types = require(script.Parent.Parent.Parent:WaitForChild("Types"))

return {
    Keyword = {"admin", "temprank"},
    Category = "Administrative",
    Description = "Assigns a rank until the player leaves this server.",
    Arguments = {
        { Type = "basicSystemPlayers", Name = "Players", Description = "Players to assign a temporary rank to." },
        { Type = "basicSystemRank", Name = "Rank", Description = "Rank name or level.", Default = 1 },
    },
    ServerRun = function(Context: Types.CmdrCommandContext, Players: {Player}, Rank: number)
        local Util = IncludedCommandUtil.ForContext(Context)
        local Authorization = Util:GetServerApi().Authorization
        for _, Player in Players do
            Util:SendMessage(Authorization:ChangeRankAsync(Context.Executor, Player, Rank, false))
        end
    end,
}
