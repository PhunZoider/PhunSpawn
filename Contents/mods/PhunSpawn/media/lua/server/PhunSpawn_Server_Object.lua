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
    -- x = {
    --     type = "number",
    --     default = 0
    -- },
    -- y = {
    --     type = "number",
    --     default = 0
    -- },
    -- z = {
    --     type = "number",
    --     default = 0
    -- }
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

-- local specialObjectsCount = square:getSpecialObjects():size();
-- local specialObjectsAllowed = 0;

-- for i = 0, square:getObjects():size() - 1 do
--     if square:getObjects():get(i):getName() == "WaterPipe" then
--         return false;
--     end
-- --		if (square:getObjects():get(i):getType() == IsoObjectType.wall) then
-- --			testForPermitted = true;
-- --		end

-- end

-- -- local door = nil;
-- for i = 0, specialObjectsCount - 1 do
--     if (square:getSpecialObjects():get(i):getType() == IsoObjectType.wall) then
--         specialObjectsAllowed = specialObjectsAllowed + 1;
--     end
-- end

-- if specialObjectsAllowed >= specialObjectsCount then
--     return true;
-- end

-- return false;

function SPhunSpawnObject:getStateValue(isoObject)
    return "A state"
end

-- transfers state from IsoObject
function SPhunSpawnObject:stateFromIsoObject(isoObject)
    print("PhunSpawnObject:stateFromIsoObject ", tostring(isoObject))

    PhunTools:printTable(isoObject:getModData())

    -- send to isoObject clients
    isoObject:transmitModData()
end

-- transfers state to IsoObject
function SPhunSpawnObject:stateToIsoObject(isoObject)
    print("PhunSpawnObject:stateToIsoObject")
    isoObject:transmitModData()
end

-- function SPhunSpawnObject.initModData(modData)
--     print("PhunSpawnObject:initModData")
--     for k, v in pairs(fields) do
--         if modData[k] == nil and self[k] == nil then
--             modData[k] = v.default
--         end
--     end
-- end

-- function SPhunSpawnObject:getObject()
--     print("PhunSpawnObject:getObject")
--     return self:getIsoObject()
-- end

-- function SPhunSpawnObject:render(x, y, z, square)
--     print("PhunSpawnObject:render")
--     SGlobalObject:render(self, x, y, z, square)
-- end

-- function SPhunSpawnObject:changeSprite(force)
--     print("PhunSpawnObject:changeSprite")
--     local isoObject = self:getIsoObject()
--     if not isoObject then
--         return
--     end

--     local def = PS:getrSpawnPoint(self.key)

--     if def and def.sprites then
--         local spriteName = PM:resolveSprite(def.sprites.sheet, def.sprites.row, self.direction, hasPower == false)

--         if spriteName and
--             (force == true or (not isoObject:getSprite() or spriteName ~= isoObject:getSprite():getName())) then
--             isoObject:setSprite(spriteName)
--             isoObject:transmitUpdatedSpriteToClients()
--         end
--     end
-- end

function SPhunSpawnObject:saveData()
    print("PhunSpawnObject:saveData")
    local isoObject = self:getIsoObject()
    if isoObject then
        self:toModData(isoObject:getModData())
        isoObject:transmitModData()
    end
end

function SPhunSpawnObject:fromModData(modData)
    print("PhunSpawnObject:fromModData")
    for k, v in pairs(modData) do
        if fields[k] then
            self[k] = fields[k].type == "number" and tonumber(v) or v
        end
    end
end

function SPhunSpawnObject:toModData(modData)
    print("PhunSpawnObject:toModData")
    for k, v in pairs(fields) do
        modData[k] = self[k]
    end
end

