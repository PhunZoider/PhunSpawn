PhunSpawn = {
    name = "PhunSpawn",
    consts = {
        spawnpoints = "PhunSpawn_SpawnPoints",
        discoveries = "PhunSpawn_Discoveries",
        settings = "PhunSpawn_Settings",
        activated = "PhunSpawn_Activated",
        modifiedLuaFile = "PhunSpawn_Changes.lua",
        modifiedData = "PhunSpawn_Modified"
    },
    commands = {
        getAllSpawns = "getAllSpawns",
        allSpawnPoints = "allSpawnPoints",
        killZombie = "killZombie",
        upsertSpawnPoint = "upsertSpawnPoint",
        upsertedSpawnPoint = "upsertedSpawnPoint",
        deleteSpawnPoint = "deleteSpawnPoint",
        getMyDiscoveries = "getMyDiscoveries",
        registerDiscovery = "registerDiscovery"

    },
    events = {},
    settings = {},
    data = {
        spawnPoints = nil,
        allSpawnPoints = nil,
        discovered = nil,
        basePool = nil,
        modifiedPool = nil,
        mergedPool = nil,
        activatedPools = nil,
        finalised = nil
    },
    system = nil,
    ui = {
        main = nil
    }
}
local Core = PhunSpawn
Core.isLocal = not isClient() and not isServer() and not isCoopHost()
Core.settings = SandboxVars[Core.name] or {}
-- Setup any events
for _, event in pairs(PhunSpawn.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

-- Transforms an objects xyz into a key that SHOULD be unique
function Core:getKey(obj)
    if type(obj) == "string" then
        return obj
    end
    if obj then
        if obj.getX then
            return obj:getX() .. "_" .. obj:getY() .. "_" .. obj:getZ()
        elseif obj.x then
            return obj.x .. "_" .. obj.y .. "_" .. obj.z
        end
    end
end

function Core:xyzFromKey(key)
    if not key or string.len(key) == 0 then
        return
    end
    local result = {}
    for substring in string.gmatch(key, "[^_]+") do
        table.insert(result, substring)
    end
    return {
        x = tonumber(result[1]),
        y = tonumber(result[2]),
        z = tonumber(result[3])
    }
end

function Core:defaultPoints()

    local data = {}

    if SandboxVars.PhunSpawn.RespawnHospitalRooms then

        -- hard code hospital spawn points
        local rhr = {{
            x = 30000, -- 1
            y = 30001,
            z = 0
        }, {
            x = 30000, -- 2
            y = 30061,
            z = 0
        }, {
            x = 30000, -- 3
            y = 30121,
            z = 0
        }, {
            x = 30000, -- 4
            y = 30181,
            z = 0
        }, {
            x = 30000, -- 5
            y = 30241,
            z = 0
        }, {
            x = 30060, -- 6
            y = 30001,
            z = 0
        }, {
            x = 30060, -- 7
            y = 30061,
            z = 0
        }, {
            x = 30060, -- 8
            y = 30121,
            z = 0
        }, {
            x = 30060, -- 9
            y = 30181,
            z = 0
        }, {
            x = 30060, -- 10
            y = 30241,
            z = 0
        }, {
            x = 30120, -- 11
            y = 30001,
            z = 0
        }, {
            x = 30120, -- 12
            y = 30061,
            z = 0
        }, {
            x = 30120, -- 13
            y = 30121,
            z = 0
        }, {
            x = 30120, -- 14
            y = 30181,
            z = 0
        }, {
            x = 30120, -- 15
            y = 30241,
            z = 0
        }, {
            x = 30180, -- 16
            y = 30001,
            z = 0
        }, {
            x = 30180, -- 17
            y = 30061,
            z = 0
        }, {
            x = 30180, -- 18
            y = 30121,
            z = 0
        }, {
            x = 30180, -- 19
            y = 30181,
            z = 0
        }, {
            x = 30180, -- 20
            y = 30241,
            z = 0
        }, {
            x = 30240, -- 21
            y = 30001,
            z = 0
        }, {
            x = 30240, -- 22
            y = 30061,
            z = 0
        }, {
            x = 30240, -- 23
            y = 30121,
            z = 0
        }, {
            x = 30240, -- 23
            y = 30181,
            z = 0
        }, {
            x = 30240, -- 24
            y = 30241,
            z = 0
        }}

        for i, v in ipairs(rhr) do
            local key = self:getKey(v)
            data[key] = {
                city = "Hospital",
                title = "Room " .. i,
                discoverable = false,
                autoDiscovered = false,
                canEnter = true,
                description = "",
                mod = "respawn-hospital-rooms2",
                x = v.x,
                y = v.y,
                z = v.z
            }
        end

    end

    return data

end

