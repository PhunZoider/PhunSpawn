if not isClient() then
    return
end
local PhunSpawn = PhunSpawn
local mapFunctions = require("UI/PhunSpawn_Map")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)

local FONT_SCALE = FONT_HGT_SMALL / 14
local HEADER_HGT = FONT_HGT_MEDIUM + 2 * 2

local MINZOOM = 10
local MAXZOOM = 24

PhunSpawnSelectorUI = ISPanelJoypad:derive("PhunSpawnSelectorUI");
PhunSpawnSelectorUI.instances = {}
local csystem = nil

function PhunSpawnSelectorUI:getCityBounds(city)

    if city and city.locations then

        local x, x2, y, y2 = city.x, city.x2, city.y, city.y2

        local padding = 10
        local map = self.miniMap.mapAPI
        local wx = map:worldToUIX(x - padding, x - padding)
        local wx2 = map:worldToUIX(x2 + padding, x2 + padding)
        local wy = map:worldToUIY(y - padding, y - padding)
        local wy2 = map:worldToUIY(y2 + padding, y2 + padding)
        return wx, wx2, wy, wy2
    end

end

function PhunSpawnSelectorUI.OnOpenPanel(playerObj)

    if csystem == nil then
        csystem = CPhunSpawnSystem.instance
    end

    -- if isAdmin() and csystem.data.allSpawnPoints == nil then
    --     sendClientCommand(playerObj, PhunSpawn.name, PhunSpawn.commands.getAllSpawns, {})
    -- end

    local pNum = playerObj:getPlayerNum()

    local data = PhunSpawn:getSpawnPoints()

    if PhunSpawnSelectorUI.instances[pNum] then
        -- there is already an instance of this panel for this player
        if not PhunSpawnSelectorUI.instances[pNum]:isVisible() then
            PhunSpawnSelectorUI.instances[pNum]:addToUIManager();
            PhunSpawnSelectorUI.instances[pNum]:setVisible(true);
            PhunSpawnSelectorUI.instances[pNum]:rebuild(data)
            PhunSpawnSelectorUI.instances[pNum]:ensureVisible()
            return
        end
        return
    end

    local core = getCore()
    local FONT_SCALE = getTextManager():getFontHeight(UIFont.Small) / 14
    local core = getCore()
    local width = 800 * FONT_SCALE
    local height = 800 * FONT_SCALE

    local x = (core:getScreenWidth() - width) / 2
    local y = (core:getScreenHeight() - height) / 2

    local pIndex = playerObj:getPlayerNum()
    PhunSpawnSelectorUI.instances[pIndex] = PhunSpawnSelectorUI:new(x, y, width, height, playerObj);
    PhunSpawnSelectorUI.instances[pIndex]:initialise();
    PhunSpawnSelectorUI.instances[pIndex]:addToUIManager();
    PhunSpawnSelectorUI.instances[pNum]:rebuild(data)
    PhunSpawnSelectorUI.instances[pNum]:ensureVisible()
    return PhunSpawnSelectorUI.instances[pIndex];

end

function PhunSpawnSelectorUI:rebuild(spawnpoints)

    getSoundManager():PlaySound("PhunSpawn_Enter", false, 0):setVolume(0.90);

    local cityKeys = {}
    local groups = {}
    local newPoints = {}

    self.city:clear()

    self.spawns = spawnpoints or self.spawns or {}

    local data = self.spawns

    local cities = {}
    local cityCount = 0

    local discoveries = csystem:getPlayerDiscoveries(self.player)

    local boundX = 0
    local boundY = 0
    local boundX2 = 0
    local boundY2 = 0
    local centreX = 0
    local centreY = 0
    local cityCount = 0

    for k, spawn in pairs(data) do

        local enable = spawn.enabled ~= false

        if spawn.autoDiscovered ~= true then
            enable = discoveries[k] == true
        end

        if enable or (isAdmin() and self.showAll.selected[1] == true) then

            local cityName = spawn.city or nil

            if cityName == nil then
                print("ERROR: PhunSpawn: No city name for spawn point ", k)
                cityName = csystem:getDefaultCityName(spawn.x, spawn.y) or "Unknown"
            end

            if not cities[cityName] then

                cities[cityName] = {
                    title = cityName,
                    titleWidth = getTextManager():MeasureStringX(UIFont.Small, cityName),
                    titleHeight = getTextManager():MeasureStringY(UIFont.Small, cityName),
                    titleLeft = 0,
                    titleTop = 0,
                    x = 0,
                    y = 0,
                    x2 = 0,
                    y2 = 0,
                    locations = {}
                }

                table.insert(cityKeys, cityName)
            end

            local c = cities[cityName]

            table.insert(c.locations, k)

            if c.x == 0 or spawn.x < c.x then
                c.x = spawn.x
            end
            if c.y == 0 or spawn.y < c.y then
                c.y = spawn.y
            end
            if spawn.x > c.x2 then
                c.x2 = spawn.x
            end
            if spawn.y > c.y2 then
                c.y2 = spawn.y
            end
            cities[cityName].centreX = cities[cityName].x + (cities[cityName].x2 - cities[cityName].x)
            cities[cityName].centreY = cities[cityName].y + (cities[cityName].y2 - cities[cityName].y)

            cities[cityName].titleLeft = cities[cityName].centreX - (cities[cityName].titleWidth / 2)
            cities[cityName].titleTop = cities[cityName].centreY - (cities[cityName].titleHeight / 2) - 5

            if spawn.city ~= "Hospital" then
                cityCount = cityCount + 1
                centreX = centreX + spawn.x
                centreY = centreY + spawn.y
                if boundX == 0 or spawn.x < boundX then
                    boundX = spawn.x
                end
                if boundY == 0 or spawn.y < boundY then
                    boundY = spawn.y
                end
                if boundX2 == 0 or spawn.x > boundX2 then
                    boundX2 = spawn.x
                end
                if boundY2 == 0 or spawn.y > boundY2 then
                    boundY2 = spawn.y
                end
            end
        end
    end

    self.cities = cities
    self.cityKeys = cityKeys
    self.initialBounds = {
        x = boundX,
        y = boundY,
        x2 = boundX2,
        y2 = boundY2
    }

    local api = self.miniMap.mapAPI
    api:centerOn(centreX / cityCount, centreY / cityCount)

    self:refreshCitiesCombo()
end

function PhunSpawnSelectorUI:refreshCitiesCombo()
    self.city:clear()

    self.city:addOptionWithData("", nil)

    table.sort(self.cityKeys, function(a, b)
        return a < b
    end)

    for _, k in ipairs(self.cityKeys) do
        local spawn = self.cities[k]
        self.city:addOptionWithData(spawn.title, spawn)
    end
end

function PhunSpawnSelectorUI:setSelectedCityByKey(key)

    local combo = self.city
    for i, city in ipairs(combo.options) do
        local data = city.data
        if data and data.title == key then
            self:setSelectedCity(i)
            return
        end
    end

end

function PhunSpawnSelectorUI:setSelectedCity(cityIndex)

    self.city.selected = cityIndex

    local city = cityIndex and self.city.options[cityIndex] and self.city.options[cityIndex].data or nil
    if not city then
        self.selectedCity = nil
        self:refreshLocations()
        return
    end
    self.selectedCity = city
    self:refreshLocations()

    if #city.locations == 1 then
        self:setSelectedLocation(1)
        self.locationSingle:setVisible(true)
    else
        self:setSelectedLocation(ZombRand(#city.locations) + 1)
        self.locationSingle:setVisible(false)
    end

end

function PhunSpawnSelectorUI:refreshLocations()
    self.location:clear()
    self.selectedLocation = nil
    self.description:setText("")
    self.description.textDirty = true;
    local city = self.selectedCity

    if not city then
        return
    end
    mapFunctions.zoomAndCentreMapToBounds(self.miniMap, city.x, city.y, city.x2, city.y2)
    for _, location in ipairs(city.locations) do
        self.location:addOptionWithData(self.spawns[location].title, self.spawns[location])
    end

end

function PhunSpawnSelectorUI:setSelectedLocation(locationIndex)

    self.notOk:setVisible(false)
    self.location.selected = locationIndex
    local location = locationIndex and self.location.options[locationIndex] and
                         self.location.options[locationIndex].data or nil
    if not location then
        self.selectedLocation = nil
        self.description:setText("")
        self.description.textDirty = true;
        return
    end
    self.notOk:setVisible(false)
    self.selectedLocation = location
    -- self.description:setText(" <LEFT> " .. (location.description or self.selectedCity.description or ""))
    local zf = tostring(self.miniMap.mapAPI:getZoomF())
    local ws = tostring(self.miniMap.mapAPI:getWorldScale())
    local o = ""
    if self.zBorder then
        o =
            tostring(self.zBorder.x) .. ", " .. tostring(self.zBorder.y) .. ", " .. tostring(self.zBorder.width) .. ", " ..
                tostring(self.zBorder.height)
    end
    self.description:setText(zf .. ", ws=" .. ws .. ", zBorder=" .. o)
    self.description.textDirty = true;
end

function PhunSpawnSelectorUI:isValid()

    local data = self.spawns or {}
    local city = self.selectedCity and self.selectedCity > 0 and data[self.selectedCity - 1] or {}

    -- location will be nil if player hasn't actually selected one
    local location = self.selectedLocation and self.selectedLocation > 0 and
                         self.selectedData.locations[self.selectedLocation - 1] or nil

    local isValid = false
    if self.selectedData then

        local loc = nil

        if not location then
            -- player hasn't selected a location (just a city)
            -- force the first option in the list
            loc = self.selectedData.locations[1]
        else
            loc = location
        end

        self.locationSingle:setVisible(#self.selectedData.locations == 1)

        -- choose a random location
        loc = loc.locations[ZombRand(#loc.locations) + 1]

        if loc.x and loc.y and loc.z then
            self.selectedCityAndLocation = {
                x = loc.x,
                y = loc.y,
                z = loc.z,
                city = self.selectedData.name,
                location = loc.name
            }
            isValid = true
        end
    end

    if not isValid then
        self.selectedCityAndLocation = nil
    end
    self.notOk:setVisible(not isValid)
    return isValid
end

function PhunSpawnSelectorUI:doTele(destinationX, destinationY, destinationZ)
    local player = self.player

    if SandboxVars.PhunSpawn.RespawnHospitalRooms == true then
        -- do RHR shut down items
        if player:getModData().RHR then
            RHR_ExitRoom(player)
        end
    end
    player:setX(destinationX)
    player:setY(destinationY)
    player:setZ(destinationZ)
    player:setLx(destinationX)
    player:setLy(destinationY)
    player:setLz(destinationZ)

    local retries = 100
    local playerPorting
    playerPorting = function()
        -- wait for square to load
        local square = player:getCurrentSquare()
        if square == nil then
            return
        end
        retries = retries - 1
        if retries <= 0 then
            player:Say(getText("IGUI_PhunSpawn_Failed_To_Find_Free_Square"))
            Events.OnPlayerUpdate.Remove(playerPorting)
            return
        end

        local free = AdjacentFreeTileFinder.FindClosest(square, player)
        if free then
            player:setX(free:getX())
            player:setY(free:getY())
            player:setZ(free:getZ())
            player:setLx(free:getX())
            player:setLy(free:getY())
            player:setLz(free:getZ())
            Events.OnPlayerUpdate.Remove(playerPorting)
        end

        local room = square:getRoom()
        if room then
            local squares = room:getSquares()
            -- remove all zeds from room
            for itSq = 0, squares:size() - 1, 1 do
                local squareToCheck = squares:get(itSq)
                for i = squareToCheck:getMovingObjects():size(), 1, -1 do
                    local testZed = squareToCheck:getMovingObjects():get(i - 1)
                    if instanceof(testZed, "IsoZombie") then
                        local onlineID = testZed:getOnlineID()
                        sendClientCommand(PhunSpawn.name, PhunSpawn.commands.killZombie, {
                            id = onlineID
                        })
                        testZed:removeFromWorld()
                        testZed:removeFromSquare()
                    end
                end
            end
        else
            -- outside?
        end

    end
    Events.OnPlayerUpdate.Add(playerPorting)
end

function PhunSpawnSelectorUI:exitRoom(destinationTitle, destinationCity, destinationX, destinationY, destinationZ)

    print("exitRoom for ", destinationTitle, " in ", destinationCity, "x ", destinationX, ", y ", destinationY, ", z ",
        destinationZ)

    local md = self.player:getModData()
    local message = ""
    if SandboxVars.PhunSpawn.RespawnHospitalRooms and md and md.RHR then
        message = getText("IGUI_PhunSpawn_Confirm_Exit_Room", destinationTitle, destinationCity)
    else
        -- don't prompt if not in starting bit
        self:doTele(destinationX, destinationY, destinationZ)
        self:close()
        return
    end
    local message = getText("IGUI_PhunSpawn_Confirm_Exit_Room", destinationTitle, destinationCity)
    local w = 300 * FONT_SCALE
    local h = 200 * FONT_SCALE
    local modal = ISModalDialog:new(getCore():getScreenWidth() / 2 - w / 2, getCore():getScreenHeight() / 2 - h / 2, w,
        h, message, true, self, function(self, button)
            if button.internal == "YES" then
                self:doTele(destinationX, destinationY, destinationZ)
            end
            self:close()
        end, nil);
    modal:initialise()
    modal:addToUIManager()

end

function PhunSpawnSelectorUI:close()
    self:removeFromUIManager();
    PhunSpawnSelectorUI.instances[self.pIndex] = nil
end

function PhunSpawnSelectorUI:prerender()
    ISPanelJoypad.prerender(self)

    self:drawRectBorder(self.description.x, self.description.y, self.description.width, self.description.height,
        self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

    self:drawRectBorder(self.miniMap.x, self.miniMap.y, self.miniMap.width, self.miniMap.height, self.borderColor.a,
        self.borderColor.r, self.borderColor.g, self.borderColor.b);

end

function PhunSpawnSelectorUI:recalcClusters()

    local scale = self.miniMap.mapAPI:getWorldScale()
    local distance = 200 / scale

    local clusters = {}
    for k, v in pairs(self.spawns) do
        if v.enabled ~= true then
            table.insert(clusters, {v.x, v.y})
        end
    end

    print(scale, ", ", distance)
    local cs = mapFunctions.proximityClustering(clusters, distance)
    local info = {}
    for _, c in ipairs(cs) do
        local xs = 0
        local ys = 0
        local x = 0
        local y = 0
        local x2 = 0
        local y2 = 0
        local h = 0
        local w = 0

        for _, p in ipairs(c) do
            xs = xs + p[1]
            ys = ys + p[2]
            if x == 0 or p[1] < x then
                x = p[1]
            end
            if y == 0 or p[2] < y then
                y = p[2]
            end
            if x2 == 0 or p[1] > x2 then
                x2 = p[1]
            end
            if y2 == 0 or p[2] > y2 then
                y2 = p[2]
            end
            h = y2 - y
            w = x2 - x
        end

        x = self.miniMap.mapAPI:worldToUIX(x, x)
        y = self.miniMap.mapAPI:worldToUIX(y, y)
        x2 = self.miniMap.mapAPI:worldToUIX(x2, x2)
        y2 = self.miniMap.mapAPI:worldToUIX(y2, y2)

        h = y2 - y
        w = x2 - x

        -- if h < 30 or w < 30 then
        --     x = x - 15
        --     y = y - 15
        --     x2 = x2 + 15
        --     y2 = y2 + 15
        --     h = y2 - y
        --     w = x2 - x
        -- end

        table.insert(info, {
            centerX = xs / #c,
            centerY = ys / #c,
            count = #c,
            x = x,
            y = y,
            x2 = x2,
            y2 = y2,
            h = h,
            w = w,
            texture = getTexture("media/textures/worldMap/circle_only_highlight.png"),
            textureInner = getTexture("media/textures/worldMap/circle_center.png")
        })
    end
    self.clusters = info
    PhunTools:printTable(self.clusters)
end

local oldScale, oldDistance, oldCenterX, oldCenterY, oldX, oldY = nil, nil, nil, nil, nil, nil
function PhunSpawnSelectorUI:render()

    ISPanelJoypad.render(self)

    local newX = self.miniMap.mapAPI:uiToWorldX(1, 1)
    local newY = self.miniMap.mapAPI:uiToWorldY(1, 1)

    -- if oldX ~= newX or oldY ~= newY then
    --     self:recalcClusters()
    --     oldX = newX
    --     oldY = newY
    -- end

    -- clip any markers on map that aren't visible
    self:setStencilRect(self.miniMap.x, self.miniMap.y, self.miniMap.width, self.miniMap.height)

    -- for _, c in ipairs(self.clusters or {}) do
    --     local bgColor = self.markerBackgroundColour
    --     local borderColor = self.markerBorderColour

    --     -- local texture = getTexture("media/textures/worldMap/circle_only_highlight.png")
    --     self:drawTextureScaled(c.texture, c.x, c.y, c.x2 - c.x, c.y2 - c.y, 0.7, 1, 0, 0);
    --     self:drawTextureScaled(c.textureInner, c.x, c.y, c.x2 - c.x, c.y2 - c.y, 0.7, 1, 0, 0);
    --     -- self.miniMap:drawRect(c.x, c.y, c.x2 - c.x, c.y2 - c.y, .5, bgColor.r, bgColor.g, bgColor.b);
    --     -- self.miniMap:drawRectBorder(c.x, c.y, c.x2 - c.x, c.y2 - c.y, .5, borderColor.r, borderColor.g, borderColor.b);
    -- end

    for k, city in pairs(self.cities) do

        city.labelX = math.floor(self.miniMap.mapAPI:worldToUIX(city.x, city.y));
        city.labelY = math.floor(self.miniMap.mapAPI:worldToUIY(city.y, city.y));
        local bgColor = self.markerBackgroundColour
        local borderColor = self.markerBorderColour
        if self.selectedLocation and self.selectedLocation.city == k then
            bgColor = self.markerSelectedBackgroundColor
            borderColor = self.markerSelectedBorderColour
        end
        self.miniMap:drawRect(city.labelX - 1, city.labelY - 1, city.titleWidth + 2, city.titleHeight + 2, bgColor.a,
            bgColor.r, bgColor.g, bgColor.b);
        self.miniMap:drawRectBorder(city.labelX - 1, city.labelY - 1, city.titleWidth + 2, city.titleHeight + 2,
            borderColor.a, borderColor.r, borderColor.g, borderColor.b);
        self.miniMap:drawText(city.title, city.labelX, city.labelY, 1, 1, 1, 1, UIFont.Small);

        local cityIndex = self.city.selected

        local city = cityIndex and self.city.options[cityIndex] and self.city.options[cityIndex].data or nil
        if city then
            local wx, wx2, wy, wy2 = self:getCityBounds(city)
            self.miniMap:drawRect(wx, wy, wx2 - wx, wy2 - wy, .3, 1, 0, 0);
        end

    end

    -- clear the stencil
    self:clearStencilRect()

    if self.locationSingle:isVisible() and #self.location.options > 0 then
        local loc = self.location
        local opts = loc.options
        local selected = loc.selected
        local item = opts[selected]
        if item == nil then
            item = opts[1]
        end
        self.locationSingle:drawText(item.text, 10, 5, 1, 1, 1, 0.9, UIFont.Small);
    end

end

function PhunSpawnSelectorUI:createChildren()

    ISPanelJoypad.createChildren(self);

    local padding = 10
    local x = padding
    local y = padding

    -- close button
    self.closeButton = ISButton:new(self.width - 30, padding, 25, 25, "X", self, function()
        self:close()
    end)
    self.closeButton:initialise()
    self:addChild(self.closeButton)

    -- combo for city selection
    self.city = ISComboBox:new(x, y, (self.closeButton.x / 2) - padding, 30, self, function()
        self:setSelectedCity(self.city.selected)
    end);
    self.city:initialise()
    self:addChild(self.city)

    -- combo for multiple locations
    local l = self.city.x + self.city.width + padding
    local w = self.closeButton.x - padding - l
    self.location = ISComboBox:new(l, self.city.y, w, self.city.height, self, function()
        self:setSelectedLocation(self.location.selected)
    end);
    self.location:initialise()
    self:addChild(self.location)

    -- overlay for when there is not multiple options for location
    self.locationSingle = ISPanel:new(self.location.x, self.location.y, self.location.width, self.location.height);
    self.locationSingle:initialise();
    self.locationSingle.backgroundColor = self.location.backgroundColor;
    self.locationSingle.borderColor = self.location.borderColor;
    self.locationSingle:setVisible(true)
    self:addChild(self.locationSingle)

    -- description
    self.description = ISRichTextPanel:new(x, self.city.y + self.city.height + 10, self.width - (padding * 2), 50);
    self.description:initialise();
    self.description:instantiate();
    self.description.marginLeft = 5
    self.description.marginTop = 5
    self.description.marginRight = 5
    self.description.marginBottom = 5
    self.description.background = false
    self.description.borderColor = self.buttonBorderColor
    self.description:setText("")
    self.description.autosetheight = false
    self.description.clip = true
    self.description:paginate()

    self:addChild(self.description);

    y = self.description.y + self.description.height + 10

    -- map
    self.miniMap = ISMiniMapInner:new(padding, y, self.width - (padding * 2), self.height - y - 45, self.pIndex);
    self:addChild(self.miniMap);
    self:InitPlayer()

    x = padding

    if isAdmin() then
        self.showAll = ISTickBox:new(x, self.height - 35, 25, 25, "", self, function()

        end)
        self.showAll:initialise();
        self.showAll:addOption("Show all");
        self.showAll.changeOptionMethod = function()
            if self.showAll.selected[1] then
                self:rebuild(PhunSpawn:getAllSpawnPoints())
                self.miniMap.mapAPI:setBoolean("HideUnvisited", false)
            else
                -- api:setBoolean("HideUnvisited", true)
                local points = PhunSpawn:getSpawnPoints()
                for k, v in pairs(points) do
                    if v.enabled ~= true then
                        points[k] = v
                    end
                end
                self:rebuild(points)
            end
        end
        self.showAll:setSelected(1, false)
        self:addChild(self.showAll);

        x = x + 100
    end

    -- ok button
    self.ok = ISButton:new(x, self.height - 35, self.width - x - padding, 25, "Leave Room", self, function()

        if self.selectedLocation then
            local loc = self.selectedLocation
            self:exitRoom(self.selectedLocation.title, self.selectedLocation.city, loc.x, loc.y, loc.z)
        end

    end)
    self.ok:initialise()
    self:addChild(self.ok)

    -- disabled cover for ok button
    self.notOk = ISPanel:new(self.ok.x, self.ok.y, self.ok.width, self.ok.height);
    self.notOk:initialise();
    self.notOk.backgroundColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 0.8
    };
    self.notOk.borderColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 1
    };
    self.notOk:setVisible(true)
    self:addChild(self.notOk)

end

function PhunSpawnSelectorUI:new(x, y, width, height, player)
    local o = {};
    o = ISPanelJoypad:new(x, y, width, height, player);
    setmetatable(o, self);
    self.__index = self;

    o.variableColor = {
        r = 0.9,
        g = 0.55,
        b = 0.1,
        a = 1
    };
    o.backgroundColor = {
        r = 0,
        g = 0,
        b = 0,
        a = 0.8
    };
    o.buttonBorderColor = {
        r = 0.7,
        g = 0.7,
        b = 0.7,
        a = 1
    };
    o.markerSelectedBackgroundColor = {
        r = 0.0,
        g = 0.9,
        b = 0,
        a = 1
    };
    o.markerSelectedBorderColour = {
        r = 0,
        g = 0,
        b = 0,
        a = 1
    };
    o.markerBackgroundColour = {
        r = 0,
        g = 0,
        b = 0.6,
        a = 1
    };
    o.markerBorderColour = {
        r = 0,
        g = 0,
        b = 1,
        a = 1
    };
    o.anchorRight = true
    o.anchorBottom = true
    o.player = player
    o.pIndex = player:getPlayerNum()
    o.zOffsetLargeFont = 25;
    o.zOffsetMediumFont = 20;
    o.zOffsetSmallFont = 6;
    o.selectedCity = nil;
    o.selectedLocation = nil;
    o:setWantKeyEvents(true)
    return o;
end

--[[

    Keyboad stuff

]] -- ]   

function PhunSpawnSelectorUI:isKeyConsumed(key)
    return key == Keyboard.KEY_ESCAPE
end

function PhunSpawnSelectorUI:onKeyRelease(key)
    if key == Keyboard.KEY_ESCAPE then
        self:close()
    end
end

--[[

    MiniMap

]] --
function PhunSpawnSelectorUI:InitPlayer()
    local mini = self.miniMap
    local api = mini.mapAPI

    local dirs = getLotDirectories()
    for i = 1, dirs:size() do

        local file = 'media/maps/' .. dirs:get(i - 1) .. '/worldmap.xml'
        if fileExists(file) then
            mini.mapAPI:addData(file)
        end

        api:endDirectoryData()

        api:addImages('media/maps/' .. dirs:get(i - 1))
    end
    api:setBoundsFromWorld()
    api:setZoom(11.5)

    api:setBoolean("HideUnvisited", true)
    api:setBoolean("Players", true)
    api:setBoolean("Symbols", false)
    api:setBoolean("MiniMapSymbols", true)
    api:setBoolean("Isometric", false)
    api:setBoolean("RemotePlayers", true)
    api:setBoolean("PlayerNames", true)
    api:centerOn(api:getMaxXInSquares() / 2, api:getMaxYInSquares() / 2)

    function mini:onMouseUp(x, y)
        ISMiniMapInner.onMouseUp(self, x, y)
        if mini.dragging then
            mini.dragging = false
            if mini.dragMoved then
                return
            end

            for k, marker in pairs(mini.parent.cities) do

                if marker.labelX and x >= marker.labelX and x <= (marker.labelX + marker.titleWidth) and y >=
                    marker.labelY and y <= (marker.labelY + marker.titleHeight) then
                    return mini.parent:setSelectedCityByKey(k)
                end
            end
        end
        self.parent:recalcClusters()
    end

    function mini:onMouseWheel(del)
        local res = ISMiniMapInner.onMouseWheel(self, del)
        self.parent:recalcClusters()
        return res
    end

    MapUtils.initDefaultStyleV1(mini)

end
