# Frequently asked questions

## Where do I install the model?

Insert `Basic-System.rbxm` into `ServerScriptService`. Open the resulting **Basic System** model to find `BasicSystemSettings`.

## How do I get Owner?

The experience creator or owning group's owner receives Owner. For other trusted accounts, add their Roblox UserIds to `OwnerUserIds` in `BasicSystemSettings`.

## Why did a temporary rank disappear?

`:admin` grants a rank until the player leaves the server. Use `:setrank` for a saved rank in a published experience.

## Why did clearing a rank restore a staff tier?

`:clearrank` restores the rank from the user's configured UserId or Roblox group. Use `:setrank Username Player` to save a demotion for that player.

## How do I add a command?

See [Creating Commands](creating-commands.md).
