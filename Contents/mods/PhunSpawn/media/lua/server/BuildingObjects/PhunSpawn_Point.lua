require "BuildingObjects/ISBuildingObject"

PhunSpawnPoint = ISBuildingObject:derive("PhunSpawnPoint");

function PhunSpawnPoint:create(x, y, z, north, sprite)
    local cell = getWorld():getCell();
    self.sq = cell:getGridSquare(x, y, z);
    self.javaObject = IsoThumpable.new(cell, self.sq, sprite, north, self);
    buildUtil.setInfo(self.javaObject, self);
    buildUtil.consumeMaterial(self);
    -- the barrel have 200 base health + 100 per carpentry lvl
    self.javaObject:setMaxHealth(self:getHealth());
    self.javaObject:setHealth(self.javaObject:getMaxHealth());
    -- the sound that will be played when our barrel will be broken
    self.javaObject:setBreakSound("BreakObject");
    -- add the item to the ground
    self.sq:AddSpecialObject(self.javaObject);
    -- IsoObjects with 'waterAmount' 
    -- self.javaObject:getModData()["waterMax"] = self.waterMax;
    -- self.javaObject:getModData()["waterAmount"] = 0;
    self.javaObject:setSpecialTooltip(true)
    self.javaObject:transmitCompleteItemToServer();
    -- OnObjectAdded event will create the SRainBarrelGlobalObject on the server.
    -- This is only needed for singleplayer which doesn't trigger OnObjectAdded.
    triggerEvent("OnObjectAdded", self.javaObject)
    -- ~ 	print("add a barrel at : " .. x .. "," .. y);
end

function PhunSpawnPoint:new(player, sprite, waterMax)
    -- OOP stuff
    -- we create an item (o), and return it
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    o:init();
    -- the number of sprites can be up to 4, one for each direction, you ALWAYS need at least 2 sprites, south (Sprite) and north (NorthSprite)
    -- here we're not gonna be able to rotate our building (it's a barrel, so every face are the same), so we set that the south sprite = north sprite
    o:setSprite(sprite);
    o:setNorthSprite(sprite);
    o.name = "PhunSpawnPoint";
    o.player = player;
    -- the barrel will be dismantable (come from IsoThumpable stuff, check buildUtil.setInfo to see wich options are available)
    -- o.dismantable = true;
    -- you can't barricade it
    -- o.canBarricade = false;
    -- the item will block all the square where it placed (not like a wall for example)
    -- o.blockAllTheSquare = true;
    return o;
end

function PhunSpawnPoint:getHealth()
    return 200 + buildUtil.getWoodHealth(self);
end

function PhunSpawnPoint:isValid(square)
    if not square then
        return false
    end
    if square:isSolid() or square:isSolidTrans() then
        return false
    end
    if square:HasStairs() then
        return false
    end
    if square:HasTree() then
        return false
    end
    if not square:getMovingObjects():isEmpty() then
        return false
    end
    if not square:TreatAsSolidFloor() then
        return false
    end
    if not self:haveMaterial(square) then
        return false
    end
    for i = 1, square:getObjects():size() do
        local obj = square:getObjects():get(i - 1)
        if self:getSprite() == obj:getTextureName() then
            return false
        end
    end
    if buildUtil.stairIsBlockingPlacement(square, true) then
        return false;
    end
    if square:isVehicleIntersecting() then
        return false
    end
    return true
end

function PhunSpawnPoint:render(x, y, z, square)
    ISBuildingObject.render(self, x, y, z, square)
end
