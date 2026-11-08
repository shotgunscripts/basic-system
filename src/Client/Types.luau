--Passthrough for types for development.
--For backwards compatibility, the client modules can't be moved.
--!strict

local Types = require(script.Parent.Parent:WaitForChild("Types"))

export type Cmdr = Types.Cmdr
export type NexusFeatureFlagsSource = Types.NexusFeatureFlagsSource
export type BasicSystemCommandData = Types.BasicSystemCommandData
export type Authorization = Types.Authorization
export type Configuration = Types.Configuration
export type Executor = Types.Executor
export type Filter = Types.Filter
export type Logs = Types.Logs
export type LogsRegistryClient = Types.LogsRegistryClient
export type MessagesClient = Types.MessagesClient
export type Registry = Types.Registry
export type Time = Types.Time
export type Window = Types.Window
export type BasicSystemApiClient = Types.BasicSystemApiClient

return true