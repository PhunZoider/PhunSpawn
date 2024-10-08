if not isServer() then
    return
end

require "Map/SGlobalObject"

SPhunSpawnObject = SGlobalObject:derive("SPhunSpawnObject")
local PS = PhunSpawn

local fields = {
    id = {
        type = "string",
        default = "0_0_0"
    },
    key = {
        type = "string",
        default = "default"
    },
    label = {
        type = "string",
        default = "PhunSpawn"
    },
    direction = {
        type = "string",
        default = "south"
    },
    location = {
        type = "table",
        default = {
            x = 0,
            y = 0,
            z = 0
        }
    },
    sprites = {
        type = "table",
        default = {
            sheet = 1,
            row = 1
        }
    }
}

function SPhunSpawnObject:new(luaSystem, globalObject)
    local o = SGlobalObject.new(self, luaSystem, globalObject)
    return o
end

function SPhunSpawnObject:initNew()
    for k, v in pairs(fields) do
        self[k] = v.default
    end
end

function SPhunSpawnObject.initModData(modData)
    for k, v in pairs(fields) do
        if modData[k] == nil and self[k] == nil then
            modData[k] = v.default
        end
    end
end

function SPhunSpawnObject:stateFromIsoObject(isoObject)
    self:initNew()
    self:fromModData(isoObject:getModData())

    local square = isoObject:getSquare()

    self:changeSprite()

    self:toModData(isoObject:getModData())
    isoObject:transmitModData()
end

function SPhunSpawnObject:getObject()
    return self:getIsoObject()
end

function SPhunSpawnObject:stateToIsoObject(isoObject)
    self:toModData(isoObject:getModData())
    self:changeSprite()
    isoObject:transmitModData()
end

function SPhunSpawnObject:render(x, y, z, square)
    SGlobalObject:render(self, x, y, z, square)
end

function SPhunSpawnObject:changeSprite(force)

    local isoObject = self:getIsoObject()
    if not isoObject then
        return
    end

    local def = PS:getrSpawnPoint(self.key)

    if def and def.sprites then
        local spriteName = PM:resolveSprite(def.sprites.sheet, def.sprites.row, self.direction, hasPower == false)

        if spriteName and
            (force == true or (not isoObject:getSprite() or spriteName ~= isoObject:getSprite():getName())) then
            isoObject:setSprite(spriteName)
            isoObject:transmitUpdatedSpriteToClients()
        end
    end
end

function SPhunSpawnObject:saveData()
    local isoObject = self:getIsoObject()
    if isoObject then
        self:toModData(isoObject:getModData())
        isoObject:transmitModData()
    end
end

function SPhunSpawnObject:fromModData(modData)
    for k, v in pairs(modData) do
        if fields[k] then
            self[k] = fields[k].type == "number" and tonumber(v) or v
        end
    end
end

function SPhunSpawnObject:toModData(modData)
    for k, v in pairs(fields) do
        modData[k] = self[k]
    end
end

