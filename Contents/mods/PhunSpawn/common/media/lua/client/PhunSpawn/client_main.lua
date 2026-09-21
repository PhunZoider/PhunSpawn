if isServer() then
    return
end
require "PhunSpawn/points"
local Core = PhunSpawn

-- ---------------------------------------------------------------------------
-- Client state and the small things that touch the screen.
--
-- Everything the client holds here is a COPY for drawing. The server decides
-- what a character knows, and a client that disagrees is simply drawing a
-- stale list: nothing here is allowed to be the reason a point can be picked.
-- ---------------------------------------------------------------------------

local Client = {}
Core.client = Client

-- The last payload the server sent. Nil until playerSetup has answered, which
-- the UI reads as "not ready yet" rather than as "you know nothing".
Client.points = nil
Client.lastChoice = nil
-- Whether the server says this character is new and still choosing, and
-- whether the spawn button would be honoured. Both are hints for drawing; the
-- server asks again when the button is pressed.
Client.pending = false
Client.canSpawn = false
-- The picker opens by itself once per session for a new character, and never
-- again after that: a player who closes it has decided to, and the context
-- menu is how they get it back.
Client.autoOpened = false

--- A fresh picture of what this character knows.
--
-- Stored in one place and announced, rather than handed to whoever asked. Any
-- number of panels read it, and a payload delivered only to the caller is how
-- two views of one list come to disagree.
function Client.receivePoints(arguments)
    Client.points = arguments and arguments.points or {}
    if arguments and arguments.last then
        Client.lastChoice = arguments.last
    end
    Client.pending = arguments and arguments.pending == true
    Client.canSpawn = arguments and arguments.canSpawn == true

    -- The flag goes up BEFORE opening. Opening asks the server for a fresh
    -- payload, and in single player that answer arrives inside this call.
    if Client.pending and not Client.autoOpened then
        Client.autoOpened = true
        Client.openPicker()
    end

    triggerEvent(Core.events.OnPointsReceived, Client.points)
end

function Client.notify(arguments)
    if not arguments or not arguments.text then
        return
    end
    local text = getText(arguments.text, arguments.arg)
    local player = getPlayer()
    if player then
        player:setHaloNote(text, 255, 255, 255, 300)
    else
        Core.logLn(text)
    end
end

--- "You just found one."
function Client.announceUnlock(arguments)
    if not arguments then
        return
    end
    Client.notify({
        text = "IGUI_PhunSpawn_Discovered",
        arg = arguments.label
    })
end

--- Ask the server to look at where we are standing.
--
-- Sends a request and no claim. The server reads the position off the player
-- itself, so there is nothing in the message to take on trust.
function Client.requestDiscovery()
    Core.dispatch(Core.commands.discover, {})
end

function Client.choose(id)
    Core.dispatch(Core.commands.choose, {id = id})
end

--- Ask to be put at a point now. The server decides; see placement.lua.
function Client.spawn(id)
    Core.dispatch(Core.commands.spawn, {id = id})
end

--- Ask for a fresh payload. Answered through receivePoints like any other.
function Client.refreshPoints()
    Core.dispatch(Core.commands.playerSetup, {})
end

--- Open the spawn point picker.
--
-- Required on first use rather than at the top of this file, because the
-- picker requires this file and a require cycle in Kahlua hands one side a
-- half built module.
function Client.openPicker()
    local Picker = require "PhunSpawn/ui/picker"
    Picker.open(getPlayer())
end

return Client
