PhunSpawn = {
    name = "PhunSpawn",
    consts = {
        spawnpoints = "PhunSpawn_SpawnPoints",
        discoveries = "PhunSpawn_Discoveries",
        settings = "PhunSpawn_Settings"
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
    settings = {
        debug = true
    },
    data = {
        spawnPoints = nil,
        allSpawnPoints = nil,
        discovered = nil
    },
    system = nil
}

-- Setup any events
for _, event in pairs(PhunSpawn.events) do
    if not Events[event] then
        LuaEventManager.AddEvent(event)
    end
end

function PhunSpawn:debug(...)
    if self.settings.debug then
        local args = {...}
        PhunTools:debug(args)
    end
end

-- Transforms an objects xyz into a key that SHOULD be unique
function PhunSpawn:getKey(obj)
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

function PhunSpawn:xyzFromKey(key)
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

function PhunSpawn:defaultPoints()

    local data = {}

    if SandboxVars.PhunSpawn.RespawnHospitalRooms then

        -- hard code hospital spawn points
        local rhr = {{
            x = 30000,
            y = 30001,
            z = 0
        }, {
            x = 30000,
            y = 30061,
            z = 0
        }, {
            x = 30000,
            y = 30121,
            z = 0
        }, {
            x = 30000,
            y = 30181,
            z = 0
        }, {
            x = 30000,
            y = 30241,
            z = 0
        }, {
            x = 30060,
            y = 30001,
            z = 0
        }, {
            x = 30060,
            y = 30061,
            z = 0
        }, {
            x = 30060,
            y = 30121,
            z = 0
        }, {
            x = 30060,
            y = 30181,
            z = 0
        }, {
            x = 30060,
            y = 30241,
            z = 0
        }, {
            x = 30120,
            y = 30001,
            z = 0
        }, {
            x = 30120,
            y = 30061,
            z = 0
        }, {
            x = 30120,
            y = 30121,
            z = 0
        }, {
            x = 30120,
            y = 30181,
            z = 0
        }, {
            x = 30120,
            y = 30241,
            z = 0
        }, {
            x = 30180,
            y = 30061,
            z = 0
        }, {
            x = 30180,
            y = 30121,
            z = 0
        }, {
            x = 30180,
            y = 30181,
            z = 0
        }, {
            x = 30180,
            y = 30241,
            z = 0
        }, {
            x = 30240,
            y = 30001,
            z = 0
        }, {
            x = 30240,
            y = 30061,
            z = 0
        }, {
            x = 30240,
            y = 30121,
            z = 0
        }, {
            x = 30240,
            y = 30181,
            z = 0
        }, {
            x = 30240,
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

