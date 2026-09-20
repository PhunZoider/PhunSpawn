require "PhunSpawn/core"
require "PhunSpawn/tools"
local Core = PhunSpawn

-- ---------------------------------------------------------------------------
-- The spawn point registry.
--
-- A point is data, not arithmetic. There is deliberately no "origin plus
-- pitch times index" form: a genuinely regular set of points is a for loop in
-- the caller, and the moment somebody wants one that is not on the grid an
-- arithmetic scheme cannot describe it at all. PhunInteriors learned that the
-- expensive way with its room locations.
--
-- A point id is a key in a registry shared with third parties, so ours are
-- namespaced `phun.spawn.*` and the author docs tell everybody else to
-- namespace theirs. Re-registering your own id replaces it; re-registering
-- somebody else's is a warning and still replaces it, because a silent
-- replacement is worse than a loud one.
--
-- Every reverse index is rebuilt LAZILY, on the first read after any
-- registration. That is what lets a third party register from any vanilla
-- hook, including one that fires long after our own boot sequence, without
-- anybody having to sequence anything. Nothing here may warn about a missing
-- link at boot, because at boot it cannot tell "not registered yet" from "the
-- mod that owns it is not installed".
-- ---------------------------------------------------------------------------

-- How a point is unlocked. The value is stored on the point and read by
-- server/unlocks.lua; nothing else keys on it.
Core.discovery = {
    -- known from character creation
    start = "start",
    -- unlocked by getting within DiscoveryRadius of it
    explore = "explore",
    -- unlocked by building the thing that marks it
    built = "built",
    -- unlocked by something else entirely: another mod, a quest, an admin
    granted = "granted"
}

local function invalidate()
    Core.indexesBuilt = false
end

--- Register a spawn point.
--
-- @param id     namespaced string, eg "phun.spawn.muldraugh.warehouse"
-- @param def    table:
--   label       what a player sees. Required, because an id is not prose and
--               must never become prose: the label is editable and the id is
--               what a character's unlock list persists, so two strings that
--               look alike with opposite mutability is a trap.
--   x, y, z     where the character wakes up. Required.
--   region      free text, used only for grouping in the picker. Optional.
--   discovery   one of Core.discovery. Defaults to `explore`, because a point
--               that is unlocked from the start should have to say so: the
--               safe default is the one that gives nothing away.
--   room        a PhunInteriors room id, if this point wakes you up inside
--               one rather than on the square. Optional, and ignored when
--               PhunInteriors is absent.
--   priority    lower sorts first in the picker. Optional.
function Core.registerPoint(id, def)
    if type(id) ~= "string" or id == "" then
        Core.logLn("registerPoint needs a string id")
        return nil
    end
    if type(def) ~= "table" then
        Core.logLn("registerPoint('" .. id .. "') needs a definition table")
        return nil
    end
    if type(def.label) ~= "string" or def.label == "" then
        Core.logLn("registerPoint('" .. id .. "') needs a label")
        return nil
    end
    if type(def.x) ~= "number" or type(def.y) ~= "number" then
        Core.logLn("registerPoint('" .. id .. "') needs numeric x and y")
        return nil
    end

    if Core.points[id] then
        Core.logLn("point '" .. id .. "' is being redefined")
    end

    local point = {
        id = id,
        label = def.label,
        x = def.x,
        y = def.y,
        z = def.z or 0,
        region = def.region,
        discovery = def.discovery or Core.discovery.explore,
        room = def.room,
        priority = def.priority or 0
    }

    Core.points[id] = point
    invalidate()
    return point
end

--- Forget a point.
--
-- Note what this does NOT do: it does not go round every character's unlock
-- list taking the id out. An unlock naming a point that no longer exists is
-- filtered on read, which is cheap and which means removing a point set
-- temporarily and putting it back does not cost anybody their exploring.
function Core.removePoint(id)
    if not Core.points[id] then
        return false
    end
    Core.points[id] = nil
    invalidate()
    return true
end

--- Rebuild the reverse indexes. Called by every reader, never by a writer.
function Core.buildIndexes()
    if Core.indexesBuilt then
        return
    end
    Core.indexesBuilt = true

    local regions = {}
    for id, point in pairs(Core.points) do
        local region = point.region or ""
        regions[region] = regions[region] or {}
        regions[region][id] = true
    end
    Core.regions = regions
end

--- Every point, sorted for a stable picker.
--
-- Sorted on (priority, label, id). The id tail is not decoration: pairs()
-- order is not stable, ties are routine, and without it one save would draw
-- the same list in two different orders.
function Core.sortedPoints()
    Core.buildIndexes()
    local out = {}
    for _, point in pairs(Core.points) do
        table.insert(out, point)
    end
    table.sort(out, function(a, b)
        if a.priority ~= b.priority then
            return a.priority < b.priority
        end
        if a.label ~= b.label then
            return a.label < b.label
        end
        return a.id < b.id
    end)
    return out
end

--- The points in one region, sorted the same way.
function Core.pointsInRegion(region)
    Core.buildIndexes()
    local ids = Core.regions[region or ""] or {}
    local out = {}
    for _, point in ipairs(Core.sortedPoints()) do
        if ids[point.id] then
            table.insert(out, point)
        end
    end
    return out
end

--- The point nearest a position, and how far away it is.
--
-- Squared distance throughout, so nothing needs a square root to answer
-- "is anything within the discovery radius". The caller compares against
-- radius * radius.
function Core.nearestPoint(x, y, z)
    Core.buildIndexes()
    local best, bestDistance
    for _, point in pairs(Core.points) do
        if (point.z or 0) == (z or 0) then
            local dx, dy = point.x - x, point.y - y
            local distance = (dx * dx) + (dy * dy)
            if not bestDistance or distance < bestDistance then
                best, bestDistance = point, distance
            end
        end
    end
    return best, bestDistance
end

--- Counts, for the boot log. Always true, unlike anything about what is
--- missing, which is why this is all that is logged at boot.
function Core.describeRegistry()
    Core.buildIndexes()
    local points, regions = 0, 0
    for _ in pairs(Core.points) do
        points = points + 1
    end
    for _ in pairs(Core.regions) do
        regions = regions + 1
    end
    return tostring(points) .. " point(s) across " .. tostring(regions) .. " region(s)"
end

return Core
