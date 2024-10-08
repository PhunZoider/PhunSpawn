if not isServer() then
    return
end
local PS = PhunSpawn
local sandbox = SandboxVars.PhunSpawn
require "Map/SGlobalObjectSystem"
local Commands = require "PhunSpawn_Server_Commands"

SPhunSpawnSystem = SGlobalObjectSystem:derive("system")

local system = system

system.lockedShopIds = {}

function system:new()
    local o = SGlobalObjectSystem.new(self, "phunspawn")
    return o
end

function system.addToWorld(square, shop, direction)

    direction = direction or "south"
    PS:getKey(square)

    local isoObject

    isoObject = IsoThumpable.new(square:getCell(), square, "phunspawn_01_0", false, {})

    shop.direction = direction

    isoObject:setModData(shop)

    isoObject:setName("PhunSpawnPoint")
    square:AddSpecialObject(isoObject, -1)
    triggerEvent("OnObjectAdded", isoObject)
    isoObject:transmitCompleteItemToClients()
end

function system:addFromSprite(x, y, z, sprite)

    -- iterate through shops to get the associated shop

    local point = nil
    local dir = nil
    -- is there a shop but it is orphaned from the obj?
    local key = PS:getKey({
        x = x,
        y = y,
        z = z
    })

    if point and dir then
        self:removeLuaObjectAt(x, y, z)
        local square = getCell():getGridSquare(x, y, z)
        if square then
            for i = 0, square:getObjects():size() - 1 do
                local object = square:getObjects():get(i)
                if object:getSprite():getName() == sprite then
                    square:RemoveTileObject(object);
                    object:transmitUpdatedSpriteToClients()
                end
            end

            local s = PM:upsertSpawnPoint(square)
            self.addToWorld(square, s, dir)
        end
    else
        print("ERROR! shop not found for sprite " .. sprite)
    end

end

function system:initSystem()

    SGlobalObjectSystem.initSystem(self)
    self.lockedShopIds = {}
    -- Specify GlobalObjectSystem fields that should be saved.
    self.system:setModDataKeys({})

    -- Specify GlobalObject fields that should be saved.
    self.system:setObjectModDataKeys({'id', 'key', 'label', 'direction', 'location', 'sprites'})

end

function system:isValidModData(modData)
    return modData and modData.restocked
end

function system:newLuaObject(globalObject)
    return SPhunSpawnObject:new(self, globalObject)
end

function system:generateRandomShopOnSquare(square, direction, removeOnSuccess)
    direction = direction or "south"
    local shop = PM:generateShop(square)
    if shop ~= nil then
        square:transmitRemoveItemFromSquare(removeOnSuccess)
        self.addToWorld(square, shop, direction)
    end

end

function system:newLuaObjectAt(x, y, z)
    self:noise("adding luaObject " .. x .. ',' .. y .. ',' .. z)
    local globalObject = self.system:newObject(x, y, z)
    return self:newLuaObject(globalObject)
end

function system:isValidIsoObject(isoObject)
    return instanceof(isoObject, "IsoThumpable") and isoObject:getName() == "PhunSpawnPoint"
end

function system:OnClientCommand(command, playerObj, args)
    if Commands[command] ~= nil then
        Commands[command](playerObj, args)
    end
end

function system:receiveCommand(playerObj, command, args)
    Commands[command](playerObj, args)
end

SGlobalObjectSystem.RegisterSystemClass(system)

