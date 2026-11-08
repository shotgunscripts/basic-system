--Loads Basic System on the client.
--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")

local BasicSystemClient = require(ReplicatedStorage:WaitForChild("BasicSystemClient")) :: {
    Cmdr: {
        SetActivationKeys: (self: any, {Enum.KeyCode}) -> (),
    },
    Authorization: {
        IsPlayerAuthorized: (self: any, Player: Player, AdminLevel: number) -> (boolean),
    },
    Configuration: {
        ActivationKeys: {Enum.KeyCode},
        DefaultAdminLevel: number,
        GetCommandAdminLevel: (self: any, CommandGroup: string, Command: string) -> (number),
    },
    Registry: {
        LoadServerCommands: (self: any) -> (),
    },
    LoadIncludedCommands: (self: any) -> (),
}
BasicSystemClient.Cmdr:SetActivationKeys(BasicSystemClient.Configuration.ActivationKeys)
BasicSystemClient.Registry:LoadServerCommands()
BasicSystemClient:LoadIncludedCommands()

--Roblox's Keyboard Navigation collides with the original default keybind of \.
--To get around this, navigation is disabled when \ is pressed, the user is an admin, and it is an activation key.
local CmdrWindow = require(ReplicatedStorage:WaitForChild("CmdrClient"):WaitForChild("CmdrInterface"):WaitForChild("Window")) :: {AddLine: (self: any, Message: string, {Color: Color3}) -> ()}
for _, ActivationKey in BasicSystemClient.Configuration.ActivationKeys do
    if ActivationKey ~= Enum.KeyCode.BackSlash then return end
    ContextActionService:BindAction("BasicSystemLegacyKeybindWarning", function()
        --Return if the keyboard navigation is already disabled.
        if not GuiService.AutoSelectGuiEnabled then
            return Enum.ContextActionResult.Pass
        end

        --Return if the player is not authorized to use the window.
        local AdminLevel = BasicSystemClient.Configuration:GetCommandAdminLevel("Administrative", "cmdbar")
        if not BasicSystemClient.Authorization:IsPlayerAuthorized(Players.LocalPlayer, AdminLevel) then
            return Enum.ContextActionResult.Pass
        end

        --Disable keyboard navigation and show the deprecation message.
        GuiService.AutoSelectGuiEnabled = false
        local Message = "Using \\ for opening the Cmdr window is deprecated due to Roblox's Keyboard Navigation.\n"
        .."https://devforum.roblox.com/t/new-keybinds-for-keyboard-navigation/2069353\n\n"
        .."F2 is the new default for toggling the window.\n"
        .."Keyboard navigation is disabled for those who can toggle the command bar (this window).\n"
        .."Please specify ActivationKeys in the loader of Basic System to not contain Enum.KeyCode.BackSlash."
        if AdminLevel <= BasicSystemClient.Configuration.DefaultAdminLevel then
            Message ..= "\nIf you are keeping \\ as an activation key, please set cmdbar command to an admin level that is above non-admins so that they can use keyboard navigation."
        end
        CmdrWindow:AddLine(Message, {
            Color = Color3.fromRGB(255, 200, 0),
        })
        return Enum.ContextActionResult.Pass
    end, false, Enum.KeyCode.BackSlash)
    break
end

