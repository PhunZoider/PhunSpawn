if isServer() then
    return
end
require "PhunSpawn/client_main"
local Core = PhunSpawn
local Client = Core.client

-- ---------------------------------------------------------------------------
-- The context menu.
--
-- One option, and it is a request rather than an action: "look at where I am
-- standing". Everything it might unlock is decided server side, so the worst
-- a player can do by spamming it is ask a question the server answers with
-- no.
-- ---------------------------------------------------------------------------

local function onCheckHere()
    Client.requestDiscovery()
end

local function onOpenPicker()
    Client.openPicker()
end

Events.OnFillWorldObjectContextMenu.Add(function(playerIndex, context, worldObjects, test)
    local player = getSpecificPlayer(playerIndex)
    if not player then
        return
    end

    context:addOption(getText("ContextMenu_PhunSpawn_CheckHere"), player, onCheckHere)

    -- For everybody. It is how a new character who closed the picker gets it
    -- back, and for everyone else it is a map of what they know; whether the
    -- spawn button works is the server's decision, not this menu's.
    context:addOption(getText("ContextMenu_PhunSpawn_Points"), player, onOpenPicker)
end)
