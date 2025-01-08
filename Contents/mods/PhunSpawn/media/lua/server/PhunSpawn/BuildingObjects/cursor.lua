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

local PS = PhunSpawn
local objectName = "PhunSpawnCursor"
local Obj = ISBuildingObject:derive(objectName)
PhunSpawnCursor = Obj

function Obj:create(x, y, z, north, sprite)
    local cell = getWorld():getCell()
    local square = cell:getGridSquare(x, y, z)
    local chunkX, chunkY = math.floor(x / 10), math.floor(y / 10)
    local cellX, cellY = math.floor(x / 300), math.floor(y / 300)

    local city = CPhunSpawnSystem.instance:getDefaultCityName(x, y) or ""
    local title = chunkX .. ", " .. chunkY

    city = (string.gsub(city, "^%s*(.-)%s*$", "%1"))
    if #city == 0 then
        city = title
    end

    local mod = nil

    local data = {
        key = PS:getKey(square),
        city = city,
        title = title,
        discoverable = true,
        owner = Obj.character:getUsername(),
        x = x,
        y = y,
        z = z
    }

    if isAdmin() or isDebugMode() then
        PhunSpawnPointSettingUI.OnOpenPanel(Obj.character, nil, data, {
            mode = "CREATE"
        })
    else

        local modal = ISTextBox:new(0, 0, 280, 180, getText("IGUI_PhunSpawn_BuildingName"), data.title, nil,
            function(target, button, obj)
                if button.internal == "OK" then
                    data.title = button.parent.entry:getText() or data.title
                    data.description = getText("IGUI_PhunSpawn_PlacedBy", data.owner)
                    CPhunSpawnSystem.instance:createFromData(Obj.character, data)
                    Obj.playerObject:removeFromHands(Obj.pipeItem);
                end
            end, Obj.character:getPlayerNum())
        modal:initialise()
        modal:addToUIManager()

    end

end

function Obj:walkTo(x, y, z)
    return true
end

local invalidInstances =
    {"IsoWindow", "IsoDoor", "IsoStove", "IsoLightSwitch", "IsoRadio", "IsoGenerator", "IsoCurtain"}

function Obj:isValid(square)

    if square:TreatAsSolidFloor() and square:isFree(true) then

        local north = square:getWall(true)
        local west = square:getWall(false)

        if north and Obj.placeNorth then
            Obj.direction = "N"
            Obj.spriteName = "phunspawn_01_4"
        elseif west and not Obj.placeNorth then
            Obj.direction = "W"
            Obj.spriteName = "phunspawn_01_6"
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

function Obj:rotateKey(key)
    if key == getCore():getKey("Rotate building") then
        Obj.placeNorth = not Obj.placeNorth
    end
end

function Obj:render(x, y, z, square)
    local player = getPlayer()

    local sprite2 = IsoSprite.new();
    if Obj.placeNorth then
        sprite2:LoadFramesNoDirPageSimple("phunspawn_01_4");
    else
        sprite2:LoadFramesNoDirPageSimple("phunspawn_01_6");
    end

    local spriteFree = Obj:isValid(square)
    if spriteFree and not Obj.canBeAlwaysPlaced and (not square or not square:isFreeOrMidair(true)) then
        spriteFree = false
    end
    if spriteFree then
        sprite2:RenderGhostTile(x, y, z);
    else
        sprite2:RenderGhostTileRed(x, y, z);
    end

end

function Obj:new(sprite, north, character)
    local o = {}
    setmetatable(o, Obj)
    Obj.__index = Obj
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

