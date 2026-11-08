--!strict

return {
    CommandPrefix = ":",
    ActivationKeys = { Enum.KeyCode.F2 },

    -- The Roblox experience creator or owning group's owner already has Owner access.
    -- Add trusted Owner accounts here by Roblox UserId.
    OwnerUserIds = {
        -- [123456789] = true,
    },

    -- Assign named ranks or their numeric levels to specific Roblox UserIds.
    Admins = {
        -- [123456789] = "Head Admin",
    },

    -- Each threshold is a Roblox group rank number (0–255).
    -- Players get the highest Basic System level they qualify for.
    GroupAdminLevels = {
        -- [123456] = {
        --     [100] = "Moderator",
        --     [200] = "Admin",
        -- },
    },

    -- -1 Player, 0 Helper, 1 Moderator, 2 Admin, 3 Senior Admin, 4 Head Admin, 5 Owner.
    -- Customize labels by level if needed. Keep level 5 as the highest level by default.
    AdminNames = {},

    RankPersistenceEnabled = true,
    StudioRankPersistenceEnabled = false,

    -- Override the minimum level for individual commands by category.
    CommandLevelOverrides = {
        -- Administrative = { kick = "Admin" },
        -- BasicCommands = { shutdown = "Owner" },
    },

    BannedUsers = {},
    FeatureFlagOverrides = {},
}
