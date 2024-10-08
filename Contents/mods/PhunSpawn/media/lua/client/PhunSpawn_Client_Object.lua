if not isClient() then
    return
end
require "Map/CGlobalObject"
local PS = PhunSpawn
CPhunSpawnObject = CGlobalObject:derive("spawnPoint")
local spawnPoint = CPhunSpawnObject

function spawnPoint:new(luaSystem, globalObject)
    local o = CGlobalObject.new(self, luaSystem, globalObject)
    o.poop = true
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
