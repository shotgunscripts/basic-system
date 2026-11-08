--!strict

local IncludedCommandUtil = require(script.Parent.Parent:WaitForChild("IncludedCommandUtil"))
local Types = require(script.Parent.Parent.Parent:WaitForChild("Types"))

return {
    Keyword = "unadmin",
    Category = "Administrative",
    Description = "Sets the target's rank to Player until they leave this server.",
    Arguments = {
        { Type = "basicSystemPlayers", Name = "Players", Description = "Players to demote for this session." },
    },
    ServerRun = function(Context: Types.CmdrCommandContext, Players: {Player})
        local Util = IncludedCommandUtil.ForContext(Context)
        local Authorization = Util:GetServerApi().Authorization
        for _, Player in Players do
            Util:SendMessage(Authorization:ChangeRankAsync(Context.Executor, Player, -1, false))
        end
    end,
}
