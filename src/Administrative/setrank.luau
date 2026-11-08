--!strict

local IncludedCommandUtil = require(script.Parent.Parent:WaitForChild("IncludedCommandUtil"))
local Types = require(script.Parent.Parent.Parent:WaitForChild("Types"))

return {
    Keyword = {"setrank", "rank"},
    Category = "Administrative",
    Description = "Saves a rank for an online player.",
    Arguments = {
        { Type = "basicSystemRankPlayer", Name = "Username", Description = "Exact Roblox username in this server." },
        { Type = "basicSystemRank", Name = "Rank", Description = "Rank name or level." },
    },
    ServerRun = function(Context: Types.CmdrCommandContext, Target: Player, Rank: number): string
        local Api = IncludedCommandUtil.ForContext(Context):GetServerApi()
        return Api.Authorization:ChangeRankAsync(Context.Executor, Target, Rank, true)
    end,
}
