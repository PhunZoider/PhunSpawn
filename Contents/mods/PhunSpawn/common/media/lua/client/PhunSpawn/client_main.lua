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

--- Open the spawn point picker.
--
-- TODO: unbuilt. When it is, the panels to vendor are PhunMart2's
-- ui/base/list_panel.lua and form_panel.lua, the way PhunInteriors vendored
-- them: an admin or player running several Phun mods should not have to learn
-- a second kind of list to do the same job. Vendored and not depended on, so
-- it is a fork maintained by hand, which is the accepted cost.
function Client.openPicker()
    Core.logLn("the spawn point picker is not built yet")
end

return Client
