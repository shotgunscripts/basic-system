--Rank arguments shared by the command bar and server.
--!strict

local Players = game:GetService("Players")
local Types = require(script.Parent.Parent.Parent:WaitForChild("Types"))

return function(Api: Types.BasicSystemApi)
    local Config = Api.Configuration
    local AssignableNames = {}
    for Level, Name in Config.AdminNames do
        if Level < Config.OwnerRankLevel then
            table.insert(AssignableNames, Name)
        end
    end
    table.sort(AssignableNames)
    local FindRankNames = Api.Cmdr.Util.MakeFuzzyFinder(AssignableNames)

    Api.Cmdr.Registry:RegisterType("basicSystemRank", {
        Transform = function(Text: string)
            return { Level = Config:ResolveRank(Text), Text = Text }
        end,
        Validate = function(Value)
            return Value.Level ~= nil and Value.Level < Config.OwnerRankLevel,
                "Choose a rank by name or level from the rank list."
        end,
        Autocomplete = function(Value)
            return FindRankNames(Value.Text)
        end,
        Parse = function(Value)
            return Value.Level
        end,
    } :: any)

    Api.Cmdr.Registry:RegisterType("basicSystemRankPlayer", {
        Transform = function(Text: string)
            local Username = string.lower(Text):gsub("^@", "")
            local Matches = {}
            local Target = nil
            for _, Player in Players:GetPlayers() do
                local Name = string.lower(Player.Name)
                if Name == Username then
                    Target = Player
                end
                if string.sub(Name, 1, #Username) == Username then
                    table.insert(Matches, Player.Name)
                end
            end
            return { Target = Target, Matches = Matches }
        end,
        Validate = function(Value)
            return Value.Target ~= nil, "Enter the exact username of a player in this server."
        end,
        Autocomplete = function(Value)
            return Value.Matches
        end,
        Parse = function(Value)
            return Value.Target
        end,
    } :: any)
end
