if not isClient() then
    return
end
local PhunSpawn = PhunSpawn

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)

local FONT_SCALE = FONT_HGT_SMALL / 14
local HEADER_HGT = FONT_HGT_MEDIUM + 2 * 2

PhunSpawnSelectorUI = ISPanelJoypad:derive("PhunSpawnSelectorUI");
PhunSpawnSelectorUI.instances = {}

function PhunSpawnSelectorUI.OnOpenPanel(playerObj)

    if isAdmin() and PhunSpawn.data.allSpawnPoints == nil then
        sendClientCommand(playerObj, PhunSpawn.name, PhunSpawn.commands.getAllSpawns, {})
    end

    local pNum = playerObj:getPlayerNum()
    local ps = PhunSpawn
    local data = ps.data.spawnPoints or {}

    if PhunSpawnSelectorUI.instances[pNum] then
        -- there is already an instance of this panel for this player
        if not PhunSpawnSelectorUI.instances[pNum]:isVisible() then
            PhunSpawnSelectorUI.instances[pNum]:addToUIManager();
            PhunSpawnSelectorUI.instances[pNum]:setVisible(true);
            PhunSpawnSelectorUI.instances[pNum].spawns = data
            PhunSpawnSelectorUI.instances[pNum]:rebuild()
            PhunSpawnSelectorUI.instances[pNum]:refreshCitiesCombo()
            PhunSpawnSelectorUI.instances[pNum]:ensureVisible()
            return
        end
        return
    end

    local core = getCore()
    local FONT_SCALE = getTextManager():getFontHeight(UIFont.Small) / 14
    local core = getCore()
    local width = 400 * FONT_SCALE
    local height = 400 * FONT_SCALE

    local x = (core:getScreenWidth() - width) / 2
    local y = (core:getScreenHeight() - height) / 2

    local pIndex = playerObj:getPlayerNum()
    PhunSpawnSelectorUI.instances[pIndex] = PhunSpawnSelectorUI:new(x, y, width, height, playerObj);
    PhunSpawnSelectorUI.instances[pIndex]:initialise();
    PhunSpawnSelectorUI.instances[pIndex]:addToUIManager();
    PhunSpawnSelectorUI.instances[pNum].spawns = data
    PhunSpawnSelectorUI.instances[pNum]:rebuild()
    PhunSpawnSelectorUI.instances[pNum]:refreshCitiesCombo()
    PhunSpawnSelectorUI.instances[pNum]:ensureVisible()
    return PhunSpawnSelectorUI.instances[pIndex];

end

function PhunSpawnSelectorUI:rebuild(spawnpoints)

    self.city:clear()

    local cityKeys = {}

    local data = spawnpoints or self.spawns or {}

    local cities = {}
    local locations = {}
    local centerPointTotal = {
        x = 0,
        y = 0
    }
    local boundsTotal = {
        x = 0,
        y = 0,
        x2 = 0,
        y2 = 0
    }
    local cityCount = 0

    local discoveries = CPhunSpawnSystem.instance:getPlayerDiscoveries(self.player)

    for k, spawn in pairs(data) do

        local enable = spawn.enabled ~= false
        if spawn.autoDiscovered ~= true then
            enable = discoveries[k] == true
        end

        if enable then

            if not cities[spawn.city] then

                cities[spawn.city] = {
                    title = spawn.city,
                    titleWidth = getTextManager():MeasureStringX(UIFont.Small, spawn.city),
                    titleHeight = getTextManager():MeasureStringY(UIFont.Small, spawn.city),
                    titleLeft = 0,
                    titleTop = 0,
                    x = 0,
                    y = 0,
                    locations = {}
                }

                table.insert(cityKeys, spawn.city)
            end

            table.insert(cities[spawn.city].locations, k)

            local x = 0
            local y = 0
            local x2 = nil
            local y2 = nil

        end
    end

    for k, v in pairs(cities) do
        local city = cities[k]
        local locations = #city.locations

        for _, spawnKey in ipairs(city.locations) do
            local spawn = data[spawnKey]
            if spawn.x and spawn.y then
                city.x = city.x + spawn.x
                city.y = city.y + spawn.y
                centerPointTotal.x = centerPointTotal.x + spawn.x
                centerPointTotal.y = centerPointTotal.y + spawn.y
                cityCount = cityCount + 1
                if boundsTotal.x == 0 or spawn.x < boundsTotal.x then
                    boundsTotal.x = spawn.x
                end
                if boundsTotal.y == 0 or spawn.y < boundsTotal.y then
                    boundsTotal.y = spawn.y
                end
                if boundsTotal.x2 == 0 or spawn.x > boundsTotal.x2 then
                    boundsTotal.x2 = spawn.x
                end
                if boundsTotal.y2 == 0 or spawn.y > boundsTotal.y2 then
                    boundsTotal.y2 = spawn.y
                end
            end
        end

        city.x = city.x / #city.locations
        city.y = city.y / #city.locations

        city.titleLeft = city.x - (city.titleWidth / 2)
        city.titleTop = city.y - (city.titleHeight / 2) - 5
    end

    self.centerPoint = {
        x = centerPointTotal.x / cityCount,
        y = centerPointTotal.y / cityCount
    }

    self.cities = cities
    self.cityKeys = cityKeys
    self.initialBounds = boundsTotal
    local api = self.miniMap.mapAPI
    api:centerOn(centerPointTotal.x / cityCount, centerPointTotal.y / cityCount)

    -- TODO: Figure out how to zoom to bounding box
    -- local zx = api:worldToUIX(boundsTotal.x, boundsTotal.y)
    -- local zy = api:worldToUIY(boundsTotal.x2, boundsTotal.y2)

    -- local zoom = api:getZoomF()
    -- local w = self.miniMap:getWidth()
    -- local h = self.miniMap:getHeight()

    -- local zoomX = (boundsTotal.x2 - boundsTotal.x) / w
    -- local zoomY = (boundsTotal.y2 - boundsTotal.y) / h
    -- local newZoom = math.min(zoomX, zoomY)
    -- local scale = ISMap.SCALE
    -- local newScale = newZoom / zoom
    -- api:setZoom(8)

    -- api:zoomAt(centerPointTotal.x / cityCount, centerPointTotal.y / cityCount, newZoom)

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
    self.description:setText(" <LEFT> " .. (location.description or self.selectedCity.description or ""))
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

    -- self.noLocation:setVisible(location == nil)
    -- self.noLocation:setVisible(false)

    return isValid
end

function PhunSpawnSelectorUI:exitRoom(destinationTitle, destinationCity, destinationX, destinationY, destinationZ)

    print("exitRoom for ", destinationTitle, " in ", destinationCity, "x ", destinationX, ", y ", destinationY, ", z ",
        destinationZ)

    local message = getText("IGUI_PhunSpawn_Confirm_Exit_Room", destinationTitle, destinationCity)
    local w = 300
    local h = 200
    local modal = ISModalDialog:new(getCore():getScreenWidth() / 2 - w / 2, getCore():getScreenHeight() / 2 - h / 2, w,
        h, message, true, self, function(self, button)
            if button.internal == "YES" then

                local player = self.player

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
                    local room = square:getRoom()
                    if room then

                        local squares = room:getSquares()
                        -- move to a random free square in the room
                        local free = room:getRandomFreeSquare()
                        if free then
                            player:setX(free:getX())
                            player:setY(free:getY())
                            player:setZ(free:getZ())
                            player:setLx(free:getX())
                            player:setLy(free:getY())
                            player:setLz(free:getZ())
                            Events.OnPlayerUpdate.Remove(playerPorting)
                        end

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
                    end
                end
                Events.OnPlayerUpdate.Add(playerPorting)
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

function PhunSpawnSelectorUI:render()

    ISPanelJoypad.render(self)

    -- clip any markers on map that aren't visible
    self:setStencilRect(self.miniMap.x, self.miniMap.y, self.miniMap.width, self.miniMap.height)

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
    self.city = ISComboBox:new(x, y, 240, 30, self, function()
        self:setSelectedCity(self.city.selected)
    end);
    self.city:initialise()
    self:addChild(self.city)

    -- combo for multiple locations
    self.location = ISComboBox:new(self.city.x + self.city.width + padding, self.city.y, self.city.width,
        self.city.height, self, function()
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
                self:rebuild(PhunSpawn.data.allSpawnPoints)
            else
                self:rebuild(PhunSpawn.data.spawnPoints)
            end
        end
        self.showAll:setSelected(1, "Show all")
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
        if mini.dragging then
            mini.dragging = false
            if mini.dragMoved then
                return
            end

            for k, marker in pairs(mini.parent.cities) do

                if x >= marker.labelX and x <= (marker.labelX + marker.titleWidth) and y >= marker.labelY and y <=
                    (marker.labelY + marker.titleHeight) then
                    return mini.parent:setSelectedCityByKey(k)
                end
            end
        end
    end

    MapUtils.initDefaultStyleV1(mini)

end
