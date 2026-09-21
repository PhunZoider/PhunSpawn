-- Just enough of the PZ global surface to load the shared and server files
-- under LuaJIT.
--
-- This is not a mock of the game. It stubs the globals the files touch while
-- LOADING, so the pure Lua half of the mod -- the point registry, the reverse
-- indexes, the unlock bookkeeping -- can be exercised without one. Any test
-- that needs an IsoGridSquare belongs in the game, not here. Do not try to
-- grow this into a simulator.
--
-- Note what LuaJIT cannot catch: PZ's sandbox does not expose next(), and
-- LuaJIT does, so a next() call passes here and fails in game. The same goes
-- for loadstring, load and loadfile, which B42.20.4 removed.

local stubs = {}

function stubs.install(root)
    local handlers = {}
    local function slot(name)
        handlers[name] = handlers[name] or {fns = {}}
        local s = handlers[name]
        s.Add = s.Add or function(fn) table.insert(s.fns, fn) end
        s.Remove = s.Remove or function() end
        return s
    end

    Events = setmetatable({}, {__index = function(_, k) return slot(k) end})
    LuaEventManager = {AddEvent = function(name) slot(name) end}
    function triggerEvent(name, ...)
        for _, fn in ipairs(slot(name).fns) do fn(...) end
    end

    -- SP: both false, so shared, server and client files all load.
    function isClient() return false end
    function isServer() return false end
    function isCoopHost() return false end

    function getSandboxOptions() return {getOptionByName = function() return nil end} end

    stubs.worldAge = 0
    stubs.hour = 12
    function getGameTime()
        return {
            getWorldAgeHours = function() return stubs.worldAge end,
            getHour = function() return stubs.hour end
        }
    end

    -- An empty world. Nothing here pretends to be an IsoGridSquare; a test
    -- that needs a real one belongs in the game.
    function getCell() return {getGridSquare = function() return nil end} end

    -- A world with no edges. The only caller uses the meta grid to refuse
    -- coordinates this world does not have, so saying yes to everything is
    -- the "nothing is out of range" case and is the one every spec wants. A
    -- spec that cares about the refusal replaces this for the length of the
    -- test.
    function getWorld()
        return {
            getMetaGrid = function()
                return {
                    isValidSquare = function() return true end,
                    getMinX = function() return 0 end,
                    getMaxX = function() return 0 end,
                    getMinY = function() return 0 end,
                    getMaxY = function() return 0 end
                }
            end
        }
    end

    local modData = {}
    ModData = {getOrCreate = function(k) modData[k] = modData[k] or {}; return modData[k] end}
    function getOnlinePlayers() return nil end
    function getPlayer() return nil end
    function getText(key, arg) return tostring(key) .. (arg and (" " .. tostring(arg)) or "") end

    -- Sequential rather than random, because a test that asserts on an id is
    -- more use than one that asserts an id exists.
    local uuids = 0
    function getRandomUUID() uuids = uuids + 1; return "uuid-" .. uuids end

    -- The mod's own require, resolving "PhunSpawn/x" against the three source
    -- trees the game merges into one.
    local lua = root .. "/Contents/mods/PhunSpawn/common/media/lua/"
    local loaded = {}
    function require(path)
        if loaded[path] then return loaded[path] end
        loaded[path] = true
        for _, dir in ipairs({"shared/", "server/", "client/"}) do
            local file = lua .. dir .. path .. ".lua"
            local fh = io.open(file, "r")
            if fh then
                fh:close()
                loaded[path] = assert(loadfile(file))() or true
                return loaded[path]
            end
        end
        error("no module " .. path)
    end
end

--- A stand-in player: a username and a modData table that persists for the
--- length of the test. Enough for everything the unlock layer does, and
--- deliberately not enough for anything that reads a square.
---
--- `hours` is how long the character has survived, which is how placement.lua
--- tells a new character from an established one. Defaults to 0, a new one.
function stubs.player(name, hours)
    local md = {}
    local x, y, z = 0, 0, 0
    return {
        getUsername = function() return name end,
        getModData = function() return md end,
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return z end,
        getHoursSurvived = function() return hours or 0 end,
        moveTo = function(nx, ny, nz) x, y, z = nx, ny, nz or 0 end
    }
end

-- Minimal assertion surface. Deliberately does not stop at the first failure:
-- a registry bug usually breaks several of these at once and the pattern is
-- the diagnosis.
function stubs.reporter()
    local r = {checks = 0, failures = 0}
    function r.check(label, got, want)
        r.checks = r.checks + 1
        if got ~= want then
            r.failures = r.failures + 1
            print(string.format("  FAIL %-52s got %s want %s", label, tostring(got), tostring(want)))
        end
    end
    function r.finish(name)
        print(string.format("%-16s %d checks, %d failures", name, r.checks, r.failures))
        return r.failures
    end
    return r
end

return stubs
