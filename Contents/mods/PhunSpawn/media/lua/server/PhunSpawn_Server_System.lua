if not isServer() then
    return
end
local PS = PhunSpawn
local sandbox = SandboxVars.PhunSpawn
require "Map/SGlobalObjectSystem"

SPhunSpawnSystem = SGlobalObjectSystem:derive("SPhunSpawnSystem")
SPhunSpawnSystem.Commands = require "PhunSpawn_Server_Commands"
function SPhunSpawnSystem:new()
    local o = SGlobalObjectSystem.new(self, "phunspawn")
    o.data = {
        spawnPoints = ModData.getOrCreate(PS.consts.spawnpoints),
        allSpawnPoints = nil,
        discovered = ModData.getOrCreate(PS.consts.discoveries)
    }
    o:loadSpawnPoints()
    return o
end

local function isNorth(square)
    return square:getWall(true)
end

local function isWest(square)
    return square:getWall(false)
end

function SPhunSpawnSystem.addToWorld(square, data, direction)
    print("Add to world")
    direction = direction or "south"
    PS:getKey(square)

    local isoObject

    -- isoObject = IsoThumpable.new(square:getCell(), square, "phunspawn_01_0", false, {})
    isoObject = IsoObject.new(square, "phunspawn_01_0")

    data.direction = direction

    isoObject:getModData()['PhunSpawn'] = data
    if isNorth(square) then
        isoObject:setSprite("phunspawn_01_4")
    elseif isWest(square) then
        isoObject:setSprite("phunspawn_01_6")
    else
        isoObject:setSprite("phunspawn_01_0")
    end

    isoObject:setName("PhunSpawnPoint")
    square:AddSpecialObject(isoObject, -1)
    triggerEvent("OnObjectAdded", isoObject)
    isoObject:transmitCompleteItemToClients()
end

local oldOnChunkLoaded = SGlobalObjectSystem.OnChunkLoaded
SGlobalObjectSystem.OnChunkLoaded = function(self, wx, wy)

    print("''''''''''''''''''''''''''''''''")
    print("OnChunkLoaded ", wx, wy)
    print("11111111111111111111111111111111")

    local ckey = wx .. "_" .. wy
    if PS.data.chunkedSpawnPoints[ckey] then
        -- check that chunks spawn points are loaded
        print("Following spawn points need verification ", ckey)
        PhunTools:printTable(PS.data.chunkedSpawnPoints[ckey])
    else
        print("No spawn points for chunk ", ckey)
    end

    return oldOnChunkLoaded(self, wx, wy)
end

function SPhunSpawnSystem:addFromSprite(x, y, z, sprite)

    -- iterate through shops to get the associated shop

    local point = nil
    local dir = nil
    -- is there a shop but it is orphaned from the obj?
    local key = PS:getKey({
        x = x,
        y = y,
        z = z
    })

end

function SPhunSpawnSystem:initSystem()
    print("=========================")
    print("PhunSpawnSystem:initSystem")
    print("=========================")
    SGlobalObjectSystem.initSystem(self)
    print("inited system")
    -- Specify GlobalObjectSystem fields that should be saved.
    self.system:setModDataKeys({})
    print("set mod data keys")
    -- Specify GlobalObject fields that should be saved.
    self.system:setObjectModDataKeys({'id', 'key', 'label', 'direction', 'location', 'sprites'})
    print("set object mod data keys")

end

function SPhunSpawnSystem:addObject()
    print("----- ADD OBJECT --- ")
end

function SPhunSpawnSystem:isValidModData(modData)
    return modData and modData.restocked
end

function SPhunSpawnSystem:newLuaObject(globalObject)
    return SPhunSpawnObject:new(self, globalObject)
end

function SPhunSpawnSystem:newLuaObjectAt(x, y, z)
    self:noise("adding luaObject " .. x .. ',' .. y .. ',' .. z)
    print("adding luaObject " .. x .. ',' .. y .. ',' .. z)
    local globalObject = self.system:newObject(x, y, z)
    return self:newLuaObject(globalObject)
end

function SPhunSpawnSystem:isValidIsoObject(isoObject)
    return instanceof(isoObject, "IsoObject") and isoObject:getName() == "PhunSpawnPoint"
end

local getSpawnPointsFromFile = function()
    local file = PhunSpawn.consts.spawnpoints .. ".lua"
    local results = PhunTools:loadTable(file)
    return results
end

function SPhunSpawnSystem:getSpawnPoints(optionalAll)
    if optionalAll then
        if not self.data.allSpawnPoints then
            local points = {}
            local chunked = {}
            local data = getSpawnPointsFromFile()
            for _, v in ipairs(data) do
                local key = PS:getKey(v)
                v.key = key
                local ckey = math.floor(v.x / 10) .. "_" .. math.floor(v.y / 10)
                if not chunked[ckey] then
                    chunked[ckey] = {}
                end
                table.insert(chunked[ckey], v)
                points[key] = v
            end
            self.data.chunkedSpawnPoints = chunked
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
            ModData.add(PS.consts.spawnpoints, points)
        end
        return self.data.spawnPoints
    end
end

function SPhunSpawnSystem:upsertSpawnPoint(data)
    local points = self:getSpawnPoints(true)
    local key = PS:getKey(data)
    data.key = key
    points[key] = data
    self.data.allSpawnPoints = points
    PhunTools:saveTable(self.consts.spawnpoints .. ".lua", points)
    self:loadSpawnPoints()
end

function SPhunSpawnSystem:deleteSpawnPoint(key)
    local points = self:getSpawnPoints(true)
    points[key] = nil
    self.data.allSpawnPoints = points
    PhunTools:saveTable(self.consts.spawnpoints .. ".lua", points)
    for playerName, discoveries in pairs(self.data.discovered) do
        if discoveries[key] then
            discoveries[key] = nil
        end
    end

    self:loadSpawnPoints()
end

function SPhunSpawnSystem:registerDiscovery(player, key)
    local name = type(player) == "string" and player or player:getUsername()
    local discoveries = self:getPlayerDiscoveries(player)
    discoveries[key] = true
    return discoveries
end

function SPhunSpawnSystem:getPlayerDiscoveries(player)
    local name = type(player) == "string" and player or player:getUsername()
    if not self.system.data.discovered then
        self.data.discovered = {}
    end
    if not self.system.data.discovered[name] then
        self.system.data.discovered[name] = {}
    end
    return self.system.data.discovered[name]
end

function SPhunSpawnSystem:verifyOnLoadSquare(square)

    local key = square:getX() .. "_" .. square:getY() .. "_" .. square:getZ()
    if self.data.spawnPoints[key] then
        local v = self.data.spawnPoints[key]
        local existing = self:getIsoObjectAt(v.x, v.y, v.z)
        if not existing then
            print("Missing existing object for " .. v.x .. ',' .. v.y .. ',' .. v.z)
            self.addToWorld(square, v, "south")
        end
    end
end

function SPhunSpawnSystem:loadSpawnPoints()
    self.data.spawnPoints = nil
    self.data.allSpawnPoints = nil
    local points = self:getSpawnPoints()
    ModData.add(PS.consts.spawnpoints, points)
    ModData.transmit(PS.consts.spawnpoints)
end

SGlobalObjectSystem.RegisterSystemClass(SPhunSpawnSystem)

