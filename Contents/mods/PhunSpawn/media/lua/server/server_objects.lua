if isClient() then
    return
end
require "Map/SGlobalObject"

local PS = PhunSpawn
local obectName = "SPhunSpawnObject"
local SPhunSpawnObject = SGlobalObject:derive(obectName)
local Obj = SPhunSpawnObject

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

function Obj:new(luaSystem, globalObject, state)
    return SGlobalObject.new(self, luaSystem, globalObject)
end

function Obj:initNew()
    for k, v in pairs(fields) do
        if v.default ~= nil then
            self[k] = v.default
        end
    end
end

function Obj:isValidIsoObject(isoObject)
    return instanceof(isoObject, "IsoObject") and isoObject:getName() == "PhunSpawnPoint"
end

function Obj:getStateValue(isoObject)
    return "A state"
end

-- transfers state from IsoObject
function Obj:stateFromIsoObject(isoObject)
    -- send to isoObject clients
    isoObject:transmitModData()
end

-- transfers state to IsoObject
function Obj:stateToIsoObject(isoObject)
    isoObject:transmitModData()
end

function Obj:saveData()
    local isoObject = self:getIsoObject()
    if isoObject then
        self:toModData(isoObject:getModData())
        isoObject:transmitModData()
    end
end

function Obj:fromModData(modData)
    for k, v in pairs(modData) do
        if fields[k] then
            self[k] = fields[k].type == "number" and tonumber(v) or v
        end
    end
end

function Obj:toModData(modData)
    for k, v in pairs(fields) do
        modData[k] = self[k]
    end
end

