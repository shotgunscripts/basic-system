--Stores and parses the configuration.
--!strict

local DEFAULT_RANK_NAMES = {
    [-1] = "Player",
    [0] = "Helper",
    [1] = "Moderator",
    [2] = "Admin",
    [3] = "Senior Admin",
    [4] = "Head Admin",
    [5] = "Owner",
}

local DEFAULT_COMMAND_LEVELS: {[string]: {[string]: number}} = {
    Administrative = {
        admin = 5, unadmin = 5, setrank = 5, clearrank = 5,
        myrank = -1, admins = 0, cmdbar = 0,
        cmds = -1, usage = -1, alias = -1, keybind = -1, unkeybind = -1, keybinds = -1,
        kick = 1, ban = 3, unban = 3, bans = 3, slock = 2, logs = 1,
        system = 4, snapshot = 4, featureflag = 5, featureflags = 4, featureflaglogs = 4,
    },
    BasicCommands = {
        mute = 1, unmute = 1, respawn = 1, refresh = 1, joinlogs = 1, chatlogs = 1,
        shutdown = 4, softshutdown = 4, crash = 5, gear = 5, startergive = 4,
    },
    BuildUtility = { s = 5, insert = 5, clearterrain = 4 },
    FunCommands = { hat = 5, face = 5 },
}

local Configuration = {}
Configuration.__index = Configuration

export type Configuration = {
    Version: string,
    VersionNumberId: number,
    CmdrVersion: string,
    RawConfiguration: {[string]: any},
    CommandPrefix: string,
    ActivationKeys: {Enum.KeyCode},
    DefaultAdminLevel: number,
    AdministrativeLevel: number,
    BuildUtilityLevel: number,
    BasicCommandsLevel: number,
    UsefulFunCommandsLevel: number,
    FunCommandsLevel: number,
    PersistentCommandsLevel: number,
    Admins: {[number]: number},
    AdminNames: {[number]: string},
    GroupAdminLevels: {[number]: {[number]: number}},
    OwnerUserIds: {[number]: boolean},
    OwnerRankLevel: number,
    RankPersistenceEnabled: boolean,
    StudioRankPersistenceEnabled: boolean,
    BannedUsers: {[number]: string | boolean},
    CommandConfigurations: {[string]: any},
    CommandLevelOverrides: {[string]: {[string]: number | string}},
    FeatureFlagOverrides: {[string]: any},
} & typeof(setmetatable({}, Configuration))

local function NormalizeRankName(Name: string): string
    return (string.lower(Name):gsub("[%s_%-]+", ""))
end

function Configuration.ResolveRank(self: Configuration, Value: number | string): number?
    local Level = tonumber(Value)
    if Level then
        return if self.AdminNames[Level] then Level else nil
    end
    if type(Value) == "string" then
        local Name = NormalizeRankName(Value)
        for RankLevel, RankName in self.AdminNames do
            if NormalizeRankName(RankName) == Name then
                return RankLevel
            end
        end
    end
    return nil
end

local function ReadAssignedRank(Self: Configuration, Value: number | string, Setting: string): number
    local Level = assert(Self:ResolveRank(Value), `Unknown Basic System rank "{Value}" in {Setting}.`)
    assert(Level < Self.OwnerRankLevel, `Use OwnerUserIds to grant the Owner rank instead of {Setting}.`)
    return Level
end

function Configuration.new(ConfigurationTable: {[string]: any}?): Configuration
    local Raw = ConfigurationTable or {}
    local RankNames = table.clone(DEFAULT_RANK_NAMES)
    local OwnerRankLevel = 5
    for Level, Name in Raw.AdminNames or {} do
        assert(type(Level) == "number" and Level >= -1 and Level < math.huge and Level % 1 == 0,
            "AdminNames keys must be whole rank levels of -1 or higher.")
        assert(type(Name) == "string" and NormalizeRankName(Name) ~= "" and not tonumber(Name),
            "AdminNames values must be nonempty rank names.")
        RankNames[Level] = Name
        OwnerRankLevel = math.max(OwnerRankLevel, Level)
    end
    if OwnerRankLevel > 5 and not (Raw.AdminNames and Raw.AdminNames[5]) then
        RankNames[5] = "Lead Admin"
    end
    local UsedNames = {}
    for _, Name in RankNames do
        local Key = NormalizeRankName(Name)
        assert(not UsedNames[Key], `Duplicate Basic System rank name "{Name}".`)
        UsedNames[Key] = true
    end

    local self = setmetatable({
        Version = "Version 1.0.0",
        VersionNumberId = 1.0,
        CmdrVersion = "Version 1.12.0 (030e1a6)",
        RawConfiguration = Raw,
        CommandPrefix = Raw.CommandPrefix or ":",
        ActivationKeys = table.clone(Raw.ActivationKeys or {Enum.KeyCode.BackSlash}),
        DefaultAdminLevel = -1,
        AdministrativeLevel = Raw.AdministrativeLevel or 2,
        BuildUtilityLevel = Raw.BuildUtilityLevel or 3,
        BasicCommandsLevel = Raw.BasicCommandsLevel or 2,
        UsefulFunCommandsLevel = Raw.UsefulFunCommandsLevel or 2,
        FunCommandsLevel = Raw.FunCommandsLevel or 3,
        PersistentCommandsLevel = Raw.PersistentCommandsLevel or Raw.PersistentCommands or 4,
        Admins = {},
        AdminNames = RankNames,
        GroupAdminLevels = {},
        OwnerUserIds = Raw.OwnerUserIds or {},
        OwnerRankLevel = OwnerRankLevel,
        RankPersistenceEnabled = Raw.RankPersistenceEnabled ~= false,
        StudioRankPersistenceEnabled = Raw.StudioRankPersistenceEnabled == true,
        BannedUsers = Raw.BannedUsers or {},
        CommandLevelOverrides = Raw.CommandLevelOverrides or {},
        FeatureFlagOverrides = Raw.FeatureFlagOverrides or {},
        CommandConfigurations = table.clone(Raw.CommandConfigurations or {}),
    }, Configuration) :: Configuration

    self.DefaultAdminLevel = ReadAssignedRank(self, Raw.DefaultAdminLevel or -1, "DefaultAdminLevel")
    for UserId, Rank in Raw.Admins or {} do
        self.Admins[UserId] = ReadAssignedRank(self, Rank, `Admins[{UserId}]`)
    end
    for GroupId, Ranks in Raw.GroupAdminLevels or {} do
        self.GroupAdminLevels[GroupId] = {}
        for GroupRank, Rank in Ranks do
            self.GroupAdminLevels[GroupId][GroupRank] =
                ReadAssignedRank(self, Rank, `GroupAdminLevels[{GroupId}][{GroupRank}]`)
        end
    end

    self.CommandConfigurations.DefaultServerLockAdminLevel =
        self.CommandConfigurations.DefaultServerLockAdminLevel or 0
    self.CommandConfigurations.PersistentBanImmuneLevel =
        self.CommandConfigurations.PersistentBanImmuneLevel or self.PersistentCommandsLevel

    if table.find(self.ActivationKeys, Enum.KeyCode.BackSlash) and not table.find(self.ActivationKeys, Enum.KeyCode.F2) then
        table.insert(self.ActivationKeys, Enum.KeyCode.F2)
    end
    return self
end

function Configuration.GetRaw(self: Configuration): {[string]: any}
    return self.RawConfiguration
end

function Configuration.GetRankName(self: Configuration, Level: number): string
    return self.AdminNames[Level] or tostring(Level)
end

function Configuration.GetCommandAdminLevel(self: Configuration, Category: string, Command: string): number
    local CategoryDefault = (self :: any)[`{Category}Level`] :: number
    assert(CategoryDefault, `"{Category}" is not a command category supported by the configuration.`)

    local Overrides = self.CommandLevelOverrides[Category]
    local Override = Overrides and Overrides[Command]
    if type(Override) == "string" then
        return assert(self:ResolveRank(Override), `Unknown rank "{Override}" for command "{Command}".`)
    elseif type(Override) == "number" then
        return Override
    end
    local Defaults = DEFAULT_COMMAND_LEVELS[Category]
    local Default = Defaults and Defaults[Command]
    if Default == 5 then
        return self.OwnerRankLevel
    end
    return Default or CategoryDefault
end

return Configuration
