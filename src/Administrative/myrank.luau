--!strict

local IncludedCommandUtil = require(script.Parent.Parent:WaitForChild("IncludedCommandUtil"))
local Types = require(script.Parent.Parent.Parent:WaitForChild("Types"))

return {
    Keyword = "myrank",
    Category = "Administrative",
    Prefix = "!",
    Description = "Shows your active Basic System rank.",
    ClientRun = function(Context: Types.CmdrCommandContext): string
        local Api = IncludedCommandUtil.ForContext(Context):GetClientApi()
        local Rank = Api.Authorization:YieldForAdminLevel(Context.Executor)
        return `Basic System rank: {Api.Configuration:GetRankName(Rank)} ({Rank}).`
    end,
}
