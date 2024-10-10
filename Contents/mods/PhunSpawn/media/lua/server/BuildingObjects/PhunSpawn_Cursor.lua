require "BuildingObjects/ISDestroyCursor"
local luautils = luautils
local oldDestroyStuffFn = ISDestroyCursor.canDestroy
function ISDestroyCursor:canDestroy(obj)
    local result = oldDestroyStuffFn(self, obj)
    if result then

        if obj and obj.getSprite then
            local sn = obj:getSprite():getName()
            if sn and luautils.stringStarts(sn, 'phunspawn_01') then
                return false
            end
        end

    end
    return result
end

local PhunSpawn = PhunSpawn
PhunSpawnCursor = ISBuildingObject:derive("PhunSpawnCursor")

function PhunSpawnCursor:create(x, y, z, north, sprite)
    local cell = getWorld():getCell()
    local square = cell:getGridSquare(x, y, z)

    CPhunSpawnSystem.instance:createAtSquare(square, self.character, {
        key = PhunSpawn:getKey(square),
        city = "City at " .. x .. ", " .. y,
        title = "Building name",
        discoverable = true,
        x = x,
        y = y,
        z = z
    })

    -- local spawner = IsoObject.new(self.square, self.spriteName)

    -- spawner:setName("PhunSpawner")
    -- spawner:setSprite(self.spriteName)
    -- spawner:getModData().PhunSpawn = {
    --     key = PhunSpawn:getKey(square),
    --     virgin = true,
    --     x = x,
    --     y = y,
    --     z = z
    -- }
    -- square:AddSpecialObject(spawner)
    -- spawner:transmitCompleteItemToServer()

end

function PhunSpawnCursor:walkTo(x, y, z)
    return true
end

function PhunSpawnCursor:isValid(square)

    if square:TreatAsSolidFloor() and square:isFree(false) then

        local north = square:getWall(true)
        local west = square:getWall(false)

        if north and self.placeNorth then
            self.direction = "N"
            self.spriteName = "phunspawn_01_4"
        elseif west and not self.placeNorth then
            self.direction = "W"
            self.spriteName = "phunspawn_01_6"
        else
            return false
        end
        return true

    end
end

function PhunSpawnCursor:rotateKey(key)
    if key == getCore():getKey("Rotate building") then
        self.placeNorth = not self.placeNorth
    end
end

function PhunSpawnCursor:render(x, y, z, square)
    local player = getPlayer()

    local sprite2 = IsoSprite.new();
    if self.placeNorth then
        sprite2:LoadFramesNoDirPageSimple("phunspawn_01_4");
    else
        sprite2:LoadFramesNoDirPageSimple("phunspawn_01_6");
    end

    local spriteFree = self:isValid(square)
    if spriteFree and not self.canBeAlwaysPlaced and (not square or not square:isFreeOrMidair(true)) then
        spriteFree = false
    end
    if spriteFree then
        sprite2:RenderGhostTile(x, y, z);
    else
        sprite2:RenderGhostTileRed(x, y, z);
    end

end

function PhunSpawnCursor:new(sprite, north, character)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o:init()
    o:setSprite(sprite or "phunspawn_01_4")
    o:setNorthSprite(north and "phunspawn_01_4")
    o.character = character
    o.player = character:getPlayerNum()
    o.noNeedHammer = true
    o.skipBuildAction = true
    o.placeNorth = north
    return o
end

