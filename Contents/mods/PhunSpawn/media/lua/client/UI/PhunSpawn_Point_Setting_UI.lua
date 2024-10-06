local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)

local FONT_SCALE = FONT_HGT_SMALL / 14
local HEADER_HGT = FONT_HGT_MEDIUM + 2 * 2

local PhunSpawn = PhunSpawn
PhunSpawnPointSettingUI = ISPanelJoypad:derive("PhunSpawnPointSettingUI");
local UI = PhunSpawnPointSettingUI
UI.instances = {}

function UI.OnOpenPanel(playerObj, obj)

    if PhunSpawn.data.allSpawnPoints == nil then
        sendClientCommand(playerObj, PhunSpawn.name, PhunSpawn.commands.getAllSpawns, {})
    end

    local data = PhunSpawn:getSpawnPoint(obj) or {}

    if not data.city then
        if PhunZones then
            local zone = PhunZones:getLocation(obj:getX(), obj:getY())
            if zone then
                data.city = zone.title
            end
        end
    end

    local square = obj:getSquare()

    local core = getCore()
    local FONT_SCALE = getTextManager():getFontHeight(UIFont.Small) / 14
    local core = getCore()
    local width = 400 * FONT_SCALE
    local height = 400 * FONT_SCALE

    local x = (core:getScreenWidth() - width) / 2
    local y = (core:getScreenHeight() - height) / 2

    local pIndex = playerObj:getPlayerNum()
    PhunSpawnPointSettingUI.instances[pIndex] = PhunSpawnPointSettingUI:new(x, y, width, height, playerObj, data,
        square, obj);
    PhunSpawnPointSettingUI.instances[pIndex]:initialise();
    PhunSpawnPointSettingUI.instances[pIndex]:addToUIManager();
    PhunSpawnPointSettingUI.instances[pIndex]:ensureVisible()
    return PhunSpawnPointSettingUI.instances[pIndex];

end

function UI:close()
    self:removeFromUIManager();
    UI.instances[self.pIndex] = nil
end

function UI:delete()
    local w = 300
    local h = 200
    local message = getText("IGUI_PhunSpawn_Confirm_Remove_Spawner")
    local modal = ISModalDialog:new(getCore():getScreenWidth() / 2 - w / 2, getCore():getScreenHeight() / 2 - h / 2, w,
        h, message, true, self, function(self, button)
            if button.internal == "YES" then
                sledgeDestroy(self.obj);

                local key = PhunSpawn:getKey(self.obj)
                PhunSpawn:removeDiscovery(self.player, key)

                sendClientCommand(self.player, PhunSpawn.name, PhunSpawn.commands.deleteSpawnPoint, {
                    key = key
                })
                self:close()
            end
        end)
    modal:initialise()
    modal:addToUIManager()
end

function UI:createChildren()

    ISPanelJoypad.createChildren(self);

    local padding = 10
    local x = padding
    local y = 50

    self.labelCity = ISLabel:new(padding, y, FONT_HGT_MEDIUM, getText("IGUI_PhunSpawn_Setting_City"), 1, 1, 1, 0.5,
        UIFont.small, true);
    self.labelCity:initialise();
    self.labelCity:instantiate();
    self:addChild(self.labelCity);

    y = y + self.labelCity.height + 2
    self.city = ISTextEntryBox:new(self.data.city or "", x, y, self.width - (padding * 2), 25);
    self.city:initialise();
    self.city:instantiate();
    self.city.onTextChange = function()
        self:isValid()
    end
    self:addChild(self.city);

    y = y + self.city.height + 5

    self.labelTitle = ISLabel:new(padding, y, FONT_HGT_MEDIUM, getText("IGUI_PhunSpawn_Setting_Title"), 1, 1, 1, 0.5,
        UIFont.small, true);
    self.labelTitle:initialise();
    self.labelTitle:instantiate();
    self:addChild(self.labelTitle);

    y = y + self.labelTitle.height + 2
    self.title = ISTextEntryBox:new(self.data.title or "", x, y, self.width - (padding * 2), 25);
    self.title:initialise();
    self.title:instantiate();
    self.title.onTextChange = function()
        self:isValid()
    end
    self:addChild(self.title);

    y = y + self.city.height + 5

    self.labelMod = ISLabel:new(padding, y, FONT_HGT_MEDIUM, getText("IGUI_PhunSpawn_Setting_Mod"), 1, 1, 1, 0.5,
        UIFont.small, true);
    self.labelMod:initialise();
    self.labelMod:instantiate();
    self:addChild(self.labelMod);

    y = y + self.labelMod.height + 2
    self.mod = ISTextEntryBox:new(self.data.mod or "", x, y, self.width - (padding * 2), 25);
    self.mod:initialise();
    self.mod:instantiate();
    self.mod.onTextChange = function()
        self:isValid()
    end
    self:addChild(self.mod);

    y = y + self.mod.height + 5

    self.labelDescription = ISLabel:new(padding, y, FONT_HGT_MEDIUM, getText("IGUI_PhunSpawn_Setting_Description"), 1,
        1, 1, 0.5, UIFont.small, true);
    self.labelDescription:initialise();
    self.labelDescription:instantiate();
    self:addChild(self.labelDescription);

    y = self.labelDescription.y + self.labelDescription.height + 2

    -- description
    self.description = ISTextEntryBox:new(self.data.description or "", x, y, self.width - (padding * 2), 100);
    self.description:initialise();
    self.description:instantiate();
    self.description.onTextChange = function()
        self:isValid()
    end
    self:addChild(self.description);

    y = self.description.y + self.description.height + 5

    self.discoverable = ISTickBox:new(padding, y, 25, 25, "", self, function()
    end)
    self.discoverable:initialise();
    self.discoverable:addOption(getText("IGUI_PhunSpawn_Setting_Discoverable"));
    self.discoverable.changeOptionMethod = function()
        self:isValid()
    end
    self.discoverable:setSelected(1, self.data.discoverable == true)
    self:addChild(self.discoverable);

    self.autoDiscovered = ISTickBox:new((self.width / 2) - (padding * 2), y, 25, 25, "", self, function()
    end)
    self.autoDiscovered:initialise();
    self.autoDiscovered:addOption(getText("IGUI_PhunSpawn_Setting_AutoDiscovered"));
    self.autoDiscovered.changeOptionMethod = function()
        self:isValid()
    end
    self.autoDiscovered:setSelected(1, self.data.autoDiscovered == true)
    self:addChild(self.autoDiscovered);

    y = y + self.city.height + 5

    -- ok button
    self.deleteButton = ISButton:new(padding, self.height - 35, (self.width / 3) - (padding * 3), 25, getText("Delete"),
        self, function()
            self:delete()
        end)
    self.deleteButton:initialise()
    self:addChild(self.deleteButton)

    -- ok button
    self.ok = ISButton:new((self.width / 3) + padding, self.height - 35, (self.width / 3) - (padding * 3), 25,
        getText("Save"), self, function()
            self:isValid()
            if self.validData then
                self.obj:getModData().PhunSpawn = self.validData
                sendClientCommand(self.player, PhunSpawn.name, PhunSpawn.commands.upsertSpawnPoint, self.validData)
                self:close()
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

    self.cancel = ISButton:new(((self.width / 3) * 2) + padding, self.height - 35, (self.width / 3) - (padding * 3), 25,
        getText("Cancel"), self, function()
            self:close()
        end)
    self.cancel:initialise()
    self:addChild(self.cancel)

end

local function lblValid(lbl, isValid)
    if isValid then
        lbl:setColor(1, 1, 1)
    else
        lbl:setColor(1, 0, 0)
    end
end

function UI:isValid()

    local city = self.city:getText()
    local title = self.title:getText()
    local mod = self.mod:getText()
    local description = self.description:getText()
    local discoverable = self.discoverable:isSelected(1)
    local autoDiscovered = self.autoDiscovered:isSelected(1)
    local x, y, z = self.square:getX(), self.square:getY(), self.square:getZ()
    local key = x .. "_" .. y .. "_" .. z

    local validColor = {
        r = 1,
        g = 1,
        b = 1,
        a = 0.5
    }
    local invalidColor = {
        r = 1,
        g = 0,
        b = 0,
        a = 1
    }
    local isValid = true
    -- validate city
    if city == nil or city == "" then
        lblValid(self.labelCity, false)
        isValid = false
    else
        lblValid(self.labelCity, true)
        self.labelCity.color = validColor
    end

    -- validate title
    if title == nil or title == "" then
        lblValid(self.labelTitle, false)
        isValid = false
    else
        lblValid(self.labelTitle, true)
        self.labelTitle.color = validColor
    end

    if isValid then
        self.notOk:setVisible(false)
        self.validData = {
            city = city,
            title = title,
            mod = mod,
            key = key,
            description = description,
            discoverable = discoverable == true,
            autoDiscovered = autoDiscovered == true,
            x = x,
            y = y,
            z = z
        }
    else
        self.notOk:setVisible(true)
        self.validData = nil
    end

end

function UI:new(x, y, width, height, player, data, square, obj)
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
    o.data = data
    o.square = square
    o.obj = obj
    o.anchorRight = true
    o.anchorBottom = true
    o.player = player
    o.pIndex = player:getPlayerNum()
    o.zOffsetLargeFont = 25;
    o.zOffsetMediumFont = 20;
    o.zOffsetSmallFont = 6;
    o:setWantKeyEvents(true)
    return o;
end
--[[

    Keyboad stuff

]] -- ]   

function UI:isKeyConsumed(key)
    return key == Keyboard.KEY_ESCAPE
end

function UI:onKeyRelease(key)
    if key == Keyboard.KEY_ESCAPE then
        self:close()
    end
end
