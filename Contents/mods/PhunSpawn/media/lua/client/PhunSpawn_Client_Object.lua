if not isClient() then
    return
end
require "Map/CGlobalObject"
local PS = PhunSpawn
CPhunSpawnObject = CGlobalObject:derive("CPhunSpawnObject")
local spawnPoint = CPhunSpawnObject

function spawnPoint:new(luaSystem, globalObject)
    local o = CGlobalObject.new(self, luaSystem, globalObject)
    -- Initialize your object properties. eg
    -- o.status = "active"
    return o
end

function spawnPoint:fromModData(modData)
    for k, v in pairs(modData) do
        self[k] = v
    end
end

function spawnPoint:getObject()
    return self:getIsoObject()
end

function spawnPoint:open(playerObj)
    PhunSpawnSelectorUI.OnOpenPanel(playerObj, self)
end

function spawnPoint:OnLuaObjectUpdated(luaObject)
    -- luaObject fields were updated with new values from the server
    self:noise('OnLuaObjectUpdated')
end
