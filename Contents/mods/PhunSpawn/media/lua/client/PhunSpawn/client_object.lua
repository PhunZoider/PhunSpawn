if isServer() then
    return
end
require "Map/CGlobalObject"
local PS = PhunSpawn
local objectName = "CPhunSpawnObject"
local CPhunSpawnObject = CGlobalObject:derive(objectName)
local Obj = CPhunSpawnObject

function Obj:new(luaSystem, globalObject)
    local o = CGlobalObject.new(self, luaSystem, globalObject)
    -- Initialize your object properties. eg
    -- o.status = "active"
    return o
end

function Obj:fromModData(modData)
    for k, v in pairs(modData) do
        self[k] = v
    end
end

function Obj:getObject()
    return self:getIsoObject()
end

function Obj:open(playerObj)
    PS.ui.main.OnOpenPanel(playerObj, self)
end

function Obj:OnLuaObjectUpdated(luaObject)
    -- luaObject fields were updated with new values from the server
    self:noise('OnLuaObjectUpdated')
end
