if isClient() then
    return
end
require "Map/SGlobalObjectSystem"
local fileTools = require("PhunSpawn/files")
local PS = PhunSpawn
local Commands = nil
local objName = "SPhunSpawnSystem"
local ServerSystem = SGlobalObjectSystem:derive("SPhunSpawnSystem")
SPhunSpawnSystem = ServerSystem

function ServerSystem:new()
    local o = ServerSystem.new(self, "phunspawn")
    o.data = {
        spawnPoints = ModData.getOrCreate(PS.consts.spawnpoints),
        allSpawnPoints = nil,
        discovered = ModData.getOrCreate(PS.consts.discoveries),
        chunkedSpawnPoints = {}
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

function ServerSystem.addToWorld(square, data, direction)
    direction = direction or "south"
    PS:getKey(square)

    local isoObject

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

-- local oldOnChunkLoaded = SGlobalObjectSystem.OnChunkLoaded
-- SGlobalObjectSystem.OnChunkLoaded = function(self, wx, wy)

--     print("OnChunkLoaded ", wx, wy)
--     local ckey = wx .. "_" .. wy
--     local chunk = PS:getChunk(ckey)
--     if chunk then
--         -- check that chunks spawn points are loaded
--         print("Following spawn points need verification ", ckey)
--         PhunTools:printTable(chunk)

--         for _, v in ipairs(chunk) do
--             local sq = getCell():getGridSquare(v.x, v.y, v.z)
--             if sq then
--                 SPhunSpawnSystem.instance:verifyOnLoadSquare(sq)
--             end
--         end
--     end

--     return oldOnChunkLoaded(self, wx, wy)
-- end

function ServerSystem:addFromSprite(x, y, z, sprite)

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

function ServerSystem:initSystem()
    SGlobalObjectSystem.initSystem(self)
    -- Specify GlobalObjectSystem fields that should be saved.
    self.system:setModDataKeys({})
    -- Specify GlobalObject fields that should be saved.
    self.system:setObjectModDataKeys({'id', 'key', 'label', 'direction', 'location', 'sprites'})

end

function ServerSystem:addObject()

end

function ServerSystem:isValidModData(modData)
    return modData and modData.restocked
end

function ServerSystem:newLuaObject(globalObject)
    return SPhunSpawnObject:new(self, globalObject)
end

function ServerSystem:newLuaObjectAt(x, y, z)
    self:noise("adding luaObject " .. x .. ',' .. y .. ',' .. z)
    local globalObject = self.system:newObject(x, y, z)
    return self:newLuaObject(globalObject)
end

function ServerSystem:isValidIsoObject(isoObject)
    return instanceof(isoObject, "IsoObject") and isoObject:getName() == "PhunSpawnPoint"
end

function ServerSystem:upsertSpawnPoint(data)
    data.direction = nil
    local points = PS:getSpawnPoints(true)
    local key = PS:getKey(data)
    data.key = key
    if not points[key] then
        -- new spawn point
        local sq = getCell():getGridSquare(data.x, data.y, data.z)
        if sq then
            ServerSystem.addToWorld(sq, data, "south")
        end

    end
    points[key] = data
    self.data.allSpawnPoints = points

    local filePoints = PS:getPointsFromFile()
    filePoints[key] = data

    fileTools:saveTable(PS.consts.spawnpoints .. ".lua", filePoints)
    self:loadSpawnPoints()
end

function ServerSystem:deleteSpawnPoint(key)
    local points = PS:getSpawnPoints(true)
    points[key] = nil
    self.data.allSpawnPoints = points
    local filePoints = PS:getPointsFromFile()
    filePoints[key] = data

    fileTools:saveTable(PS.consts.spawnpoints .. ".lua", filePoints)
    for playerName, discoveries in pairs(self.data.discovered) do
        if discoveries[key] then
            discoveries[key] = nil
        end
    end

    self:loadSpawnPoints()
end

function ServerSystem:registerDiscovery(player, key)
    print("registerDiscovery ", key)
    local name = type(player) == "string" and player or player:getUsername()
    local discoveries = self:getPlayerDiscoveries(player)
    discoveries[key] = true

    return discoveries
end

function ServerSystem:getPlayerDiscoveries(player)
    local name = type(player) == "string" and player or player:getUsername()
    if not self.system.data.discovered then
        self.data.discovered = {}
    end
    if not self.system.data.discovered[name] then
        self.system.data.discovered[name] = {}
    end
    return self.system.data.discovered[name]
end

function ServerSystem:getSpawnPoint(keyOrObj)
    local key = PS:getKey(keyOrObj)
    return PS:getSpawnPoints()[key] or nil
end

function ServerSystem:verifyOnLoadSquare(square)

    local key = square:getX() .. "_" .. square:getY() .. "_" .. square:getZ()
    if self:getSpawnPoint(key) then
        -- print("Found spawn point for " .. key)
        local v = self:getSpawnPoint(key)
        local existing = self:getIsoObjectAt(v.x, v.y, v.z)
        if not existing then
            print("Missing existing object for " .. v.x .. ',' .. v.y .. ',' .. v.z)
            self.addToWorld(square, v, "south")
        end
    end
end

function ServerSystem:OnClientCommand(command, player, args)
    if not Commands then
        Commands = require "PhunSpawn_Server_Commands"
    end
    print("OnClientCommand ", command)
    for k, v in pairs(Commands) do
        print(k)
    end
    if Commands[command] then
        Commands[command](player, args)
    end
end

function ServerSystem:loadSpawnPoints()
    self.data.spawnPoints = nil
    self.data.allSpawnPoints = nil
    local points = PS:getSpawnPoints()
    ModData.add(PS.consts.spawnpoints, points)
    ModData.transmit(PS.consts.spawnpoints)
end

SGlobalObjectSystem.RegisterSystemClass(ServerSystem)

