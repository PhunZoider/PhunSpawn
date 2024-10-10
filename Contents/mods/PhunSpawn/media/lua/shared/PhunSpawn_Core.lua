PhunSpawn = {
    name = "PhunSpawn",
    consts = {
        spawnpoints = "PhunSpawn_SpawnPoints",
        discoveries = "PhunSpawn_Discoveries"
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

-- function PhunSpawn:getSpawnPoint(keyOrObj)
--     local key = self:getKey(keyOrObj)
--     return self.data.spawnPoints[key]
-- end

-- function PhunSpawn:isDiscovered(player, key)
--     local discoveries = self:getPlayerDiscoveries(player)
--     return discoveries[key] == true
-- end

-- function PhunSpawn:getPlayerDiscoveries(player)
--     local name = type(player) == "string" and player or player:getUsername()
--     if not self.system.data.discovered then
--         self.data.discovered = {}
--     end
--     if not self.system.data.discovered[name] then
--         self.system.data.discovered[name] = {}
--     end
--     return self.system.data.discovered[name]
-- end

-- function PhunSpawn:registerDiscovery(player, key)
--     local name = type(player) == "string" and player or player:getUsername()
--     local discoveries = self:getPlayerDiscoveries(player)
--     discoveries[key] = true
--     if isClient() then
--         -- tell server about this discovery
--         sendServerCommand(self.name, self.commands.registerDiscovery, {
--             playername = name,
--             key = key
--         })
--     end
--     return discoveries
-- end

-- function PhunSpawn:removeDiscovery(player, key)
--     self:getPlayerDiscoveries(player)[key] = nil
-- end
