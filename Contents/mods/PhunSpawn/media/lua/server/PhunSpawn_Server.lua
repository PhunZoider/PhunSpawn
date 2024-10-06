if not isServer() then
    return
end

local PhunSpawn = PhunSpawn

local getSpawnPointsFromFile = function()
    local file = PhunSpawn.consts.spawnpoints .. ".lua"
    local results = PhunTools:loadTable(file)
    return results
end

function PhunSpawn:getSpawnPoints(optionalAll)
    if optionalAll then
        if not self.data.allSpawnPoints then
            local points = {}
            local data = getSpawnPointsFromFile()
            for _, v in ipairs(data) do
                local key = self:getKey(v)
                v.key = key
                points[key] = v
            end
            self.data.allSpawnPoints = points
        end

        return self.data.allSpawnPoints
    else
        if not self.data.spawnPoints then
            local data = self:getSpawnPoints(true)
            local points = {}
            for key, v in pairs(data) do
                local enabled = (v.mod == nil or v.mod == "") or getActivatedMods():contains(v.mod)
                if enabled and v.enabled ~= true then
                    points[key] = v
                end
            end
            self.data.spawnPoints = points
            ModData.add(self.consts.spawnpoints, points)
        end
        return self.data.spawnPoints
    end
end

function PhunSpawn:upsertSpawnPoint(data)
    local points = self:getSpawnPoints(true)
    local key = self:getKey(data)
    data.key = key
    points[key] = data
    self.data.allSpawnPoints = points
    PhunTools:saveTable(self.consts.spawnpoints .. ".lua", points)
    self:loadSpawnPoints()
end

function PhunSpawn:deleteSpawnPoint(key)
    local points = self:getSpawnPoints(true)
    points[key] = nil
    self.data.allSpawnPoints = points
    PhunTools:saveTable(self.consts.spawnpoints .. ".lua", points)
    print("Deleted spawn point: " .. key)
    PhunTools:printTable(self.data.discovered)
    for playerName, discoveries in pairs(self.data.discovered) do
        if discoveries[key] then
            discoveries[key] = nil
        end
    end
    print("Deleted spawn point:NOW " .. key)
    PhunTools:printTable(self.data.discovered)

    self:loadSpawnPoints()
end

function PhunSpawn:loadSpawnPoints()
    self.data.spawnPoints = nil
    self.data.allSpawnPoints = nil
    local points = self:getSpawnPoints()
    ModData.add(self.consts.spawnpoints, points)
    ModData.transmit(self.consts.spawnpoints)
end

