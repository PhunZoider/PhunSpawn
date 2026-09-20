if isClient() then
    return
end
require "PhunSpawn/points"
require "PhunSpawn/tools"
local Core = PhunSpawn
local Unlocks = require "PhunSpawn/unlocks"
local Commands = {}

-- ---------------------------------------------------------------------------
-- Server command handlers.
--
-- Returns a table; server_events.lua dispatches into it. Every handler takes
-- (player, args) and re-checks everything, because a command is an entry
-- point and never a gate: the client menu deciding not to offer something is
-- a convenience, not a permission.
-- ---------------------------------------------------------------------------

Commands[Core.commands.playerSetup] = function(player, args)
    Unlocks.load(player)
    Core.respond(player, Core.commands.points, {
        points = Unlocks.payloadFor(player),
        last = player:getModData()[Core.consts.lastChoiceKey]
    })
end

--- "I am standing on a point, count it as found."
--
-- Carries a square and nothing else. The server reads the point off the
-- position rather than taking a point id from the client, which is the same
-- direction PhunInteriors' entry path takes and for the same reason: a
-- position can be checked against where the player actually is, and an id
-- cannot be checked against anything.
Commands[Core.commands.discover] = function(player, args)
    local point = Unlocks.checkDiscovery(player)
    if not point then
        return
    end
    Core.respond(player, Core.commands.unlocked, {
        id = point.id,
        label = point.label
    })
    Core.respond(player, Core.commands.points, {
        points = Unlocks.payloadFor(player)
    })
end

--- "Wake me up here next time."
Commands[Core.commands.choose] = function(player, args)
    local id = args and args.id
    if not id or not Core.points[id] then
        Core.respond(player, Core.commands.notify, {
            text = "IGUI_PhunSpawn_NoSuchPoint"
        })
        return
    end
    if not Unlocks.has(player, id) then
        -- Refused rather than silently ignored. A client that got here has
        -- either a stale list or a modified one, and both cases deserve an
        -- answer the player can see.
        Core.respond(player, Core.commands.notify, {
            text = "IGUI_PhunSpawn_NotDiscovered"
        })
        return
    end

    player:getModData()[Core.consts.lastChoiceKey] = id
    Core.respond(player, Core.commands.notify, {
        text = "IGUI_PhunSpawn_ChoiceSet",
        arg = Core.points[id].label
    })
end

--- "Put a point of mine on the map here."
--
-- TODO: unbuilt. What it has to do is mint an id, write it into the marker
-- object's modData under consts.objectIdKey, register the point and grant it.
-- The id must live inside movableData rather than at the top level, and the
-- lesson from PhunInteriors' tents is the one to design against: modData does
-- NOT survive a pickup reliably, and whether it does depends on which tile
-- was clicked. So either the marker refuses to be picked up, or a built point
-- must not depend on its modData surviving one.
Commands[Core.commands.buildPoint] = function(player, args)
    if not Core.settings.AllowBuiltPoints then
        Core.respond(player, Core.commands.notify, {
            text = "IGUI_PhunSpawn_BuiltPointsOff"
        })
        return
    end
    Core.logLn("buildPoint is not implemented yet")
end

--- Admin actions, reachable from the console as PhunSpawn.admin(action, args).
--
-- Every one re-checks admin rights here rather than trusting the caller, and
-- the result goes back as lines for a log rather than as a structure, which
-- is why it has its own command.
Commands[Core.commands.admin] = function(player, args)
    if not Core.tools.isAdmin(player) then
        return
    end
    local action = args and args.action
    local result = {}

    if action == "list" then
        for _, point in ipairs(Core.sortedPoints()) do
            table.insert(result, string.format("%-44s %-16s %d,%d,%d  %s",
                point.id, tostring(point.region), point.x, point.y, point.z, point.discovery))
        end
        if #result == 0 then
            table.insert(result, "no points registered")
        end

    elseif action == "grant" then
        local target = args.username and Core.tools.getPlayerByUsername(args.username) or player
        if target and args.id and Unlocks.grant(target, args.id) then
            table.insert(result, "granted " .. tostring(args.id))
        else
            table.insert(result, "nothing granted")
        end

    elseif action == "where" then
        table.insert(result, string.format("%d, %d, %d",
            player:getX(), player:getY(), player:getZ()))

    else
        table.insert(result, Core.describeRegistry())
    end

    Core.respond(player, Core.commands.adminResult, {result = result})
end

return Commands
