require "BuildingObjects/ISDestroyCursor"
local luautils = luautils
local oldDestroyStuffFn = ISDestroyCursor.canDestroy
function ISDestroyCursor:canDestroy(obj)
    local result = oldDestroyStuffFn(self, obj)
    if result then
        if obj and obj.getSprite then
            local point = CPhunSpawnSystem.instance:getSpawnPoint(obj)
            if point then
                -- if point.owner ~= self.character:getUsername() then
                return false
                -- end
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
    local chunkX, chunkY = math.floor(x / 10), math.floor(y / 10)
    local cellX, cellY = math.floor(x / 300), math.floor(y / 300)

    -- local room = getWorld():getMetaGrid():getRoomAt(x, y, z)

    local city = CPhunSpawnSystem.instance:getDefaultCityName(x, y) or ""
    local title = chunkX .. ", " .. chunkY

    city = (string.gsub(city, "^%s*(.-)%s*$", "%1"))
    if #city == 0 then
        city = title
    end

    local mod = nil

    local data = {
        key = PhunSpawn:getKey(square),
        city = city,
        title = title,
        discoverable = true,
        owner = self.character:getUsername(),
        x = x,
        y = y,
        z = z
    }

    if isAdmin() then
        PhunSpawnPointSettingUI.OnOpenPanel(self.character, nil, data, {
            mode = "CREATE"
        })
    else

        local modal = ISTextBox:new(0, 0, 280, 180, getText("IGUI_PhunSpawn_BuildingName"), data.title, nil,
            function(target, button, obj)
                if button.internal == "OK" then
                    data.title = button.parent.entry:getText() or data.title
                    data.description = getText("IGUI_PhunSpawn_PlacedBy", data.owner)
                    CPhunSpawnSystem.instance:createFromData(self.character, data)
                    self.playerObject:removeFromHands(self.pipeItem);
                    -- self.playerObject:getInventory():Remove("WaterPipe2");

                    -- --self.sq:AddSpecialObject(self.javaObject);
                    -- self.sq:AddTileObject(self.javaObject);
                    -- -- table.insert(WaterPipe.modData.waterPipes.pipes, pipe);

                    -- self.javaObject:transmitCompleteItemToServer();
                    -- self.javaObject:transmitCompleteItemToClients();
                end
            end, self.character:getPlayerNum())
        modal:initialise()
        modal:addToUIManager()

    end

end

function PhunSpawnCursor:walkTo(x, y, z)
    return true
end

local invalidInstances =
    {"IsoWindow", "IsoDoor", "IsoStove", "IsoLightSwitch", "IsoRadio", "IsoGenerator", "IsoCurtain"}

function PhunSpawnCursor:isValid(square)

    if square:TreatAsSolidFloor() and square:isFree(true) then

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

        local objects = square:getObjects();
        for i = 0, objects:size() - 1 do
            local object = objects:get(i);
            if object then
                local name = tostring(object:getName())
                for _, invalidInstance in ipairs(invalidInstances) do
                    if instanceof(object, invalidInstance) then
                        print("Invalid instance: " .. invalidInstance)
                        return false
                    end
                end

                if name == "PhunSpawnPoint" then
                    -- there is already vent here
                    print("PhunSpawnPoint already exists here ", name)
                    return false
                end
            end
        end

        print("All good")
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

