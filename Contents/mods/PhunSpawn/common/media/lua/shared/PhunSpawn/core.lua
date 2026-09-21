-- PhunSpawn
--
-- Spawn points that are earned rather than listed. A character starts knowing
-- the few the save is configured to give them and finds the rest by walking
-- the map or by building one, and a new character wakes up in a room rather
-- than on a kerb.
--
-- Standard Phun conventions, mirroring PhunInteriors and PhunCure2:
--   * everything hangs off this one global and nothing else,
--   * nothing may be hung off it under a name this table already declares,
--   * *_commands.lua returns a Commands table and *_events.lua dispatches
--     into it,
--   * server files open with `if isClient() then return end`, client files
--     with `if isServer() then return end`, and in SP both load,
--   * one code path for SP and MP, through Core.dispatch / Core.respond.
PhunSpawn = {
    name = "PhunSpawn",
    consts = {
        -- global ModData key, and the key every sub table hangs off
        modDataKey = "PhunSpawn",
        -- Which points this character has unlocked, on the PLAYER.
        --
        -- Player modData rather than our own store, for the reason
        -- PhunInteriors keeps its entrance position there: IsoPlayer.save
        -- reaches IsoMovingObject.save, which writes the modData KahluaTable
        -- into the character record. So an unlock survives a restart and the
        -- loss of global_mod_data.bin, which is the difference between a
        -- player losing an afternoon of exploring and not.
        --
        -- It is per CHARACTER and deliberately so. Discovery is the mechanic,
        -- and an account wide list would hand the second character a map that
        -- is already solved.
        unlockedKey = "PhunSpawn_unlocked",
        -- Where this character last chose to wake up, so the picker opens on
        -- it rather than on the top of the list.
        lastChoiceKey = "PhunSpawn_lastChoice",
        -- Whether this character has been placed yet, on the PLAYER. See
        -- server/placement.lua: nil is "not looked at", "pending" is a new
        -- character still choosing, and a number is when they were placed.
        -- Kept beside the unlocks for the same reason: a character who
        -- rejoins must not be offered a second free choice.
        spawnedKey = "PhunSpawn_spawned",
        -- Durable id of a point a player BUILT, written into the object's
        -- modData. Inside movableData rather than at the top level, because
        -- vanilla drops a top level key on pickup for some object classes and
        -- not others: see the pickup row in PhunInteriors' API table.
        objectIdKey = "PhunSpawn_pointId"
    },
    data = {},
    commands = {
        -- client -> server, on login: "tell me what I know about"
        playerSetup = "playerSetup",
        -- server -> client: the points this character may pick from
        points = "points",
        -- client -> server: "wake me up here next time"
        choose = "choose",
        -- client -> server: "put me at this point now". Carries a point id,
        -- which the server checks against the character's own unlocks and
        -- against whether they may still choose at all.
        spawn = "spawn",
        -- server -> client: "you just found one", so the client can say so
        unlocked = "unlocked",
        -- client -> server: "I am standing on a point, count it as found".
        -- Carries a square and nothing else. The server reads the point off
        -- the position rather than taking a point id from a client, the same
        -- way PhunInteriors names a position and never an identity.
        discover = "discover",
        -- client -> server: "put a point of mine on the map here"
        buildPoint = "buildPoint",
        notify = "notify",
        admin = "admin",
        adminResult = "adminResult"
    },
    events = {
        -- Where third party mods register their own points, and where
        -- defaults.lua registers ours. Fired from Core.openRegistration.
        --
        -- Events rather than an "is PhunSpawn loaded" test on their side: if
        -- we are absent they never fire, so nobody has to guess how far
        -- through booting we are. What this does NOT buy is load order
        -- independence, which comes from the author hooking a vanilla event
        -- and registering from inside it. See README.md.
        OnRegisterPoints = "PhunSpawnOnRegisterPoints",
        OnReady = "PhunSpawnOnReady",
        -- A character unlocked a point. Carries (player, point).
        OnPointUnlocked = "PhunSpawnOnPointUnlocked",
        -- A character was spawned at one. Carries (player, point).
        OnSpawned = "PhunSpawnOnSpawned",
        -- CLIENT side: a fresh points payload has landed in Client.points.
        -- Carries the payload. The picker's list redraws on it, so a point
        -- found while the window is open shows up without reopening it.
        OnPointsReceived = "PhunSpawnOnPointsReceived"
    },
    -- Registry, populated by points.lua and by other mods on the register
    -- event.
    --   points:  id -> one spawn point
    --   regions: region name -> {pointId = true}, rebuilt lazily on first
    --            read after any registration, so a point that registers late
    --            is indexed without anybody having to sequence anything.
    points = {},
    regions = {},
    -- Server side only: username -> {pointId = true}. A cache of what the
    -- character's own modData says, so a lookup does not reach into the
    -- character record on every tick. The modData is the truth; this is the
    -- copy, and it is rebuilt on playerSetup.
    unlocked = {},
    settings = {},
    ui = {},
    modules = {}
}

local Core = PhunSpawn

Core.isLocal = not isClient() and not isServer() and not isCoopHost()

for _, event in pairs(Core.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

--- Open registration.
--
-- Guarded, because in single player both server_events and client_events load
-- and each fires the boot sequence. Without the guard every handler, ours and
-- every third party's, runs twice. Mostly harmless here, since registerPoint
-- replaces rather than accumulates, but it logs a redefinition for every point
-- on every SP boot and turns a warning that ought to mean something into noise
-- nobody reads.
function Core.openRegistration()
    if Core.registrationFired then
        return false
    end
    Core.registrationFired = true
    triggerEvent(Core.events.OnRegisterPoints, Core)
    return true
end

-- Every constraint is a switch and the defaults are the balanced ones.
Core.defaults = {
    Debug = false,
    -- A new character wakes up in the spawn room rather than at the point
    -- itself. Needs PhunInteriors. With it absent this does nothing and the
    -- character is placed at the point, which is the honest fallback rather
    -- than a failure.
    UseSpawnRoom = true,
    -- How close you have to get before a point counts as found.
    DiscoveryRadius = 12,
    -- Whether undiscovered points are drawn greyed out or not at all. Shown
    -- is a map of somewhere to head for, hidden is a blank one.
    ShowUndiscovered = false,
    -- Whether a player may build a point of their own.
    AllowBuiltPoints = true,
    -- How many a character may hold at once. Zero means no limit.
    BuiltPointLimit = 3,
    -- Whether choosing a point costs the character anything on respawn.
    RespawnPenalty = false
}

function Core.getOption(name, default)
    local opt = getSandboxOptions():getOptionByName(Core.name .. "." .. name)
    local val = opt and opt:getValue()
    if val == nil then
        return default
    end
    return val
end

function Core.refreshSettings()
    for name, default in pairs(Core.defaults) do
        Core.settings[name] = Core.getOption(name, default)
    end
    return Core.settings
end

function Core.debugLn(str)
    if Core.settings.Debug then
        print("[" .. Core.name .. "] " .. tostring(str))
    end
end

function Core.logLn(str)
    print("[" .. Core.name .. "] " .. tostring(str))
end

-- Client -> server. In single player there is no round trip, so call the
-- handler directly. This is what keeps SP and MP on one code path, and it is
-- the one rule in this family nothing may work around: a separate SP
-- implementation is two halves that drift.
function Core.dispatch(command, args)
    if Core.isLocal then
        local handlers = require "PhunSpawn/server_commands"
        local handler = handlers[command]
        if handler then
            handler(getPlayer(), args or {})
        end
    else
        sendClientCommand(Core.name, command, args or {})
    end
end

-- Server -> client, same deal in reverse.
function Core.respond(player, command, args)
    if Core.isLocal then
        local handlers = require "PhunSpawn/client_commands"
        local handler = handlers[command]
        if handler then
            handler(args or {})
        else
            Core.logLn("no local client handler for '" .. tostring(command) .. "'")
        end
    else
        sendServerCommand(player, Core.name, command, args or {})
    end
end

function Core.playerKey(player)
    if not player then
        return nil
    end
    return player:getUsername() or tostring(player:getOnlineID())
end

function Core.now()
    return getGameTime():getWorldAgeHours()
end

Core.refreshSettings()

Events.EveryTenMinutes.Add(function()
    Core.refreshSettings()
end)

return Core
