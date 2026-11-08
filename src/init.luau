--Server API for Basic System.
--!strict

local CMDR_OVERRIDE_ADMIN_LEVELS = {
    --Provides DataStore access.
    var = 0,
    varSet = 0,
}

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(script:WaitForChild("Types"))

local Loaded = false
local API = {}

export type BasicSystemApi = typeof(API) & Types.BasicSystemApiServer



--[[
Converts the number indexes to strings.
--]]
local function ConvertNumberIndexesToStrings(Array: any): {[string]: any}
    local NewArray = {}
    for Key,Value in Array do
        --Convert the value if it is an array.
        if type(Value) == "table" then
            Value = ConvertNumberIndexesToStrings(Value)
        end

        --Add the index.
        NewArray[tostring(Key)] = Value
    end

    return NewArray
end



--[[
Loads Basic System.
--]]
function API:Load(ConfigurationTable: {[string]: any}): ()
    --Create the containers.
    local EventContainer = Instance.new("Folder")
    EventContainer.Name = "BasicSystemEvents"
    EventContainer.Parent = ReplicatedStorage

    local AdminItemContainer = Instance.new("Folder")
    AdminItemContainer.Name = "BasicSystemItemContainer"
    AdminItemContainer.Parent = Workspace

    --Prepare the scripts to ReplicatedStorage.
    local BasicSystemClient = script:WaitForChild("Client"):Clone()
    BasicSystemClient.Name = "BasicSystemClient"

    BasicSystemClient:WaitForChild("Types"):Destroy()
    local TypesModule = script:WaitForChild("Types"):Clone()
    TypesModule.Parent = BasicSystemClient

    local Common = script:WaitForChild("Common"):Clone()
    Common.Parent = BasicSystemClient

    local Packages = script:WaitForChild("Packages")
    Packages:Clone().Parent = BasicSystemClient

    local LocalIncludedCommands = script:WaitForChild("IncludedCommands"):WaitForChild("Local"):Clone()
    LocalIncludedCommands.Name = "IncludedCommands"
    LocalIncludedCommands.Parent = BasicSystemClient

    local IncludedCommandUtil = script:WaitForChild("IncludedCommands"):WaitForChild("IncludedCommandUtil"):Clone()
    IncludedCommandUtil.Parent = LocalIncludedCommands

    local FlyState = script:WaitForChild("IncludedCommands"):WaitForChild("Resources"):WaitForChild("FlyState"):Clone()
    FlyState.Parent = LocalIncludedCommands:WaitForChild("Resources")

    --Initialize the resources.
    local Cmdr = require(Packages:WaitForChild("Cmdr"))
    local Configuration = require(script:WaitForChild("Common"):WaitForChild("Configuration")).new(ConfigurationTable)
    local Authorization = require(script:WaitForChild("Server"):WaitForChild("ServerAuthorization")).new(Configuration, EventContainer);
    (Authorization):InitializePlayers()
    local Messages = require(script:WaitForChild("Server"):WaitForChild("ServerMessages")).new(EventContainer)
    local FeatureFlags = require(Packages:WaitForChild("NexusFeatureFlags"))
    local Replicator = require(script:WaitForChild("Server"):WaitForChild("Replicator")).new()
    local Filter = require(script:WaitForChild("Server"):WaitForChild("ServerFilter")).new()
    local Time = require(script:WaitForChild("Common"):WaitForChild("Time"))
    local Logs = require(script:WaitForChild("Common"):WaitForChild("Logs")).new()
    local Registry = require(script:WaitForChild("Server"):WaitForChild("ServerRegistry")).new(Cmdr, Configuration, Authorization, Messages :: any, Logs :: any, Time, Filter :: any, EventContainer)
    local LogsRegistry = require(script:WaitForChild("Server"):WaitForChild("ServerLogsRegistry")).new(Authorization :: any, EventContainer)
    local Executor = require(script:WaitForChild("Common"):WaitForChild("Executor")).new(Cmdr, Registry)

    --Create the configuration fetching.
    local GetConfiguration = Instance.new("RemoteFunction")
    GetConfiguration.Name = "GetConfiguration"
    GetConfiguration.Parent = EventContainer

    function GetConfiguration.OnServerInvoke()
        local ClientConfiguration = table.clone(ConfigurationTable or {})
        ClientConfiguration.OwnerUserIds = nil
        ClientConfiguration.Admins = nil
        ClientConfiguration.GroupAdminLevels = nil
        ClientConfiguration.BannedUsers = nil
        return ConvertNumberIndexesToStrings(ClientConfiguration)
    end

    --Set the resouces.
    API.Types = {}
    API.CommandData = {}
    API.Cmdr = Cmdr
    API.Configuration = Configuration
    API.Authorization = Authorization
    API.Executor = Executor
    API.Messages = Messages
    API.Filter = Filter
    API.Time = Time
    API.Replicator = Replicator
    API.Logs = Logs
    API.Registry = Registry
    API.LogsRegistry = LogsRegistry
    API.FeatureFlags = FeatureFlags
    API.Version = Configuration.Version
    API.VersionNumberId = Configuration.VersionNumberId
    API.CmdrVersion = Configuration.CmdrVersion
    API.EventContainer = EventContainer
    API.AdminItemContainer = AdminItemContainer

    --Add the custom Cmdr types.
    for _, TypeModule in script:WaitForChild("Common"):WaitForChild("Types"):GetChildren() do
        (require(TypeModule) :: (Types.BasicSystemApiServer) -> ())(API :: any)
    end

    --Set the feature flag overrides.
    for Name, Value in Configuration.FeatureFlagOverrides do
        FeatureFlags:SetFeatureFlag(Name, Value)
    end

    --Add the initial feature flags.
    FeatureFlags:AddFeatureFlag("UseNativeMessageGui", true)
    FeatureFlags:AddFeatureFlag("UseNativeHintGui", true)
    FeatureFlags:AddFeatureFlag("UseNativeNotificationGui", true)
    FeatureFlags:AddFeatureFlag("DisplayAdminLevelNotifications", true)
    FeatureFlags:AddFeatureFlag("AllowChatCommandExecuting", true)

    --Mark the system as loaded.
    BasicSystemClient.Parent = ReplicatedStorage
    Loaded = true
end

--[[
Loads the including commands.
--]]
function API.LoadIncludedCommands(self: BasicSystemApi): ()
    --Load the Basic System commands.
    local IncludedCommands = ReplicatedStorage:WaitForChild("BasicSystemClient"):WaitForChild("IncludedCommands")
    local Categories = {"Administrative", "BasicCommands", "BuildUtility", "Cmdr", "UsefulFun", "Fun", "Persistent"}
    for _, Category in Categories do
        --Add the scripts.
        local Folder = script:WaitForChild("IncludedCommands"):WaitForChild(Category)
        for _, Module in Folder:GetChildren() do
            if not Module:IsA("ModuleScript") then return end
            self.Registry:RegisterIncludedCommand(Module, self :: Types.BasicSystemApiServer, IncludedCommands)
        end

        --Connect adding new scripts.
        Folder.ChildAdded:Connect(function(Module: Instance): ()
            if not Module:IsA("ModuleScript") then return end
            self.Registry:RegisterIncludedCommand(Module, self :: Types.BasicSystemApiServer, IncludedCommands)
        end)
    end

    --Load the Cmdr utility commands.
    --Cmdr commands are located in the separate folder for the client to move to ensure required commands are registered.
    --This is due to a race condition where alias is not registered before AutoExecs are called.
    local ClientCmdrCommands = Instance.new("Folder")
    ClientCmdrCommands.Name = "ClientCmdrCommands"
    ClientCmdrCommands.Parent = self.EventContainer

    local Cmdr = script:WaitForChild("Packages"):WaitForChild("Cmdr")
    local CmdrUtilityCommands = Cmdr:WaitForChild("Server commands"):WaitForChild("Utility")
    local CmdrCommandsToLoad = Cmdr:WaitForChild("Server commands"):WaitForChild("Utility"):GetChildren()
    table.insert(CmdrCommandsToLoad, Cmdr:WaitForChild("Server commands"):WaitForChild("help"))
    for _, CommandScript in CmdrCommandsToLoad do
        if not CommandScript:IsA("ModuleScript") or string.find(CommandScript.Name, "Server") then continue end
        if self.Registry.Cmdr.Registry:GetCommand(CommandScript.Name) then continue end --Prevent loading over Basic System's reimplementations.
        local ServerCommandScript = CmdrUtilityCommands:FindFirstChild(`{CommandScript.Name}Server`)
        local CommandData = require(CommandScript) :: Types.BasicSystemCommandData
        if CommandData.Name == "help" then
            CommandData.Aliases = {} --help's aliases collide with Basic System's cmds and commands. Before V.2.10.3, Basic System's commands took priority.
        end
        CommandData.AutoExec = nil --AutoExec is handled on the client.
        CommandData.AdminLevel = CMDR_OVERRIDE_ADMIN_LEVELS[CommandScript.Name]
        if ServerCommandScript then
            CommandData.Run = require(ServerCommandScript) :: (CommandContext: Types.CmdrCommandContext, ...any) -> (string?)
        end
        if CommandData.Run then
            local BaseRun = CommandData.Run
            CommandData.Run = function(_,...)
                return BaseRun(...)
            end
        end
        if CommandData.ClientRun then
            local BaseRun = CommandData.ClientRun
            CommandData.ClientRun = function(_,...)
                return BaseRun(...)
            end
        end
        self.Registry:LoadCommand(CommandData)
        CommandScript.Parent = ClientCmdrCommands
    end
end

--[[
Loads the client loader to all clients.
--]]
function API.LoadClientLoader(self: BasicSystemApi): ()
    script:WaitForChild("Resources"):WaitForChild("BasicSystemClientLoader").Parent = ReplicatedStorage:WaitForChild("BasicSystemClient")
end

--[[
Returns if Basic System is loaded.
--]]
function API.GetAdminLoaded(self: BasicSystemApi): boolean
    return Loaded
end

--Add the API fetchers.
function _G.BasicSystem_GetServerAPI()
    return API
end

function _G.GetBasicSystemServerAPI()
    return API
end

--Add the deprecated API.
function API.GetConfig()
    warn("BasicSystemServerAPI.GetConfig() is deprecated as of V.2.0.0. Please use BasicSystemServerAPI.Configuration:GetRaw() instead.")
    return API.Configuration:GetRaw()
end

function API.AddCommandToLoad(Table)
    warn("BasicSystemServerAPI.AddCommandToLoad(CommandTable) is deprecated as of V.2.0.0. Please use BasicSystemServerAPI.Registry:LoadCommand(CommandTable) instead.")
    API.Registry:LoadCommand(Table)
end

function API.GetLogs()
    warn("BasicSystemServerAPI.GetLogs() is deprecated as of V.2.0.0. Please use BasicSystemServerAPI.Logs:GetLogs() instead.")
    return API.Logs:GetLogs()
end

function API.AddToLogs(Log)
    warn("BasicSystemServerAPI.AddToLogs(Log) is deprecated as of V.2.0.0. Please use BasicSystemServerAPI.Logs:Add(Log) instead.")
    return API.Logs:Add(Log)
end

function API.GetAdmins(GetRaw)
    error("BasicSystemServerAPI.GetAdmins(GetRaw) is removed as of V.2.0.0. If needed, BasicSystemServerAPI.Authorization.AdminLevels can be used.")
end

function API.GetAdminLevel(Player)
    warn("BasicSystemServerAPI.GetAdminLevel(Player) is deprecated as of V.2.0.0. Please use BasicSystemServerAPI.Authorization:GetAdminLevel(Player) instead.")
    return API.Authorization:GetAdminLevel(Player)
end

function API.InvokeCommand(Command,ArgumentString,ReferencePlayer)
    warn("BasicSystemServerAPI.InvokeCommand(Command,ArgumentString,ReferencePlayer) is deprecated as of V.2.0.0. Please use BasicSystemServerAPI.Executor:ExecuteCommandWithPrefix(Command,ReferencePlayer) instead.")
    return API.Executor:ExecuteCommandWithPrefix(`{Command} {ArgumentString}`, ReferencePlayer)
end

function API.DisplayHint(Player,Message,DisplayTime)
    warn("BasicSystemServerAPI.DisplayHint(Player,Message,DisplayTime) is deprecated as of V.2.0.0. Please use BasicSystemServerAPI.Messages:DisplayHint(Player,Message,DisplayTime) instead.")
    return API.Messages:DisplayHint(Player,Message,DisplayTime)
end

function API.DisplayMessage(Player,TopText,Message,DisplayTime)
    warn("BasicSystemServerAPI.DisplayMessage(Player,TopText,Message,DisplayTime) is deprecated as of V.2.0.0. Please use BasicSystemServerAPI.Messages:DisplayMessage(Player,TopText,Message,DisplayTime) instead.")
    return API.Messages:DisplayMessage(Player,TopText,Message,DisplayTime)
end

function API.AddScriptToPlayer(Player,Script)
    warn("BasicSystemServerAPI.AddScriptToPlayer(Player,Script) is deprecated as of V.2.0.0. Please use BasicSystemServerAPI.Replicator:GiveScriptToPlayer(Player,Script) instead.")
    API.Replicator:GiveScriptToPlayer(Player, Script)
end

function API.BindScriptToSpawn(Script)
    warn("BasicSystemServerAPI.BindScriptToSpawn(Script) is deprecated as of V.2.0.0. Please use BasicSystemServerAPI.Replicator:GiveStarterScript(Script) instead.")
    API.Replicator:GiveStarterScript(Script)
end

function API.FilterStringAsync(String,PlayerFrom,PlayerTo)
    warn("BasicSystemServerAPI.FilterStringAsync(String,PlayerFrom,PlayerTo) is deprecated as of V.2.0.0. Please use BasicSystemServerAPI.Filter:FilterString(String,PlayerFrom,PlayerTo) instead.")
    return API.Filter:FilterString(String,PlayerFrom,PlayerTo)
end

function API.GetTimeString()
    warn("BasicSystemServerAPI.GetTimeString() is deprecated as of V.2.0.0. Please use BasicSystemServerAPI.Time:GetTimeString() instead.")
    return API.Time:GetTimeString()
end

--Set the metatable for throwing errors for when the system is not loaded.
setmetatable(API, {
    __index = function(_, Index: string)
        local Result = rawget(API, Index)

        --Throw an error if the result doesn't exist.
        if Result == nil then
            if Loaded then
                error(`"{Index}" is not a valid member of Basic System.`)
            else
                error(`Basic System has not been loaded. Call BasicSystem:Load(ConfigurationTable) before indexing {Index}.`)
            end
        end

        --Return the result.
        return Result
    end
})



--Return the API.
return (API :: any) :: Types.BasicSystemApiServer