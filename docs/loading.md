# Loading Basic System

Install the bundled model in `ServerScriptService` as described in the [GitHub setup guide](../../README.md). Configure its `BasicSystemSettings` ModuleScript before starting the game. The loader installs the API and starts the client command bar.

A server plugin can require the API after it loads.

```luau
local ServerScriptService = game:GetService("ServerScriptService")
local BasicSystem = require(ServerScriptService:WaitForChild("BasicSystem"))

while not BasicSystem:GetAdminLoaded() do
    task.wait()
end
```

A LocalScript can require the client API.

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BasicSystem = require(ReplicatedStorage:WaitForChild("BasicSystemClient"))
```

See [Creating Commands](creating-commands.md) for command registration examples.
