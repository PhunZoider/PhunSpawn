if isClient() then
    return
end
require "PhunSpawn/points"
require "PhunSpawn/tools"
local Core = PhunSpawn
local Unlocks = {}

-- ---------------------------------------------------------------------------
-- What a character knows about.
--
-- The truth is a table in the character's own modData, keyed by point id.
-- Core.unlocked is a server side cache of it, rebuilt on login, so a lookup
-- does not reach into the character record every time somebody moves.
--
-- Server side because it is the authority. A client that simply declines to
-- run the discovery check must still not be able to pick a point it has not
-- found, so every read that decides anything goes through here and the client
-- copy is only ever for drawing.
-- ---------------------------------------------------------------------------

local function record(player)
    local md = player:getModData()
    md[Core.consts.unlockedKey] = md[Core.consts.unlockedKey] or {}
    return md[Core.consts.unlockedKey]
end

--- Load a character's list into the cache and return it.
--
-- Points that no longer exist are filtered on READ rather than deleted, which
-- is why removePoint does not have to walk every character. Removing a point
-- set temporarily and putting it back costs nobody their exploring.
function Unlocks.load(player)
    local key = Core.playerKey(player)
    if not key then
        return {}
    end
    local stored = record(player)
    local live = {}
    for id in pairs(stored) do
        if Core.points[id] then
            live[id] = true
        end
    end
    -- The starters are granted on read rather than stamped once at character
    -- creation. A point added to the start set in a later version then
    -- reaches existing characters, and there is no migration to write.
    for id, point in pairs(Core.points) do
        if point.discovery == Core.discovery.start then
            live[id] = true
        end
    end
    Core.unlocked[key] = live
    return live
end

function Unlocks.has(player, pointId)
    local key = Core.playerKey(player)
    if not key then
        return false
    end
    -- The registry is asked first, and not just the cache. A point removed
    -- since the cache was built is still sitting in it, so trusting the cache
    -- alone would report a place nobody can go as known, and the failure
    -- would land at the moment somebody picked it. This is the same filter
    -- Unlocks.load applies; it has to be here too, because the cache outlives
    -- a registration change and nothing invalidates it.
    if not Core.points[pointId] then
        return false
    end
    local live = Core.unlocked[key] or Unlocks.load(player)
    return live[pointId] == true
end

--- Grant a point. Returns true only when something actually changed, so a
--- caller can use the return value to decide whether to tell the player.
function Unlocks.grant(player, pointId)
    local point = Core.points[pointId]
    if not point then
        return false
    end
    if Unlocks.has(player, pointId) then
        return false
    end

    record(player)[pointId] = true
    local key = Core.playerKey(player)
    Core.unlocked[key] = Core.unlocked[key] or {}
    Core.unlocked[key][pointId] = true

    triggerEvent(Core.events.OnPointUnlocked, player, point)
    Core.debugLn(tostring(key) .. " unlocked " .. pointId)
    return true
end

function Unlocks.revoke(player, pointId)
    if not Unlocks.has(player, pointId) then
        return false
    end
    record(player)[pointId] = nil
    local key = Core.playerKey(player)
    if Core.unlocked[key] then
        Core.unlocked[key][pointId] = nil
    end
    return true
end

--- Is this character standing close enough to an undiscovered point to have
--- found it? Returns the point that was unlocked, or nil.
--
-- Squared distance against a squared radius, so nothing needs a square root.
function Unlocks.checkDiscovery(player)
    if not player then
        return nil
    end
    local point, distance = Core.nearestPoint(player:getX(), player:getY(), player:getZ())
    if not point or point.discovery ~= Core.discovery.explore then
        return nil
    end
    local radius = Core.settings.DiscoveryRadius or 0
    if distance > (radius * radius) then
        return nil
    end
    if Unlocks.grant(player, point.id) then
        return point
    end
    return nil
end

--- What to send a client: every point it may see, flagged with whether this
--- character has it.
--
-- The payload carries the coordinates of an undiscovered point only when
-- ShowUndiscovered says so. That is not tidiness: a client that is handed the
-- position can draw it whatever the option says, so the option has to be
-- honoured on this side or it is not honoured at all.
function Unlocks.payloadFor(player)
    local live = Unlocks.load(player)
    local out = {}
    for _, point in ipairs(Core.sortedPoints()) do
        local known = live[point.id] == true
        if known or Core.settings.ShowUndiscovered then
            table.insert(out, {
                id = point.id,
                label = point.label,
                region = point.region,
                known = known,
                x = known and point.x or nil,
                y = known and point.y or nil,
                z = known and point.z or nil
            })
        end
    end
    return out
end

Core.modules.unlocks = Unlocks
return Unlocks
