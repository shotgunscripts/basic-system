--Resolves configured, saved, and temporary ranks on the server.
--!strict

local GROUP_LEVEL_CACHE_EXPIRE_SECONDS = 30 * 60

local DataStoreService = game:GetService("DataStoreService")
local GroupService = game:GetService("GroupService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Authorization = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("Authorization"))
local Configuration = require(script.Parent.Parent:WaitForChild("Common"):WaitForChild("Configuration"))

type PlayerRanks = {
    Configured: number?,
    Saved: number?,
    Temporary: number?,
    ConfiguredRead: boolean?,
    SavedRead: boolean?,
}

local ServerAuthorization = {}
ServerAuthorization.__index = ServerAuthorization
setmetatable(ServerAuthorization, Authorization)

export type ServerAuthorization = {
    GroupService: GroupService,
    GameId: number,
    CreatorId: number,
    CreatorType: Enum.CreatorType,
    GroupGameCreator: number?,
    RankStore: DataStore?,
    RankReadOptions: DataStoreGetOptions?,
    RankWrites: {[number]: boolean},
    PlayerRanks: {[Player]: PlayerRanks},
    AdminLevelChangedRemote: RemoteEvent,
    GroupAdminLevelCache: {[number]: {AdminLevel: number, ExpireTime: number}},
} & typeof(setmetatable({}, ServerAuthorization)) & Authorization.Authorization

function ServerAuthorization.new(Config: Configuration.Configuration, Remotes: Folder): ServerAuthorization
    local self = setmetatable(Authorization.new(Config), ServerAuthorization) :: ServerAuthorization
    self.GroupService = GroupService
    self.GameId = game.GameId
    self.CreatorId = game.CreatorId
    self.CreatorType = game.CreatorType
    self.GroupAdminLevelCache = {}
    self.PlayerRanks = {}
    self.RankWrites = {}

    if self.CreatorType == Enum.CreatorType.Group then
        local Success, Info = pcall(GroupService.GetGroupInfoAsync, GroupService, self.CreatorId)
        if Success then
            self.GroupGameCreator = if Info.Owner then Info.Owner.Id else nil
        else
            warn(`[BASIC SYSTEM] Could not resolve the owning group's owner: {Info}`)
        end
    end

    if self.GameId > 0 and Config.RankPersistenceEnabled
        and (not RunService:IsStudio() or Config.StudioRankPersistenceEnabled) then
        self.RankStore = DataStoreService:GetDataStore("BasicSystemRanks_v1")
        local ReadOptions = Instance.new("DataStoreGetOptions")
        ReadOptions.UseCache = false
        self.RankReadOptions = ReadOptions
    end

    local AuthorizationEvents = Instance.new("Folder")
    AuthorizationEvents.Name = "AuthorizationEvents"
    AuthorizationEvents.Parent = Remotes

    local GetAdminLevels = Instance.new("RemoteFunction")
    GetAdminLevels.Name = "GetAdminLevels"
    GetAdminLevels.OnServerInvoke = function()
        return self.AdminLevels
    end
    GetAdminLevels.Parent = AuthorizationEvents

    local AdminLevelChanged = Instance.new("RemoteEvent")
    AdminLevelChanged.Name = "AdminLevelChanged"
    AdminLevelChanged.Parent = AuthorizationEvents
    self.AdminLevelChangedRemote = AdminLevelChanged
    return self
end

function ServerAuthorization.IsOwnerUserId(self: ServerAuthorization, UserId: number): boolean
    if RunService:IsStudio() and self.GameId == 0 and UserId >= -1 then
        return true
    end
    if UserId <= 0 then
        return false
    end
    return self.Configuration.OwnerUserIds[UserId] == true
        or (self.CreatorType == Enum.CreatorType.User and UserId == self.CreatorId)
        or (self.CreatorType == Enum.CreatorType.Group and UserId == self.GroupGameCreator)
end

function ServerAuthorization.GetAdminLevel(self: ServerAuthorization, Player: Player): number
    local Level = self.AdminLevels[tostring(Player.UserId)]
    if Level ~= nil then return Level end
    return if self:IsOwnerUserId(Player.UserId) then self.Configuration.OwnerRankLevel else -1
end

function ServerAuthorization.InitializePlayers(self: ServerAuthorization): ()
    Players.PlayerRemoving:Connect(function(Player: Player)
        self.PlayerRanks[Player] = nil
        self.AdminLevels[tostring(Player.UserId)] = nil
        self.GroupAdminLevelCache[Player.UserId] = nil
    end)
    Players.PlayerAdded:Connect(function(Player: Player)
        self:InitializePlayer(Player)
    end)
    for _, Player in Players:GetPlayers() do
        task.spawn(function()
            self:InitializePlayer(Player)
        end)
    end
end

local function ApplyRank(Self: ServerAuthorization, Player: Player, Ranks: PlayerRanks): ()
    local Rank = Ranks.Temporary or Ranks.Saved or Ranks.Configured
    if Rank ~= nil then
        Authorization.SetAdminLevel(Self, Player, Rank)
        Self.AdminLevelChangedRemote:FireAllClients(Player.UserId, Rank)
    end
end

function ServerAuthorization.InitializePlayer(self: ServerAuthorization, Player: Player): ()
    if self.PlayerRanks[Player] then return end
    local Ranks: PlayerRanks = {}
    self.PlayerRanks[Player] = Ranks

    local UserId = Player.UserId
    if self:IsOwnerUserId(UserId) then
        Ranks.Configured = self.Configuration.OwnerRankLevel
        ApplyRank(self, Player, Ranks)
        return
    end

    --A player may rejoin while a previous rank write is finishing.
    while self.RankWrites[UserId] do
        task.wait()
        if self.PlayerRanks[Player] ~= Ranks then return end
    end
    local Configured, ConfiguredRead = self:EvaluateConfiguredLevelAsync(UserId)
    local Saved, SavedRead = self:ReadSavedRankAsync(UserId)
    if self.PlayerRanks[Player] ~= Ranks then return end
    Ranks.Configured = Configured
    Ranks.ConfiguredRead = ConfiguredRead
    Ranks.SavedRead = SavedRead
    --A failed read may hide a saved demotion. Start with Player privileges in that case.
    Ranks.Saved = if SavedRead then Saved else -1
    ApplyRank(self, Player, Ranks)
end

function ServerAuthorization.ReadSavedRankAsync(self: ServerAuthorization, UserId: number): (number?, boolean)
    local Store = self.RankStore
    if not Store or UserId <= 0 then return nil, true end

    local Success, Value = pcall(Store.GetAsync, Store, tostring(UserId), self.RankReadOptions)
    if not Success then
        warn(`[BASIC SYSTEM] Could not load saved rank for {UserId}: {Value}`)
        return nil, false
    end
    if type(Value) == "number" and self.Configuration.AdminNames[Value] and Value < self.Configuration.OwnerRankLevel then
        return Value, true
    end
    return nil, true
end

function ServerAuthorization.EvaluateConfiguredLevelAsync(self: ServerAuthorization, UserId: number): (number, boolean)
    local Level = math.max(self.Configuration.DefaultAdminLevel, self.Configuration.Admins[UserId] or -math.huge)
    if UserId <= 0 or not next(self.Configuration.GroupAdminLevels) then return Level, true end

    local Cached = self.GroupAdminLevelCache[UserId]
    if Cached and os.time() < Cached.ExpireTime then
        return math.max(Level, Cached.AdminLevel), true
    end

    local Success, Groups = pcall(self.GroupService.GetGroupsAsync, self.GroupService, UserId)
    if not Success then
        warn(`[BASIC SYSTEM] Could not check Roblox groups for {UserId}: {Groups}`)
        return Level, false
    end

    local GroupLevel = -math.huge
    for _, Group in Groups do
        local Thresholds = self.Configuration.GroupAdminLevels[Group.Id]
        if Thresholds then
            for Threshold, Rank in Thresholds do
                if Group.Rank >= Threshold then
                    GroupLevel = math.max(GroupLevel, Rank)
                end
            end
        end
    end
    self.GroupAdminLevelCache[UserId] = {
        AdminLevel = GroupLevel,
        ExpireTime = os.time() + GROUP_LEVEL_CACHE_EXPIRE_SECONDS,
    }
    return math.max(Level, GroupLevel), true
end

local function HasKnownRank(Ranks: PlayerRanks): boolean
    return Ranks.Temporary ~= nil or (Ranks.SavedRead == true and
        (Ranks.Saved ~= nil or Ranks.ConfiguredRead == true))
end

function ServerAuthorization.CanModeratePlayer(self: ServerAuthorization, Executor: Player, Target: Player, MinimumLevel: number): boolean
    local Ranks = self.PlayerRanks[Target]
    local ExecutorLevel = self:GetAdminLevel(Executor)
    return Ranks ~= nil and HasKnownRank(Ranks) and ExecutorLevel >= MinimumLevel
        and self:GetAdminLevel(Target) < ExecutorLevel
end

function ServerAuthorization.EvaluateAdminLevelAsync(self: ServerAuthorization, UserId: number): (number, boolean)
    if self:IsOwnerUserId(UserId) then return self.Configuration.OwnerRankLevel, true end
    local Player = Players:GetPlayerByUserId(UserId)
    local Ranks = Player and self.PlayerRanks[Player]
    local Current = self.AdminLevels[tostring(UserId)]
    if Current ~= nil and Ranks then
        return Current, HasKnownRank(Ranks)
    end

    local Saved, ReadSucceeded = self:ReadSavedRankAsync(UserId)
    if Saved ~= nil then return Saved, true end
    local Configured, GroupCheckSucceeded = self:EvaluateConfiguredLevelAsync(UserId)
    return Configured, ReadSucceeded and GroupCheckSucceeded
end

--Sets a temporary rank from a trusted server script.
function ServerAuthorization.SetAdminLevel(self: ServerAuthorization, Player: Player, Rank: number): ()
    local Ranks = self.PlayerRanks[Player]
    if not Ranks or Ranks.Configured == nil or self.RankWrites[Player.UserId] then return end
    if self:IsOwnerUserId(Player.UserId) or not self.Configuration.AdminNames[Rank] or Rank >= self.Configuration.OwnerRankLevel then return end

    Ranks.Temporary = Rank
    ApplyRank(self, Player, Ranks)
end

--All player-issued rank changes pass through this owner check.
function ServerAuthorization.ChangeRankAsync(self: ServerAuthorization, Executor: Player?, Target: Player, Rank: number?, Save: boolean): string
    if not Executor or not self:IsOwnerUserId(Executor.UserId) then
        return "Only an Owner can change ranks."
    end
    if self:IsOwnerUserId(Target.UserId) then
        return "Owner ranks are managed in BasicSystemSettings."
    end
    if Rank ~= nil and (not self.Configuration.AdminNames[Rank] or Rank >= self.Configuration.OwnerRankLevel) then
        return "Choose an assignable rank from the rank list."
    end

    local Ranks = self.PlayerRanks[Target]
    if not Ranks or Ranks.Configured == nil then
        return "This player's rank is still loading. Try again shortly."
    end
    local UserId = Target.UserId
    if self.RankWrites[UserId] then
        return "A rank change for this player is already being saved."
    end
    if not Save then
        if Rank == nil then return "Choose a temporary rank." end
        self:SetAdminLevel(Target, Rank)
        return `{Target.Name} is now {self.Configuration:GetRankName(Rank)} for this session.`
    end

    local Store = self.RankStore
    if not Store or UserId <= 0 then
        return "Saved ranks require a published experience with rank persistence enabled. Use admin for a temporary rank."
    end

    self.RankWrites[UserId] = true
    local Success, Error = pcall(Store.UpdateAsync, Store, tostring(UserId), function()
        --Returning nil would cancel UpdateAsync, so false marks a cleared override.
        return Rank or false
    end)
    self.RankWrites[UserId] = nil
    if not Success then
        warn(`[BASIC SYSTEM] Could not save rank for {UserId}: {Error}`)
        return "The rank could not be saved. Try again shortly."
    end

    if self.PlayerRanks[Target] == Ranks then
        Ranks.Saved = Rank
        Ranks.SavedRead = true
        Ranks.Temporary = nil
        ApplyRank(self, Target, Ranks)
    end
    if Rank == nil then
        return `Cleared {Target.Name}'s saved rank. Their configured rank now applies.`
    end
    return `Saved {self.Configuration:GetRankName(Rank)} for {Target.Name}.`
end

return ServerAuthorization
