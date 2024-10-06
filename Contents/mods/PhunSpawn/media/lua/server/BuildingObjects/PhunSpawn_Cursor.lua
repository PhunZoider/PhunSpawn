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
    local spawner = IsoThumpable.new(cell, self.square, self.spriteName, north, self)
    spawner:setName("PhunSpawner")
    spawner:setSprite(self.spriteName)
    spawner:setIsThumpable(false);
    spawner:setIsDismantable(false);
    spawner:getModData().PhunSpawn = {
        key = PhunSpawn:getKey(square),
        x = x,
        y = y,
        z = z
    }
    square:AddSpecialObject(spawner)
    spawner:transmitCompleteItemToServer()
    PhunSpawnPointSettingUI.OnOpenPanel(getSpecificPlayer(self.player), spawner)
end

function PhunSpawnCursor:walkTo(x, y, z)
    return true
end

function PhunSpawnCursor:isValid(square)
    if square:TreatAsSolidFloor() and square:isFree(false) then
        local westWall = false
        local northWall = false
        for i = 0, square:getObjects():size() - 1 do
            local obj = square:getObjects():get(i);
            local props = obj:getProperties()
            if props:Is(IsoFlagType.WallN or IsoFlagType.WallW) or props:Is(IsoFlagType.WallNW) then
                self.spriteName = "phunspawn_01_1"
                return true
            elseif props:Is(IsoFlagType.WallW) then
                self.spriteName = "phunspawn_01_0"
                return true
            end
        end
        return false
    end
end

function PhunSpawnCursor:render(x, y, z, square)
    local player = getPlayer()

    if not self.floorSprite then
        self.floorSprite = IsoSprite.new()
        self.floorSprite:LoadFramesNoDirPageSimple('media/ui/FloorTileCursor.png')
    end

    local spriteFree = self:isValid(square)
    if spriteFree and not self.canBeAlwaysPlaced and (not square or not square:isFreeOrMidair(true)) then
        spriteFree = false
    end
    if spriteFree then
        self.floorSprite:RenderGhostTile(x, y, z);
    else
        self.floorSprite:RenderGhostTileRed(x, y, z);
    end

end

function PhunSpawnCursor:new(sprite, northSprite, character)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o:init()
    o:setSprite(sprite)
    o:setNorthSprite(northSprite)
    o.character = character
    o.player = character:getPlayerNum()
    o.noNeedHammer = true
    o.skipBuildAction = true
    return o
end

