if isClient() then
    return
end
require "Map/SGlobalObjectSystem"

local Core = PhunSpawn
local PL = PhunLib

Core.ServerSystem = SGlobalObjectSystem:derive("SPhunSpawnSystem")
local Commands = require "PhunSpawn/server_commands"

local ServerSystem = Core.ServerSystem

local function isNorth(square)
    return square:getWall(true)
end

local function isWest(square)
    return square:getWall(false)
end

function ServerSystem:new()
    local o = SGlobalObjectSystem.new(self, "phunspawn")
    o.data = {
        spawnPoints = ModData.getOrCreate(Core.consts.spawnpoints),
        allSpawnPoints = nil,
        discovered = ModData.getOrCreate(Core.consts.discoveries),
        chunkedSpawnPoints = {}
    }
    o:loadSpawnPoints()
    return o
end

function ServerSystem:removeLuaObject(luaObject)
    Core:removeInstance(luaObject)
    SGlobalObjectSystem.removeLuaObject(self, luaObject)
end

function ServerSystem:removeInvalidInstanceData()

    local checked = {}
    local instanceCount = 0
    for k, v in pairs(Core.instances) do
        checked[k] = true
        instanceCount = instanceCount + 1
    end
    local objectCount = 0
    for i = 1, self:getLuaObjectCount() do
        local obj = self:getLuaObjectByIndex(i)
        checked[obj.x .. "_" .. obj.y .. "_" .. obj.z] = nil
        objectCount = objectCount + 1
    end
    local removed = 0
    for k, v in pairs(checked) do
        Core.instances[k] = nil
        removed = removed + 1
    end
    print("Removed " .. tostring(removed) .. " invalid instances")

end

function ServerSystem:initSystem()
    SGlobalObjectSystem.initSystem(self)
    -- Specify GlobalObjectSystem fields that should be saved.
    self.system:setModDataKeys({})

    -- Specify GlobalObject fields that should be saved.
    self.system:setObjectModDataKeys({'id', 'key', 'label', 'direction', 'location', 'sprites'})
end

function ServerSystem.addToWorld(square, data, direction)

    direction = direction or "south"
    Core:getKey(square)

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

function ServerSystem:isValidModData(modData)
    return modData and modData.restocked
end

function ServerSystem:newLuaObject(globalObject)
    return Core.ServerObject:new(self, globalObject)
end

function ServerSystem:newLuaObjectAt(x, y, z)
    local globalObject = self.system:newObject(x, y, z)
    return self:newLuaObject(globalObject)
end

function ServerSystem:isValidIsoObject(isoObject)
    return instanceof(isoObject, "IsoObject") and isoObject:getName() == "PhunSpawnPoint"
end

function ServerSystem:upsertSpawnPoint(data)
    data.direction = nil
    local modified = PL.file.loadTable(Core.const.modifiedLuaFile) or {}
    local key = Core:getKey(data)
    data.key = key

    local points = Core:getActivatedPoints(false)
    Core:syncPoints()

    points[key] = data
    self.data.allSpawnPoints = points

    local filePoints = Core:getPointsFromFile()
    filePoints[key] = data

    PL.file.saveTable(Core.consts.spawnpoints .. ".lua", filePoints)
    self:loadSpawnPoints()
end

function ServerSystem:deleteSpawnPoint(key)
    local points = Core:getSpawnPoints(true)
    points[key] = nil
    self.data.allSpawnPoints = points
    local filePoints = Core:getPointsFromFile()
    filePoints[key] = data

    PL.file.saveTable(Core.consts.spawnpoints .. ".lua", filePoints)
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
    local key = Core:getKey(keyOrObj)
    return Core:getSpawnPoints()[key] or nil
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
    local points = Core:getSpawnPoints()
    ModData.add(Core.consts.spawnpoints, points)
    ModData.transmit(Core.consts.spawnpoints)
end

SGlobalObjectSystem.RegisterSystemClass(ServerSystem)

