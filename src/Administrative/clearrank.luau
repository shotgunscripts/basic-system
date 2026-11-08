--!strict

local IncludedCommandUtil = require(script.Parent.Parent:WaitForChild("IncludedCommandUtil"))
local Types = require(script.Parent.Parent.Parent:WaitForChild("Types"))

return {
    Keyword = {"clearrank", "unrank"},
    Category = "Administrative",
    Description = "Clears a saved rank and restores the player's configured rank.",
    Arguments = {
        { Type = "basicSystemRankPlayer", Name = "Username", Description = "Exact Roblox username in this server." },
    },
    ServerRun = function(Context: Types.CmdrCommandContext, Target: Player): string
        local Api = IncludedCommandUtil.ForContext(Context):GetServerApi()
        return Api.Authorization:ChangeRankAsync(Context.Executor, Target, nil, true)
    end,
}
