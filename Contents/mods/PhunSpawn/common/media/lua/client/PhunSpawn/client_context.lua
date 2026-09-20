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

    -- Admin only, for now, because the picker is not built and an option that
    -- prints to the console is not something to put in front of a player.
    if Core.tools and Core.tools.isAdmin and Core.tools.isAdmin(player) then
        context:addOption(getText("ContextMenu_PhunSpawn_Points"), player, onOpenPicker)
    end
end)
