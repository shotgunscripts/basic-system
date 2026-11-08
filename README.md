# Basic System

Basic System is a Roblox admin package based on Nexus Admin by TheNexusAvenger. It includes the Cmdr command bar, the original command collection, and a seven-tier rank system.

## GitHub edition

Follow the [GitHub setup guide](../README.md) to install the model and configure the repository. This folder contains the editable code and the original Rojo project.

## Ranks and permissions

| Level | Rank | Examples of default access |
| --- | --- | --- |
| -1 | Player | View your rank and available commands |
| 0 | Helper | View the staff roster |
| 1 | Moderator | Kick, mute, refresh, and view moderation logs |
| 2 | Admin | Use player commands and lock the server |
| 3 | Senior Admin | Issue server bans and use more effects and build commands |
| 4 | Head Admin | Issue persistent bans and shut down the server |
| 5 | Owner | Assign ranks and access owner-level commands |

The server checks command permissions. Kick and ban also require a confirmed target rank below the executor's rank. Only Owners can assign or clear ranks. To grant Owner, edit `OwnerUserIds` in Studio.

| Chat command | Result |
| --- | --- |
| `!myrank` | Show your effective rank |
| `!ranks` | Open the ranked staff roster |
| `!cmds` | Open the command list for your rank |
| `:admin ExampleUser Moderator` | Grant a temporary rank until the player leaves |
| `:unadmin ExampleUser` | Set the player to Player until they leave |
| `:setrank ExampleUser "Senior Admin"` | Save a rank for a player in this server |
| `:clearrank ExampleUser` | Clear the saved rank and apply their configured rank |
| `:setrank ExampleUser Player` | Save a demotion to Player, including for a user with a configured staff rank |

Use the commands without chat prefixes in the F2 command bar. Rank arguments accept names and numbers. Saved changes require the exact Roblox username of a player in the server. `:rank` and `:unrank` are aliases for `:setrank` and `:clearrank`.

## Configure staff

Edit `BasicSystemSettings` in the model. In the source project the same settings are in `BasicSystemSettings.luau`.

```luau
OwnerUserIds = {
    [123456789] = true,
},
Admins = {
    [234567890] = "Head Admin",
},
GroupAdminLevels = {
    [123456] = {
        [100] = "Moderator",
        [200] = "Admin",
    },
},
CommandLevelOverrides = {
    Administrative = { kick = "Admin" },
},
```

Replace the example IDs with your Roblox UserIds and group ID. Group thresholds use Roblox's rank numbers. If several configured grants apply, the highest level wins. For non-Owners, a temporary rank takes precedence over a saved rank, and a saved rank takes precedence over configuration.

Saved ranks use a Roblox data store in published experiences. Changes apply immediately in the current server and on the player's next join elsewhere. For a published Studio test copy, turn on `StudioRankPersistenceEnabled` in the model and enable **Studio Access to API Services** in **Experience Settings → Security**. Temporary ranks work in an unpublished Studio playtest. The first simulated player receives Owner in a local unpublished test. [Roblox data store documentation](https://create.roblox.com/docs/cloud-services/data-stores)

## Upgrading plugins

The server module now loads as `ServerScriptService.BasicSystem`. The client module is `ReplicatedStorage.BasicSystemClient`. Update existing plugin paths and change the player argument type to `basicSystemPlayers`. Move old direct level 5 grants to `OwnerUserIds`. Existing persistent ban and feature flag records still use their previous storage keys.

## Build from source

Rojo 7.7.0 can rebuild the model and a separate smoke-test place. Cmdr and its supporting packages are included.

```bash
rojo build -o Basic-System.rbxm
rojo build place-standalone.project.json -o Basic-System-Test.rbxl
```

See [the API documentation](docs/api.md) and [custom command examples](docs/creating-commands.md). The original MIT license is in [LICENSE](LICENSE). Cmdr and the bundled Wally packages include their licenses alongside their source.
