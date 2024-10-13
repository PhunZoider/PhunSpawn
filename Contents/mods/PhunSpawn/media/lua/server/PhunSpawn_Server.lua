if not isServer() then
    return
end

local cached = nil
local cachedAll = nil
local cachedChunked = nil

local function addToChunks(point)
    if cachedChunked == nil then
        cachedChunked = {}
    end
    local ckey = math.floor(point.x / 10) .. "_" .. math.floor(point.y / 10)
    if not cachedChunked[ckey] then
        cachedChunked[ckey] = {}
    end
    table.insert(cachedChunked[ckey], ckey)
end

function PhunSpawn:getPointsFromFile(points)
    points = points or {}
    local file = self.consts.spawnpoints .. ".lua"
    local fromFile = PhunTools:loadTable(file)

    for _, v in ipairs(fromFile) do
        local key = v.key or self:getKey(v)
        if v.direction then
            v.direction = nil
        end
        points[key] = v
    end
    return points
end

function PhunSpawn:getChunk(ckey)
    if cachedAll == nil then
        self:getAllSpawnPoints(true)
    end
    return cachedChunked[ckey]
end

function PhunSpawn:getAllSpawnPoints(reload)

    if cachedAll ~= nil and not reload then
        return cachedAll
    end

    local points = {}

    -- add all the hard coded points
    local defaults = self:defaultPoints()
    for k, v in pairs(defaults) do
        v.default = true
        points[k] = v
    end

    self:getPointsFromFile(points)

    cachedAll = points
    return points

end

function PhunSpawn:getSpawnPoints(reload)

    if cached ~= nil and not reload then
        return cached
    end

    -- load all points
    local data = self:getAllSpawnPoints(reload)

    print("All spawn points:")
    PhunTools:printTable(data)

    local points = {}
    local forModData = {}

    -- filter out the ones that are not enabled or require mods that are not enabled
    for key, v in pairs(data) do
        local enabled = (v.mod == nil or v.mod == "") or getActivatedMods():contains(v.mod)
        if enabled and v.enabled ~= true then
            points[key] = v
            addToChunks(v) -- add to chunk map
            if v.default ~= true then
                -- this isn't a harccoded point
                -- so add to mod data for transmission to clients
                forModData[key] = v
            end
            v.default = nil
        end
    end

    ModData.add(self.consts.spawnpoints, forModData)

    cached = points
    return points
end

function OnEat_VentClue(food, player, percent)
    print("OnEat_VentClue")
    sendServerCommand(player, "PhunSpawn", "OnEat_VentClue", {
        name = player:getUsername()
    })
end
