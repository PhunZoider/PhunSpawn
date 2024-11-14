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

function SPhunSpawnObject:new(luaSystem, globalObject, state)
    return SGlobalObject.new(self, luaSystem, globalObject)
end

function SPhunSpawnObject:initNew()
    for k, v in pairs(fields) do
        if v.default ~= nil then
            self[k] = v.default
        end
    end
end

function SPhunSpawnObject:isValidIsoObject(isoObject)
    return instanceof(isoObject, "IsoObject") and isoObject:getName() == "PhunSpawnPoint"
end

function SPhunSpawnObject:getStateValue(isoObject)
    return "A state"
end

-- transfers state from IsoObject
function SPhunSpawnObject:stateFromIsoObject(isoObject)
    -- send to isoObject clients
    isoObject:transmitModData()
end

-- transfers state to IsoObject
function SPhunSpawnObject:stateToIsoObject(isoObject)
    isoObject:transmitModData()
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

